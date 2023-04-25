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
update(obj)
    save cached object changes to the database
select_by_id(T, id)
    fetch a specific row by model and id number
select_from(T, where, ..params, limit=0, offset=0)
    lookup an object in the database, save it to the cache, return a Cached(T)
    where, limit, and offset are optional, but must be constant
delete(*obj)
    delete a cached database object from the database

fetch(*obj)
    fetch the object from the database

is_fetched(obj)
    returns whether or not the object exists in the local database cache
flush_cache()
    flush the local database cache

 */

ORM :: struct {
    DELETE_DATABASE_EVERY_RUN :: true; // for testing
    INTERNAL_COLUMN_COUNT :: 3; // id, created, modified

    Model :: struct {
        id: ID;
        created: s32;  // UNIX timestamp for now
        modified: s32; // UNIX timestamp for now

        ID :: #type,isa s64;
    }

    Cached :: struct(type: Type) #modify { return is_a_model(type); } {
        fetch_id: type.ID;
        using pointer: *type;
    }

    init :: (filename := ":memory:") #expand {
        #if DELETE_DATABASE_EVERY_RUN if filename != ":memory:" then (#import "File").file_delete(filename);
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

    insert :: (_obj: $T/Model) -> result: Result, user: Cached(T) {
        assert(_obj.id == 0, "Attempted to insert a % with an id already set!", T);
        obj := _obj;

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
                if member_is_foreign_key(it) then print_to_builder(*sb, #string XX
        result = bind(statement, %1, id_or_fetch_id(_obj.%2));
XX,             /* 1 */question_mark_index,
                /* 2 */it.name
                );
                else print_to_builder(*sb, #string XX
        result = bind(statement, %1, %3_obj.%2);
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

        result = Result.BUSY;
        while result == .BUSY {
            result = step(statement);
            if result == .ROW {
                obj.id       = xx column_int64(statement, 0);
                obj.created  =    column_int  (statement, 1);
                obj.modified =    obj.created;
                continue;
            }
            if result != .DONE then return result, .{};
        }

        #insert #run sprint(#string XX
        pointer := table_set(*context.db_cache._%, obj.id, obj);
XX,     /* 1 */T
        );

        result = finalize(statement);
        return result, .{obj.id, pointer};
    }

    update :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run -> string {
            sb_fields: String_Builder;
            for serializable_members_of(T.type) {
                if it_index != 0 then append(*sb_fields, ", ");
                append(*sb_fields, sprint("% = ?", it.name));
            }
            return sprint("UPDATE %1 SET %2, modified = CURRENT_TIMESTAMP WHERE id = ?;",
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
                print_to_builder(*sb, #string XX
        result = bind(statement, %1, %2cached_obj.%3);
        if result != .OK then return result;
    XX,         /* 1 */question_mark_index,
                /* 2 */get_sqlite_cast_string_for_model_member(it),
                /* 3 */it.name
                );
            }
            return builder_to_string(*sb);
        }

        result = bind(statement, INDEX_OF_ID_QUESTION_MARK, cached_obj.id);
        if result != .OK then return result;

        result = Result.BUSY;
        while result == .BUSY {
            result = step(statement);
            if result != .DONE && result != .BUSY then return result;
        }

        result = finalize(statement);
        return result;
    }

    // update :: ($type: Type, set: string, where: string)

    select_by_id :: ($type: Type, id: type.ID) -> result: Result, obj: Cached(type) #modify { return is_a_model(type); } {
        SQL_STATEMENT :: #run -> string {
            sb: String_Builder;
            for serializable_members_of(type) {
                if it_index != 0 then append(*sb, ", ");
                append(*sb, it.name);
                if member_is_foreign_key(it) then append(*sb, "_id");
            }
            return sprint("SELECT id, strftime(\"%%s\", created), strftime(\"%%s\", modified), %1 FROM %2 WHERE id = ?;",
            /* 1 */builder_to_string(*sb),
            /* 2 */type
            );
        }

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result, .{};

        result = bind(statement, 1, id);
        if result != .OK then return result, .{};

        obj: type;

        result = Result.BUSY;
        while result == .BUSY {
            result = step(statement);
            if result == .ROW { fetch_row(*obj, statement); break; }
            if result != .DONE && result != .BUSY then return result, .{};
        }

        #insert #run sprint(#string XX
        pointer := table_set(*context.db_cache._%1, obj.id, obj);
