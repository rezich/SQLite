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

is_fetched(cached_obj)
    returns whether or not the object exists in the local database cache
is_null(cached_obj)
    returns whether or not the object "is a null reference" (fetch_id == 0)
reset_model_cache()
    flush the database cache in the context

*/

NOTE_DO_NOT_SERIALIZE :: "do_not_serialize";
NOTE_AUTOFETCH        :: "autofetch";
NOTE_FETCH            :: "fetch";

Model :: struct {
    id: s64;
    created: s32;  // UNIX timestamp for now
    modified: s32; // UNIX timestamp for now
}
ORM_INTERNAL_COLUMN_COUNT :: #run type_info(Model).members.count;

Cached :: struct(type: Type) /*#modify { return is_a_model(type); }*/ {
    fetch_id: s64;
    using pointer: *type;
}
operator? :: (cached_obj: $T/Cached, when_null: Code, caller_code := #caller_code) -> T #expand {
    if is_null(cached_obj) then #insert,scope(caller_code) when_null;
    return cached_obj;
}
operator? :: (cached_objs: [] $T/Cached, when_null: Code, caller_code := #caller_code) -> [] T #expand {
    if cached_objs.count == 0 then #insert,scope(caller_code) when_null;
    return cached_objs;
}
operator== :: (a: $T/Cached, b: T) -> bool { return a.fetch_id == b.fetch_id && a.pointer == b.pointer; }

