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
    lookup an object in the database, save it to the cache, return a Cached(T)
delete(obj)
    delete a cached database object from the database

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
        if !database_already_existed {
            { result, error := exec(`DATABASE_SCHEMA); AssertIfError(); }
            for string.[
                "journal_mode = WAL",
                "synchronous = NORMAL",
                "foreign_keys = ON",
            ] { result, error := exec(tprint("PRAGMA %;", it)); AssertIfError(); }
        }
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
            return sprint("INSERT INTO %1(%2) VALUES (%3) RETURNING id, strftime(\"%%s\", created);", T, builder_to_string(*sb_values), builder_to_string(*sb_question_marks));
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
XX,             question_mark_index, it.name);
                else print_to_builder(*sb, #string XX
        result = bind(statement, %1, %3_obj.%2);
XX,             question_mark_index, it.name, get_sqlite_cast_string_for_model_member(it));
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

        #insert #run sprint("cache := context.db_cache._%1;", T);
        return result, .{obj.id, table_set(*cache, obj.id, obj)};
    }

    update :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run -> string {
            sb_fields: String_Builder;
            for serializable_members_of(T.type) {
                if it_index != 0 then append(*sb_fields, ", ");
                append(*sb_fields, sprint("% = ?", it.name));
            }
            return sprint("UPDATE %1 SET %2, modified = CURRENT_TIMESTAMP WHERE id = ?;", T.type, builder_to_string(*sb_fields));
        }
        INDEX_OF_ID_QUESTION_MARK :: #run serializable_members_of(T.type).count;
        statement: Statement;
        result: Result;

        result, statement = prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        #insert -> string {
            sb: String_Builder;
            for serializable_members_of(T.type) {
                question_mark_index := it_index + 1;
                print_to_builder(*sb, #string XX
        result = bind(statement, %1, %3cached_obj.%2);
        if result != .OK then return result;
    XX,         question_mark_index, it.name, get_sqlite_cast_string_for_model_member(it));
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
            return sprint("SELECT id, strftime(\"%%s\", created), strftime(\"%%s\", modified), %1 FROM %2 WHERE id = ?;", builder_to_string(*sb), type);
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

        #insert #run sprint("cache := context.db_cache._%1;", type);
        return result, .{obj.id, table_set(*cache, obj.id, obj)};
    }

    select_from :: ($type: Type, where: string) -> result: Result, rows: [..] Cached(type) {
        rows: [..] Cached(type);
        return .OK, rows;
    }

    delete :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run sprint("DELETE FROM %1 WHERE id = ?;", T.type);
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

        #insert #run sprint("cache := context.db_cache._%1;", T.type);
        table_remove(*cache, cached_obj.id);

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
                obj.%1.fetch_id = xx column_int64(statement, %2);
XX, it.name, column_number);
                else if it.type.type == {
                    case .BOOL; print_to_builder(*sb, #string XX
                obj.%1 = cast(bool) column_int(statement, %2);
XX, it.name, column_number);
                    case .INTEGER; print_to_builder(*sb, #string XX
                obj.%1 = column_int%3(statement, %2);
XX, it.name, column_number, ifx it.type.runtime_size == 8 then "64");
                    case .FLOAT; print_to_builder(*sb, #string XX
                obj.%1 = %3column_double(statement, %2);
XX, it.name, column_number, ifx it.type.runtime_size == 4 then "xx ");
                    case .STRING; print_to_builder(*sb, #string XX
                obj.%1 = column_text(statement, %2);
XX, it.name, column_number);
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
        if info.type.type == {
            case .BOOL; return " cast(int)";
        }
        return "";
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

    id_or_fetch_id :: (using cached: $T/Cached) -> T.ID {
        assert(fetch_id != 0);
        if !is_fetched(cached) then return fetch_id; else return id;
    }

    is_fetched :: (using cached: $T/Cached) -> bool { return pointer != null; }
}

#import "Hash_Table";
