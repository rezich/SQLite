// This is the jai "fancy wrapper" for SQLite.
// If you want the raw bindings instead for whatever reason, see ../lib/sqlite3.jai.

Handle             :: #type *sqlite3;
Callback           :: #type sqlite3_callback;
Statement          :: #type *sqlite3_stmt;
Column_Type        :: enum { INTEGER; FLOAT; BLOB; NULL; TEXT; }
Foreign_Key_Action :: enum { NO_ACTION; RESTRICT; SET_NULL; SET_DEFAULT; CASCADE; }

#load "Result.jai";

assert_ok :: (result: Result, loc := #caller_location) { assert(result == .OK, "%: %", result, errmsg(), loc=loc); }


SQLite_Info :: struct {
    filename:  string = ":memory:";
    handle:    Handle;
    is_open:   bool;
    pragmas:   [..] string;
}
#if !FROM_METAPROGRAM #add_context sqlite: SQLite_Info;


set_pragmas :: (new_pragmas: [] string) -> Result {
    using context.sqlite;
    result: Result;
    if is_open {
        assert(false, "(maybe don't do this just yet though)");
        for new_pragmas {
            // it seems weird that it appends the pragmas if the database is open...
            result = exec(tprint("PRAGMA %;", it));
            if result != .OK then return result;
            array_add(*pragmas, it);
        }
    }
    // ...yet replaces them when it's not...
    else array_copy(*pragmas, new_pragmas);
    return result;
    // ...but it makes sense, I think, for reasons I'm too tired to explain right now.
}


open :: () -> result: Result, error: string {
    using context.sqlite;
    result := cast(Result) sqlite3_open(xx temp_c_string(filename), *handle);
    error := ifx result != .OK then to_string(cast(*u8) sqlite3_errmsg(handle));
    is_open = result == .OK;
    for pragmas { result = exec(tprint("PRAGMA %;", it)); if result != .OK then return result, error; }
    return result, error;
}

open_for :: ($code: Code, name: string="", $caller_code := #caller_code) {
    begin := current_time_monotonic();
    #if VERBOSE then       verbose_begin_open_for(name);
    #if VERBOSE then defer verbose_end\ _open_for(name);

    open(); defer close();
    
    #insert,scope(caller_code) code;
}

close :: () -> Result {
    using context.sqlite;
    result := cast(Result) sqlite3_close(handle);
    if result == .OK then is_open = false;
    return result;
}


/*exec :: (sql: string, callback: Callback = null, callback_arg: *void = null) -> result: Result, error: string {
    #if VERBOSE then print_color("%\n", sql, color=.HI_MAGENTA);
    error_cstring: *s8; // TODO: reuse instead of allocating & freeing every time?
    result := cast(Result) sqlite3_exec(context.sqlite.handle, xx temp_c_string(sql), callback, callback_arg, *error_cstring);
    error := ifx result != .OK then to_string(cast(*u8) error_cstring);
    sqlite3_free(error_cstring); // TODO: reuse instead of allocating & freeing every time?
    return result, error;
}*/

// this version of exec is not actually SQLite's exec,
// but it does the same thing, just without a callback function
exec :: (
    sql: string,                   // the SQL statement
    params: ..Any,                 // parameters to bind
    $code: Code = #code,null,      // run this code for each returned row
    $ignore_returned_rows := false // ignore returned rows
) -> Result
#modify { if code != #code,null then ignore_returned_rows = true; return true; }
#expand {
    result, statement := prepare(sql);
    if result != .OK then return result;

    parameter_count_passed_in := params.count;
    parameter_count_in_sql := bind_parameter_count(statement);
    assert(parameter_count_passed_in == parameter_count_in_sql,
        "Mismatch between number of params passed in [%1 (%4)] and the number of question marks in the SQL string [%2]\n%3\n\nparams: %5",
    /* 1 */ parameter_count_passed_in,
    /* 2 */ parameter_count_in_sql,
    /* 3 */ sql,
    /* 4 */ params.count,
    /* 5 */ params
    );

    param_number: s32 = 1;
    for params {
        if it.type.type == {
            case .BOOL;
                result =     bind(statement, param_number, <<cast(*   bool) it.value_pointer);
            case .ENUM; #through;
            case .INTEGER;
                if it.type.runtime_size <= 4
                    result = bind(statement, param_number, <<cast(*    s32) it.value_pointer);
                else
                    result = bind(statement, param_number, <<cast(*    s64) it.value_pointer);
            case .FLOAT;
                result =     bind(statement, param_number, <<cast(*float64) it.value_pointer);
            case .STRING;
                result =     bind(statement, param_number, <<cast(* string) it.value_pointer);
        }
        if result != .OK then return result;
        param_number += 1;
    }

    should_return := false;
    for statement {
        assert(ignore_returned_rows);
        STATEMENT_SCOPE : Code : #this; // very cool that this works
        #if code != #code,null then #insert,scope() code;
    }
    if should_return then return result;

    result = finalize(statement);
    return result;

    column_count  :: ()                   -> s32         #expand { return column_count (`statement);                }
    column_double :: (column_number: s32) -> float64     #expand { return column_double(`statement, column_number); }
    column_int    :: (column_number: s32) -> s32         #expand { return column_int   (`statement, column_number); }
    column_int64  :: (column_number: s32) -> s64         #expand { return column_int64 (`statement, column_number); }
    column_text   :: (column_number: s32) -> string      #expand { return column_text  (`statement, column_number); }
    column_name   :: (column_number: s32) -> string      #expand { return column_name  (`statement, column_number); }
    column_type   :: (column_number: s32) -> Column_Type #expand { return column_type  (`statement, column_number); }
}

