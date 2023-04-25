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
    #if VERBOSE then print_color("%\n", sql, color=.MAGENTA);
    error_cstring: *s8; // TODO: reuse instead of allocating & freeing every time?
    result := cast(Result) sqlite3_exec(context.db, xx temp_c_string(sql), callback, callback_arg, *error_cstring);
    error := ifx result != .OK then to_string(cast(*u8) error_cstring);
    sqlite3_free(error_cstring); // TODO: reuse instead of allocating & freeing every time?
    return result, error;
}
prepare_v2 :: (sql: string) -> result: Result, statement: Statement {
    #if VERBOSE then print_color("%\n", sql, color=.MAGENTA);
    sql_cstring := temp_c_string(sql);
    statement: Statement;
    return cast(Result) sqlite3_prepare_v2(context.db, cast(*s8) sql_cstring, cast(s32) c_style_strlen(sql_cstring), *statement, null), statement;
}
step :: (statement: Statement) -> Result {
    return cast(Result) sqlite3_step(statement);
}
finalize :: (statement: Statement) -> Result {
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
    text_cstring := cast(*u8) sqlite3_column_text(statement, column_number);
    return copy_temporary_string(to_string(text_cstring));
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
    #if VERBOSE then print_color("  %1: %2\n", index, value, color=.CYAN);
    return cast(Result) sqlite3_bind_double(statement, index, value);
}
bind :: (statement: Statement, index: s32, value: s32) -> Result {
    #if VERBOSE then print_color("  %1: %2\n", index, value, color=.CYAN);
    return cast(Result) sqlite3_bind_int(statement, index, value);
}
bind :: (statement: Statement, index: s32, value: s64) -> Result {
    #if VERBOSE then print_color("  %1: %2\n", index, value, color=.CYAN);
    return cast(Result) sqlite3_bind_int64(statement, index, value);
}
bind :: (statement: Statement, index: s32, value: string) -> Result {
    #if VERBOSE then print_color("  %1: %2\n", index, value, color=.CYAN);
    value_cstring := temp_c_string(value);
    return cast(Result) sqlite3_bind_text(statement, index, cast(*s8) value_cstring, cast(s32) c_style_strlen(value_cstring), null);
}
bind :: (statement: Statement, index: s32) -> Result {
    #if VERBOSE then print_color("  %1: NULL\n", index, color=.CYAN);
    return cast(Result) sqlite3_bind_null(statement, index);
}

#scope_file
#load "sqlite3.jai";
#import "Basic";
#if VERBOSE then #import "Print_Color";
