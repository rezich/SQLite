User :: struct { using #as model: ORM.Model;
    name: string;
    age: int;
    favorite_floating_point_number: float;
    corporate_id: s64;
    is_awesome := false;
    something_else: string; @NoSerialize
}

Post :: struct { using #as model: ORM.Model;
    body: string;
    author: ORM.Cached(User);
}

main :: () {
    ORM.init("database.db");
    result: SQL.Result;
    {
        user1, user2: ORM.Cached(User);

        log("inserting a User");
        result, user1 = ORM.insert(User.{name="Alice", age=32, favorite_floating_point_number=3.14, corporate_id=3_000_000_000});
        AssertNoErrors();

        log("inserting another User");
        result, user2 = ORM.insert(User.{name="Bob", age=64, favorite_floating_point_number=1.111, corporate_id=3_000_000_001, is_awesome=true});
        AssertNoErrors();

        log("inserting two Posts");
        result = ORM.insert(Post.{body="First post",  author=user2}); AssertNoErrors();
        result = ORM.insert(Post.{body="Second post", author=user2}); AssertNoErrors();

        log("deleting the first User");
        result = ORM.delete(user1); AssertNoErrors();

        list_posts_for(user2);

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
    }{
        log("flushing the cache");
        ORM.flush_cache();
    }{
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

list_posts_for :: (author: ORM.Cached(User)) {
    if ORM.is_fetched(author) {
        log("getting posts for %", author.name);
        result, posts := ORM.select_from(Post, where="author_id = ?", author.id); AssertNoErrors();
        for posts log("  % %", it.id, it.body);
    }
}

AssertNoErrors :: () #expand { assert(`result == .OK, "%: %", `result, SQL.errmsg()); }

#import "Basic";
#import "Hash_Table";
#import "File";

SQL :: #import,dir "../../../SQLite";
ORM :: SQL.ORM;

#add_context db_cache: Database_Cache;