// this one returns a single Row_Type
exec_row :: ($Row_Type: Type, sql: string, params: ..Any, $check_column_names := true) -> result: Result, row: Row_Type, success: bool {
    row: Row_Type; success: bool;
    return exec(sql, ..params, #code { assert(it_index == 0); fetch_row(*`row, statement, `check_column_names); `success = true; }), row, success;
}

// this one returns an array of Row_Type
exec_rows :: ($Row_Type: Type, sql: string, params: ..Any, allocator := temp, $check_column_names := true) -> result: Result, rows: [..] Row_Type {
    rows: [..] Row_Type; rows.allocator = allocator;
    return exec(sql, ..params, #code { fetch_row(array_add(*`rows), statement, `check_column_names); }), rows;
}

// this one returns an array of Column_Type, just one value per row
exec_column :: ($Column_Type: Type, sql: string, params: ..Any, allocator := temp, $unique := false) -> result: Result, column: [..] Column_Type {
    column: [..] Column_Type; column.allocator = allocator;
    return exec(sql, ..params, #code {
        value := fetch_value(`Column_Type, statement);
        #if `unique then array_add_if_unique(*`column, value);
        else array_add(*`column, value);
    }), column;
}

// this one returns just a single value of type Value_Type
exec_value :: ($Value_Type: Type, sql: string, params: ..Any) -> result: Result, value: Value_Type, success: bool {
    value: Value_Type; success: bool;
    return exec(sql, ..params, #code { assert(it_index == 0); `value = fetch_value(`Value_Type, statement); `success = true; }), value, success;
}


prepare :: (sql: string) -> result: Result, statement: Statement {
    #if VERBOSE then verbose_begin(sql);
    sql_cstring := temp_c_string(sql);
    statement: Statement;
    return cast(Result) sqlite3_prepare_v2(context.sqlite.handle, cast(*s8) sql_cstring, cast(s32) c_style_strlen(sql_cstring), *statement, null), statement;
}
step :: (statement: Statement) -> Result {
    return cast(Result) sqlite3_step(statement);
}
finalize :: (statement: Statement) -> Result {
    #if VERBOSE then verbose_end();
    return cast(Result) sqlite3_finalize(statement);
}
sql :: (statement: Statement) -> string {
    return copy_temporary_string(to_string(cast(*u8) sqlite3_sql(statement)));
}
#scope_file
_sql :: sql;
#scope_export
expanded_sql :: (statement: Statement) -> string {
    return copy_temporary_string(to_string(cast(*u8) sqlite3_expanded_sql(statement)));
}
column_count :: (statement: Statement) -> s32 {
    return sqlite3_column_count(statement);
}
column_double :: (statement: Statement, column_number: s32) -> float64 {
    return sqlite3_column_double(statement, column_number);
}
column_int :: (statement: Statement, column_number: s32) -> s32 {
    return sqlite3_column_int(statement, column_number);
}
column_int64 :: (statement: Statement, column_number: s32) -> s64 {
    return sqlite3_column_int64(statement, column_number);
}
column_text :: (statement: Statement, column_number: s32) -> string {
    return copy_temporary_string(to_string(cast(*u8) sqlite3_column_text(statement, column_number)));
}
column_name :: (statement: Statement, column_number: s32) -> string {
    return copy_temporary_string(to_string(cast(*u8) sqlite3_column_name(statement, column_number)));
}
column_type :: (statement: Statement, column_number: s32) -> enum { INTEGER; FLOAT; BLOB; NULL; TEXT; } {
    return xx sqlite3_column_type(statement, column_number);
}
last_insert_rowid :: () -> s64 {
    return sqlite3_last_insert_rowid(context.sqlite.handle);
}
errmsg :: () -> string {
    return to_string(cast(*u8) sqlite3_errmsg(context.sqlite.handle));
}
changes :: inline () -> int { return sqlite3_changes(context.sqlite.handle); }
bind_parameter_count :: (statement: Statement) -> int {
    return sqlite3_bind_parameter_count(statement);
}
bind :: (statement: Statement, index: s32, value: float64) -> Result {
    #if VERBOSE then verbose_bind(value);
    return cast(Result) sqlite3_bind_double(statement, index, value);
}
bind :: (statement: Statement, index: s32, value: s32) -> Result {
    #if VERBOSE then verbose_bind(value);
    return cast(Result) sqlite3_bind_int(statement, index, value);
}
bind :: (statement: Statement, index: s32, value: s64) -> Result {
    #if VERBOSE then verbose_bind(value);
    return cast(Result) sqlite3_bind_int64(statement, index, value);
}
bind :: (statement: Statement, index: s32, value: string) -> Result {
    #if VERBOSE then verbose_bind(value);
    value_cstring := temp_c_string(value);
    return cast(Result) sqlite3_bind_text(statement, index, cast(*s8) value_cstring, cast(s32) c_style_strlen(value_cstring), null);
}
bind :: (statement: Statement, index: s32) -> Result {
    #if VERBOSE then verbose_bind(null);
    return cast(Result) sqlite3_bind_null(statement, index);
}

bind :: (statement: Statement, index: s32, value: bool) -> Result {
    #if VERBOSE then verbose_bind(value);
    return cast(Result) sqlite3_bind_int(statement, index, xx ifx value then 1);
}

bind :: (statement: Statement, index: s32, value: $T) -> Result
#modify { return (cast(*Type_Info) T).type == .ENUM; } {
    #if VERBOSE then verbose_bind(value);
    #if #run type_info(T).runtime_size <= 4
        return cast(Result) sqlite3_bind_int  (statement, index, cast(s32) value);
    else
        return cast(Result) sqlite3_bind_int64(statement, index, cast(s64) value);
}

for_expansion :: (statement: Statement, body: Code, flags: For_Flags) #expand {
    `it := void; `it_index := 0;
    while true { `result = step(statement); if `result == {
        case .ROW;  defer `it_index += 1; #insert body; continue;
        case .BUSY;                                     continue;
        case .DONE;                                     break;
        case;       assert_ok(`result);
    }}
}

