/*

Model
    base struct for all database model structs
Cached(T) 
    pointer to database row object in the database cache
    when used as a model struct member, it represents a foreign key to another
    table.
    you can use @on_update=x and @on_delete=x, where x is any value of
    Foreign_Key_Action (WITHOUT the .) to append "ON UPDATE" & "ON DELETE"
    clauses to the foreign key relationship.
    for example:
        author: Cached(User); @on_update=SET_NULL @on_delete=SET_DEFAULT


init(filename)
    open the database
    filename is optional; uses in-memory database if omitted
fini()
    close the database

insert(obj)
    insert Model-"derived" object into the database
set(cached_obj, field_name, value)
    set the given field of the given cached object to the given value & save
update(cached_obj)
    save the entire cached object to the database
select_by_id(T, id)
    fetch a specific row by model and id number
select_from(T, where, ..params, limit=0, offset=0, allocator=temp)
    lookup an object in the database, save it to the cache, return a Cached(T)
    where, limit, and offset are optional, but must be constant
delete(*cached_obj)
    delete a cached database object from the database

fetch(*cached_obj)
    fetch the object from the database

is_fetched(cached_obj)
    returns whether or not the object exists in the local database cache
flush_cache()
    flush the local database cache

 */

ORM :: struct {
    INTERNAL_COLUMN_COUNT :: 3; // id, created, modified

    Model :: struct {
        id: s64;
        created: s32;  // UNIX timestamp for now
        modified: s32; // UNIX timestamp for now
    }

    Cached :: struct(type: Type) /*#modify { return is_a_model(type); }*/ {
        fetch_id: s64;
        using pointer: *type;
    }

    init :: (filename := ":memory:") #expand {
        database_already_existed := filename != ":memory:" && (#import "File_Utilities").file_exists(filename);

        { result, error := open(filename); AssertIfError(); }
        if !database_already_existed then for `TABLE_SCHEMAS { result, error := exec(it); AssertIfError(); }

        for string.[
            "journal_mode = WAL",
            "synchronous  = NORMAL",
            "foreign_keys = ON",
        ] { result, error := exec(tprint("PRAGMA %;", it)); AssertIfError(); }

        AssertIfError :: () #expand { assert(`result == .OK, "%: %", `result, `error); }
    }

    fini :: inline () { close(); }

    insert :: (obj: $T/Model) -> result: Result, user: Cached(T) {
        assert(obj.id == 0, "Attempted to insert a % with an id already set!", T);

        SQL_STATEMENT :: #run -> string {
            sb_values, sb_question_marks: String_Builder;
            for serializable_members_of(T) {
                if it_index != 0 then append(*sb_values, ", ");
                append(*sb_values, it.name);
                if member_is_foreign_key(it) then append(*sb_values, "_id");
                if it_index != 0 then append(*sb_question_marks, ", ");
                append(*sb_question_marks, "?");
            }
            return sprint("INSERT INTO %1(%2) VALUES (%3) RETURNING id, strftime(\"%%s\", created);",
            /* 1 */T,
            /* 2 */builder_to_string(*sb_values),
            /* 3 */builder_to_string(*sb_question_marks)
            );
        }

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result, .{};

        #insert -> string {
            sb: String_Builder;
            question_mark_index := 1;
            for serializable_members_of(T) {
                print_to_builder(*sb, ifx member_is_foreign_key(it) then #string XX
        result = ifx obj.%2.fetch_id == 0 then bind(statement, %1) else bind(statement, %1, obj.%2.fetch_id);
XX              else #string XX
        result = bind(statement, %1, %3obj.%2);
XX,             /* 1 */question_mark_index,
                /* 2 */it.name,
                /* 3 */get_sqlite_cast_string_for_model_member(it)
                );
                append(*sb, #string XX
        if result != .OK then return result, .{};
XX              );
                question_mark_index += 1;
            }
            return builder_to_string(*sb);
        }

        new_obj: *T;

        rows := 0;
        while true { result = step(statement); ifx result == {
            case .ROW;
                rows += 1;
                id := column_int64(statement, 0);
                #insert #run sprint(#string XX
                new_obj = table_set(*context.db_cache._%, id, obj);
XX,             /* 1 */T
                );
                new_obj.id = id;
                new_obj.created  = column_int(statement, 1);
                new_obj.modified = new_obj.created;
                continue;
            case .BUSY; continue;
            case .DONE; break;
            case;       return result, .{};
        }}
        assert(rows == 1);

        result = finalize(statement);
        return result, .{new_obj.id, new_obj};
    }

    set :: (cached_obj: $T/Cached, $field_name: string) -> result: Result #expand { return set(cached_obj, field_name, null); }
    set :: (cached_obj: $T/Cached, $field_name: string, value: $T2) -> result: Result #expand { // wish this didn't have to be #expand...
        SQL_STATEMENT :: #run sprint("UPDATE %1 SET %2%3 = ?, modified = CURRENT_TIMESTAMP WHERE id = ? RETURNING strftime(\"%%s\", modified);",
            /* 1 */T.type,
            /* 2 */field_name,
            /* 3 */ifx #run field_is_foreign_key(T.type, field_name) && !ends_with(field_name, "_id") then "_id"
        );

        #if #run type_info(T2).type == .POINTER then assert(value == null);

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        VALUE_IS_A_CACHED_STRUCT :: #run type_info(T2).type == .STRUCT && (cast(*Type_Info_Struct) type_info(T2)).name == "Cached";
        #if VALUE_IS_A_CACHED_STRUCT
            result = bind(statement, 1, value.fetch_id);
        else
            result = bind(statement, 1, value);
        if result != .OK then return result;

        result = bind(statement, 2, cached_obj.id);
        if result != .OK then return result;

        rows := 0;
        while true { result = step(statement); ifx result == {
            case .ROW;
                rows += 1;
                cached_obj.modified  = column_int(statement, 0);
                continue;
            case .BUSY; continue;
            case .DONE; break;
            case;       return result;
        }}
        assert(rows == 1);

        #insert #run sprint(ifx #run type_info(T2).type == .POINTER then #string XX
        cached_obj.%1 = .{};
