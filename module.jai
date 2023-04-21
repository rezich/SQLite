#module_parameters(
    FROM_METAPROGRAM := false,
    VERBOSE          := false,
    NAMESPACE        := "",
    USE_ORM          := true,
    STRICT_TABLES    := false
);

#if  FROM_METAPROGRAM            then #load "src/Meta.jai";
#if !FROM_METAPROGRAM && USE_ORM then #load "src/ORM.jai";
#if !FROM_METAPROGRAM            then #load "src/SQLite.jai";
#load "src/Model.jai";
