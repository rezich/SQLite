#module_parameters(
    FROM_METAPROGRAM := false,
    USE_ORM          := true,
    STRICT_TABLES    := false,
    MAKE_MIGRATIONS  := false
);

#if FROM_METAPROGRAM                    then #load "src/Meta.jai";
#if FROM_METAPROGRAM && MAKE_MIGRATIONS then #load "src/Migrator.jai";
#if FROM_METAPROGRAM || USE_ORM         then #load "src/ORM.jai";
#load "src/SQLite.jai";