XX,     /* 1 */type);

        result = finalize(statement);
        return result, .{obj.id, pointer};
    }

    select_from :: ($type: Type, $where := "", params: ..Any, $limit := 0, $offset := 0) -> result: Result, rows: [..] Cached(type) {
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

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result, rows;

        param_number: s32 = 1;
        for params {
            if it.type.type == {
                case .VARIANT; #through; //HACK
                case .BOOL; #through;
                case .INTEGER;
                    if it.type.runtime_size <= 4
                        result = bind(statement, param_number, <<cast(*s32) it.value_pointer);
                    else
                        result = bind(statement, param_number, <<cast(*s64) it.value_pointer);
                case .FLOAT;
                    result = bind(statement, param_number, <<cast(*float64) it.value_pointer);
                case .STRING;
                    result = bind(statement, param_number, <<cast(*string ) it.value_pointer);
            }
            if result != .OK then return result, rows;
            param_number += 1;
        }

        result = Result.BUSY;
        while result == .BUSY || result == .ROW {
            result = step(statement);
            if result == .ROW {
                obj: type;
                fetch_row(*obj, statement);
                #insert #run sprint(#string XX
                pointer := table_set(*context.db_cache._%1, obj.id, obj);
XX,             /* 1 */type);
                array_add(*rows, .{obj.id, pointer});
                continue;
            }
            if result != .DONE && result != .BUSY then return result, rows;
        }

        result = finalize(statement);
        return result, rows;
    }

    delete :: (using cached_obj: *$T/Cached) -> result: Result {
        SQL_STATEMENT :: #run sprint("DELETE FROM % WHERE id = ?;", T.type);

        result, statement := prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        result = bind(statement, 1, id);
        if result != .OK then return result;

        result = Result.BUSY;
        while result == .BUSY {
            result = step(statement);
            if result != .DONE && result != .BUSY then return result;
        }

        #insert #run sprint(#string XX
        table_remove(*context.db_cache._%1, id);
XX,     /* 1 */ T.type);
        pointer = null;

        result = finalize(statement);
        return result;
    }

    // delete_from :: ($type: Type, where: string)

    fetch :: (cached: *$T/Cached) -> result: Result {
        result, fetched := select_by_id(T.type, cached.fetch_id);
        cached.pointer = fetched.pointer;
        return result;
    }

    fetch_row :: (obj: *$T/Model, statement: Statement) {
        obj.id       = xx column_int64(statement, 0);
        obj.created  =    column_int  (statement, 1);
        obj.modified =    column_int  (statement, 2);
        #insert -> string {
            sb: String_Builder;
            column_number := INTERNAL_COLUMN_COUNT;
            for serializable_members_of(T) {
                if member_is_foreign_key(it) then print_to_builder(*sb, #string XX
        id := column_int64(statement, %2);
        found := table_find_pointer(*context.db_cache._%3, id);
        if found then obj.%1 = .{xx id, found}; else obj.%1 = .{xx id, null};
XX,             /* 1 */it.name,
                /* 2 */column_number,
                /* 3 */get_foreign_key_name_from(it)
                );
                else if it.type.type == {
                    case .BOOL; print_to_builder(*sb, #string XX
        obj.%1 = cast(bool) column_int(statement, %2);
XX,                 /* 1 */it.name,
                    /* 2 */column_number
                    );
                    case .INTEGER; print_to_builder(*sb, #string XX
        obj.%1 = column_int%3(statement, %2);
XX,                 /* 1 */it.name,
                    /* 2 */column_number,
                    /* 3 */ifx it.type.runtime_size == 8 then "64"
                    );
                    case .FLOAT; print_to_builder(*sb, #string XX
        obj.%1 = %3column_double(statement, %2);
XX,                 /* 1 */it.name,
                    /* 2 */column_number,
                    /* 3 */ifx it.type.runtime_size == 4 then "xx "
                    );
                    case .STRING; print_to_builder(*sb, #string XX
        obj.%1 = column_text(statement, %2);
XX,                 /* 1 */it.name,
                    /* 2 */column_number
                    );
                    case; continue;
                }
                column_number += 1;
            }
            return builder_to_string(*sb);
        }
    }

    is_a_model :: (type: Type) -> bool {
        return (#import "Compiler").is_subclass_of(cast(*Type_Info) type, "Model");
    }

    is_a_model :: (info: *Type_Info_Struct) -> bool {
        return (#import "Compiler").is_subclass_of(cast(*Type_Info) info, "Model");
    }

    get_sqlite_cast_string_for_model_member :: (info: Type_Info_Struct_Member) -> string {
        return ifx info.type.type == .BOOL then " cast(int)";
    }

    serializable_members_of :: ($type: Type) -> [..] Type_Info_Struct_Member {
        return serializable_members_of(type_info(type));
    }

    serializable_members_of :: (info: *Type_Info_Struct) -> [..] Type_Info_Struct_Member {
        NOTE_NOSERIALIZE :: "NoSerialize";

        members: [..] Type_Info_Struct_Member;
        for info.members {
            if  !member_is_foreign_key(it) &&
                it.type.type != .BOOL      &&
                it.type.type != .INTEGER   &&
                it.type.type != .FLOAT     &&
                it.type.type != .STRING
            then continue;
            has_noserialize_note := false;
            for it.notes if it == NOTE_NOSERIALIZE { has_noserialize_note = true; break; }
            if has_noserialize_note then continue;
            array_add(*members, it);
        }
        return members;
    }

    member_is_foreign_key :: (member: Type_Info_Struct_Member) -> bool {
        if member.type.type == .STRUCT then return (cast(*Type_Info_Struct) member.type).name == "Cached";
        return false;
    }
    get_foreign_key_name_from :: (member: Type_Info_Struct_Member) -> string {
        member_info := (cast(*Type_Info_Struct) member.type);
        return (cast(*Type_Info_Struct) <<cast(**Type_Info) *member_info.constant_storage[member_info.specified_parameters[0].offset_into_constant_storage]).name; // thanks, shwa!
    }

    id_or_fetch_id :: (using cached: $T/Cached) -> T.ID {
        assert(fetch_id != 0);
        if !is_fetched(cached) then return fetch_id; else return id;
    }

    is_fetched :: (using cached: $T/Cached) -> bool { return pointer != null; }

    flush_cache :: () #expand { `__flush_database_cache(); } // :P

    #import "Hash_Table";
}