XX          else #string XX
        cached_obj.%1 = value;
XX,     /* 1 */ifx ends_with_nocase(field_name, "_id") then slice(field_name, 0, field_name.count-3) else field_name);

        result = finalize(statement);
        return result;
    }

    update :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run -> string {
            sb_fields: String_Builder;
            for serializable_members_of(T.type) {
                if it_index != 0 then append(*sb_fields, ", ");
                append(*sb_fields, sprint("% = ?", it.name));
            }
            return sprint("UPDATE %1 SET %2, modified = CURRENT_TIMESTAMP WHERE id = ? RETURNING strftime(\"%%s\", modified);",
            /* 1 */T.type,
            /* 2 */builder_to_string(*sb_fields)
            );
        }
        INDEX_OF_ID_QUESTION_MARK :: #run serializable_members_of(T.type).count+1;

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        #insert -> string {
            sb: String_Builder;
            for serializable_members_of(T.type) {
                question_mark_index := it_index + 1;
                print_to_builder(*sb, ifx member_is_foreign_key(it) then #string XX
        result = ifx %2cached_obj.fetch_id == 0 then bind(statment, %1) else bind(statement, %1, %2cached_obj.%3);
XX              else #string XX
        result = bind(statement, %1, %2cached_obj.%3);
XX,             /* 1 */question_mark_index,
                /* 2 */get_sqlite_cast_string_for_model_member(it),
                /* 3 */it.name
                );
                append(*sb, #string XX
        if result != .OK then return result;
XX,             );
            }
            return builder_to_string(*sb);
        }

        result = bind(statement, INDEX_OF_ID_QUESTION_MARK, cached_obj.id);
        if result != .OK then return result;

        rows := 0;
        while true { result = step(statement); ifx result == {
            case .ROW;
                rows += 1;
                cached_obj.pointer.modified  = column_int(statement, 0);
                continue;
            case .BUSY; continue;
            case .DONE; break;
            case;       return result;
        }}
        assert(rows == 1);


        result = finalize(statement);
        return result;
    }

    // update :: ($type: Type, set: string, where: string, ..params: Any)

    select_by_id :: ($type: Type, id: s64) -> result: Result, obj: Cached(type) #modify { return is_a_model(type); } {
        result, rows := select_from(type, where="id = ?", id);
        defer array_free(rows);
        if rows.count == 0 then return result, .{};
        return result, rows[0];
    }

    select_from :: ($type: Type, $where := "", params: ..Any, $limit := 0, $offset := 0, allocator := temp) -> result: Result, rows: [..] Cached(type) #modify { return is_a_model(type); } {
        assert(is_a_model(type), "type must using #as a Model");
        assert(params.count == count_question_marks(where), "Mismatch between number of params passed in [%1] and the number of question marks in the SQL string [%2]",
        /* 1 */params.count,
        /* 2 */count_question_marks(where)
        );

        SQL_STATEMENT :: #run -> string {
            sb: String_Builder;
            for serializable_members_of(type) {
                if it_index != 0 then append(*sb, ", ");
                append(*sb, it.name);
                if member_is_foreign_key(it) then append(*sb, "_id");
            }
            return sprint("SELECT id, strftime(\"%%s\", created), strftime(\"%%s\", modified), %1 FROM %2 WHERE %3%4%5;",
            /* 1 */builder_to_string(*sb),
            /* 2 */type,
            /* 3 */where,
            /* 4 */ifx limit  then sprint(" LIMIT %" , limit ),
            /* 5 */ifx offset then sprint(" OFFSET %", offset)
            );
        }

        rows: [..] Cached(type);
        rows.allocator = allocator;

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result, rows;

        param_number: s32 = 1;
        for params {
            if it.type.type == {
                case .BOOL; #through;
                case .INTEGER;
                    if it.type.runtime_size <= 4
                        result = bind(statement, param_number, <<cast(*s32) it.value_pointer);
                    else
                        result = bind(statement, param_number, <<cast(*s64) it.value_pointer);
                case .FLOAT;
                    result = bind(statement, param_number, <<cast(*float64) it.value_pointer);
                case .STRING;
                    result = bind(statement, param_number, <<cast( *string) it.value_pointer);
            }
            if result != .OK then return result, rows;
            param_number += 1;
        }

        while true { result = step(statement); if result == {
            case .ROW;
                obj: type;
                fetch_row(*obj, statement);
                #insert #run sprint(#string XX
                pointer := table_set(*context.db_cache._%1, obj.id, obj);
XX,             /* 1 */type);
                array_add(*rows, .{obj.id, pointer});
                continue;
            case .BUSY; continue;
            case .DONE; break;
            case;       return result, rows;
        }}

        result = finalize(statement);
        return result, rows;
    }

    delete :: (using cached_obj: *$T/Cached) -> result: Result {
        SQL_STATEMENT :: #run sprint("DELETE FROM % WHERE id = ?;", T.type);

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        result = bind(statement, 1, id);
        if result != .OK then return result;

        while true { result = step(statement); if result == {
            case .BUSY; continue;
            case .DONE; break;
            case;       return result;
        }}

        #insert #run sprint(#string XX
        table_remove(*context.db_cache._%1, id);
XX,     /* 1 */T.type);
        pointer = null;
        fetch_id = 0;

        result = finalize(statement);
        return result;
    }

    // delete_from :: ($type: Type, where: string, ..params: Any)

    fetch :: (cached: *$T/Cached) -> result: Result {
        assert(cached.fetch_id != 0);
        result, fetched := select_by_id(T.type, cached.fetch_id);
        cached.pointer = fetched.pointer;
        return result;
    }

    is_a_model :: inline x => (#import "Compiler").is_subclass_of(cast(*Type_Info) x, "Model");

    get_sqlite_cast_string_for_model_member :: (info: Type_Info_Struct_Member) -> string {
        return ifx info.type.type == .BOOL then " cast(int)";
    }

    field_is_foreign_key :: ($type: Type, $field_name: string) -> bool {
        for serializable_members_of(type) if it.name == field_name return member_is_foreign_key(it);
        return false;
    }

    member_is_foreign_key :: (member: Type_Info_Struct_Member) -> bool {
        return member.type.type == .STRUCT && (cast(*Type_Info_Struct) member.type).name == "Cached";
    }

    get_foreign_key_name_from :: (member: Type_Info_Struct_Member, model_name: string) -> string {
        member_info := (cast(*Type_Info_Struct) member.type);
        return (cast(*Type_Info_Struct) <<cast(**Type_Info) *member_info.constant_storage[member_info.specified_parameters[0].offset_into_constant_storage]).name; // thanks, shwa!
    }

    is_fetched :: inline (using cached: $T/Cached) -> bool { return pointer != null; }
    is_null    :: inline (using cached: $T/Cached) -> bool { return fetch_id == 0;   }

    flush_cache :: () #expand { `__flush_database_cache(); } // :P

    #import "Hash_Table";
}
