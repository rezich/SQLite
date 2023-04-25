/*

Model
    base struct for all your database model structs
Cached(T) 
    pointer to database row object in the database cache

insert(obj)
    insert Model-"derived" object into the database
update(obj)
    save cached object changes to the database
select_by_id(T, id)
select_from(T, where, params, limit=0, offset=0)
    lookup an object in the database, save it to the cache, return a Cached(T)
    limit and offset are optional, but must be constant
delete(obj)
    delete a cached database object from the database

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

    init :: (filename: string) #expand {
        set_working_directory((#import "String").path_strip_filename((#import "System").get_path_of_running_executable()));
        database_already_existed := (#import "File_Utilities").file_exists(filename);
        #if DELETE_DATABASE_EVERY_RUN { (#import "File").file_delete(filename); database_already_existed = false; }
        { result, error := open(filename); AssertIfError(); }
        if !database_already_existed { result, error := exec(`DATABASE_SCHEMA); AssertIfError(); }
        for string.[
            "journal_mode = WAL",
            "synchronous  = NORMAL",
            "foreign_keys = ON",
        ] { result, error := exec(tprint("PRAGMA %;", it)); AssertIfError(); }
        AssertIfError :: () #expand { assert(`result == .OK, "%: %", `result, `error); }
    }

    fini :: () { close(); }

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
        statement: Statement;
        result: Result;

        result, statement = prepare_v2(SQL_STATEMENT);
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
                append(*sb, "if result != .OK then return result, .{};");
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

        result = finalize(statement);
        if result != .OK then return result, .{};

        #insert #run sprint("pointer := table_set(*context.db_cache._%, obj.id, obj);", T);
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
        statement: Statement;
        result: Result;

        result, statement = prepare_v2(SQL_STATEMENT);
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
            if result != .DONE then return result;
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
        statement: Statement;
        result: Result;

        result, statement = prepare_v2(SQL_STATEMENT);
        if result != .OK then return result, .{};

        result = bind(statement, 1, id);
        if result != .OK then return result, .{};

        obj: type;

        result = Result.BUSY;
        got_result := false;
        while result == .BUSY {
            result = step(statement);
            if result == .ROW {
                got_result = true;
                fetch_row(*obj, statement);
                continue;
            }
            if result != .DONE then return result, .{};
        }

        result = finalize(statement);
        if result != .OK then return result, .{};
        
        if !got_result return result, .{};

        #insert #run sprint("pointer := table_set(*context.db_cache._%, obj.id, obj);", type);
        return result, .{obj.id, pointer};
    }

    select_from :: ($type: Type, $where: string, params: ..Any, $limit: int=0, $offset: int=0) -> result: Result, rows: [..] Cached(type) {
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
            /* 4 */ifx limit then sprint(" LIMIT %", limit),
            /* 5 */ifx offset then sprint(" OFFSET %", offset)
            );
        }
        statement: Statement;
        result: Result;

        rows: [..] Cached(type);

        result, statement = prepare_v2(SQL_STATEMENT);
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
                    result = bind(statement, param_number, <<cast(*string)  it.value_pointer);
            }
            if result != .OK then return result, rows;
            param_number += 1;
        }

        result = Result.BUSY;
        got_result := false;
        while result == .BUSY || result == .ROW {
            result = step(statement);
            if result == .ROW {
                got_result = true;
                obj: type;
                fetch_row(*obj, statement);
                #insert #run sprint("pointer := table_set(*context.db_cache._%, obj.id, obj);", type);
                array_add(*rows, .{obj.id, pointer});
                continue;
            }
            if result != .DONE then return result, rows;
        }

        result = finalize(statement);
        if result != .OK then return result, rows;
        
        if !got_result return result, rows;
        
        return .OK, rows;
    }

    delete :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run sprint("DELETE FROM % WHERE id = ?;", T.type);
        statement: Statement;
        result: Result;

        result, statement = prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        result = bind(statement, 1, cached_obj.id);
        if result != .OK then return result;

        result = Result.BUSY;
        while result == .BUSY {
            result = step(statement);
            if result != .DONE then return result;
        }

        result = finalize(statement);

        #insert #run sprint("table_remove(*context.db_cache._%, cached_obj.id);", T.type);

        return result;
    }

    // delete_from :: ($type: Type, where: string)

    fetch :: (cached: *$T/Cached) -> result: Result {
        result: Result;
        fetched: T;
        result, fetched = select_by_id(T.type, cached.fetch_id);
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
        member_ti := (cast(*Type_Info_Struct) member.type);
        return (cast(*Type_Info_Struct) <<cast(**Type_Info) *member_ti.constant_storage[member_ti.specified_parameters[0].offset_into_constant_storage]).name;
    }

    id_or_fetch_id :: (using cached: $T/Cached) -> T.ID {
        assert(fetch_id != 0);
        if !is_fetched(cached) then return fetch_id; else return id;
    }

    is_fetched :: (using cached: $T/Cached) -> bool { return pointer != null; }

    flush_cache :: () #expand { `__flush_database_cache(); }
}

#import "Hash_Table";
