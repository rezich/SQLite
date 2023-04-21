User :: struct { using #as model: ORM.Model;
    name: string;
    age: int;
    favorite_floating_point_number: float;
    corporate_id: s64;
}

main :: () {
    db_init();

    result: SQL.Result;

    {
        user1, user2: ORM.Cached(User);

        log("inserting a user");
        result, user1 = ORM.insert(User.{name="Alice", age=32, favorite_floating_point_number=3.14, corporate_id=3_000_000_000});
        LogIfError();

        log("inserting another user");
        result, user2 = ORM.insert(User.{name="Bob", age=64, favorite_floating_point_number=1.111, corporate_id=3_000_000_001});
        LogIfError();

        log("waiting for two seconds");
        sleep_milliseconds(2000);

        log("updating second user");
        user2.name="Robert";
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

    db_fini();
}

LogIfError :: () #expand { if `result != .OK then log("%: %", `result, SQL.errmsg()); }

DATABASE_NAME :: "database.db";
DELETE_DATABASE_EVERY_RUN :: false; // for testing

PRAGMAS :: string.[
    "journal_mode = WAL",
    "synchronous = NORMAL",
    "foreign_keys = ON",
];

db_init :: () {
    set_working_directory((#import "String").path_strip_filename((#import "System").get_path_of_running_executable()));
    database_already_existed := (#import "File_Utilities").file_exists(DATABASE_NAME);
    #if DELETE_DATABASE_EVERY_RUN {
        file_delete(DATABASE_NAME);
        database_already_existed = false;
    }
    log("setting model infos");
    set_model_infos(); // this step will be replaced with something much simpler soon
    {
        log("opening database");
        result, error := SQL.open(DATABASE_NAME);
        if result != .OK { log("%: %", result, error); exit(0); }
    }
    log("setting pragmas");
    for PRAGMAS { // I *think* these don't save to the database...?
        result, error := SQL.exec(tprint("PRAGMA %;", it));
        if result != .OK { log("%: %", result, error); exit(0); }
    }
    if !database_already_existed {
        log("setting database schema");
        result, error := SQL.exec(database_schema);
        if result != .OK then log("%: %", result, error);
    }
}

db_fini :: () { log("closing database"); SQL.close(); }

#import "Basic";
#import "Hash_Table";
#import "File";
SQL :: #import,dir "../../../SQLite";
ORM :: SQL.ORM;
#add_context db_cache: Database_Cache;
