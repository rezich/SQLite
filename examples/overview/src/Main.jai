User :: struct { using #as model: ORM.Model;
    name: string;
    age: int;
    kind: Kind;
    favorite_floating_point_number: float;
    corporate_id: s64;
    is_awesome := false;
    something_else: string; @do_not_serialize

    Kind :: enum { NORMAL; SUPERUSER; MEGAUSER; ULTRAUSER; }
}

Post :: struct { using #as model: ORM.Model;
    body: string;
    author: ORM.Cached(User); @on_delete=CASCADE
    parent: ORM.Cached(Post); @on_delete=CASCADE
}

main :: () {
    DATABASE_FILENAME :: "database.db";
    set_working_directory((#import "String").path_strip_filename((#import "System").get_path_of_running_executable()));
    (#import "File").file_delete(DATABASE_FILENAME); // delete the databse every run for now
    ORM.init(DATABASE_FILENAME); // omit the filename for an in-memory database
    result: SQLite.Result;
    remembered_post_id: s64;
    {
        user1, user2, user3: ORM.Cached(User);

        log("inserting a User");
        result, user1 = ORM.insert(User.{
            name="Alice",
            age=32,
            favorite_floating_point_number=3.14,
            corporate_id=3_000_000_000
        }); AssertResultOK();

        log("inserting another User");
        result, user2 = ORM.insert(User.{
            name="Bob",
            age=64,
            favorite_floating_point_number=1.111,
            corporate_id=3_000_000_001,
            is_awesome=true
        }); AssertResultOK();

        log("inserting a third User");
        result, user3 = ORM.insert(User.{
            name="Charlie",
            age=17,
            favorite_floating_point_number=0
        }); AssertResultOK();

        {
            log("inserting a Post, and remembering the number for later");
            result, post := ORM.insert(Post.{
                body="Remembered post",
                author=user2
            }); AssertResultOK();
            remembered_post_id = post.id;
        }

        log("inserting three Posts, ignoring the second return value");
        result = ORM.insert(Post.{
            body="First post",
            author=user2
        }); AssertResultOK();
        result = ORM.insert(Post.{
            body="Second post",
            author=user2
        }); AssertResultOK();
        result = ORM.insert(Post.{
            body="Third post",
            author=user2
        }); AssertResultOK();

        log("inserting a Post");
        parent_post, child_post: ORM.Cached(Post);
        result, parent_post = ORM.insert(Post.{
            body="Parent Post",
            author=user1
        }); AssertResultOK();
        log("  Post id % will be the parent", parent_post.id);

        log("inserting another Post, with the previous Post as its parent");
        result, child_post = ORM.insert(Post.{
            body="Child Post",
            author=user1,
            parent=parent_post
        }); AssertResultOK();
        log("  Post id % will be the child", child_post.id);

        child_post_id := child_post.id;
        {
            post: ORM.Cached(Post);
            log("selecting Post id %, the child", child_post_id);
            result, post = ORM.select_by_id(Post, child_post_id); AssertResultOK();

            ORM.fetch(*post.parent);
            assert(!ORM.is_null(post.parent));
            if !ORM.is_null(post.parent) log("fetched the parent of the child; it's:\n  id: %1, body: %2",
            /* 1 */post.parent.id,
            /* 2 */post.parent.body
            );
        }

        log("deleting the first User");
        result = ORM.delete(*user1); AssertResultOK();
        assert(!ORM.is_fetched(user1));
        assert(ORM.is_null(user1));

        log("insert some posts for the third user");
        {
            post1, post2, post3: ORM.Cached(Post);
            result, post1 = ORM.insert(Post.{ body="Hey",   author=user3               }); AssertResultOK();
            result, post2 = ORM.insert(Post.{ body="Hi",    author=user3, parent=post1 }); AssertResultOK();
            result, post3 = ORM.insert(Post.{ body="Hello", author=user3, parent=post2 }); AssertResultOK();
        }

        list_posts_for(user2);
        list_posts_for(user2, limit=2);
        list_posts_for(user2, limit=2, offset=2);

        list_posts_for :: (author: ORM.Cached(User), $limit: int=0, $offset: int=0) {
            if ORM.is_fetched(author) {
                log("getting %1post%2 for %3%4",
                /* 1 */ifx limit then tprint("up to % ", limit),
                /* 2 */ifx limit != 1 then "s",
                /* 3 */author.name,
                /* 4 */ifx offset then tprint(" starting after #%", offset)
                );
                result, posts := ORM.select_from(Post, where="author_id = ?", author.id, limit=limit, offset=offset);
                AssertResultOK();
                for posts log("  % %", it.id, it.body);
            }
        }

        log("here's a bunch of sample queries");
        ORM.select_from(Post, where="author_id = ?", user2.id);                    AssertResultOK();
        ORM.select_from(Post, where="author_id = ?", user2.id, limit=2);           AssertResultOK();
        ORM.select_from(Post, where="author_id = ?", user2.id, limit=2, offset=2); AssertResultOK();
        ORM.select_from(Post, where="author_id = ?", user2.id,          offset=2); AssertResultOK();
        ORM.select_from(Post,                                  limit=2);           AssertResultOK();

        old_name := user2.name;
        new_name := "Robert";
        log("changing %'s name to %", user2.name, new_name);
        user2.name = new_name;
        result = ORM.update(user2); AssertResultOK();
        result = ORM.fetch(*user2); AssertResultOK();
        assert(user2.name == new_name);

        log("but actually let's change it back now, a simpler way");
        result = ORM.set(user2, "name", old_name); AssertResultOK();
        assert(user2.name == old_name);
        log("and let's change his age too");
        result = ORM.set(user2, "age", 47); AssertResultOK();
        //result = ORM.set(user2, "age", "forty-seven"); AssertResultOK(); // uncomment this to see a compile-time error
        //result = ORM.set(user2, "age", null); AssertResultOK(); // this should work soon, provided age is not NOT NULL
        assert(user2.age == 47);
    }{
        post, next_post: ORM.Cached(Post);
        log("selecting the Post we remembered way earlier");
        result, post = ORM.select_by_id(Post, remembered_post_id+1); AssertResultOK();
        log("and the one after it");
        result, next_post = ORM.select_by_id(Post, remembered_post_id+1); AssertResultOK();
        log("setting the second Post's parent to the first Post");
        result = ORM.set(next_post, "parent", post); AssertResultOK();
        assert(next_post.parent.fetch_id == post.fetch_id && next_post.parent.pointer == post.pointer);
        log("setting it back to NULL (parent and parent_id are interchangable here)");
        result = ORM.set(next_post, "parent_id", null); AssertResultOK();
        log("you can also leave off the value parameter to NULL it; that works too");
        result = ORM.set(next_post, "parent"); AssertResultOK();
        assert(next_post.parent.fetch_id == 0 && next_post.parent.pointer == null);
    }{
        post: ORM.Cached(Post);
        log("selecting the Post we remembered way earlier");
        result, post = ORM.select_by_id(Post, remembered_post_id); AssertResultOK();
        assert(ORM.is_fetched(post.author));
        log("  we can tell the Post's author's name is % because it's still in the cache.", post.author.name);
    }
    log("flushing the cache");
    ORM.flush_cache();
    {
        post: ORM.Cached(Post);
        log("selecting the Post we remembered way earlier");
        result, post = ORM.select_by_id(Post, remembered_post_id); AssertResultOK();
        assert(!ORM.is_fetched(post.author));
        log("  we *CAN'T* tell the Post's author's name because we flushed the cache.");
        log("fetching the author manually");
        result = ORM.fetch(*post.author); AssertResultOK();
        log("  now we know the Post's author's name: it's %", post.author.name);
    }
    log("testing generic SQL execution");
    {
        My_Selection :: struct {
            count: int;
            max_modified: string;
        }
        result, rows := SQLite.exec_into_array_of(My_Selection, "SELECT COUNT(*) AS count, MAX(modified) AS max_modified FROM Post;"); AssertResultOK();
        log("My_Selection: %", rows);
    }
    BIG_OL_QUERY :: #string SQL
SELECT
    User.name                         AS author_name,
    COUNT(*)                          AS top_level_post_count,
    MAX(strftime("%s", Post.created)) AS latest_post_date
FROM Post
LEFT JOIN User ON User.id = Post.author_id
WHERE
    author_id >= ?1 AND
    parent_id IS NULL
GROUP BY author_id
SQL;
    min_author_id := 2;
    {
        log("testing generic SQL execution with an anonymous struct");
        result, rows := SQLite.exec_into_array_of(struct { author_name: string; top_level_post_count: int; latest_post_date: string; },
            BIG_OL_QUERY,
            min_author_id
        ); AssertResultOK();
        for rows log("  %1\n    posts: %2\n    latest post date: %3",
        /* 1 */it.author_name,
        /* 2 */it.top_level_post_count,
        /* 3 */it.latest_post_date
        );
    } #if false { // remove #if false to see a runtime error
        result, rows := SQLite.exec_into_array_of(struct { blauthor_name: string; blop_level_post_count: int; blatest_post_date: string; },
            BIG_OL_QUERY,
            min_author_id
        ); AssertResultOK();
    } {
        log("no runtime error here because check_column_names=false");
        result, rows := SQLite.exec_into_array_of(struct { blauthor_name: string; blop_level_post_count: int; blatest_post_date: string; },
            BIG_OL_QUERY,
            min_author_id,
            check_column_names=false
        ); AssertResultOK();
    }
    log("testing enum support");
    user_id_to_upgrade := 2;
    kind_to_upgrade_to := User.Kind.MEGAUSER;
    {
        log("  getting User id %", user_id_to_upgrade);
        result, user := ORM.select_by_id(User, user_id_to_upgrade); AssertResultOK();
        log("  setting User id %'s kind to %", user_id_to_upgrade, kind_to_upgrade_to);
        result = ORM.set(user, "kind", kind_to_upgrade_to); AssertResultOK();
        assert(user.kind == kind_to_upgrade_to);
    }
    {
        log("  getting User id % again", user_id_to_upgrade);
        result, user := ORM.select_by_id(User, user_id_to_upgrade); AssertResultOK();
        assert(user.kind == kind_to_upgrade_to);
    }
    ORM.fini();
}

AssertResultOK :: (loc := #caller_location) #expand { assert(`result == .OK, "%: %", `result, SQLite.errmsg(), loc=loc); }

#import "Basic";

SQLite :: #import,dir "../../../../SQLite"(USE_ORM=true, VERBOSE=true);
ORM :: SQLite.ORM;

#add_context db_cache: Database_Cache;

