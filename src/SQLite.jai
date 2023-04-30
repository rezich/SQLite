// This is the jai "fancy wrapper" for SQLite.
// If you want the raw bindings instead for whatever reason, see sqlite3.jai.

Handle    :: #type *sqlite3;
Callback  :: #type sqlite3_callback;
Statement :: #type *sqlite3_stmt;

#if !FROM_METAPROGRAM #add_context db: Handle;

Result :: enum {
    OK         ::  0;   /* Successful result */
    ERROR      ::  1;   /* Generic error */
    INTERNAL   ::  2;   /* Internal logic error in SQLite */
    PERM       ::  3;   /* Access permission denied */
    ABORT      ::  4;   /* Callback routine requested an abort */
    BUSY       ::  5;   /* The database file is locked */
    LOCKED     ::  6;   /* A table in the database is locked */
    NOMEM      ::  7;   /* A malloc() failed */
    READONLY   ::  8;   /* Attempt to write a readonly database */
    INTERRUPT  ::  9;   /* Operation terminated by sqlite3_interrupt()*/
    IOERR      :: 10;   /* Some kind of disk I/O error occurred */
    CORRUPT    :: 11;   /* The database disk image is malformed */
    NOTFOUND   :: 12;   /* Unknown opcode in sqlite3_file_control() */
    FULL       :: 13;   /* Insertion failed because database is full */
    CANTOPEN   :: 14;   /* Unable to open the database file */
    PROTOCOL   :: 15;   /* Database lock protocol error */
    EMPTY      :: 16;   /* Internal use only */
    SCHEMA     :: 17;   /* The database schema changed */
    TOOBIG     :: 18;   /* String or BLOB exceeds size limit */
    CONSTRAINT :: 19;   /* Abort due to constraint violation */
    MISMATCH   :: 20;   /* Data type mismatch */
    MISUSE     :: 21;   /* Library used incorrectly */
    NOLFS      :: 22;   /* Uses OS features not supported on host */
    AUTH       :: 23;   /* Authorization denied */
    FORMAT     :: 24;   /* Not used */
    RANGE      :: 25;   /* 2nd parameter to sqlite3_bind out of range */
    NOTADB     :: 26;   /* File opened that is not a database file */
    NOTICE     :: 27;   /* Notifications from sqlite3_log() */
    WARNING    :: 28;   /* Warnings from sqlite3_log() */
    ROW        :: 100;  /* sqlite3_step() has another row ready */
    DONE       :: 101;  /* sqlite3_step() has finished executing */
}

Foreign_Key_Action :: enum { NO_ACTION; RESTRICT; SET_NULL; SET_DEFAULT; CASCADE; }

open :: (filename := ":memory:") -> result: Result, error: string {
    result := cast(Result) sqlite3_open(xx temp_c_string(filename), *context.db);
    error := ifx result != .OK then to_string(cast(*u8) sqlite3_errmsg(context.db));
    return result, error;
}
exec :: (sql: string, callback: Callback = null, callback_arg: *void = null) -> result: Result, error: string {
    #if VERBOSE then print_color("%\n", sql, color=.HI_MAGENTA);
    error_cstring: *s8; // TODO: reuse instead of allocating & freeing every time?
    result := cast(Result) sqlite3_exec(context.db, xx temp_c_string(sql), callback, callback_arg, *error_cstring);
    error := ifx result != .OK then to_string(cast(*u8) error_cstring);
    sqlite3_free(error_cstring); // TODO: reuse instead of allocating & freeing every time?
    return result, error;
}
// this version of exec is not actually SQLite's exec,
// but it does the same thing, i.e. build a statement & execute it.
exec :: ($row_type: Type, sql: string, params: ..Any, allocator := temp, $check_column_names := true) -> result: Result, selected: [..] row_type {
    assert(params.count == count_question_marks(sql), "Mismatch between number of params passed in [%1] and the number of question marks in the SQL string [%2]",
    /* 1 */params.count,
    /* 2 */count_question_marks(sql)
    );

    rows: [..] row_type;
    rows.allocator = allocator;

    result, statement := prepare_v2(sql);
    if result != .OK then return result, rows;

    param_number: s32 = 1;
    for params {
        if it.type.type == {
            case .BOOL;
                result = bind(statement, param_number,    <<cast(*bool) it.value_pointer);
            case .ENUM;
                result = bind(statement, param_number,    <<cast( *s64) it.value_pointer);
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
            fetch_row(array_add(*rows), statement, check_column_names);
            continue;
        case .BUSY; continue;
        case .DONE; break;
        case;       return result, rows;
    }}

    result = finalize(statement);
    return result, rows;
}
prepare_v2 :: (sql: string) -> result: Result, statement: Statement {
    #if VERBOSE then verbose_begin(sql);
    sql_cstring := temp_c_string(sql);
    statement: Statement;
    return cast(Result) sqlite3_prepare_v2(context.db, cast(*s8) sql_cstring, cast(s32) c_style_strlen(sql_cstring), *statement, null), statement;
}
step :: (statement: Statement) -> Result {
    return cast(Result) sqlite3_step(statement);
}
finalize :: (statement: Statement) -> Result {
    #if VERBOSE then verbose_end();
    return cast(Result) sqlite3_finalize(statement);
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
    return xx sqlite3_column_name(statement, column_number);
}
close :: () -> result: Result {
    return cast(Result) sqlite3_close(context.db);
}
last_insert_rowid :: () -> s64 {
    return sqlite3_last_insert_rowid(context.db);
}
errmsg :: () -> string {
    return to_string(cast(*u8) sqlite3_errmsg(context.db));
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
// nice to have:
bind :: (statement: Statement, index: s32, value: bool) -> Result {
    #if VERBOSE then verbose_bind(value);
    return cast(Result) sqlite3_bind_int(statement, index, xx ifx value then 1);
}
bind :: (statement: Statement, index: s32, value: $T) -> Result #modify {
    return (cast(*Type_Info) T).type == .ENUM;
} {
    #if VERBOSE then verbose_bind(value);
    return cast(Result) sqlite3_bind_int(statement, index, xx ifx value then 1);
}

