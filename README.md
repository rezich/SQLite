SQLite for Jai
==============
This is a module for Jai that allows you to interface with SQLite however works best for you.

**However, this module is still in early development and lacks rigorous testing & some features.**

***This module is heavily under construction right now!!***




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

**The following part is under construction.**

~~Included in this wrapper is a variant of `exec()` that doesn't actually run SQLite's `exec()`, but
does more or less the same thing, except it lets you pass in a variadic number of parameters to be
`bind()`ed at the end, and a type at the beginning—in addition to returning the SQLite result
value, it also returns an array of that specified type, with its members containing the results of
the query. This works with Jai's anonymous structs:~~

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

~~The array returned by this version of `exec()` is allocated using the optional `allocator`
parameter, **which is set to `temp` by default.**~~

~~In the above example, all of the column names in the SQL statement match the member names of the
struct. This seems like a pretty good idea, so by default we check this at runtime (unless a given
column is unnamed). If, for whatever reason, you don't want this behavior, you can call `exec()`
with `check_column_names=false`.~~

~~To execute a query that doesn't return any rows, you can just write:~~

```jai
some_id := 4;
result := SQLite.exec("DELETE FROM User WHERE id = ?", 4);
```

~~If you `exec()` a SQL statement that returns anything, it will error. In case you want to do this
for whatever reason (for example, setting `PRAGMA`s that can also be queried), pass
`ignore_returned_rows=false` to `exec()`.~~




Model cache
-----------
You can also `#import "SQLite"(USE_MODEL_CACHE=true);`, which, if you've set up your metaprogram
correctly (see [the “overview” example](examples/overview)), allows you to more easily create
Jai structs that can automatically interface with SQLite, like this:

```jai
using SQLite;

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
to/from your SQLite database, when using [the model cache](src/Model_Cache.jai).

`Cached(My_Other_Struct)` is used for foreign-key references. in the example above, `other` will
serialize to SQL as `other_id`, which will contain the ID of the `My_Other_Struct` that `other`
points to.

There's no need to include your own ID member, as that's included for you in `Model`, along with
`created` and `modified` timestamps. (The timestamps are all handled in SQLite, and, for now,
returned to you in Jai as UNIX timestamps.)

See [the “overview” example](examples/overview) for a sample use of this module. note that [overview.jai](examples/overview/overview.jai)
contains the metaprogram, and [src/Main.jai](examples/overview/src/Main.jai) contains the actual
program.


### Model member notes
There are various notes (`@xxx`) you can annotate the members of your model structs with, that make
things easy for you:

#### `@do_not_serialize`
Indicates that this member should *not* be stored as a field in the SQLite table

#### `@autofetch`
Indicates that this member should be automatically fetched when an instance of this model struct is
retrieved from the database.

If a model `Model_Name` has a member `member_name` that is *both* `@autofetch` *and*
`@do_not_serialize`, then you must provide a procedure called `fetch_member_name` ***within the body
of the model struct***, that takes in a `*Cached(Model_Name)` and returns nothing. This procedure
will be automatically executed when the instance is retrieved from the database.

If the member is *not* `@do_not_serialize`, then the member type *must* be a `Cached(T)`, and it
will be fetched automatically *every time* an instance of this model type is retrieved from the
database.

Here's an example:

```jai
Foo :: struct { using model: Model;
    // other will be fetched automatically (if not NULL)
    bar: Cached(Bar); @autofetch
    // member_name will be "fetched" automatically, using the procedure below
    baz: int; @autofetch @do_not_serialize
    fetch_baz :: (using foo: *Cached(Foo)) { baz = 42; }
}
Bar :: struct { using model: Model; name: string; }

// ...

bar := insert(Bar.{name="BAR"});
insert(Foo.{bar=bar});

reset_model_cache(); // reset the cache so we can prove autofetching does in fact work

foo := select_by_id(Foo, 1);
assert(foo.bar.name == "BAR"); // proving bar was autofetched
assert(foo.baz      == 42   ); // proving baz was autofetched
```

**Caution should be exercised** when using `@autofetch`! Only `@autofetch` if you're *absoutely
certain* that:
 - you will in fact use that member *every time* you retrieve a model instance from the database
 - your models' `@autofetch` members do not have *any* circular dependencies 




Context
-------
The basic SQLite wrapper will add a `sqlite: SQLIte_Info` to the `context`, which contains the
current database connection and other such bookkeeping.

Using the model cache will add an additional `sqlite_model_cache` struct to the `context`, which is a cache of rows
retrieved from the database. You can flush this cache at any time using `reset_model_cache();`.




TODO
====
 - fix the `overview` example
 - massively cull the `assert_ok()`s, with something like an `automatically_assert_ok` field in `SQLite_Info`
 - delete ~~a ton of~~ ~~even more~~ *yet even more* code from `Model_Cache` now that we have a better `exec()` and such
 - `@default=value` for model fields
 - more compile-time checking of things to make usage more pleasant, e.g. help the user if they forget to `#as` the `using #as model: Model;` in their models
 - figure out what to do about `NULL` values. consider something like `@null_if_default`/`@null_if=value`/`@not_null`/...? `Nullable(T)`...? ...?
 - `set(T, field_name, value, where, ..params)`
 - `delete_from(T, where, ..params)`
 - `insert(objs)`
 - (...)
 - maybe just huck the SQLite error message into the `context`?
 - maybe have the wrapper functions return enums that are subsets of `Result`? (`#must`...?)
 - more generally, figure out if there's a more ergonomic way to handle SQLite result and/or error passing
 - **add some kind of automatic migration system**—we can do SQLite stuff at compile time, so why not?
 - actually try this out with slightly non-trivial things like threading and such and see if it actually is good at all lmao
 - finish wrapping the rest of the SQLite API
 - test the code, like, at all
 - write documentation
