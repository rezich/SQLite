prebuild_step :: (w: Workspace) {
    options := get_build_options(w);
    DLL_NAME :: "sqlite3.dll";
    dll_\    source := sprint("%1../lib/%2", #filepath, DLL_NAME);
    dll_destination := sprint("%1/%2", options.output_path, DLL_NAME);
    (#import "File").make_directory_if_it_does_not_exist("bin");
    if !file_exists(dll_destination) then copy_file(dll_source, dll_destination);
    array_reset(*model_names);
}

build_step :: inline (message: *Message) {
    if message.kind == {
        case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;
            for typechecked_struct: typechecked.structs {
                code_struct := typechecked_struct.expression;
                name := code_struct.defined_type.name;
                if is_a_model(code_struct.defined_type) {
                    array_add_if_unique(*model_names, name);
                    sb_table: String_Builder;
                    sb_fk: String_Builder;
                    print_to_builder(*sb_table, #string SQL
CREATE TABLE %1(id INTEGER PRIMARY KEY
SQL,                /* 1 */ name);
                    append(*sb_table, #string SQL
,created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
,modified TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
SQL                 );
                    for serializable_members_of(code_struct.defined_type) {
                        if member_is_foreign_key(it) {
                            print_to_builder(*sb_table, #string SQL
,%1_id INTEGER
SQL,                        /* 1 */ it.name);
                            fk_name := get_foreign_key_name_from(it, name);
                            on_update, on_delete: string;
                            for it.notes {
                                found, key, value := split_from_left(it, #char "=");
                                if !found continue;
                                if key == "on_update" && is_valid_fk_action(value) then on_update = replace(value, "_", " ");
                                if key == "on_delete" && is_valid_fk_action(value) then on_delete = replace(value, "_", " ");
                                is_valid_fk_action :: (value: string) -> bool { for enum_names(Foreign_Key_Action) if it == value then return true; assert(false, "Invalid Foreign_Key_Action in Cached(T) note."); return false; }
                            }
                            print_to_builder(*sb_fk, #string SQL
,FOREIGN KEY(%1_id) REFERENCES %2(id)%3%4
SQL,                        /* 1 */ it.name,
                            /* 2 */ fk_name,
                            /* 3 */ ifx on_update != "" then sprint(" ON UPDATE %", on_update),
                            /* 4 */ ifx on_delete != "" then sprint(" ON DELETE %", on_delete)
                            );
                        }
                        else {
                            sql_type: string;
                            default_value: string;
                            if it.type.type == {
                                case .BOOL; #through;
                                case .ENUM; #through;
                                case .INTEGER; sql_type="INTEGER"; default_value="0";
                                case .FLOAT;   sql_type="REAL";    default_value="0";
                                case .STRING;  sql_type="TEXT";
                            }
                            print_to_builder(*sb_table, #string SQL
,%1 %2%3%4
SQL,                        /* 1 */ it.name,
                            /* 2 */ sql_type,
                            /* 3 */ " NOT NULL", //TODO: optional nullability
                            /* 4 */ ifx default_value then sprint(" DEFAULT %", default_value)
                            );
                        }
                    }
                    strict_table := STRICT_TABLES;
                    for code_struct.defined_type.notes {
                        if it == "strict" { strict_table = true; break; }
                        found, key, value := split_from_left(it, #char "=");
                        if !found continue;
                        if key == "strict" && value != "true" && value != "" { strict_table = true; break; }
                    }
                    append(*sb_table, builder_to_string(*sb_fk));
                    print_to_builder(*sb_table, #string SQL
)%1;
SQL,                /* 1 */ ifx strict_table then " STRICT");
                    array_add(*table_schemas, trim(builder_to_string(*sb_table), " \t\n"));
                }
            }
        
        case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                if !generated_code {
                    quick_sort(model_names, compare_strings);
                    add_to_build(message.workspace, #string XX
Database_Cache :: struct {
    #import "Hash_Table";
XX, iterate_model_names(#string XX
    _%1: Table(s64, %1);
XX), #string XX
}
__flush_database_cache :: (reinit := true) {
    using context.db_cache;
XX, iterate_model_names(#string XX
    table_reset(*_%1); //TODO: fix this dumb stopgap measure
    if _%1.allocated > 0 { deinit(*_%1); if reinit then init(*_%1); }
XX), #string XX
}
TABLE_SCHEMAS :: string.[
XX, iterate_table_schemas(#string XX
#string XX_TABLE_SCHEMA_XX
%1
XX_TABLE_SCHEMA_XX,
XX), #string XX
];
XX                  );
                    #if MAKE_MIGRATIONS then make_migrations(model_names, table_schemas);
                    generated_code = true;

                    iterate_model_names :: (str: string) -> string #expand {
                        sb: String_Builder;
                        for `model_names print_to_builder(*sb, str, it);
                        return builder_to_string(*sb);
                    }
                    iterate_table_schemas :: (str: string) -> string #expand {
                        sb: String_Builder;
                        for `table_schemas print_to_builder(*sb, str, it);
                        return builder_to_string(*sb);
                    }
                    add_to_build :: (w: Workspace, args: ..Any) {
                        sb: String_Builder;
                        for args print_to_builder(*sb, "%", it);
                        add_build_string(builder_to_string(*sb), w);
                    }
                }
            }
    }
}

#scope_file

model_names:   [..] string;
table_schemas: [..] string;
generated_code  :=  false;

#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "File";
#import "File_Utilities";
