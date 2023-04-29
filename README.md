SQLite for Jai
==============

this is a module for Jai that allows you to interface with SQLite however works best for you.

***however, this module is still in early development and lacks rigorous testing & some features.***

by `#import`ing `SQLite`, you get access to [bindings for the SQLite C API](src/sqlite3.jai),
as well as [more Jai-friendly wrapper functions](src/SQLite.jai).

*(note that the latter is not an exhaustive port of all SQLite functions, at least, yet)*

the database handle parameter is omitted from every wrapping procedure signature, as it is stored in
the `context` instead.

included in this wrapper is a variant of `exec()` that doesn't actually run SQLite's `exec()`, but
does more or less the same thing, except it lets you pass in a variadic number of parameters to be
`bind()`ed at the end, and a type at the beginning—in addition to returning the SQLite result
value, it also returns an array of that specified type, with its members containing the results of
the query. this works with Jai's anonymous structs:

```jai
min_author_id := 2;
result, rows := SQLite.exec(
    struct { author_name: string; count: int; total_score: int; },
    #string __SQL__
SELECT
    User.name       AS author_name,
    COUNT(*)        AS count,
    SUM(Post.score) AS total_score

FROM
    Post

LEFT JOIN
    User
ON
    User.id = Post.author_id

WHERE
    author_id >= ?

GROUP BY
    author_id
__SQL__,
    min_author_id
);
assert(result == .OK);
for rows log("%1\n  posts: %2\n  total score: %3", it.author_name, it.count, it.total_score);
```

the array returned by this version of `exec()` is allocated using the optional `allocator`
parameter, **which is set to `temp` by default.**

you can also `#import "SQLite"(USE_ORM=true);`, which, if you've set up your metaprogram correctly
(see [the example](example/)), allows you to more easily create Jai structs that can automatically
interface with SQLite, like this:

```jai
using SQLite.ORM;

My_Struct :: struct { using model: Model;
    name: string;
    boolean: bool;
    number: int;
    big_num: s64;
    real: float;
    big_real: float64;
    other: Cached(My_Other_Struct);
    private: int; @no_serialize
}
```

all of the members in the above struct, except for the last one, will be automatically de/serialized
to/from your SQLite database, when using [the ORM procedures](src/ORM.jai).

`Cached(My_Other_Struct)` is used for foreign-key references. in the example above, `other` will
serialize to SQL as `other_id`, which will contain the ID of the `My_Other_Struct` that `other`
points to.

there's no need to include your own ID member, as that's included for you in `Model`, along with
`created` and `modified` timestamps. (the timestamps are all handled in SQLite, and, for now,
returned to you in Jai as UNIX timestamps.)

see [the example](example/) for a sample use of this module. note that [example.jai](example/example.jai)
contains the metaprogram, and [src/Main.jai](example/src/Main.jai) contains the actual program.

there is no automatic lazy-loading or anything like that; if you retrieve a `My_Struct` row from the
database, it won't load the associated `My_Other_Struct` into `other` for you. instead, you must
`fetch(*my_struct.other);`.

the basic SQLite wrapper will add a `db` to the `context`, which is the current database connection.

using the ORM will add an additional `db_cache` struct to the `context`, which is a cache of rows
retrieved from the database. you can flush this cache at any time using `flush_cache();`.


TODO
====

 - more compile-time checking of things to make usage more pleasant, e.g. help the user if they forget to `#as` the `using #as model: Model;` in their models
 - figure out what to do about `NULL` values. consider something like `@null_if_default`/`@null_if=value`/`@not_null`...?
 - check the number of query-fragment question marks vs. the number of passed-in parameters at compile time
 - delete most of the code in `select_by_id(T, id)`
 - `set(T, field_name, value, where, ..params)`
 - `delete_from(T, where, ..params)`
 - `insert(objs)`
 - (...)
 - some way of doing `operator ==` with `Cached(T)`s
 - maybe just huck the SQLite error message into the `context`?
 - maybe have the wrapper functions return enums that are subsets of `Result`? (`#must`...?)
 - more generally, figure out if there's a more ergonomic way to handle SQLite result and/or error passing
 - **add some kind of automatic migration system**—we can do SQLite stuff at compile time, so why not?
 - consider whether or not the `ORM` namespace-struct-thing makes sense in the long run
 - actually try this out with slightly non-trivial things like threading and such and see if it actually is good at all lmao
 - finish wrapping the rest of the SQLite API
