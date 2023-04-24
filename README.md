SQLite for Jai
==============

this is a module for Jai that allows you to interface with SQLite however works best for you.

***however, this module is still in early development and lacks rigorous testing & some features.***

by `#import`ing `SQLite`, you get access to [bindings for the SQLite C API](src/sqlite3.jai),
as well as [more Jai-friendly wrapper functions](src/SQLite.jai).

*(note that the latter is not an exhaustive port of all SQLite functions, at least, yet)*

you can also `#import "SQLite"(USE_ORM=true);`, which, if you've set up your metaprogram correctly
(see [the example](example/)), allows you to more easily create Jai structs that can automatically
interface with SQLite, like this:

```jai
My_Struct :: struct { using model: SQLite.ORM.Model;
    name: string;
    boolean: bool;
    number: int;
    big_num: s64;
    real: float;
    big_real: float64;
    other: SQLite.ORM.Cached(My_Other_Struct);
    private: int; @NoSerialize
}
```

all of the members in the above struct, except for the last one, will be automatically de/serialized
to/from your SQLite database, when using [the ORM procedures](src/ORM.jai).

`Cached(My_Other_Struct)` is used for foreign-key references. in the example above, `other` will
serialize to SQL as `other_id`, which will contain the ID of the `My_Other_Struct` that `other`
points to.

there's no need to include your own ID member, as that's included for you in `SQLite.ORM.Model`,
along with `created` and `modified` timestamps. (the timestamps are all handled in SQLite, and, for
now, returned to you in Jai as UNIX timestamps.)

see [the example](example/) for a sample use of this module. note that [example.jai](example/example.jai)
contains the metaprogram, and [src/Main.jai](example/src/Main.jai) contains the actual program.

there is no automatic lazy-loading or anything like that; if you retrieve a `My_Struct` row from the
database, it won't load the associated `My_Other_Struct` into `other` for you. instead, you must
`SQLite.ORM.fetch(*my_struct.other);`.

the basic SQLite wrapper will add a `db` to the `context`, which is the current database connection.

using the ORM will add an additional `db_cache` struct to the `context`, which is a cache of rows
retrieved from the database. you can flush this cache at any time using `SQLite.ORM.flush_cache();`.
