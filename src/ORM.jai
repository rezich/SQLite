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
    Model :: struct {
        id: s64;
        created: s32;  // UNIX timestamp for now
        modified: s32; // UNIX timestamp for now
    }

    Cached :: struct(type: Type) #modify {
        return is_subclass_of(cast(*Type_Info) type, "Model");
    }{
        using object: *type;
    }

    /*generate_schema_for :: ($model_types: ..Type) -> string #modify {
        for model_types if !is_subclass_of(cast(*Type_Info) it, "Model") then return false;
        return true;
    }{
        sb_schema: String_Builder;
        for model_types {
            // ...
        }
        return builder_to_string(*sb_schema);
    }*/

    insert :: (_obj: $T/Model) -> result: Result, user: Cached(T) {
        assert(_obj.id == 0, "Attempted to insert a % with an id already set!", T);
        obj := _obj;

        SQL_STATEMENT :: #run -> string {
            sb_values, sb_question_marks: String_Builder;
            is_first_field := true;
            members := type_info(T).members;
            for members {
                if it.type.type == {
                    case .INTEGER; #through;
                    case .FLOAT; #through;
                    case .STRING;
                        if !is_first_field then append(*sb_values, ", ");
                        append(*sb_values, it.name);
                        if !is_first_field then append(*sb_question_marks, ", ");
                        append(*sb_question_marks, "?");
                        is_first_field = false;
                }
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
            for type_info(T).members {
                if it.type.type == {
                    case .INTEGER; #through;
                    case .FLOAT; #through;
                    case .STRING;
                        append(*sb, sprint(#string XX
        result = bind(statement, %1, _obj.%2);
        if result != .OK then return result, .{};
    XX, question_mark_index, it.name));
                        question_mark_index += 1;
                }
            }
            return builder_to_string(*sb);
        }

        result = Result.BUSY;
        while result == .BUSY {
            result = step(statement);
            if result == .ROW {
                obj.id = column_int64(statement, 0);
                obj.created = column_int(statement, 1);
                obj.modified = obj.created;
                continue;
            }
            if result != .DONE then return result, .{};
        }

        result = finalize(statement);
        if result != .OK then return result, .{};

        #insert #run sprint("cache := context.db_cache._%1;", T);
        return result, .{table_set(*cache, obj.id, obj)};
    }

    update :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run -> string {
            sb_fields: String_Builder;
            is_first_field := true;
            for type_info(T.type).members {
                if it.type.type == {
                    case .INTEGER; #through;
                    case .FLOAT; #through;
                    case .STRING;
                        if !is_first_field then append(*sb_fields, ", ");
                        append(*sb_fields, sprint("% = ?", it.name));
                        is_first_field = false;
                }
            }
            return sprint("UPDATE %1 SET %2, modified = CURRENT_TIMESTAMP WHERE id = ?;", T.type, builder_to_string(*sb_fields));
        }
        INDEX_OF_ID_QUESTION_MARK :: #run -> int {
            question_mark_index := 1;
            for type_info(T.type).members {
                if it.type.type == {
                    case .INTEGER; #through;
                    case .FLOAT; #through;
                    case .STRING;
                        question_mark_index += 1;
                }
            }
            return question_mark_index;
        }
        statement: Statement;
        result: Result;

        result, statement = prepare_v2(SQL_STATEMENT);
        if result != .OK then return result;

        #insert -> string {
            sb: String_Builder;
            question_mark_index := 1;
            for type_info(T.type).members {
                if it.type.type == {
                    case .INTEGER; #through;
                    case .FLOAT; #through;
                    case .STRING;
                        append(*sb, sprint(#string XX
        result = bind(statement, %1, cached_obj.%2);
        if result != .OK then return result;
    XX, question_mark_index, it.name));
                        question_mark_index += 1;
                }
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

    select_by_id :: ($type: Type, id: s64) -> result: Result, obj: Cached(type) #modify {
        return is_subclass_of(cast(*Type_Info) type, "Model");
    }{
        SQL_STATEMENT :: #run -> string {
            sb: String_Builder;
            is_first_field := true;
            for type_info(type).members {
                if it.type.type == {
                    case .INTEGER; #through;
                    case .FLOAT; #through;
                    case .STRING;
                        if !is_first_field then append(*sb, ", ");
                        append(*sb, it.name);
                        is_first_field = false;
                }
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
                obj.id       = column_int64(statement, 0);
                obj.created  = column\ _int(statement, 1);
                obj.modified = column\ _int(statement, 2);
                #insert -> string {
                    sb: String_Builder;
                    column_number := 3;
                    for type_info(type).members {
                        if it.type.type == {
                            case .INTEGER; append(*sb, sprint(#string XX
                obj.%1 = column_int%3(statement, %2);
    XX, it.name, column_number, ifx it.type.runtime_size == 8 then "64"));
                            case .FLOAT; append(*sb, sprint(#string XX
                obj.%1 = %3column_double(statement, %2);
    XX, it.name, column_number, ifx it.type.runtime_size == 4 then "xx "));
                            case .STRING; append(*sb, sprint(#string XX
                obj.%1 = column_text(statement, %2);
    XX, it.name, column_number));
                            case; continue;
                        }
                        column_number += 1;
                    }
                    return builder_to_string(*sb);
                }
                continue;
            }
            if result != .DONE then return result, .{};
        }

        result = finalize(statement);
        if result != .OK then return result, .{};
        
        if !got_result return result, .{};

        #insert #run sprint("cache := context.db_cache._%1;", type);
        return result, .{table_set(*cache, obj.id, obj)};
    }

    delete :: (cached_obj: $T/Cached) -> result: Result {
        SQL_STATEMENT :: #run -> string {
            return sprint("DELETE FROM %1 WHERE id = ?;", T.type);
        }
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

}


#import "Compiler";
