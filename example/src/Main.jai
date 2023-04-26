User :: struct { using #as model: ORM.Model;
    name: string;
    age: int;
    favorite_floating_point_number: float;
    corporate_id: s64;
    is_awesome := false;
    something_else: string; @do_not_serialize
}

Post :: struct { using #as model: ORM.Model;
    body: string;
    author: ORM.Cached(User); @on_delete=CASCADE
    parent: ORM.CachedThis;   @on_delete=CASCADE
}

main :: () {
    set_working_directory((#import "String").path_strip_filename((#import "System").get_path_of_running_executable()));
    ORM.init("database.db");
    result: SQL.Result;
    {
        user1, user2: ORM.Cached(User);

        log("inserting a User");
        result, user1 = ORM.insert(User.{
            name="Alice",
            age=32,
            favorite_floating_point_number=3.14,
            corporate_id=3_000_000_000
        }); AssertNoErrors();

        log("inserting another User");
        result, user2 = ORM.insert(User.{
            name="Bob",
            age=64,
            favorite_floating_point_number=1.111,
            corporate_id=3_000_000_001,
            is_awesome=true
        }); AssertNoErrors();

        log("inserting three Posts, ignoring the second return value");
        result = ORM.insert(Post.{
            body="First post",
            author=user2
        }); AssertNoErrors();
        result = ORM.insert(Post.{
            body="Second post",
            author=user2
        }); AssertNoErrors();
        result = ORM.insert(Post.{
            body="Third post",
            author=user2
        }); AssertNoErrors();

        log("inserting a Post");
        parent_post, child_post: ORM.Cached(Post);
        result, parent_post = ORM.insert(Post.{
            body="Parent Post",
            author=user1
        }); AssertNoErrors();

        log("inserting another Post, with the previous Post as its parent");
        result, child_post = ORM.insert(Post.{
            body="Child Post",
            author=user1,
            parent=xx parent_post
        }); AssertNoErrors();
        // the xx above is ugly but it's the best solution for now with regards to self-referential foreign keys

        {
            post: ORM.Cached(Post);
            result, post = ORM.select_by_id(Post, 5); AssertNoErrors();
            ORM.fetch(Post, *post.parent); AssertNoErrors();
            // another weird hack for CachedThis. but it works!
        }

        log("deleting the first User");
        result = ORM.delete(*user1); AssertNoErrors();
        assert(!ORM.is_fetched(user1));

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
                AssertNoErrors();
                for posts log("  % %", it.id, it.body);
            }
        }

        // one more time, just because this is cool:
        ORM.select_from(Post, where="author_id = ?", user2.id);
        ORM.select_from(Post, where="author_id = ?", user2.id, limit=2);
        ORM.select_from(Post, where="author_id = ?", user2.id, limit=2, offset=2);
        ORM.select_from(Post, where="author_id = ?", user2.id,          offset=2);
        ORM.select_from(Post,                                  limit=2);

        new_name := "Robert";
        log("changing %'s name to %", user2.name, new_name);
        user2.name = new_name;
        result = ORM.update(user2); AssertNoErrors();
    }{
        post: ORM.Cached(Post);
        log("selecting the first Post");
        result, post = ORM.select_by_id(Post, 1); AssertNoErrors();
        assert(ORM.is_fetched(post.author));
        log("  we can tell the Post's author's name is % because it's still in the cache.", post.author.name);
    }
    log("flushing the cache");
    ORM.flush_cache();
    {
        post: ORM.Cached(Post);
        log("selecting the first Post");
        result, post = ORM.select_by_id(Post, 1); AssertNoErrors();
        assert(!ORM.is_fetched(post.author));
        log("  we *CAN'T* tell the Post's author's name because we flushed the cache.");
        log("fetching the author manually");
        result = ORM.fetch(*post.author); AssertNoErrors();
        log("  now we know the Post's author's name: it's %", post.author.name);
    }
    ORM.fini();
}

AssertNoErrors :: () #expand { assert(`result == .OK, "%: %", `result, SQL.errmsg()); }

#import "Basic";

SQL :: #import,dir "../../../SQLite";
ORM :: SQL.ORM;

#add_context db_cache: Database_Cache;
