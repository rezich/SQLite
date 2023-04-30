SQLite for Jai
==============

This is a module for Jai that allows you to interface with SQLite however works best for you.

***however, this module is still in early development and lacks rigorous testing & some features.***


C API bindings
--------------

By `#import`ing `SQLite`, you get access to [bindings for the SQLite C API](src/sqlite3.jai). These
work exactly as you'd expect.


Jai wrapper
-----------
Unless you `#import "SQLite"(ONLY_C_BINDINGS=true)`, you also get [a more Jai-friendly set of wrapper functions](src/SQLite.jai).

*(note that the latter is not an exhaustive port of all SQLite functions, at least, yet)*

The database handle parameter is omitted from every wrapping procedure signature, as it is stored in
the `context` instead.

Included in this wrapper is a variant of `exec()` that doesn't actually run SQLite's `exec()`, but
does more or less the same thing, except it lets you pass in a variadic number of parameters to be
`bind()`ed at the end, and a type at the beginning—in addition to returning the SQLite result
value, it also returns an array of that specified type, with its members containing the results of
the query. This works with Jai's anonymous structs:

```jai
min_author_id := 2;
result, rows := SQLite.exec(
    struct { author_name: string; count: int; total_score: int; },
    #string __SQL__
SELECT
    User.name       AS author_name,
    COUNT(*)        AS count,
    SUM(Post.score) AS total_score
FROM Post
LEFT JOIN User ON User.id = Post.author_id
WHERE
    author_id >= ? AND
    parent_id IS NULL
GROUP BY author_id
__SQL__,
    min_author_id
);
assert(result == .OK);
for rows log("%1\n  posts: %2\n  total score: %3", it.author_name, it.count, it.total_score);
```

The array returned by this version of `exec()` is allocated using the optional `allocator`
parameter, **which is set to `temp` by default.**

In the above example, all of the column names in the SQL statement match the member names of the
struct. This seems like a pretty good idea, so by default we check this at runtime (unless a given
column is unnamed). If, for whatever reason, you don't want this behavior, you can call `exec()`
with `check_column_names=false`.


ORM
---

You can also `#import "SQLite"(USE_ORM=true);`, which, if you've set up your metaprogram correctly
(see [the “overview” example](examples/overview)), allows you to more easily create Jai structs that
can automatically interface with SQLite, like this:

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
    private: int; @do_not_serialize;
}
```

All of the members in the above struct--except for the last one--will be automatically de/serialized
to/from your SQLite database, when using [the ORM procedures](src/ORM.jai).

`Cached(My_Other_Struct)` is used for foreign-key references. in the example above, `other` will
serialize to SQL as `other_id`, which will contain the ID of the `My_Other_Struct` that `other`
points to.

There's no need to include your own ID member, as that's included for you in `Model`, along with
`created` and `modified` timestamps. (The timestamps are all handled in SQLite, and, for now,
returned to you in Jai as UNIX timestamps.)

See [the “overview” example](examples/overview) for a sample use of this module. note that [overview.jai](examples/overview/overview.jai)
contains the metaprogram, and [src/Main.jai](examples/overview/src/Main.jai) contains the actual
program.

**There is no automatic lazy-loading** or anything like that; if you retrieve a `My_Struct` row from
the database, it won't load the associated `My_Other_Struct` into `other` for you. Instead, you must
`fetch(*my_struct.other);`.


Context
-------

The basic SQLite wrapper will add a `db` to the `context`, which is the current database connection.

Using the ORM will add an additional `db_cache` struct to the `context`, which is a cache of rows
retrieved from the database. You can flush this cache at any time using `flush_cache();`.


TODO
====

 - more compile-time checking of things to make usage more pleasant, e.g. help the user if they forget to `#as` the `using #as model: Model;` in their models
 - figure out what to do about `NULL` values. consider something like `@null_if_default`/`@null_if=value`/`@not_null`/...? `ORM.Nullable(T)`...? ...?
 - `ORM.set(T, field_name, value, where, ..params)`
 - `ORM.delete_from(T, where, ..params)`
 - `ORM.insert(objs)`
 - (...)
 - some way of doing `operator ==` with `ORM.Cached(T)`s
 - maybe just huck the SQLite error message into the `context`?
 - maybe have the wrapper functions return enums that are subsets of `Result`? (`#must`...?)
 - more generally, figure out if there's a more ergonomic way to handle SQLite result and/or error passing
 - **add some kind of automatic migration system**—we can do SQLite stuff at compile time, so why not?
 - consider whether or not the `ORM` namespace-struct-thing makes sense in the long run
 - actually try this out with slightly non-trivial things like threading and such and see if it actually is good at all lmao
 - finish wrapping the rest of the SQLite API