optional_cleanup :: () {
    #if USE_MODEL_CACHE then reset_model_cache(reinit=false);
    array_free(context.sqlite.pragmas);
}

#scope_module

// this cuts down on code generation
bind :: inline (statement: Statement, index: s32, $$value: *void) -> Result { assert(value == null); return bind(statement, index); }

serializable_members_of :: ($type: Type) -> [..] Type_Info_Struct_Member {
    return serializable_members_of(cast(*Type_Info_Struct) type_info(type));
}

serializable_members_of :: (info: *Type_Info_Struct) -> [..] Type_Info_Struct_Member { assert(#compile_time);
    members: [..] Type_Info_Struct_Member;
    for member: info.members {
        is_a_valid_type := is_serializable(member.type);
        #if USE_MODEL_CACHE || FROM_METAPROGRAM { if is_a_model(info) && member_is_foreign_key(member) then is_a_valid_type = true; }
        if !is_a_valid_type then continue;
        #if USE_MODEL_CACHE || FROM_METAPROGRAM {
            for member.notes if it == NOTE_DO_NOT_SERIALIZE /*||
                                it == NOTE_FETCH          */ then continue member;
        }
        array_add(*members, member);
    }
    return members;
}

is_serializable :: (info) =>    info.type == .BOOL    ||
                                info.type == .ENUM    ||
                                info.type == .INTEGER ||
                                info.type == .FLOAT   ||
                                info.type == .STRING;

