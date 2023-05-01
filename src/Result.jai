Result :: enum {

    OK         ::  0;  //                            Successful result                            //
    // The SQLITE_OK result code means that the operation was successful and that there were no
    // errors. Most other result codes indicate an error.

    ERROR      ::  1;  //  //   /* Generic error */
    // The SQLITE_ERROR result code is a generic error code that is used when no other more specific
    // error code is available.

    INTERNAL   ::  2;  //                              Generic error                              //
    // The SQLITE_INTERNAL result code indicates an internal malfunction. In a working version of
    // SQLite, an application should never see this result code. If application does encounter this
    // result code, it shows that there is a bug in the database engine.
    //
    // SQLite does not currently generate this result code. However, application-defined SQL
    // functions or virtual tables, or VFSes, or other extensions might cause this result code to be
    // returned.

    PERM       ::  3;  //                        Access permission denied                         //
    // The SQLITE_PERM result code indicates that the requested access mode for a newly created
    // database could not be provided.

    ABORT      ::  4;  //                   Callback routine requested an abort                   //
    // The SQLITE_ABORT result code indicates that an operation was aborted prior to completion,
    // usually be application request. See also: SQLITE_INTERRUPT.
    //
    // If the callback function to sqlite3_exec() returns non-zero, then sqlite3_exec() will return
    // SQLITE_ABORT.
    //
    // If a ROLLBACK operation occurs on the same database connection as a pending read or write,
    // then the pending read or write may fail with an SQLITE_ABORT or SQLITE_ABORT_ROLLBACK error.
    //
    // In addition to being a result code, the SQLITE_ABORT value is also used as a conflict
    // resolution mode returned from the sqlite3_vtab_on_conflict() interface.

    BUSY       ::  5;  //                       The database file is locked                       //
    // The SQLITE_BUSY result code indicates that the database file could not be written (or in some
    // cases read) because of concurrent activity by some other database connection, usually a
    // database connection in a separate process.
    //
    // For example, if process A is in the middle of a large write transaction and at the same time
    // process B attempts to start a new write transaction, process B will get back an SQLITE_BUSY
    // result because SQLite only supports one writer at a time. Process B will need to wait for
    // process A to finish its transaction before starting a new transaction. The
    // sqlite3_busy_timeout() and sqlite3_busy_handler() interfaces and the busy_timeout pragma are
    // available to process B to help it deal with SQLITE_BUSY errors.
    //
    // An SQLITE_BUSY error can occur at any point in a transaction: when the transaction is first
    // started, during any write or update operations, or when the transaction commits. To avoid
    // encountering SQLITE_BUSY errors in the middle of a transaction, the application can use
    // BEGIN IMMEDIATE instead of just BEGIN to start a transaction. The BEGIN IMMEDIATE command
    // might itself return SQLITE_BUSY, but if it succeeds, then SQLite guarantees that no
    // subsequent operations on the same database through the next COMMIT will return SQLITE_BUSY.
    //
    // See also: SQLITE_BUSY_RECOVERY and SQLITE_BUSY_SNAPSHOT.
    //
    // The SQLITE_BUSY result code differs from SQLITE_LOCKED in that SQLITE_BUSY indicates a
    // conflict with a separate database connection, probably in a separate process, whereas
    // SQLITE_LOCKED indicates a conflict within the same database connection (or sometimes a
    // database connection with a shared cache).

    LOCKED     ::  6;  //                    A table in the database is locked                    //
    // The SQLITE_LOCKED result code indicates that a write operation could not continue because of
    // a conflict within the same database connection or a conflict with a different
    // database connection that uses a shared cache.
    // For example, a DROP TABLE statement cannot be run while another thread is reading from that
    // table on the same database connection because dropping the table would delete the table out
    // from under the concurrent reader.
    //
    // The SQLITE_LOCKED result code differs from SQLITE_BUSY in that SQLITE_LOCKED indicates a
    // conflict on the same database connection (or on a connection with a shared cache) whereas
    // SQLITE_BUSY indicates a conflict with a different database connection, probably in a
    // different process.

    NOMEM      ::  7;  //                            A malloc() failed                            //
    // The SQLITE_NOMEM result code indicates that SQLite was unable to allocate all the memory it
    // needed to complete the operation. In other words, an internal call to sqlite3_malloc() or
    // sqlite3_realloc() has failed in a case where the memory being allocated was required in order
    // to continue the operation.

    READONLY   ::  8;  //                  Attempt to write a readonly database                   //
    // The SQLITE_READONLY result code is returned when an attempt is made to alter some data for
    // which the current database connection does not have write permission.

    INTERRUPT  ::  9;  //               Operation terminated by sqlite3_interrupt()               //
    // The SQLITE_INTERRUPT result code indicates that an operation was interrupted by the
    // sqlite3_interrupt() interface. See also: SQLITE_ABORT

    IOERR      :: 10;  //                  Some kind of disk I/O error occurred                   //
    // The SQLITE_IOERR result code says that the operation could not finish because the operating
    // system reported an I/O error.
    //
    // A full disk drive will normally give an SQLITE_FULL error rather than an SQLITE_IOERR error.
    //
    // There are many different extended result codes for I/O errors that identify the specific I/O
    // operation that failed.

    CORRUPT    :: 11;  //                  The database disk image is malformed                   //
    // The SQLITE_CORRUPT result code indicates that the database file has been corrupted. See the
    // How To Corrupt Your Database Files for further discussion on how corruption can occur.

    NOTFOUND   :: 12;  //                Unknown opcode in sqlite3_file_control()                 //
    // The SQLITE_NOTFOUND result code is exposed in three ways:
    //
    //   1. SQLITE_NOTFOUND can be returned by the sqlite3_file_control() interface to indicate that
    //      the file control opcode passed as the third argument was not recognized by the
    //      underlying VFS.
    //
    // SQLITE_NOTFOUND can also be returned by the xSetSystemCall() method of an sqlite3_vfs object.
    //
    // SQLITE_NOTFOUND can be returned by sqlite3_vtab_rhs_value() to indicate that the right-hand
    // operand of a constraint is not available to the xBestIndex method that made the call.
    //
    // The SQLITE_NOTFOUND result code is also used internally by the SQLite implementation, but
    // those internal uses are not exposed to the application.

    FULL       :: 13;  //                Insertion failed because database is full                //
    // The SQLITE_FULL result code indicates that a write could not complete because the disk is
    // full. Note that this error can occur when trying to write information into the main database
    // file, or it can also occur when writing into temporary disk files.
    //
    // Sometimes applications encounter this error even though there is an abundance of primary disk
    // space because the error occurs when writing into temporary disk files on a system where
    // temporary files are stored on a separate partition with much less space that the primary disk.

    CANTOPEN   :: 14;  //                    Unable to open the database file                     //
    // The SQLITE_CANTOPEN result code indicates that SQLite was unable to open a file. The file in
    // question might be a primary database file or one of several temporary disk files.

    PROTOCOL   :: 15;  //                      Database lock protocol error                       //
    // The SQLITE_PROTOCOL result code indicates a problem with the file locking protocol used by
    // SQLite. The SQLITE_PROTOCOL error is currently only returned when using WAL mode and
    // attempting to start a new transaction. There is a race condition that can occur when two
    // separate database connections both try to start a transaction at the same time in WAL mode.
    // The loser of the race backs off and tries again, after a brief delay. If the same connection
    // loses the locking race dozens of times over a span of multiple seconds, it will eventually
    // give up and return SQLITE_PROTOCOL. The SQLITE_PROTOCOL error should appear in practice very,
    // very rarely, and only when there are many separate processes all competing intensely to write
    // to the same database.

    EMPTY      :: 16;  //                            Internal use only                            //
    // The SQLITE_EMPTY result code is not currently used.

    SCHEMA     :: 17;  //                       The database schema changed                       //
    // The SQLITE_SCHEMA result code indicates that the database schema has changed. This result
    // code can be returned from sqlite3_step() for a prepared statement that was generated using
    // sqlite3_prepare() or sqlite3_prepare16(). If the database schema was changed by some other
    // process in between the time that the statement was prepared and the time the statement was
    // run, this error can result.
    //
    // If a prepared statement is generated from sqlite3_prepare_v2() then the statement is
    // automatically re-prepared if the schema changes, up to SQLITE_MAX_SCHEMA_RETRY times
    // (default: 50). The sqlite3_step() interface will only return SQLITE_SCHEMA back to the
    // application if the failure persists after these many retries.

    TOOBIG     :: 18;  //                    String or BLOB exceeds size limit                    //
    // The SQLITE_TOOBIG error code indicates that a string or BLOB was too large. The default
    // maximum length of a string or BLOB in SQLite is 1,000,000,000 bytes. This maximum length can
    // be changed at compile-time using the SQLITE_MAX_LENGTH compile-time option, or at run-time
    // using the sqlite3_limit(db,SQLITE_LIMIT_LENGTH,...) interface. The SQLITE_TOOBIG error
    // results when SQLite encounters a string or BLOB that exceeds the compile-time or run-time
    // limit.
    //
    // The SQLITE_TOOBIG error code can also result when an oversized SQL statement is passed into
    // one of the sqlite3_prepare_v2() interfaces. The maximum length of an SQL statement defaults
    // to a much smaller value of 1,000,000,000 bytes. The maximum SQL statement length can be set
    // at compile-time using SQLITE_MAX_SQL_LENGTH or at run-time using
    // sqlite3_limit(db,SQLITE_LIMIT_SQL_LENGTH,...).

    CONSTRAINT :: 19;  //                    Abort due to constraint violation                    //
    // The SQLITE_CONSTRAINT error code means that an SQL constraint violation occurred while trying
    // to process an SQL statement. Additional information about the failed constraint can be found
    // by consulting the accompanying error message (returned via sqlite3_errmsg() or
    // sqlite3_errmsg16()) or by looking at the extended error code.
    //
    // The SQLITE_CONSTRAINT code can also be used as the return value from the xBestIndex() method
    // of a virtual table implementation. When xBestIndex() returns SQLITE_CONSTRAINT, that
    // indicates that the particular combination of inputs submitted to xBestIndex() cannot result
    // in a usable query plan and should not be given further consideration.

    MISMATCH   :: 20;  //                           Data type mismatch                            //
    // The SQLITE_MISMATCH error code indicates a datatype mismatch.
    //
    // SQLite is normally very forgiving about mismatches between the type of a value and the
    // declared type of the container in which that value is to be stored. For example, SQLite
    // allows the application to store a large BLOB in a column with a declared type of BOOLEAN. But
    // in a few cases, SQLite is strict about types. The SQLITE_MISMATCH error is returned in those
    // few cases when the types do not match.
    //
    // The rowid of a table must be an integer. Attempt to set the rowid to anything other than an
    // integer (or a NULL which will be automatically converted into the next available integer
    // rowid) results in an SQLITE_MISMATCH error.

    MISUSE     :: 21;  //                        Library used incorrectly                         //
    // The SQLITE_MISUSE return code might be returned if the application uses any SQLite interface
    // in a way that is undefined or unsupported. For example, using a prepared statement after that
    // prepared statement has been finalized might result in an SQLITE_MISUSE error.
    //
    // SQLite tries to detect misuse and report the misuse using this result code. However, there is
    // no guarantee that the detection of misuse will be successful. Misuse detection is
    // probabilistic. Applications should never depend on an SQLITE_MISUSE return value.
    //
    // If SQLite ever returns SQLITE_MISUSE from any interface, that means that the application is
    // incorrectly coded and needs to be fixed. Do not ship an application that sometimes returns
    // SQLITE_MISUSE from a standard SQLite interface because that application contains potentially
    // serious bugs.

    NOLFS      :: 22;  //                 Uses OS features not supported on host                  //
    // The SQLITE_NOLFS error can be returned on systems that do not support large files when the
    // database grows to be larger than what the filesystem can handle. "NOLFS" stands for "NO Large
    // File Support".

    AUTH       :: 23;  //                          Authorization denied                           //
    // The SQLITE_AUTH error is returned when the authorizer callback indicates that an SQL
    // statement being prepared is not authorized.

    FORMAT     :: 24;  //                                Not used                                 //
    // The SQLITE_FORMAT error code is not currently used by SQLite.
    RANGE      :: 25;  //               2nd parameter to sqlite3_bind out of range                //
    // The SQLITE_RANGE error indices that the parameter number argument to one of the sqlite3_bind
    // routines or the column number in one of the sqlite3_column routines is out of range.

    NOTADB     :: 26;  //                 File opened that is not a database file                 //
    // When attempting to open a file, the SQLITE_NOTADB error indicates that the file being opened
    // does not appear to be an SQLite database file.

    NOTICE     :: 27;  //                    Notifications from sqlite3_log()                     //
    // The SQLITE_NOTICE result code is not returned by any C/C++ interface. However, SQLITE_NOTICE
    // (or rather one of its extended error codes) is sometimes used as the first argument in an
    // sqlite3_log() callback to indicate that an unusual operation is taking place.

    WARNING    :: 28;  //                       Warnings from sqlite3_log()                       //
    // The SQLITE_WARNING result code is not returned by any C/C++ interface. However,
    // SQLITE_WARNING (or rather one of its extended error codes) is sometimes used as the first
    // argument in an sqlite3_log() callback to indicate that an unusual and possibly ill-advised
    // operation is taking place.

    ROW        :: 100; //                  sqlite3_step() has another row ready                   //
    // The SQLITE_ROW result code returned by sqlite3_step() indicates that another row of output is
    // available.

    DONE       :: 101; //                  sqlite3_step() has finished executing                  //
    // The SQLITE_DONE result code indicates that an operation has completed. The SQLITE_DONE result
    // code is most commonly seen as a return value from sqlite3_step() indicating that the SQL
    // statement has run to completion. But SQLITE_DONE can also be returned by other multi-step
    // interfaces such as sqlite3_backup_step().
}