init_model_cache :: () #expand {
    using context.sqlite;
    assert(!is_open);
    database_already_existed := filename != ":memory:" && (#import "File_Utilities").file_exists(filename);
    set_pragmas(.[
        "journal_mode = WAL",
        "synchronous  = NORMAL",
        "foreign_keys = ON"
    ]);
    if !database_already_existed then {
        open();
        for `TABLE_SCHEMAS assert_ok(exec(it));
        close();
    }
}

insert :: (obj: $T/Model) -> Cached(T) {
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
        /* 1 */ T,
        /* 2 */ builder_to_string(*sb_values),
        /* 3 */ builder_to_string(*sb_question_marks)
        );
    }

    result, statement := prepare(SQL_STATEMENT);
    assert_ok(result);

    #insert -> string {
        sb: String_Builder;
        question_mark_index := 1;
        for serializable_members_of(T) {
            print_to_builder(*sb, ifx member_is_foreign_key(it) then #string XX
    assert_ok(ifx obj.%2.fetch_id == 0 then bind(statement, %1) else bind(statement, %1, obj.%2.fetch_id));
XX              else #string XX
    assert_ok(bind(statement, %1, obj.%2));
XX,         /* 1 */ question_mark_index,
            /* 2 */ it.name
            );
            question_mark_index += 1;
        }
        return builder_to_string(*sb);
    }

    new_obj: *T;

    for statement {
        assert(it_index == 0);
        id := column_int64(statement, 0);
        #insert #run sprint(#string XX
        new_obj = table_set(*context.sqlite_model_cache._%, id, obj);
XX,     /* 1 */ T
        );
        new_obj.id = id;
        new_obj.created  = column_int(statement, 1);
        new_obj.modified = new_obj.created;
    }
    assert(!!new_obj);

    assert_ok(finalize(statement));
    return .{new_obj.id, new_obj};
}

set :: (cached_obj: $T/Cached, $field_name: string) { set(cached_obj, field_name, null); }
set :: (cached_obj: $T/Cached, $field_name: string, value: $T2) #expand {
    SQL_STATEMENT :: #run sprint("UPDATE %1 SET %2%3 = ?, modified = CURRENT_TIMESTAMP WHERE id = ? RETURNING strftime(\"%%s\", modified);",
        /* 1 */ T.type,
        /* 2 */ field_name,
        /* 3 */ ifx #run field_is_foreign_key(T.type, field_name) && !ends_with(field_name, "_id") then "_id"
    );

    #if #run type_info(T2).type == .POINTER then assert(value == null);

    result, statement := prepare(SQL_STATEMENT);
    assert_ok(result);

    #if #run ((type_info(T2).type == .STRUCT && (cast(*Type_Info_Struct) type_info(T2)).name == "Cached"))
        assert_ok(bind(statement, 1, value.fetch_id));
    else
        assert_ok(bind(statement, 1, value));

    assert_ok(bind(statement, 2, cached_obj.id));

    for statement cached_obj.modified = column_int(statement, 0);

    #insert #run sprint(ifx #run type_info(T2).type == .POINTER then #string XX
    cached_obj.%1 = .{};
XX      else #string XX
    cached_obj.%1 = value;
XX, /* 1 */ ifx ends_with_nocase(field_name, "_id") then slice(field_name, 0, field_name.count-3) else field_name);

    assert_ok(finalize(statement));
}

update :: (cached_obj: $T/Cached) {
    SQL_STATEMENT :: #run -> string {
        sb_fields: String_Builder;
        for serializable_members_of(T.type) {
            if it_index != 0 then append(*sb_fields, ", ");
            append(*sb_fields, sprint("% = ?", it.name));
        }
        return sprint("UPDATE %1 SET %2, modified = CURRENT_TIMESTAMP WHERE id = ? RETURNING strftime(\"%%s\", modified);",
        /* 1 */ T.type,
        /* 2 */ builder_to_string(*sb_fields)
        );
    }
    INDEX_OF_ID_QUESTION_MARK :: #run serializable_members_of(T.type).count+1;

    result, statement := prepare(SQL_STATEMENT);
    assert_ok(result);

    #insert -> string {
        sb: String_Builder;
        for serializable_members_of(T.type) {
            question_mark_index := it_index + 1;
            print_to_builder(*sb, ifx member_is_foreign_key(it) then #string XX
    result = ifx cached_obj.fetch_id == 0 then bind(statment, %1) else bind(statement, %1, cached_obj.%2);
XX              else #string XX
    result = bind(statement, %1, cached_obj.%2);
XX,         /* 1 */ question_mark_index,
            /* 2 */ it.name
            );
            append(*sb, #string XX
    assert_ok(result);
XX,         );
        }
        return builder_to_string(*sb);
    }

    result = bind(statement, INDEX_OF_ID_QUESTION_MARK, cached_obj.id);
    assert_ok(result);

    for statement cached_obj.pointer.modified = column_int(statement, 0);

    result = finalize(statement);
    assert_ok(result);
}

// update :: ($type: Type, set: string, where: string, ..params: Any)

select_by_id :: ($T: Type, id: s64, $fetch := "") -> Cached(T)
#modify { return is_a_model(T); } {
    return select_from(T, where="id = ?", id, limit=1, fetch=fetch); //TODO: these three lines one
}

select_from :: (
    $T         :  Type, // must be $T/Model
    $where     := "",
     params    :  ..Any,
    $limit     := 0,    // must not be 1
     offset    := 0,
    $fetch     := "",
     allocator := temp
) -> [..] Cached(T)
#modify { return is_a_model(T) && limit != 1;} {
    SQL_STATEMENT :: #run generate_sql_statement_for_select_from();

    rows: [..] Cached(T);
    rows.allocator = allocator;

    new_params: [..] Any;
    array_copy(*new_params, params);
    if limit then array_add(*new_params, offset);

    result := exec(SQL_STATEMENT, ..new_params, code=#code {
        obj: `T;
        fetch_row(*obj, statement);
        #insert #run sprint(#string XX
        pointer := table_set(*context.sqlite_model_cache._%1, obj.id, obj);
XX,     /* 1 */ `T);
        array_add(*`rows, .{obj.id, pointer});
    });
    assert_ok(result);
    array_free(new_params);

    // this is almost certainly not the best way to do this but it works for now
    #if fetch != "" then for * row: rows { #insert -> string {
        sb: String_Builder;
        for fetch_member_name: split(fetch, ",") {
            found := false;
            for type_info(T).members if it.name == fetch_member_name && member_is_foreign_key(it) { found = true; break; }
            assert(found, "could not fetch member %1 of %2",
            /* 1 */ fetch_member_name,
            /* 2 */ T
            );
            print_to_builder(*sb, #string XX
            _fetch(*row.%1);
XX,             /* 1 */ fetch_member_name);
        }
        return builder_to_string(*sb);
    }}

    return rows;
}

