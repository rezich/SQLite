#module_parameters(
    FROM_METAPROGRAM := false,
    USE_ORM          := true,
    STRICT_TABLES    := false,
    ON_DELETE : enum { NO_ACTION; RESTRICT; SET_NULL; SET_DEFAULT; CASCADE; } = .NO_ACTION // this'll be per foreign key soon
);

#if FROM_METAPROGRAM            then #load "src/Meta.jai";
#if FROM_METAPROGRAM || USE_ORM then #load "src/ORM.jai";
#load "src/SQLite.jai";
