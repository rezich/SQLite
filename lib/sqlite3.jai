// This is an automatically generated set of SQLite bindings.
// See SQLite.jai for a more jai-friendly "fancy wrapper" around this.
sqlite3_version: *s8;

sqlite3_libversion :: () -> *s8 #foreign sqlite;

sqlite3_sourceid :: () -> *s8 #foreign sqlite;

sqlite3_libversion_number :: () -> s32 #foreign sqlite;

sqlite3_compileoption_used :: (zOptName: *s8) -> s32 #foreign sqlite;

sqlite3_compileoption_get :: (N: s32) -> *s8 #foreign sqlite;

sqlite3_threadsafe :: () -> s32 #foreign sqlite;

sqlite3 :: struct {
}



sqlite_int64 :: s64;

sqlite_uint64 :: u64;

sqlite3_int64 :: sqlite_int64;

sqlite3_uint64 :: sqlite_uint64;

sqlite3_close :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_close_v2 :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_callback :: #type (a0: *void, a1: s32, a2: **s8, a3: **s8) -> s32 #c_call;

sqlite3_exec :: (unk0: *sqlite3, sql: *s8, callback: #type (a0: *void, a1: s32, a2: **s8, a3: **s8) -> s32 #c_call, unk1: *void, errmsg: **s8) -> s32 #foreign sqlite;



sqlite3_file :: struct {
    pMethods: *sqlite3_io_methods;
}



sqlite3_io_methods :: struct {
    iVersion: s32;
    xClose: #type (a0: *sqlite3_file) -> s32 #c_call;
    xRead: #type (a0: *sqlite3_file, a1: *void, a2: s32, a3: sqlite3_int64) -> s32 #c_call;
    xWrite: #type (a0: *sqlite3_file, a1: *void, a2: s32, a3: sqlite3_int64) -> s32 #c_call;
    xTruncate: #type (a0: *sqlite3_file, a1: sqlite3_int64) -> s32 #c_call;
    xSync: #type (a0: *sqlite3_file, a1: s32) -> s32 #c_call;
    xFileSize: #type (a0: *sqlite3_file, a1: *sqlite3_int64) -> s32 #c_call;
    xLock: #type (a0: *sqlite3_file, a1: s32) -> s32 #c_call;
    xUnlock: #type (a0: *sqlite3_file, a1: s32) -> s32 #c_call;
    xCheckReservedLock: #type (a0: *sqlite3_file, a1: *s32) -> s32 #c_call;
    xFileControl: #type (a0: *sqlite3_file, a1: s32, a2: *void) -> s32 #c_call;
    xSectorSize: #type (a0: *sqlite3_file) -> s32 #c_call;
    xDeviceCharacteristics: #type (a0: *sqlite3_file) -> s32 #c_call;
    xShmMap: #type (a0: *sqlite3_file, a1: s32, a2: s32, a3: s32, a4: **void) -> s32 #c_call;
    xShmLock: #type (a0: *sqlite3_file, a1: s32, a2: s32, a3: s32) -> s32 #c_call;
    xShmBarrier: #type (a0: *sqlite3_file) -> void #c_call;
    xShmUnmap: #type (a0: *sqlite3_file, a1: s32) -> s32 #c_call;
    xFetch: #type (a0: *sqlite3_file, a1: sqlite3_int64, a2: s32, a3: **void) -> s32 #c_call;
    xUnfetch: #type (a0: *sqlite3_file, a1: sqlite3_int64, a2: *void) -> s32 #c_call;
}

sqlite3_mutex :: struct {
}







sqlite3_syscall_ptr :: #type () -> void #c_call;

sqlite3_vfs :: struct {
    iVersion: s32;
    szOsFile: s32;
    mxPathname: s32;
    pNext: *sqlite3_vfs;
    zName: *s8;
    pAppData: *void;
    xOpen: #type (a0: *sqlite3_vfs, a1: *s8, a2: *sqlite3_file, a3: s32, a4: *s32) -> s32 #c_call;
    xDelete: #type (a0: *sqlite3_vfs, a1: *s8, a2: s32) -> s32 #c_call;
    xAccess: #type (a0: *sqlite3_vfs, a1: *s8, a2: s32, a3: *s32) -> s32 #c_call;
    xFullPathname: #type (a0: *sqlite3_vfs, a1: *s8, a2: s32, a3: *s8) -> s32 #c_call;
    xDlOpen: #type (a0: *sqlite3_vfs, a1: *s8) -> *void #c_call;
    xDlError: #type (a0: *sqlite3_vfs, a1: s32, a2: *s8) -> void #c_call;
    xDlSym: #type (a0: *sqlite3_vfs, a1: *void, a2: *s8) -> (() -> void #c_call) #c_call;
    xDlClose: #type (a0: *sqlite3_vfs, a1: *void) -> void #c_call;
    xRandomness: #type (a0: *sqlite3_vfs, a1: s32, a2: *s8) -> s32 #c_call;
    xSleep: #type (a0: *sqlite3_vfs, a1: s32) -> s32 #c_call;
    xCurrentTime: #type (a0: *sqlite3_vfs, a1: *float64) -> s32 #c_call;
    xGetLastError: #type (a0: *sqlite3_vfs, a1: s32, a2: *s8) -> s32 #c_call;
    xCurrentTimeInt64: #type (a0: *sqlite3_vfs, a1: *sqlite3_int64) -> s32 #c_call;
    xSetSystemCall: #type (a0: *sqlite3_vfs, a1: *s8, a2: sqlite3_syscall_ptr) -> s32 #c_call;
    xGetSystemCall: #type (a0: *sqlite3_vfs, a1: *s8) -> sqlite3_syscall_ptr #c_call;
    xNextSystemCall: #type (a0: *sqlite3_vfs, a1: *s8) -> *s8 #c_call;
}

sqlite3_initialize :: () -> s32 #foreign sqlite;

sqlite3_shutdown :: () -> s32 #foreign sqlite;

sqlite3_os_init :: () -> s32 #foreign sqlite;

sqlite3_os_end :: () -> s32 #foreign sqlite;

sqlite3_config :: (unk0: s32, __args: ..Any) -> s32 #foreign sqlite;

sqlite3_db_config :: (unk0: *sqlite3, op: s32, __args: ..Any) -> s32 #foreign sqlite;



sqlite3_mem_methods :: struct {
    xMalloc: #type (a0: s32) -> *void #c_call;
    xFree: #type (a0: *void) -> void #c_call;
    xRealloc: #type (a0: *void, a1: s32) -> *void #c_call;
    xSize: #type (a0: *void) -> s32 #c_call;
    xRoundup: #type (a0: s32) -> s32 #c_call;
    xInit: #type (a0: *void) -> s32 #c_call;
    xShutdown: #type (a0: *void) -> void #c_call;
    pAppData: *void;
}

sqlite3_extended_result_codes :: (unk0: *sqlite3, onoff: s32) -> s32 #foreign sqlite;

sqlite3_last_insert_rowid :: (unk0: *sqlite3) -> sqlite3_int64 #foreign sqlite;

sqlite3_set_last_insert_rowid :: (unk0: *sqlite3, unk1: sqlite3_int64) -> void #foreign sqlite;

sqlite3_changes :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_changes64 :: (unk0: *sqlite3) -> sqlite3_int64 #foreign sqlite;

sqlite3_total_changes :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_total_changes64 :: (unk0: *sqlite3) -> sqlite3_int64 #foreign sqlite;

sqlite3_interrupt :: (unk0: *sqlite3) -> void #foreign sqlite;

sqlite3_complete :: (sql: *s8) -> s32 #foreign sqlite;

sqlite3_complete16 :: (sql: *void) -> s32 #foreign sqlite;

sqlite3_busy_handler :: (unk0: *sqlite3, unk1: #type (a0: *void, a1: s32) -> s32 #c_call, unk2: *void) -> s32 #foreign sqlite;

sqlite3_busy_timeout :: (unk0: *sqlite3, ms: s32) -> s32 #foreign sqlite;

sqlite3_get_table :: (db: *sqlite3, zSql: *s8, pazResult: ***s8, pnRow: *s32, pnColumn: *s32, pzErrmsg: **s8) -> s32 #foreign sqlite;

sqlite3_free_table :: (result: **s8) -> void #foreign sqlite;

sqlite3_mprintf :: (unk0: *s8, __args: ..Any) -> *s8 #foreign sqlite;

//sqlite3_vmprintf :: (unk0: *s8, unk1: va_list) -> *s8 #foreign sqlite;

sqlite3_snprintf :: (unk0: s32, unk1: *s8, unk2: *s8, __args: ..Any) -> *s8 #foreign sqlite;

//sqlite3_vsnprintf :: (unk0: s32, unk1: *s8, unk2: *s8, unk3: va_list) -> *s8 #foreign sqlite;

sqlite3_malloc :: (unk0: s32) -> *void #foreign sqlite;

sqlite3_malloc64 :: (unk0: sqlite3_uint64) -> *void #foreign sqlite;

sqlite3_realloc :: (unk0: *void, unk1: s32) -> *void #foreign sqlite;

sqlite3_realloc64 :: (unk0: *void, unk1: sqlite3_uint64) -> *void #foreign sqlite;

sqlite3_free :: (unk0: *void) -> void #foreign sqlite;

sqlite3_msize :: (unk0: *void) -> sqlite3_uint64 #foreign sqlite;

sqlite3_memory_used :: () -> sqlite3_int64 #foreign sqlite;

sqlite3_memory_highwater :: (resetFlag: s32) -> sqlite3_int64 #foreign sqlite;

sqlite3_randomness :: (N: s32, P: *void) -> void #foreign sqlite;

sqlite3_set_authorizer :: (unk0: *sqlite3, xAuth: #type (a0: *void, a1: s32, a2: *s8, a3: *s8, a4: *s8, a5: *s8) -> s32 #c_call, pUserData: *void) -> s32 #foreign sqlite;

sqlite3_trace :: (unk0: *sqlite3, xTrace: #type (a0: *void, a1: *s8) -> void #c_call, unk1: *void) -> *void #foreign sqlite;

sqlite3_profile :: (unk0: *sqlite3, xProfile: #type (a0: *void, a1: *s8, a2: sqlite3_uint64) -> void #c_call, unk1: *void) -> *void #foreign sqlite;

sqlite3_trace_v2 :: (unk0: *sqlite3, uMask: u32, xCallback: #type (a0: u32, a1: *void, a2: *void, a3: *void) -> s32 #c_call, pCtx: *void) -> s32 #foreign sqlite;

sqlite3_progress_handler :: (unk0: *sqlite3, unk1: s32, unk2: #type (a0: *void) -> s32 #c_call, unk3: *void) -> void #foreign sqlite;

sqlite3_open :: (filename: *s8, ppDb: **sqlite3) -> s32 #foreign sqlite;

sqlite3_open16 :: (filename: *void, ppDb: **sqlite3) -> s32 #foreign sqlite;

sqlite3_open_v2 :: (filename: *s8, ppDb: **sqlite3, flags: s32, zVfs: *s8) -> s32 #foreign sqlite;

sqlite3_uri_parameter :: (zFilename: *s8, zParam: *s8) -> *s8 #foreign sqlite;

sqlite3_uri_boolean :: (zFile: *s8, zParam: *s8, bDefault: s32) -> s32 #foreign sqlite;

sqlite3_uri_int64 :: (unk0: *s8, unk1: *s8, unk2: sqlite3_int64) -> sqlite3_int64 #foreign sqlite;

sqlite3_uri_key :: (zFilename: *s8, N: s32) -> *s8 #foreign sqlite;

sqlite3_filename_database :: (unk0: *s8) -> *s8 #foreign sqlite;

sqlite3_filename_journal :: (unk0: *s8) -> *s8 #foreign sqlite;

sqlite3_filename_wal :: (unk0: *s8) -> *s8 #foreign sqlite;

sqlite3_database_file_object :: (unk0: *s8) -> *sqlite3_file #foreign sqlite;

sqlite3_create_filename :: (zDatabase: *s8, zJournal: *s8, zWal: *s8, nParam: s32, azParam: **s8) -> *s8 #foreign sqlite;

sqlite3_free_filename :: (unk0: *s8) -> void #foreign sqlite;

sqlite3_errcode :: (db: *sqlite3) -> s32 #foreign sqlite;

sqlite3_extended_errcode :: (db: *sqlite3) -> s32 #foreign sqlite;

sqlite3_errmsg :: (unk0: *sqlite3) -> *s8 #foreign sqlite;

sqlite3_errmsg16 :: (unk0: *sqlite3) -> *void #foreign sqlite;

sqlite3_errstr :: (unk0: s32) -> *s8 #foreign sqlite;

sqlite3_stmt :: struct {
}



sqlite3_limit :: (unk0: *sqlite3, id: s32, newVal: s32) -> s32 #foreign sqlite;

sqlite3_prepare :: (db: *sqlite3, zSql: *s8, nByte: s32, ppStmt: **sqlite3_stmt, pzTail: **s8) -> s32 #foreign sqlite;

sqlite3_prepare_v2 :: (db: *sqlite3, zSql: *s8, nByte: s32, ppStmt: **sqlite3_stmt, pzTail: **s8) -> s32 #foreign sqlite;

sqlite3_prepare_v3 :: (db: *sqlite3, zSql: *s8, nByte: s32, prepFlags: u32, ppStmt: **sqlite3_stmt, pzTail: **s8) -> s32 #foreign sqlite;

sqlite3_prepare16 :: (db: *sqlite3, zSql: *void, nByte: s32, ppStmt: **sqlite3_stmt, pzTail: **void) -> s32 #foreign sqlite;

sqlite3_prepare16_v2 :: (db: *sqlite3, zSql: *void, nByte: s32, ppStmt: **sqlite3_stmt, pzTail: **void) -> s32 #foreign sqlite;

sqlite3_prepare16_v3 :: (db: *sqlite3, zSql: *void, nByte: s32, prepFlags: u32, ppStmt: **sqlite3_stmt, pzTail: **void) -> s32 #foreign sqlite;

sqlite3_sql :: (pStmt: *sqlite3_stmt) -> *s8 #foreign sqlite;

sqlite3_expanded_sql :: (pStmt: *sqlite3_stmt) -> *s8 #foreign sqlite;

sqlite3_stmt_readonly :: (pStmt: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_stmt_isexplain :: (pStmt: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_stmt_busy :: (unk0: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_value :: struct {
}



sqlite3_context :: struct {
}



sqlite3_bind_blob :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *void, n: s32, unk3: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_bind_blob64 :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *void, unk3: sqlite3_uint64, unk4: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_bind_double :: (unk0: *sqlite3_stmt, unk1: s32, unk2: float64) -> s32 #foreign sqlite;

sqlite3_bind_int :: (unk0: *sqlite3_stmt, unk1: s32, unk2: s32) -> s32 #foreign sqlite;

sqlite3_bind_int64 :: (unk0: *sqlite3_stmt, unk1: s32, unk2: sqlite3_int64) -> s32 #foreign sqlite;

sqlite3_bind_null :: (unk0: *sqlite3_stmt, unk1: s32) -> s32 #foreign sqlite;

sqlite3_bind_text :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *s8, unk3: s32, unk4: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_bind_text16 :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *void, unk3: s32, unk4: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_bind_text64 :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *s8, unk3: sqlite3_uint64, unk4: #type (a0: *void) -> void #c_call, encoding: u8) -> s32 #foreign sqlite;

sqlite3_bind_value :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_bind_pointer :: (unk0: *sqlite3_stmt, unk1: s32, unk2: *void, unk3: *s8, unk4: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_bind_zeroblob :: (unk0: *sqlite3_stmt, unk1: s32, n: s32) -> s32 #foreign sqlite;

sqlite3_bind_zeroblob64 :: (unk0: *sqlite3_stmt, unk1: s32, unk2: sqlite3_uint64) -> s32 #foreign sqlite;

sqlite3_bind_parameter_count :: (unk0: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_bind_parameter_name :: (unk0: *sqlite3_stmt, unk1: s32) -> *s8 #foreign sqlite;

sqlite3_bind_parameter_index :: (unk0: *sqlite3_stmt, zName: *s8) -> s32 #foreign sqlite;

sqlite3_clear_bindings :: (unk0: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_column_count :: (pStmt: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_column_name :: (unk0: *sqlite3_stmt, N: s32) -> *s8 #foreign sqlite;

sqlite3_column_name16 :: (unk0: *sqlite3_stmt, N: s32) -> *void #foreign sqlite;

sqlite3_column_database_name :: (unk0: *sqlite3_stmt, unk1: s32) -> *s8 #foreign sqlite;

sqlite3_column_database_name16 :: (unk0: *sqlite3_stmt, unk1: s32) -> *void #foreign sqlite;

sqlite3_column_table_name :: (unk0: *sqlite3_stmt, unk1: s32) -> *s8 #foreign sqlite;

sqlite3_column_table_name16 :: (unk0: *sqlite3_stmt, unk1: s32) -> *void #foreign sqlite;

sqlite3_column_origin_name :: (unk0: *sqlite3_stmt, unk1: s32) -> *s8 #foreign sqlite;

sqlite3_column_origin_name16 :: (unk0: *sqlite3_stmt, unk1: s32) -> *void #foreign sqlite;

sqlite3_column_decltype :: (unk0: *sqlite3_stmt, unk1: s32) -> *s8 #foreign sqlite;

sqlite3_column_decltype16 :: (unk0: *sqlite3_stmt, unk1: s32) -> *void #foreign sqlite;

sqlite3_step :: (unk0: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_data_count :: (pStmt: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_column_blob :: (unk0: *sqlite3_stmt, iCol: s32) -> *void #foreign sqlite;

sqlite3_column_double :: (unk0: *sqlite3_stmt, iCol: s32) -> float64 #foreign sqlite;

sqlite3_column_int :: (unk0: *sqlite3_stmt, iCol: s32) -> s32 #foreign sqlite;

sqlite3_column_int64 :: (unk0: *sqlite3_stmt, iCol: s32) -> sqlite3_int64 #foreign sqlite;

sqlite3_column_text :: (unk0: *sqlite3_stmt, iCol: s32) -> *u8 #foreign sqlite;

sqlite3_column_text16 :: (unk0: *sqlite3_stmt, iCol: s32) -> *void #foreign sqlite;

sqlite3_column_value :: (unk0: *sqlite3_stmt, iCol: s32) -> *sqlite3_value #foreign sqlite;

sqlite3_column_bytes :: (unk0: *sqlite3_stmt, iCol: s32) -> s32 #foreign sqlite;

sqlite3_column_bytes16 :: (unk0: *sqlite3_stmt, iCol: s32) -> s32 #foreign sqlite;

sqlite3_column_type :: (unk0: *sqlite3_stmt, iCol: s32) -> s32 #foreign sqlite;

sqlite3_finalize :: (pStmt: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_reset :: (pStmt: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_create_function :: (db: *sqlite3, zFunctionName: *s8, nArg: s32, eTextRep: s32, pApp: *void, xFunc: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xStep: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xFinal: #type (a0: *sqlite3_context) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_create_function16 :: (db: *sqlite3, zFunctionName: *void, nArg: s32, eTextRep: s32, pApp: *void, xFunc: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xStep: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xFinal: #type (a0: *sqlite3_context) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_create_function_v2 :: (db: *sqlite3, zFunctionName: *s8, nArg: s32, eTextRep: s32, pApp: *void, xFunc: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xStep: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xFinal: #type (a0: *sqlite3_context) -> void #c_call, xDestroy: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_create_window_function :: (db: *sqlite3, zFunctionName: *s8, nArg: s32, eTextRep: s32, pApp: *void, xStep: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xFinal: #type (a0: *sqlite3_context) -> void #c_call, xValue: #type (a0: *sqlite3_context) -> void #c_call, xInverse: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, xDestroy: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_aggregate_count :: (unk0: *sqlite3_context) -> s32 #foreign sqlite;

sqlite3_expired :: (unk0: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_transfer_bindings :: (unk0: *sqlite3_stmt, unk1: *sqlite3_stmt) -> s32 #foreign sqlite;

sqlite3_global_recover :: () -> s32 #foreign sqlite;

sqlite3_thread_cleanup :: () -> void #foreign sqlite;

sqlite3_memory_alarm :: (unk0: #type (a0: *void, a1: sqlite3_int64, a2: s32) -> void #c_call, unk1: *void, unk2: sqlite3_int64) -> s32 #foreign sqlite;

sqlite3_value_blob :: (unk0: *sqlite3_value) -> *void #foreign sqlite;

sqlite3_value_double :: (unk0: *sqlite3_value) -> float64 #foreign sqlite;

sqlite3_value_int :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_int64 :: (unk0: *sqlite3_value) -> sqlite3_int64 #foreign sqlite;

sqlite3_value_pointer :: (unk0: *sqlite3_value, unk1: *s8) -> *void #foreign sqlite;

sqlite3_value_text :: (unk0: *sqlite3_value) -> *u8 #foreign sqlite;

sqlite3_value_text16 :: (unk0: *sqlite3_value) -> *void #foreign sqlite;

sqlite3_value_text16le :: (unk0: *sqlite3_value) -> *void #foreign sqlite;

sqlite3_value_text16be :: (unk0: *sqlite3_value) -> *void #foreign sqlite;

sqlite3_value_bytes :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_bytes16 :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_type :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_numeric_type :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_nochange :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_frombind :: (unk0: *sqlite3_value) -> s32 #foreign sqlite;

sqlite3_value_subtype :: (unk0: *sqlite3_value) -> u32 #foreign sqlite;

sqlite3_value_dup :: (unk0: *sqlite3_value) -> *sqlite3_value #foreign sqlite;

sqlite3_value_free :: (unk0: *sqlite3_value) -> void #foreign sqlite;

sqlite3_aggregate_context :: (unk0: *sqlite3_context, nBytes: s32) -> *void #foreign sqlite;

sqlite3_user_data :: (unk0: *sqlite3_context) -> *void #foreign sqlite;

sqlite3_context_db_handle :: (unk0: *sqlite3_context) -> *sqlite3 #foreign sqlite;

sqlite3_get_auxdata :: (unk0: *sqlite3_context, N: s32) -> *void #foreign sqlite;

sqlite3_set_auxdata :: (unk0: *sqlite3_context, N: s32, unk1: *void, unk2: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_destructor_type :: #type (a0: *void) -> void #c_call;

sqlite3_result_blob :: (unk0: *sqlite3_context, unk1: *void, unk2: s32, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_blob64 :: (unk0: *sqlite3_context, unk1: *void, unk2: sqlite3_uint64, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_double :: (unk0: *sqlite3_context, unk1: float64) -> void #foreign sqlite;

sqlite3_result_error :: (unk0: *sqlite3_context, unk1: *s8, unk2: s32) -> void #foreign sqlite;

sqlite3_result_error16 :: (unk0: *sqlite3_context, unk1: *void, unk2: s32) -> void #foreign sqlite;

sqlite3_result_error_toobig :: (unk0: *sqlite3_context) -> void #foreign sqlite;

sqlite3_result_error_nomem :: (unk0: *sqlite3_context) -> void #foreign sqlite;

sqlite3_result_error_code :: (unk0: *sqlite3_context, unk1: s32) -> void #foreign sqlite;

sqlite3_result_int :: (unk0: *sqlite3_context, unk1: s32) -> void #foreign sqlite;

sqlite3_result_int64 :: (unk0: *sqlite3_context, unk1: sqlite3_int64) -> void #foreign sqlite;

sqlite3_result_null :: (unk0: *sqlite3_context) -> void #foreign sqlite;

sqlite3_result_text :: (unk0: *sqlite3_context, unk1: *s8, unk2: s32, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_text64 :: (unk0: *sqlite3_context, unk1: *s8, unk2: sqlite3_uint64, unk3: #type (a0: *void) -> void #c_call, encoding: u8) -> void #foreign sqlite;

sqlite3_result_text16 :: (unk0: *sqlite3_context, unk1: *void, unk2: s32, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_text16le :: (unk0: *sqlite3_context, unk1: *void, unk2: s32, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_text16be :: (unk0: *sqlite3_context, unk1: *void, unk2: s32, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_value :: (unk0: *sqlite3_context, unk1: *sqlite3_value) -> void #foreign sqlite;

sqlite3_result_pointer :: (unk0: *sqlite3_context, unk1: *void, unk2: *s8, unk3: #type (a0: *void) -> void #c_call) -> void #foreign sqlite;

sqlite3_result_zeroblob :: (unk0: *sqlite3_context, n: s32) -> void #foreign sqlite;

sqlite3_result_zeroblob64 :: (unk0: *sqlite3_context, n: sqlite3_uint64) -> s32 #foreign sqlite;

sqlite3_result_subtype :: (unk0: *sqlite3_context, unk1: u32) -> void #foreign sqlite;

sqlite3_create_collation :: (unk0: *sqlite3, zName: *s8, eTextRep: s32, pArg: *void, xCompare: #type (a0: *void, a1: s32, a2: *void, a3: s32, a4: *void) -> s32 #c_call) -> s32 #foreign sqlite;

sqlite3_create_collation_v2 :: (unk0: *sqlite3, zName: *s8, eTextRep: s32, pArg: *void, xCompare: #type (a0: *void, a1: s32, a2: *void, a3: s32, a4: *void) -> s32 #c_call, xDestroy: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_create_collation16 :: (unk0: *sqlite3, zName: *void, eTextRep: s32, pArg: *void, xCompare: #type (a0: *void, a1: s32, a2: *void, a3: s32, a4: *void) -> s32 #c_call) -> s32 #foreign sqlite;

sqlite3_collation_needed :: (unk0: *sqlite3, unk1: *void, unk2: #type (a0: *void, a1: *sqlite3, a2: s32, a3: *s8) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_collation_needed16 :: (unk0: *sqlite3, unk1: *void, unk2: #type (a0: *void, a1: *sqlite3, a2: s32, a3: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_sleep :: (unk0: s32) -> s32 #foreign sqlite;

sqlite3_temp_directory: *s8;

sqlite3_data_directory: *s8;

sqlite3_win32_set_directory :: (type: u32, zValue: *void) -> s32 #foreign sqlite;

sqlite3_win32_set_directory8 :: (type: u32, zValue: *s8) -> s32 #foreign sqlite;

sqlite3_win32_set_directory16 :: (type: u32, zValue: *void) -> s32 #foreign sqlite;

sqlite3_get_autocommit :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_db_handle :: (unk0: *sqlite3_stmt) -> *sqlite3 #foreign sqlite;

sqlite3_db_filename :: (db: *sqlite3, zDbName: *s8) -> *s8 #foreign sqlite;

sqlite3_db_readonly :: (db: *sqlite3, zDbName: *s8) -> s32 #foreign sqlite;

sqlite3_txn_state :: (unk0: *sqlite3, zSchema: *s8) -> s32 #foreign sqlite;

sqlite3_next_stmt :: (pDb: *sqlite3, pStmt: *sqlite3_stmt) -> *sqlite3_stmt #foreign sqlite;

sqlite3_commit_hook :: (unk0: *sqlite3, unk1: #type (a0: *void) -> s32 #c_call, unk2: *void) -> *void #foreign sqlite;

sqlite3_rollback_hook :: (unk0: *sqlite3, unk1: #type (a0: *void) -> void #c_call, unk2: *void) -> *void #foreign sqlite;

sqlite3_autovacuum_pages :: (db: *sqlite3, unk0: #type (a0: *void, a1: *s8, a2: u32, a3: u32, a4: u32) -> u32 #c_call, unk1: *void, unk2: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_update_hook :: (unk0: *sqlite3, unk1: #type (a0: *void, a1: s32, a2: *s8, a3: *s8, a4: sqlite3_int64) -> void #c_call, unk2: *void) -> *void #foreign sqlite;

sqlite3_enable_shared_cache :: (unk0: s32) -> s32 #foreign sqlite;

sqlite3_release_memory :: (unk0: s32) -> s32 #foreign sqlite;

sqlite3_db_release_memory :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_soft_heap_limit64 :: (N: sqlite3_int64) -> sqlite3_int64 #foreign sqlite;

sqlite3_hard_heap_limit64 :: (N: sqlite3_int64) -> sqlite3_int64 #foreign sqlite;

sqlite3_soft_heap_limit :: (N: s32) -> void #foreign sqlite;

sqlite3_table_column_metadata :: (db: *sqlite3, zDbName: *s8, zTableName: *s8, zColumnName: *s8, pzDataType: **s8, pzCollSeq: **s8, pNotNull: *s32, pPrimaryKey: *s32, pAutoinc: *s32) -> s32 #foreign sqlite;

sqlite3_load_extension :: (db: *sqlite3, zFile: *s8, zProc: *s8, pzErrMsg: **s8) -> s32 #foreign sqlite;

sqlite3_enable_load_extension :: (db: *sqlite3, onoff: s32) -> s32 #foreign sqlite;

sqlite3_auto_extension :: (xEntryPoint: #type () -> void #c_call) -> s32 #foreign sqlite;

sqlite3_cancel_auto_extension :: (xEntryPoint: #type () -> void #c_call) -> s32 #foreign sqlite;

sqlite3_reset_auto_extension :: () -> void #foreign sqlite;









sqlite3_module :: struct {
    iVersion: s32;
    xCreate: #type (a0: *sqlite3, a1: *void, a2: s32, a3: **s8, a4: **sqlite3_vtab, a5: **s8) -> s32 #c_call;
    xConnect: #type (a0: *sqlite3, a1: *void, a2: s32, a3: **s8, a4: **sqlite3_vtab, a5: **s8) -> s32 #c_call;
    xBestIndex: #type (a0: *sqlite3_vtab, a1: *sqlite3_index_info) -> s32 #c_call;
    xDisconnect: #type (a0: *sqlite3_vtab) -> s32 #c_call;
    xDestroy: #type (a0: *sqlite3_vtab) -> s32 #c_call;
    xOpen: #type (a0: *sqlite3_vtab, a1: **sqlite3_vtab_cursor) -> s32 #c_call;
    xClose: #type (a0: *sqlite3_vtab_cursor) -> s32 #c_call;
    xFilter: #type (a0: *sqlite3_vtab_cursor, a1: s32, a2: *s8, a3: s32, a4: **sqlite3_value) -> s32 #c_call;
    xNext: #type (a0: *sqlite3_vtab_cursor) -> s32 #c_call;
    xEof: #type (a0: *sqlite3_vtab_cursor) -> s32 #c_call;
    xColumn: #type (a0: *sqlite3_vtab_cursor, a1: *sqlite3_context, a2: s32) -> s32 #c_call;
    xRowid: #type (a0: *sqlite3_vtab_cursor, a1: *sqlite3_int64) -> s32 #c_call;
    xUpdate: #type (a0: *sqlite3_vtab, a1: s32, a2: **sqlite3_value, a3: *sqlite3_int64) -> s32 #c_call;
    xBegin: #type (a0: *sqlite3_vtab) -> s32 #c_call;
    xSync: #type (a0: *sqlite3_vtab) -> s32 #c_call;
    xCommit: #type (a0: *sqlite3_vtab) -> s32 #c_call;
    xRollback: #type (a0: *sqlite3_vtab) -> s32 #c_call;
    xFindFunction: #type (a0: *sqlite3_vtab, a1: s32, a2: *s8, a3: *#type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a4: **void) -> s32 #c_call;
    xRename: #type (a0: *sqlite3_vtab, a1: *s8) -> s32 #c_call;
    xSavepoint: #type (a0: *sqlite3_vtab, a1: s32) -> s32 #c_call;
    xRelease: #type (a0: *sqlite3_vtab, a1: s32) -> s32 #c_call;
    xRollbackTo: #type (a0: *sqlite3_vtab, a1: s32) -> s32 #c_call;
    xShadowName: #type (a0: *s8) -> s32 #c_call;
}

sqlite3_index_info :: struct {
    nConstraint: s32;
    sqlite3_index_constraint :: struct {
        iColumn: s32;
        op: u8;
        usable: u8;
        iTermOffset: s32;
    }
    aConstraint: *sqlite3_index_constraint;
    nOrderBy: s32;
    sqlite3_index_orderby :: struct {
        iColumn: s32;
        desc: u8;
    }
    aOrderBy: *sqlite3_index_orderby;
    sqlite3_index_constraint_usage :: struct {
        argvIndex: s32;
        omit: u8;
    }
    aConstraintUsage: *sqlite3_index_constraint_usage;
    idxNum: s32;
    idxStr: *s8;
    needToFreeIdxStr: s32;
    orderByConsumed: s32;
    estimatedCost: float64;
    estimatedRows: sqlite3_int64;
    idxFlags: s32;
    colUsed: sqlite3_uint64;
}

sqlite3_create_module :: (db: *sqlite3, zName: *s8, p: *sqlite3_module, pClientData: *void) -> s32 #foreign sqlite;

sqlite3_create_module_v2 :: (db: *sqlite3, zName: *s8, p: *sqlite3_module, pClientData: *void, xDestroy: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_drop_modules :: (db: *sqlite3, azKeep: **s8) -> s32 #foreign sqlite;

sqlite3_vtab :: struct {
    pModule: *sqlite3_module;
    nRef: s32;
    zErrMsg: *s8;
}

sqlite3_vtab_cursor :: struct {
    pVtab: *sqlite3_vtab;
}

sqlite3_declare_vtab :: (unk0: *sqlite3, zSQL: *s8) -> s32 #foreign sqlite;

sqlite3_overload_function :: (unk0: *sqlite3, zFuncName: *s8, nArg: s32) -> s32 #foreign sqlite;

sqlite3_blob :: struct {
}



sqlite3_blob_open :: (unk0: *sqlite3, zDb: *s8, zTable: *s8, zColumn: *s8, iRow: sqlite3_int64, flags: s32, ppBlob: **sqlite3_blob) -> s32 #foreign sqlite;

sqlite3_blob_reopen :: (unk0: *sqlite3_blob, unk1: sqlite3_int64) -> s32 #foreign sqlite;

sqlite3_blob_close :: (unk0: *sqlite3_blob) -> s32 #foreign sqlite;

sqlite3_blob_bytes :: (unk0: *sqlite3_blob) -> s32 #foreign sqlite;

sqlite3_blob_read :: (unk0: *sqlite3_blob, Z: *void, N: s32, iOffset: s32) -> s32 #foreign sqlite;

sqlite3_blob_write :: (unk0: *sqlite3_blob, z: *void, n: s32, iOffset: s32) -> s32 #foreign sqlite;

sqlite3_vfs_find :: (zVfsName: *s8) -> *sqlite3_vfs #foreign sqlite;

sqlite3_vfs_register :: (unk0: *sqlite3_vfs, makeDflt: s32) -> s32 #foreign sqlite;

sqlite3_vfs_unregister :: (unk0: *sqlite3_vfs) -> s32 #foreign sqlite;

sqlite3_mutex_alloc :: (unk0: s32) -> *sqlite3_mutex #foreign sqlite;

sqlite3_mutex_free :: (unk0: *sqlite3_mutex) -> void #foreign sqlite;

sqlite3_mutex_enter :: (unk0: *sqlite3_mutex) -> void #foreign sqlite;

sqlite3_mutex_try :: (unk0: *sqlite3_mutex) -> s32 #foreign sqlite;

sqlite3_mutex_leave :: (unk0: *sqlite3_mutex) -> void #foreign sqlite;



sqlite3_mutex_methods :: struct {
    xMutexInit: #type () -> s32 #c_call;
    xMutexEnd: #type () -> s32 #c_call;
    xMutexAlloc: #type (a0: s32) -> *sqlite3_mutex #c_call;
    xMutexFree: #type (a0: *sqlite3_mutex) -> void #c_call;
    xMutexEnter: #type (a0: *sqlite3_mutex) -> void #c_call;
    xMutexTry: #type (a0: *sqlite3_mutex) -> s32 #c_call;
    xMutexLeave: #type (a0: *sqlite3_mutex) -> void #c_call;
    xMutexHeld: #type (a0: *sqlite3_mutex) -> s32 #c_call;
    xMutexNotheld: #type (a0: *sqlite3_mutex) -> s32 #c_call;
}

//sqlite3_mutex_held :: (unk0: *sqlite3_mutex) -> s32 #foreign sqlite;

//sqlite3_mutex_notheld :: (unk0: *sqlite3_mutex) -> s32 #foreign sqlite;

sqlite3_db_mutex :: (unk0: *sqlite3) -> *sqlite3_mutex #foreign sqlite;

sqlite3_file_control :: (unk0: *sqlite3, zDbName: *s8, op: s32, unk1: *void) -> s32 #foreign sqlite;

sqlite3_test_control :: (op: s32, __args: ..Any) -> s32 #foreign sqlite;

sqlite3_keyword_count :: () -> s32 #foreign sqlite;

sqlite3_keyword_name :: (unk0: s32, unk1: **s8, unk2: *s32) -> s32 #foreign sqlite;

sqlite3_keyword_check :: (unk0: *s8, unk1: s32) -> s32 #foreign sqlite;

sqlite3_str :: struct {
}



sqlite3_str_new :: (unk0: *sqlite3) -> *sqlite3_str #foreign sqlite;

sqlite3_str_finish :: (unk0: *sqlite3_str) -> *s8 #foreign sqlite;

sqlite3_str_appendf :: (unk0: *sqlite3_str, zFormat: *s8, __args: ..Any) -> void #foreign sqlite;

//sqlite3_str_vappendf :: (unk0: *sqlite3_str, zFormat: *s8, unk1: va_list) -> void #foreign sqlite;

sqlite3_str_append :: (unk0: *sqlite3_str, zIn: *s8, N: s32) -> void #foreign sqlite;

sqlite3_str_appendall :: (unk0: *sqlite3_str, zIn: *s8) -> void #foreign sqlite;

sqlite3_str_appendchar :: (unk0: *sqlite3_str, N: s32, C: s8) -> void #foreign sqlite;

sqlite3_str_reset :: (unk0: *sqlite3_str) -> void #foreign sqlite;

sqlite3_str_errcode :: (unk0: *sqlite3_str) -> s32 #foreign sqlite;

sqlite3_str_length :: (unk0: *sqlite3_str) -> s32 #foreign sqlite;

sqlite3_str_value :: (unk0: *sqlite3_str) -> *s8 #foreign sqlite;

sqlite3_status :: (op: s32, pCurrent: *s32, pHighwater: *s32, resetFlag: s32) -> s32 #foreign sqlite;

sqlite3_status64 :: (op: s32, pCurrent: *sqlite3_int64, pHighwater: *sqlite3_int64, resetFlag: s32) -> s32 #foreign sqlite;

sqlite3_db_status :: (unk0: *sqlite3, op: s32, pCur: *s32, pHiwtr: *s32, resetFlg: s32) -> s32 #foreign sqlite;

sqlite3_stmt_status :: (unk0: *sqlite3_stmt, op: s32, resetFlg: s32) -> s32 #foreign sqlite;

sqlite3_pcache :: struct {
}





sqlite3_pcache_page :: struct {
    pBuf: *void;
    pExtra: *void;
}



sqlite3_pcache_methods2 :: struct {
    iVersion: s32;
    pArg: *void;
    xInit: #type (a0: *void) -> s32 #c_call;
    xShutdown: #type (a0: *void) -> void #c_call;
    xCreate: #type (a0: s32, a1: s32, a2: s32) -> *sqlite3_pcache #c_call;
    xCachesize: #type (a0: *sqlite3_pcache, a1: s32) -> void #c_call;
    xPagecount: #type (a0: *sqlite3_pcache) -> s32 #c_call;
    xFetch: #type (a0: *sqlite3_pcache, a1: u32, a2: s32) -> *sqlite3_pcache_page #c_call;
    xUnpin: #type (a0: *sqlite3_pcache, a1: *sqlite3_pcache_page, a2: s32) -> void #c_call;
    xRekey: #type (a0: *sqlite3_pcache, a1: *sqlite3_pcache_page, a2: u32, a3: u32) -> void #c_call;
    xTruncate: #type (a0: *sqlite3_pcache, a1: u32) -> void #c_call;
    xDestroy: #type (a0: *sqlite3_pcache) -> void #c_call;
    xShrink: #type (a0: *sqlite3_pcache) -> void #c_call;
}



sqlite3_pcache_methods :: struct {
    pArg: *void;
    xInit: #type (a0: *void) -> s32 #c_call;
    xShutdown: #type (a0: *void) -> void #c_call;
    xCreate: #type (a0: s32, a1: s32) -> *sqlite3_pcache #c_call;
    xCachesize: #type (a0: *sqlite3_pcache, a1: s32) -> void #c_call;
    xPagecount: #type (a0: *sqlite3_pcache) -> s32 #c_call;
    xFetch: #type (a0: *sqlite3_pcache, a1: u32, a2: s32) -> *void #c_call;
    xUnpin: #type (a0: *sqlite3_pcache, a1: *void, a2: s32) -> void #c_call;
    xRekey: #type (a0: *sqlite3_pcache, a1: *void, a2: u32, a3: u32) -> void #c_call;
    xTruncate: #type (a0: *sqlite3_pcache, a1: u32) -> void #c_call;
    xDestroy: #type (a0: *sqlite3_pcache) -> void #c_call;
}

sqlite3_backup :: struct {
}



sqlite3_backup_init :: (pDest: *sqlite3, zDestName: *s8, pSource: *sqlite3, zSourceName: *s8) -> *sqlite3_backup #foreign sqlite;

sqlite3_backup_step :: (p: *sqlite3_backup, nPage: s32) -> s32 #foreign sqlite;

sqlite3_backup_finish :: (p: *sqlite3_backup) -> s32 #foreign sqlite;

sqlite3_backup_remaining :: (p: *sqlite3_backup) -> s32 #foreign sqlite;

sqlite3_backup_pagecount :: (p: *sqlite3_backup) -> s32 #foreign sqlite;

//sqlite3_unlock_notify :: (pBlocked: *sqlite3, xNotify: #type (a0: **void, a1: s32) -> void #c_call, pNotifyArg: *void) -> s32 #foreign sqlite;

sqlite3_stricmp :: (unk0: *s8, unk1: *s8) -> s32 #foreign sqlite;

sqlite3_strnicmp :: (unk0: *s8, unk1: *s8, unk2: s32) -> s32 #foreign sqlite;

sqlite3_strglob :: (zGlob: *s8, zStr: *s8) -> s32 #foreign sqlite;

sqlite3_strlike :: (zGlob: *s8, zStr: *s8, cEsc: u32) -> s32 #foreign sqlite;

sqlite3_log :: (iErrCode: s32, zFormat: *s8, __args: ..Any) -> void #foreign sqlite;

sqlite3_wal_hook :: (unk0: *sqlite3, unk1: #type (a0: *void, a1: *sqlite3, a2: *s8, a3: s32) -> s32 #c_call, unk2: *void) -> *void #foreign sqlite;

sqlite3_wal_autocheckpoint :: (db: *sqlite3, N: s32) -> s32 #foreign sqlite;

sqlite3_wal_checkpoint :: (db: *sqlite3, zDb: *s8) -> s32 #foreign sqlite;

sqlite3_wal_checkpoint_v2 :: (db: *sqlite3, zDb: *s8, eMode: s32, pnLog: *s32, pnCkpt: *s32) -> s32 #foreign sqlite;

sqlite3_vtab_config :: (unk0: *sqlite3, op: s32, __args: ..Any) -> s32 #foreign sqlite;

sqlite3_vtab_on_conflict :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_vtab_nochange :: (unk0: *sqlite3_context) -> s32 #foreign sqlite;

sqlite3_vtab_collation :: (unk0: *sqlite3_index_info, unk1: s32) -> *s8 #foreign sqlite;

//sqlite3_stmt_scanstatus :: (pStmt: *sqlite3_stmt, idx: s32, iScanStatusOp: s32, pOut: *void) -> s32 #foreign sqlite;

//sqlite3_stmt_scanstatus_reset :: (unk0: *sqlite3_stmt) -> void #foreign sqlite;

sqlite3_db_cacheflush :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_system_errno :: (unk0: *sqlite3) -> s32 #foreign sqlite;

sqlite3_snapshot :: struct {
    hidden: [48] u8;
}



//sqlite3_snapshot_get :: (db: *sqlite3, zSchema: *s8, ppSnapshot: **sqlite3_snapshot) -> s32 #foreign sqlite;

//sqlite3_snapshot_open :: (db: *sqlite3, zSchema: *s8, pSnapshot: *sqlite3_snapshot) -> s32 #foreign sqlite;

//sqlite3_snapshot_free :: (unk0: *sqlite3_snapshot) -> void #foreign sqlite;

//sqlite3_snapshot_cmp :: (p1: *sqlite3_snapshot, p2: *sqlite3_snapshot) -> s32 #foreign sqlite;

//sqlite3_snapshot_recover :: (db: *sqlite3, zDb: *s8) -> s32 #foreign sqlite;

sqlite3_serialize :: (db: *sqlite3, zSchema: *s8, piSize: *sqlite3_int64, mFlags: u32) -> *u8 #foreign sqlite;

sqlite3_deserialize :: (db: *sqlite3, zSchema: *s8, pData: *u8, szDb: sqlite3_int64, szBuf: sqlite3_int64, mFlags: u32) -> s32 #foreign sqlite;





sqlite3_rtree_dbl :: float64;

sqlite3_rtree_geometry_callback :: (db: *sqlite3, zGeom: *s8, xGeom: #type (a0: *sqlite3_rtree_geometry, a1: s32, a2: *sqlite3_rtree_dbl, a3: *s32) -> s32 #c_call, pContext: *void) -> s32 #foreign sqlite;

sqlite3_rtree_geometry :: struct {
    pContext: *void;
    nParam: s32;
    aParam: *sqlite3_rtree_dbl;
    pUser: *void;
    xDelUser: #type (a0: *void) -> void #c_call;
}

sqlite3_rtree_query_callback :: (db: *sqlite3, zQueryFunc: *s8, xQueryFunc: #type (a0: *sqlite3_rtree_query_info) -> s32 #c_call, pContext: *void, xDestructor: #type (a0: *void) -> void #c_call) -> s32 #foreign sqlite;

sqlite3_rtree_query_info :: struct {
    pContext: *void;
    nParam: s32;
    aParam: *sqlite3_rtree_dbl;
    pUser: *void;
    xDelUser: #type (a0: *void) -> void #c_call;
    aCoord: *sqlite3_rtree_dbl;
    anQueue: *u32;
    nCoord: s32;
    iLevel: s32;
    mxLevel: s32;
    iRowid: sqlite3_int64;
    rParentScore: sqlite3_rtree_dbl;
    eParentWithin: s32;
    eWithin: s32;
    rScore: sqlite3_rtree_dbl;
    apSqlParam: **sqlite3_value;
}



Fts5Context :: struct {
}





fts5_extension_function :: #type (a0: *Fts5ExtensionApi, a1: *Fts5Context, a2: *sqlite3_context, a3: s32, a4: **sqlite3_value) -> void #c_call;

Fts5PhraseIter :: struct {
    a: *u8;
    b: *u8;
}

Fts5ExtensionApi :: struct {
    iVersion: s32;
    xUserData: #type (a0: *Fts5Context) -> *void #c_call;
    xColumnCount: #type (a0: *Fts5Context) -> s32 #c_call;
    xRowCount: #type (a0: *Fts5Context, a1: *sqlite3_int64) -> s32 #c_call;
    xColumnTotalSize: #type (a0: *Fts5Context, a1: s32, a2: *sqlite3_int64) -> s32 #c_call;
    xTokenize: #type (a0: *Fts5Context, a1: *s8, a2: s32, a3: *void, a4: #type (a0: *void, a1: s32, a2: *s8, a3: s32, a4: s32, a5: s32) -> s32 #c_call) -> s32 #c_call;
    xPhraseCount: #type (a0: *Fts5Context) -> s32 #c_call;
    xPhraseSize: #type (a0: *Fts5Context, a1: s32) -> s32 #c_call;
    xInstCount: #type (a0: *Fts5Context, a1: *s32) -> s32 #c_call;
    xInst: #type (a0: *Fts5Context, a1: s32, a2: *s32, a3: *s32, a4: *s32) -> s32 #c_call;
    xRowid: #type (a0: *Fts5Context) -> sqlite3_int64 #c_call;
    xColumnText: #type (a0: *Fts5Context, a1: s32, a2: **s8, a3: *s32) -> s32 #c_call;
    xColumnSize: #type (a0: *Fts5Context, a1: s32, a2: *s32) -> s32 #c_call;
    xQueryPhrase: #type (a0: *Fts5Context, a1: s32, a2: *void, a3: #type (a0: *Fts5ExtensionApi, a1: *Fts5Context, a2: *void) -> s32 #c_call) -> s32 #c_call;
    xSetAuxdata: #type (a0: *Fts5Context, a1: *void, a2: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    xGetAuxdata: #type (a0: *Fts5Context, a1: s32) -> *void #c_call;
    xPhraseFirst: #type (a0: *Fts5Context, a1: s32, a2: *Fts5PhraseIter, a3: *s32, a4: *s32) -> s32 #c_call;
    xPhraseNext: #type (a0: *Fts5Context, a1: *Fts5PhraseIter, a2: *s32, a3: *s32) -> void #c_call;
    xPhraseFirstColumn: #type (a0: *Fts5Context, a1: s32, a2: *Fts5PhraseIter, a3: *s32) -> s32 #c_call;
    xPhraseNextColumn: #type (a0: *Fts5Context, a1: *Fts5PhraseIter, a2: *s32) -> void #c_call;
}

Fts5Tokenizer :: struct {
}





fts5_tokenizer :: struct {
    xCreate: #type (a0: *void, a1: **s8, a2: s32, a3: **Fts5Tokenizer) -> s32 #c_call;
    xDelete: #type (a0: *Fts5Tokenizer) -> void #c_call;
    xTokenize: #type (a0: *Fts5Tokenizer, a1: *void, a2: s32, a3: *s8, a4: s32, a5: #type (a0: *void, a1: s32, a2: *s8, a3: s32, a4: s32, a5: s32) -> s32 #c_call) -> s32 #c_call;
}



fts5_api :: struct {
    iVersion: s32;
    xCreateTokenizer: #type (a0: *fts5_api, a1: *s8, a2: *void, a3: *fts5_tokenizer, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    xFindTokenizer: #type (a0: *fts5_api, a1: *s8, a2: **void, a3: *fts5_tokenizer) -> s32 #c_call;
    xCreateFunction: #type (a0: *fts5_api, a1: *s8, a2: *void, a3: fts5_extension_function, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
}

sqlite3_api_routines :: struct #type_info_none {
    aggregate_context: #type (a0: *sqlite3_context, a1: s32) -> *void #c_call;
    aggregate_count: #type (a0: *sqlite3_context) -> s32 #c_call;
    bind_blob: #type (a0: *sqlite3_stmt, a1: s32, a2: *void, a3: s32, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    bind_double: #type (a0: *sqlite3_stmt, a1: s32, a2: float64) -> s32 #c_call;
    bind_int: #type (a0: *sqlite3_stmt, a1: s32, a2: s32) -> s32 #c_call;
    bind_int64: #type (a0: *sqlite3_stmt, a1: s32, a2: sqlite_int64) -> s32 #c_call;
    bind_null: #type (a0: *sqlite3_stmt, a1: s32) -> s32 #c_call;
    bind_parameter_count: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    bind_parameter_index: #type (a0: *sqlite3_stmt, a1: *s8) -> s32 #c_call;
    bind_parameter_name: #type (a0: *sqlite3_stmt, a1: s32) -> *s8 #c_call;
    bind_text: #type (a0: *sqlite3_stmt, a1: s32, a2: *s8, a3: s32, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    bind_text16: #type (a0: *sqlite3_stmt, a1: s32, a2: *void, a3: s32, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    bind_value: #type (a0: *sqlite3_stmt, a1: s32, a2: *sqlite3_value) -> s32 #c_call;
    busy_handler: #type (a0: *sqlite3, a1: #type (a0: *void, a1: s32) -> s32 #c_call, a2: *void) -> s32 #c_call;
    busy_timeout: #type (a0: *sqlite3, a1: s32) -> s32 #c_call;
    changes: #type (a0: *sqlite3) -> s32 #c_call;
    close: #type (a0: *sqlite3) -> s32 #c_call;
    collation_needed: #type (a0: *sqlite3, a1: *void, a2: #type (a0: *void, a1: *sqlite3, a2: s32, a3: *s8) -> void #c_call) -> s32 #c_call;
    collation_needed16: #type (a0: *sqlite3, a1: *void, a2: #type (a0: *void, a1: *sqlite3, a2: s32, a3: *void) -> void #c_call) -> s32 #c_call;
    column_blob: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_bytes: #type (a0: *sqlite3_stmt, a1: s32) -> s32 #c_call;
    column_bytes16: #type (a0: *sqlite3_stmt, a1: s32) -> s32 #c_call;
    column_count: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    column_database_name: #type (a0: *sqlite3_stmt, a1: s32) -> *s8 #c_call;
    column_database_name16: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_decltype: #type (a0: *sqlite3_stmt, a1: s32) -> *s8 #c_call;
    column_decltype16: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_double: #type (a0: *sqlite3_stmt, a1: s32) -> float64 #c_call;
    column_int: #type (a0: *sqlite3_stmt, a1: s32) -> s32 #c_call;
    column_int64: #type (a0: *sqlite3_stmt, a1: s32) -> sqlite_int64 #c_call;
    column_name: #type (a0: *sqlite3_stmt, a1: s32) -> *s8 #c_call;
    column_name16: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_origin_name: #type (a0: *sqlite3_stmt, a1: s32) -> *s8 #c_call;
    column_origin_name16: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_table_name: #type (a0: *sqlite3_stmt, a1: s32) -> *s8 #c_call;
    column_table_name16: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_text: #type (a0: *sqlite3_stmt, a1: s32) -> *u8 #c_call;
    column_text16: #type (a0: *sqlite3_stmt, a1: s32) -> *void #c_call;
    column_type: #type (a0: *sqlite3_stmt, a1: s32) -> s32 #c_call;
    column_value: #type (a0: *sqlite3_stmt, a1: s32) -> *sqlite3_value #c_call;
    commit_hook: #type (a0: *sqlite3, a1: #type (a0: *void) -> s32 #c_call, a2: *void) -> *void #c_call;
    complete: #type (a0: *s8) -> s32 #c_call;
    complete16: #type (a0: *void) -> s32 #c_call;
    create_collation: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: *void, a4: #type (a0: *void, a1: s32, a2: *void, a3: s32, a4: *void) -> s32 #c_call) -> s32 #c_call;
    create_collation16: #type (a0: *sqlite3, a1: *void, a2: s32, a3: *void, a4: #type (a0: *void, a1: s32, a2: *void, a3: s32, a4: *void) -> s32 #c_call) -> s32 #c_call;
    create_function: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: s32, a4: *void, a5: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a6: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a7: #type (a0: *sqlite3_context) -> void #c_call) -> s32 #c_call;
    create_function16: #type (a0: *sqlite3, a1: *void, a2: s32, a3: s32, a4: *void, a5: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a6: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a7: #type (a0: *sqlite3_context) -> void #c_call) -> s32 #c_call;
    create_module: #type (a0: *sqlite3, a1: *s8, a2: *sqlite3_module, a3: *void) -> s32 #c_call;
    data_count: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    db_handle: #type (a0: *sqlite3_stmt) -> *sqlite3 #c_call;
    declare_vtab: #type (a0: *sqlite3, a1: *s8) -> s32 #c_call;
    enable_shared_cache: #type (a0: s32) -> s32 #c_call;
    errcode: #type (a0: *sqlite3) -> s32 #c_call;
    errmsg: #type (a0: *sqlite3) -> *s8 #c_call;
    errmsg16: #type (a0: *sqlite3) -> *void #c_call;
    exec: #type (a0: *sqlite3, a1: *s8, a2: sqlite3_callback, a3: *void, a4: **s8) -> s32 #c_call;
    expired: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    finalize: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    free: #type (a0: *void) -> void #c_call;
    free_table: #type (a0: **s8) -> void #c_call;
    get_autocommit: #type (a0: *sqlite3) -> s32 #c_call;
    get_auxdata: #type (a0: *sqlite3_context, a1: s32) -> *void #c_call;
    get_table: #type (a0: *sqlite3, a1: *s8, a2: ***s8, a3: *s32, a4: *s32, a5: **s8) -> s32 #c_call;
    global_recover: #type () -> s32 #c_call;
    interruptx: #type (a0: *sqlite3) -> void #c_call;
    last_insert_rowid: #type (a0: *sqlite3) -> sqlite_int64 #c_call;
    libversion: #type () -> *s8 #c_call;
    libversion_number: #type () -> s32 #c_call;
    malloc: #type (a0: s32) -> *void #c_call;
    mprintf: #type (a0: *s8) -> *s8 #c_call;
    open: #type (a0: *s8, a1: **sqlite3) -> s32 #c_call;
    open16: #type (a0: *void, a1: **sqlite3) -> s32 #c_call;
    prepare: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: **sqlite3_stmt, a4: **s8) -> s32 #c_call;
    prepare16: #type (a0: *sqlite3, a1: *void, a2: s32, a3: **sqlite3_stmt, a4: **void) -> s32 #c_call;
    profile: #type (a0: *sqlite3, a1: #type (a0: *void, a1: *s8, a2: sqlite_uint64) -> void #c_call, a2: *void) -> *void #c_call;
    progress_handler: #type (a0: *sqlite3, a1: s32, a2: #type (a0: *void) -> s32 #c_call, a3: *void) -> void #c_call;
    realloc: #type (a0: *void, a1: s32) -> *void #c_call;
    reset: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    result_blob: #type (a0: *sqlite3_context, a1: *void, a2: s32, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    result_double: #type (a0: *sqlite3_context, a1: float64) -> void #c_call;
    result_error: #type (a0: *sqlite3_context, a1: *s8, a2: s32) -> void #c_call;
    result_error16: #type (a0: *sqlite3_context, a1: *void, a2: s32) -> void #c_call;
    result_int: #type (a0: *sqlite3_context, a1: s32) -> void #c_call;
    result_int64: #type (a0: *sqlite3_context, a1: sqlite_int64) -> void #c_call;
    result_null: #type (a0: *sqlite3_context) -> void #c_call;
    result_text: #type (a0: *sqlite3_context, a1: *s8, a2: s32, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    result_text16: #type (a0: *sqlite3_context, a1: *void, a2: s32, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    result_text16be: #type (a0: *sqlite3_context, a1: *void, a2: s32, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    result_text16le: #type (a0: *sqlite3_context, a1: *void, a2: s32, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    result_value: #type (a0: *sqlite3_context, a1: *sqlite3_value) -> void #c_call;
    rollback_hook: #type (a0: *sqlite3, a1: #type (a0: *void) -> void #c_call, a2: *void) -> *void #c_call;
    set_authorizer: #type (a0: *sqlite3, a1: #type (a0: *void, a1: s32, a2: *s8, a3: *s8, a4: *s8, a5: *s8) -> s32 #c_call, a2: *void) -> s32 #c_call;
    set_auxdata: #type (a0: *sqlite3_context, a1: s32, a2: *void, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    xsnprintf: #type (a0: s32, a1: *s8, a2: *s8) -> *s8 #c_call;
    step: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    table_column_metadata: #type (a0: *sqlite3, a1: *s8, a2: *s8, a3: *s8, a4: **s8, a5: **s8, a6: *s32, a7: *s32, a8: *s32) -> s32 #c_call;
    thread_cleanup: #type () -> void #c_call;
    total_changes: #type (a0: *sqlite3) -> s32 #c_call;
    trace: #type (a0: *sqlite3, a1: #type (a0: *void, a1: *s8) -> void #c_call, a2: *void) -> *void #c_call;
    transfer_bindings: #type (a0: *sqlite3_stmt, a1: *sqlite3_stmt) -> s32 #c_call;
    update_hook: #type (a0: *sqlite3, a1: #type (a0: *void, a1: s32, a2: *s8, a3: *s8, a4: sqlite_int64) -> void #c_call, a2: *void) -> *void #c_call;
    user_data: #type (a0: *sqlite3_context) -> *void #c_call;
    value_blob: #type (a0: *sqlite3_value) -> *void #c_call;
    value_bytes: #type (a0: *sqlite3_value) -> s32 #c_call;
    value_bytes16: #type (a0: *sqlite3_value) -> s32 #c_call;
    value_double: #type (a0: *sqlite3_value) -> float64 #c_call;
    value_int: #type (a0: *sqlite3_value) -> s32 #c_call;
    value_int64: #type (a0: *sqlite3_value) -> sqlite_int64 #c_call;
    value_numeric_type: #type (a0: *sqlite3_value) -> s32 #c_call;
    value_text: #type (a0: *sqlite3_value) -> *u8 #c_call;
    value_text16: #type (a0: *sqlite3_value) -> *void #c_call;
    value_text16be: #type (a0: *sqlite3_value) -> *void #c_call;
    value_text16le: #type (a0: *sqlite3_value) -> *void #c_call;
    value_type: #type (a0: *sqlite3_value) -> s32 #c_call;
//    vmprintf: #type (a0: *s8, a1: va_list) -> *s8 #c_call;
    overload_function: #type (a0: *sqlite3, a1: *s8, a2: s32) -> s32 #c_call;
    prepare_v2: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: **sqlite3_stmt, a4: **s8) -> s32 #c_call;
    prepare16_v2: #type (a0: *sqlite3, a1: *void, a2: s32, a3: **sqlite3_stmt, a4: **void) -> s32 #c_call;
    clear_bindings: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    create_module_v2: #type (a0: *sqlite3, a1: *s8, a2: *sqlite3_module, a3: *void, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    bind_zeroblob: #type (a0: *sqlite3_stmt, a1: s32, a2: s32) -> s32 #c_call;
    blob_bytes: #type (a0: *sqlite3_blob) -> s32 #c_call;
    blob_close: #type (a0: *sqlite3_blob) -> s32 #c_call;
    blob_open: #type (a0: *sqlite3, a1: *s8, a2: *s8, a3: *s8, a4: sqlite3_int64, a5: s32, a6: **sqlite3_blob) -> s32 #c_call;
    blob_read: #type (a0: *sqlite3_blob, a1: *void, a2: s32, a3: s32) -> s32 #c_call;
    blob_write: #type (a0: *sqlite3_blob, a1: *void, a2: s32, a3: s32) -> s32 #c_call;
    create_collation_v2: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: *void, a4: #type (a0: *void, a1: s32, a2: *void, a3: s32, a4: *void) -> s32 #c_call, a5: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    file_control: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: *void) -> s32 #c_call;
    memory_highwater: #type (a0: s32) -> sqlite3_int64 #c_call;
    memory_used: #type () -> sqlite3_int64 #c_call;
    mutex_alloc: #type (a0: s32) -> *sqlite3_mutex #c_call;
    mutex_enter: #type (a0: *sqlite3_mutex) -> void #c_call;
    mutex_free: #type (a0: *sqlite3_mutex) -> void #c_call;
    mutex_leave: #type (a0: *sqlite3_mutex) -> void #c_call;
    mutex_try: #type (a0: *sqlite3_mutex) -> s32 #c_call;
    open_v2: #type (a0: *s8, a1: **sqlite3, a2: s32, a3: *s8) -> s32 #c_call;
    release_memory: #type (a0: s32) -> s32 #c_call;
    result_error_nomem: #type (a0: *sqlite3_context) -> void #c_call;
    result_error_toobig: #type (a0: *sqlite3_context) -> void #c_call;
    sleep: #type (a0: s32) -> s32 #c_call;
    soft_heap_limit: #type (a0: s32) -> void #c_call;
    vfs_find: #type (a0: *s8) -> *sqlite3_vfs #c_call;
    vfs_register: #type (a0: *sqlite3_vfs, a1: s32) -> s32 #c_call;
    vfs_unregister: #type (a0: *sqlite3_vfs) -> s32 #c_call;
    xthreadsafe: #type () -> s32 #c_call;
    result_zeroblob: #type (a0: *sqlite3_context, a1: s32) -> void #c_call;
    result_error_code: #type (a0: *sqlite3_context, a1: s32) -> void #c_call;
    test_control: #type (a0: s32) -> s32 #c_call;
    randomness: #type (a0: s32, a1: *void) -> void #c_call;
    context_db_handle: #type (a0: *sqlite3_context) -> *sqlite3 #c_call;
    extended_result_codes: #type (a0: *sqlite3, a1: s32) -> s32 #c_call;
    limit: #type (a0: *sqlite3, a1: s32, a2: s32) -> s32 #c_call;
    next_stmt: #type (a0: *sqlite3, a1: *sqlite3_stmt) -> *sqlite3_stmt #c_call;
    sql: #type (a0: *sqlite3_stmt) -> *s8 #c_call;
    status: #type (a0: s32, a1: *s32, a2: *s32, a3: s32) -> s32 #c_call;
    backup_finish: #type (a0: *sqlite3_backup) -> s32 #c_call;
    backup_init: #type (a0: *sqlite3, a1: *s8, a2: *sqlite3, a3: *s8) -> *sqlite3_backup #c_call;
    backup_pagecount: #type (a0: *sqlite3_backup) -> s32 #c_call;
    backup_remaining: #type (a0: *sqlite3_backup) -> s32 #c_call;
    backup_step: #type (a0: *sqlite3_backup, a1: s32) -> s32 #c_call;
    compileoption_get: #type (a0: s32) -> *s8 #c_call;
    compileoption_used: #type (a0: *s8) -> s32 #c_call;
    create_function_v2: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: s32, a4: *void, a5: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a6: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a7: #type (a0: *sqlite3_context) -> void #c_call, a8: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    db_config: #type (a0: *sqlite3, a1: s32) -> s32 #c_call;
    db_mutex: #type (a0: *sqlite3) -> *sqlite3_mutex #c_call;
    db_status: #type (a0: *sqlite3, a1: s32, a2: *s32, a3: *s32, a4: s32) -> s32 #c_call;
    extended_errcode: #type (a0: *sqlite3) -> s32 #c_call;
    log: #type (a0: s32, a1: *s8) -> void #c_call;
    soft_heap_limit64: #type (a0: sqlite3_int64) -> sqlite3_int64 #c_call;
    sourceid: #type () -> *s8 #c_call;
    stmt_status: #type (a0: *sqlite3_stmt, a1: s32, a2: s32) -> s32 #c_call;
    strnicmp: #type (a0: *s8, a1: *s8, a2: s32) -> s32 #c_call;
    unlock_notify: #type (a0: *sqlite3, a1: #type (a0: **void, a1: s32) -> void #c_call, a2: *void) -> s32 #c_call;
    wal_autocheckpoint: #type (a0: *sqlite3, a1: s32) -> s32 #c_call;
    wal_checkpoint: #type (a0: *sqlite3, a1: *s8) -> s32 #c_call;
    wal_hook: #type (a0: *sqlite3, a1: #type (a0: *void, a1: *sqlite3, a2: *s8, a3: s32) -> s32 #c_call, a2: *void) -> *void #c_call;
    blob_reopen: #type (a0: *sqlite3_blob, a1: sqlite3_int64) -> s32 #c_call;
    vtab_config: #type (a0: *sqlite3, a1: s32) -> s32 #c_call;
    vtab_on_conflict: #type (a0: *sqlite3) -> s32 #c_call;
    close_v2: #type (a0: *sqlite3) -> s32 #c_call;
    db_filename: #type (a0: *sqlite3, a1: *s8) -> *s8 #c_call;
    db_readonly: #type (a0: *sqlite3, a1: *s8) -> s32 #c_call;
    db_release_memory: #type (a0: *sqlite3) -> s32 #c_call;
    errstr: #type (a0: s32) -> *s8 #c_call;
    stmt_busy: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    stmt_readonly: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    stricmp: #type (a0: *s8, a1: *s8) -> s32 #c_call;
    uri_boolean: #type (a0: *s8, a1: *s8, a2: s32) -> s32 #c_call;
    uri_int64: #type (a0: *s8, a1: *s8, a2: sqlite3_int64) -> sqlite3_int64 #c_call;
    uri_parameter: #type (a0: *s8, a1: *s8) -> *s8 #c_call;
//    xvsnprintf: #type (a0: s32, a1: *s8, a2: *s8, a3: va_list) -> *s8 #c_call;
    wal_checkpoint_v2: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: *s32, a4: *s32) -> s32 #c_call;
    auto_extension: #type (a0: #type () -> void #c_call) -> s32 #c_call;
    bind_blob64: #type (a0: *sqlite3_stmt, a1: s32, a2: *void, a3: sqlite3_uint64, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    bind_text64: #type (a0: *sqlite3_stmt, a1: s32, a2: *s8, a3: sqlite3_uint64, a4: #type (a0: *void) -> void #c_call, a5: u8) -> s32 #c_call;
    cancel_auto_extension: #type (a0: #type () -> void #c_call) -> s32 #c_call;
    load_extension: #type (a0: *sqlite3, a1: *s8, a2: *s8, a3: **s8) -> s32 #c_call;
    malloc64: #type (a0: sqlite3_uint64) -> *void #c_call;
    msize: #type (a0: *void) -> sqlite3_uint64 #c_call;
    realloc64: #type (a0: *void, a1: sqlite3_uint64) -> *void #c_call;
    reset_auto_extension: #type () -> void #c_call;
    result_blob64: #type (a0: *sqlite3_context, a1: *void, a2: sqlite3_uint64, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    result_text64: #type (a0: *sqlite3_context, a1: *s8, a2: sqlite3_uint64, a3: #type (a0: *void) -> void #c_call, a4: u8) -> void #c_call;
    strglob: #type (a0: *s8, a1: *s8) -> s32 #c_call;
    value_dup: #type (a0: *sqlite3_value) -> *sqlite3_value #c_call;
    value_free: #type (a0: *sqlite3_value) -> void #c_call;
    result_zeroblob64: #type (a0: *sqlite3_context, a1: sqlite3_uint64) -> s32 #c_call;
    bind_zeroblob64: #type (a0: *sqlite3_stmt, a1: s32, a2: sqlite3_uint64) -> s32 #c_call;
    value_subtype: #type (a0: *sqlite3_value) -> u32 #c_call;
    result_subtype: #type (a0: *sqlite3_context, a1: u32) -> void #c_call;
    status64: #type (a0: s32, a1: *sqlite3_int64, a2: *sqlite3_int64, a3: s32) -> s32 #c_call;
    strlike: #type (a0: *s8, a1: *s8, a2: u32) -> s32 #c_call;
    db_cacheflush: #type (a0: *sqlite3) -> s32 #c_call;
    system_errno: #type (a0: *sqlite3) -> s32 #c_call;
    trace_v2: #type (a0: *sqlite3, a1: u32, a2: #type (a0: u32, a1: *void, a2: *void, a3: *void) -> s32 #c_call, a3: *void) -> s32 #c_call;
    expanded_sql: #type (a0: *sqlite3_stmt) -> *s8 #c_call;
    set_last_insert_rowid: #type (a0: *sqlite3, a1: sqlite3_int64) -> void #c_call;
    prepare_v3: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: u32, a4: **sqlite3_stmt, a5: **s8) -> s32 #c_call;
    prepare16_v3: #type (a0: *sqlite3, a1: *void, a2: s32, a3: u32, a4: **sqlite3_stmt, a5: **void) -> s32 #c_call;
    bind_pointer: #type (a0: *sqlite3_stmt, a1: s32, a2: *void, a3: *s8, a4: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    result_pointer: #type (a0: *sqlite3_context, a1: *void, a2: *s8, a3: #type (a0: *void) -> void #c_call) -> void #c_call;
    value_pointer: #type (a0: *sqlite3_value, a1: *s8) -> *void #c_call;
    vtab_nochange: #type (a0: *sqlite3_context) -> s32 #c_call;
    value_nochange: #type (a0: *sqlite3_value) -> s32 #c_call;
    vtab_collation: #type (a0: *sqlite3_index_info, a1: s32) -> *s8 #c_call;
    keyword_count: #type () -> s32 #c_call;
    keyword_name: #type (a0: s32, a1: **s8, a2: *s32) -> s32 #c_call;
    keyword_check: #type (a0: *s8, a1: s32) -> s32 #c_call;
    str_new: #type (a0: *sqlite3) -> *sqlite3_str #c_call;
    str_finish: #type (a0: *sqlite3_str) -> *s8 #c_call;
    str_appendf: #type (a0: *sqlite3_str, a1: *s8) -> void #c_call;
//    str_vappendf: #type (a0: *sqlite3_str, a1: *s8, a2: va_list) -> void #c_call;
    str_append: #type (a0: *sqlite3_str, a1: *s8, a2: s32) -> void #c_call;
    str_appendall: #type (a0: *sqlite3_str, a1: *s8) -> void #c_call;
    str_appendchar: #type (a0: *sqlite3_str, a1: s32, a2: s8) -> void #c_call;
    str_reset: #type (a0: *sqlite3_str) -> void #c_call;
    str_errcode: #type (a0: *sqlite3_str) -> s32 #c_call;
    str_length: #type (a0: *sqlite3_str) -> s32 #c_call;
    str_value: #type (a0: *sqlite3_str) -> *s8 #c_call;
    create_window_function: #type (a0: *sqlite3, a1: *s8, a2: s32, a3: s32, a4: *void, a5: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a6: #type (a0: *sqlite3_context) -> void #c_call, a7: #type (a0: *sqlite3_context) -> void #c_call, a8: #type (a0: *sqlite3_context, a1: s32, a2: **sqlite3_value) -> void #c_call, a9: #type (a0: *void) -> void #c_call) -> s32 #c_call;
    normalized_sql: #type (a0: *sqlite3_stmt) -> *s8 #c_call;
    stmt_isexplain: #type (a0: *sqlite3_stmt) -> s32 #c_call;
    value_frombind: #type (a0: *sqlite3_value) -> s32 #c_call;
    drop_modules: #type (a0: *sqlite3, a1: **s8) -> s32 #c_call;
    hard_heap_limit64: #type (a0: sqlite3_int64) -> sqlite3_int64 #c_call;
    uri_key: #type (a0: *s8, a1: s32) -> *s8 #c_call;
    filename_database: #type (a0: *s8) -> *s8 #c_call;
    filename_journal: #type (a0: *s8) -> *s8 #c_call;
    filename_wal: #type (a0: *s8) -> *s8 #c_call;
    create_filename: #type (a0: *s8, a1: *s8, a2: *s8, a3: s32, a4: **s8) -> *s8 #c_call;
    free_filename: #type (a0: *s8) -> void #c_call;
    database_file_object: #type (a0: *s8) -> *sqlite3_file #c_call;
    txn_state: #type (a0: *sqlite3, a1: *s8) -> s32 #c_call;
    changes64: #type (a0: *sqlite3) -> sqlite3_int64 #c_call;
    total_changes64: #type (a0: *sqlite3) -> sqlite3_int64 #c_call;
    autovacuum_pages: #type (a0: *sqlite3, a1: #type (a0: *void, a1: *s8, a2: u32, a3: u32, a4: u32) -> u32 #c_call, a2: *void, a3: #type (a0: *void) -> void #c_call) -> s32 #c_call;
}

sqlite3_loadext_entry :: #type (a0: *sqlite3, a1: **s8, a2: *sqlite3_api_routines) -> s32 #c_call;

SQLITE_OK         ::  0;   /* Successful result */
SQLITE_ERROR      ::  1;   /* Generic error */
SQLITE_INTERNAL   ::  2;   /* Internal logic error in SQLite */
SQLITE_PERM       ::  3;   /* Access permission denied */
SQLITE_ABORT      ::  4;   /* Callback routine requested an abort */
SQLITE_BUSY       ::  5;   /* The database file is locked */
SQLITE_LOCKED     ::  6;   /* A table in the database is locked */
SQLITE_NOMEM      ::  7;   /* A malloc() failed */
SQLITE_READONLY   ::  8;   /* Attempt to write a readonly database */
SQLITE_INTERRUPT  ::  9;   /* Operation terminated by sqlite3_interrupt()*/
SQLITE_IOERR      :: 10;   /* Some kind of disk I/O error occurred */
SQLITE_CORRUPT    :: 11;   /* The database disk image is malformed */
SQLITE_NOTFOUND   :: 12;   /* Unknown opcode in sqlite3_file_control() */
SQLITE_FULL       :: 13;   /* Insertion failed because database is full */
SQLITE_CANTOPEN   :: 14;   /* Unable to open the database file */
SQLITE_PROTOCOL   :: 15;   /* Database lock protocol error */
SQLITE_EMPTY      :: 16;   /* Internal use only */
SQLITE_SCHEMA     :: 17;   /* The database schema changed */
SQLITE_TOOBIG     :: 18;   /* String or BLOB exceeds size limit */
SQLITE_CONSTRAINT :: 19;   /* Abort due to constraint violation */
SQLITE_MISMATCH   :: 20;   /* Data type mismatch */
SQLITE_MISUSE     :: 21;   /* Library used incorrectly */
SQLITE_NOLFS      :: 22;   /* Uses OS features not supported on host */
SQLITE_AUTH       :: 23;   /* Authorization denied */
SQLITE_FORMAT     :: 24;   /* Not used */
SQLITE_RANGE      :: 25;   /* 2nd parameter to sqlite3_bind out of range */
SQLITE_NOTADB     :: 26;   /* File opened that is not a database file */
SQLITE_NOTICE     :: 27;   /* Notifications from sqlite3_log() */
SQLITE_WARNING    :: 28;   /* Warnings from sqlite3_log() */
SQLITE_ROW        :: 100;  /* sqlite3_step() has another row ready */
SQLITE_DONE       :: 101;  /* sqlite3_step() has finished executing */


sqlite :: #library "../lib/sqlite3";