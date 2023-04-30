#module_parameters(
    ONLY_C_BINDINGS  := false, // don't even include the wrapper
    VERBOSE          := false, // log wrapper-invoked SQL statements to console
    FROM_METAPROGRAM := false, // set true in your meta program for ORM features
    USE_ORM          := false, // set true in your main program for ORM features
    STRICT_TABLES    := false, // (ORM) use strict tables
    MAKE_MIGRATIONS  := false  // (ORM) work in progress
);

#if MAKE_MIGRATIONS && !FROM_METAPROGRAM then #assert false "MAKE_MIGRATIONS only works from the metaprogram.";

#if !ONLY_C_BINDINGS {                           #load "src/SQLite.jai";
    #if FROM_METAPROGRAM                    then #load "src/Meta.jai";
    #if FROM_METAPROGRAM && MAKE_MIGRATIONS then #load "src/Migrator.jai";
    #if FROM_METAPROGRAM || USE_ORM         then #load "src/ORM.jai";
}
                                                 #load "src/sqlite3.jai";