fetch_value :: ($Value_Type: Type, statement: Statement) -> Value_Type
#modify { return is_serializable(cast(*Type_Info) Value_Type); } {
    value: Value_Type;
    #insert #run get_column_cast("value", 0, type_info(Value_Type));
    return value;
}

fetch_row :: (obj: *$T, statement: Statement, $check_column_names := false) {
    #insert -> string {
        sb: String_Builder;
        column_number := 0;
        #if (USE_MODEL_CACHE || FROM_METAPROGRAM) && #run is_a_model(T) then column_number = ORM_INTERNAL_COLUMN_COUNT;
        for serializable_members_of(T) {
            handled := false;
            #if check_column_names then print_to_builder(*sb, #string XX
    {
        database_column_name := column_name(statement, %1);
        MEMBER_NAME :: "%2";
        assert(database_column_name == "" || database_column_name == MEMBER_NAME, "Column name mismatch; expected %%1, got %%2",
    /* 1 */database_column_name,
    /* 2 */MEMBER_NAME);
    }
XX,         /* 1 */ column_number,
            /* 2 */ it.name);
            #if USE_MODEL_CACHE || FROM_METAPROGRAM then if member_is_foreign_key(it) then { print_to_builder(*sb, #string XX
    {
        id := column_int64(statement, %2);
        found := table_find_pointer(*context.sqlite_model_cache._%3, id);
        if found then obj.%1 = .{id, found}; else obj.%1 = .{id, null};
    }
XX,         /* 1 */ it.name,
            /* 2 */ column_number,
            /* 3 */ get_foreign_key_name_from(it, sprint("%", T))
            ); handled = true; }
            if !handled then {
                print_to_builder(*sb, "    obj.%", get_column_cast(it.name, column_number, it.type));
            }
            column_number += 1;
        }
        return builder_to_string(*sb);
    }
    #if (USE_MODEL_CACHE || FROM_METAPROGRAM) && #run is_a_model(T) {
        obj.id       = column_int64(statement, 0);
        obj.created  = column_int  (statement, 1);
        obj.modified = column_int  (statement, 2);
    }
}

get_column_cast :: (var_name: string, column_number: int, info: *Type_Info) -> string {
    if info.type == {
        case .BOOL; return tprint(#string XX
%1 = cast(bool) column_int(statement, %2);
XX,     /* 1 */ var_name,
        /* 2 */ column_number
        );
        case .ENUM; return tprint(#string XX
%1 = xx column_int%3(statement, %2);
XX,     /* 1 */ var_name,
        /* 2 */ column_number,
        /* 3 */ ifx info.runtime_size > 4 then "64"
        );
        case .INTEGER; return tprint(#string XX
%1 = column_int%3(statement, %2);
XX,     /* 1 */ var_name,
        /* 2 */ column_number,
        /* 3 */ ifx info.runtime_size > 4 then "64"
        );
        case .FLOAT; return tprint(#string XX
%1 = %3column_double(statement, %2);
XX,     /* 1 */ var_name,
        /* 2 */ column_number,
        /* 3 */ ifx info.runtime_size == 4 then "xx "
        );
        case .STRING; return tprint(#string XX
%1 = column_text(statement, %2);
XX,     /* 1 */ var_name,
        /* 2 */ column_number
        );
        case; assert(false, "this should never happen"); return "";
    }
}

#scope_file

#if VERBOSE then #load "Verbose.jai";

#import "Basic";
