User :: struct { using #as model: ORM.Model;
    name: string;
    age: int;
    favorite_floating_point_number: float;
    corporate_id: s64;
    is_awesome := false;
    something_else: string; @NoSerialize
}

main :: () {
    ORM.init("database.db");
    result: SQL.Result;
    {
        user1, user2: ORM.Cached(User);

        log("inserting a user");
        result, user1 = ORM.insert(User.{name="Alice", age=32, favorite_floating_point_number=3.14, corporate_id=3_000_000_000});
        LogIfError();

        log("inserting another user");
        result, user2 = ORM.insert(User.{name="Bob", age=64, favorite_floating_point_number=1.111, corporate_id=3_000_000_001, is_awesome=true});
        LogIfError();

        log("waiting for two seconds");
        sleep_milliseconds(2000);

        log("updating second user");
        user2.name = "Robert";
        result = ORM.update(user2);
        LogIfError();

        log("deleting first user");
        result = ORM.delete(user1);
        LogIfError();
    }{
        log("retreiving user id 2");
        cached_user: ORM.Cached(User);
        result, cached_user = ORM.select_by_id(User, 2);
        LogIfError();
        { using cached_user; log("  User #%1 is named %2, age %3, favorite float %4, corp id %5", id, name, age, favorite_floating_point_number, corporate_id); }
    }
    ORM.fini();
}

LogIfError :: () #expand { if `result != .OK then log("%: %", `result, SQL.errmsg()); }

#import "Basic";
#import "Hash_Table";
#import "File";

SQL :: #import,dir "../../../SQLite";
ORM :: SQL.ORM;

#add_context db_cache: Database_Cache;