#scope_module

// this cuts down on code generation
bind :: inline (statement: Statement, index: s32, $$value: *void) -> Result { assert(value == null); return bind(statement, index); }

count_question_marks :: (sql: string) -> int {
    question_marks := 0;
    cursor := find_index_from_left(sql, #char "?");
    while cursor != -1 {
        question_marks += 1;
        cursor = find_index_from_left(sql, #char "?", cursor+1);
    }
    return question_marks;
}

serializable_members_of :: ($type: Type) -> [..] Type_Info_Struct_Member {
    return serializable_members_of(cast(*Type_Info_Struct) type_info(type));
}

serializable_members_of :: (info: *Type_Info_Struct) -> [..] Type_Info_Struct_Member {
    NOTE_DO_NOT_SERIALIZE :: "do_not_serialize";

    members: [..] Type_Info_Struct_Member;
    for info.members {
        is_a_valid_type :=
            it.type.type == .BOOL    ||
            it.type.type == .ENUM    ||
            it.type.type == .INTEGER ||
            it.type.type == .FLOAT   ||
            it.type.type == .STRING;
        #if USE_ORM || FROM_METAPROGRAM { if ORM.is_a_model(info) && ORM.member_is_foreign_key(it) then is_a_valid_type = true; }
        if !is_a_valid_type then continue;
        #if USE_ORM || FROM_METAPROGRAM {
            has_do_not_serialize_note := false;
            for it.notes if it == NOTE_DO_NOT_SERIALIZE { has_do_not_serialize_note = true; break; }
            if has_do_not_serialize_note then continue;
        }
        array_add(*members, it);
    }
    return members;
}

fetch_row :: (obj: *$T, statement: Statement, $check_column_names := false) {
    #if (USE_ORM || FROM_METAPROGRAM) && #run ORM.is_a_model(T) {
        obj.id       = column_int64(statement, 0);
        obj.created  = column_int  (statement, 1);
        obj.modified = column_int  (statement, 2);
    }
    #insert -> string {
        sb: String_Builder;
        column_number := 0;
        #if (USE_ORM || FROM_METAPROGRAM) && #run ORM.is_a_model(T) then column_number = ORM.INTERNAL_COLUMN_COUNT;
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
XX,         /* 1 */column_number,
            /* 2 */it.name);
            #if USE_ORM || FROM_METAPROGRAM then if ORM.member_is_foreign_key(it) then { print_to_builder(*sb, #string XX
    {
        id := column_int64(statement, %2);
        found := table_find_pointer(*context.db_cache._%3, id);
        if found then obj.%1 = .{id, found}; else obj.%1 = .{id, null};
    }
XX,         /* 1 */it.name,
            /* 2 */column_number,
            /* 3 */ORM.get_foreign_key_name_from(it, sprint("%", T))
            ); handled = true; }
            if !handled then if it.type.type == {
                case .BOOL; print_to_builder(*sb, #string XX
    obj.%1 = cast(bool) column_int(statement, %2);
XX,             /* 1 */it.name,
                /* 2 */column_number
                );
                case .ENUM; print_to_builder(*sb, #string XX
    obj.%1 = xx column_int64(statement, %2);
XX,             /* 1 */it.name,
                /* 2 */column_number
                );
                case .INTEGER; print_to_builder(*sb, #string XX
    obj.%1 = column_int%3(statement, %2);
XX,             /* 1 */it.name,
                /* 2 */column_number,
                /* 3 */ifx it.type.runtime_size == 8 then "64"
                );
                case .FLOAT; print_to_builder(*sb, #string XX
    obj.%1 = %3column_double(statement, %2);
XX,             /* 1 */it.name,
                /* 2 */column_number,
                /* 3 */ifx it.type.runtime_size == 4 then "xx "
                );
                case .STRING; print_to_builder(*sb, #string XX
    obj.%1 = column_text(statement, %2);
XX,             /* 1 */it.name,
                /* 2 */column_number
                );
                case; continue;
            }
            column_number += 1;
        }
        return builder_to_string(*sb);
    }
}

#scope_file

#if VERBOSE {
    #import "Print_Color";
    #import "String";
    #add_context sqlite_verbose: struct {
        statement: string;
        parameter_count: int;
        parameters: [100] string;
    };
    verbose_begin :: (statement: string) { context.sqlite_verbose.statement = statement; }
    verbose_bind :: (param: $T) {
        using context.sqlite_verbose;
        #if #run type_info(T).type == .ENUM    then parameters[parameter_count] = tprint("% [%]", cast,force(s64) param, param); else
        #if #run type_info(T).type == .POINTER then parameters[parameter_count] = "NULL"; else
        #if #run type_info(T).type == .BOOL    then parameters[parameter_count] = tprint("% [%]", ifx param then 1, ifx param then "TRUE" else "FALSE"); else
                                                    parameters[parameter_count] = tprint("%", param);
        parameter_count += 1;
    }
    verbose_end :: () {
        using context.sqlite_verbose;
        for split(statement, "?") {
            with_console_color(.MAGENTA, write_string(it));
            if it_index < parameter_count then with_console_color(.CYAN, write_string(parameters[it_index]));
        }
        write_string("\n");
        parameter_count = 0;
        statement = "";
    }
}

#import "Basic";
