// This is a work in progress!

Migration :: struct {
    index: int;
    table_schemas: Table(string, Table_Schema);
}

Table_Schema :: struct {
    create: string;
    columns: Table(string, Column);
    foreign_keys: Table(string, Foreign_Key);
    strict: bool;

    Column :: struct {
        name: string;
        type: string;
        not_null: bool;
        default: string;
    }
    Foreign_Key :: struct {
        parent_table: string;
        child_table: string;
        parent_key: string;
        child_key: string;
        on_update: string;
        on_delete: string;
    }
}

migrations: [..] Migration;

parse_table_schema :: (using table_schema: *Table_Schema) {
    for split(create, "\n") {
        if begins_with(it, "CREATE TABLE")   then continue;
        if begins_with(it, ",created TEXT")  then continue;
        if begins_with(it, ",modified TEXT") then continue;
        if begins_with(it, ",FOREIGN KEY") {
            fk: Foreign_Key;
            right := it;
            left: string;
            found: bool;
            found, left, right = split_from_left(right, ",FOREIGN KEY(");
            found, left, right = split_from_left(right, ") REFERENCES ");
            fk.child_key = copy_string(left);
            found, left, right = split_from_left(right, "(");
            fk.parent_table = copy_string(left);
            found, left, right = split_from_left(right, ")");
            fk.parent_key = copy_string(left);
            if contains(it, "ON UPDATE") {
                on: string;
                found, left, right = split_from_left(right, "ON UPDATE ");
                found, left, on = split_from_left(right, " ON DELETE ");
                fk.on_update = copy_string(on);
            }
            if contains(it, "ON DELETE") {
                on: string;
                found, left, on = split_from_left(right, "ON DELETE ");
                fk.on_delete = copy_string(on);
            }
            table_set(*foreign_keys, fk.child_key, fk);
            continue;
        }
        if begins_with(it, ",") {
            column: Column;
            right := it;
            left: string;
            found: bool;
            found, left, right = split_from_left(right, ",");
            found, left, right = split_from_left(right, " ");
            column.name = copy_string(left);
            column.not_null = contains(it, "NOT NULL");
            if contains(it, " DEFAULT ") {
                found, left, right = split_from_left(right, " DEFAULT ");
                column.default = copy_string(right);
            }
            table_set(*columns, column.name, column);
            continue;
        }
        if begins_with(it, ")") {
            strict = contains(it, "STRICT");
            continue;
        }
    }
}

load_migration :: (index: int) -> Migration {
    migration: Migration;
    migration.index = index;
    for files_in_migration(index) {
        table_schema := table_set(
            *migration.table_schemas,
            path_strip_extension(it),
            .{create=read_entire_file(sprint("migrations/%/%", index, it))}
        );
        parse_table_schema(table_schema);
    }
    return migration;
}

compare_migrations :: (old: Migration, new: Migration) {
    tables_compared: [..] string;
    for table_schema, table_name: old.table_schemas {
        defer array_add(*tables_compared, table_name);
        new_table_schema := table_find_pointer(*new.table_schemas, table_name);
        if !new_table_schema {
            log("table % was removed", table_name);
            continue;
        }
        if compare_table_schemas(table_schema, new_table_schema) {
            log("table % was altered", table_name);
        }
    }
    for table_schema, table_name: new.table_schemas {
        for tables_compared if it == table_name then continue table_schema;
        defer array_add(*tables_compared, table_name);
        log("table % was added", table_name);
    }
    
}

compare_table_schemas :: (old: Table_Schema, new: Table_Schema) -> bool {
    return compare(old.create, new.create) != 0;
}

make_migrations :: (model_names: [] string, table_schemas: [] string) {
    current_migration_in_filesystem, current_migration_on_disk: Migration;

    for table_schemas {
        table_schema := table_set(
            *current_migration_in_filesystem.table_schemas,
            model_names[it_index],
            .{create=it}
        );
        parse_table_schema(table_schema);
    }

    make_directory_if_it_does_not_exist("migrations");
    migration_already_existed := file_exists("migrations/0");
    if migration_already_existed {
        current_migration_on_disk = load_migration(0);
        compare_migrations(
            current_migration_in_filesystem,
            current_migration_on_disk
        );
    }
    save_current_migration_to_disk();
    /*existing_migrations := migrations_list();
    if existing_migrations.count == 0 {
        make_directory_if_it_does_not_exist("migrations/1");
        for `model_names write_entire_file(
            sprint("migrations/1/%.sql", it),
            `table_schemas[it_index]
        );
    }*/
}

save_current_migration_to_disk :: () #expand {
    make_directory_if_it_does_not_exist("migrations/0");
    for `model_names write_entire_file(
        sprint("migrations/0/%.sql", it),
        `table_schemas[it_index]
    );
}

migrations_list :: () -> [] string #must {
    files : [..] string;
    visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
        if info.short_name != "0" then array_add(user_data, copy_string(info.short_name));
    }
    visit_files("migrations", false, *files, visitor, visit_files=false, visit_directories=true);
    return files;
}

files_in_migration :: (migration: int) -> [] string #must {
    files : [..] string;
    visitor :: (info: *File_Visit_Info, user_data: *[..] string) {
        array_add(user_data, copy_string(info.short_name));
    }
    visit_files(sprint("migrations/%", migration), false, *files, visitor);
    return files;
}

#import "Hash_Table";