select_from :: (
    $T      :  Type, // must be $T/Model
    $where  := "",
     params :  ..Any,
    $limit  := 0,    // must be 1
     offset := 0,
    $fetch  := ""
) -> Cached(T)
#modify { return is_a_model(T) && limit == 1; } {
    SQL_STATEMENT :: #run generate_sql_statement_for_select_from();

    obj: T;
    obj_pointer: *T;

    new_params: [..] Any;
    array_copy(*new_params, params);
    array_add(*new_params, offset);

    result := exec(SQL_STATEMENT, ..new_params, code=#code {
        fetch_row(*`obj, statement);
        #insert #run sprint(#string XX
        `obj_pointer = table_set(*context.sqlite_model_cache._%1, `obj.id, `obj);
XX,     /* 1 */ `T);
    });
    assert_ok(result);
    array_free(new_params);

    // this is almost certainly not the best way to do this but it works for now
    #if fetch != "" then #insert -> string {
        sb: String_Builder;
        for fetch_member_name: split(fetch, ",") {
            found := false;
            for type_info(T).members if it.name == fetch_member_name && member_is_foreign_key(it) { found = true; break; }
            assert(found, "could not fetch member %1 of %2",
            /* 1 */ fetch_member_name,
            /* 2 */ T
            );
            print_to_builder(*sb, #string XX
        _fetch(*obj_pointer.%1);
XX,         /* 1 */ fetch_member_name);
        }
        return builder_to_string(*sb);
    }

    return .{obj.id, obj_pointer};
}

delete :: (using cached_obj: *$T/Cached) {
    SQL_STATEMENT :: #run sprint("DELETE FROM % WHERE id = ?;", T.type);

    assert_ok(exec(SQL_STATEMENT,
    /* 1 */ T.type
    ));

    #insert #run sprint(#string XX
    table_remove(*context.sqlite_model_cache._%1, id);
XX, /* 1 */ T.type);
    pointer = null;
    fetch_id = 0;
}

// delete_from :: ($type: Type, where: string, ..params: Any)

fetch :: (cached: *$T/Cached) {
    assert(cached.fetch_id != 0);
    cached.pointer = select_by_id(T.type, cached.fetch_id).pointer;
}
#scope_file
_fetch :: fetch;
#scope_export

is_a_model :: inline x => (#import "Compiler").is_subclass_of(cast(*Type_Info) x, "Model");

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

#placeholder __reset_model_cache;
reset_model_cache :: inline (reinit := true) { __reset_model_cache(reinit); } // :P


#import "Hash_Table";

#scope_file


generate_sql_statement_for_select_from :: () -> string #expand {
    sb: String_Builder;
    for serializable_members_of(`T) {
        if it_index != 0 then append(*sb, ", ");
        append(*sb, it.name);
        if member_is_foreign_key(it) then append(*sb, "_id");
    }
    x := sprint("SELECT id, strftime(\"%%s\", created), strftime(\"%%s\", modified), %1 FROM %2%3%4%5;",
    /* 1 */ builder_to_string(*sb),
    /* 2 */ `T,
    /* 3 */ ifx `where then sprint(" WHERE %" , `where ),
    /* 4 */ ifx `limit then sprint(" LIMIT %" , `limit ),
    /* 5 */ ifx `limit then        " OFFSET ?"
    );
    return x;
}