prebuild_step :: (w: Workspace) {
    options := get_build_options(w);
    DLL_NAME :: "sqlite3.dll";
    dll_destination := sprint("%1/%2", options.output_path, DLL_NAME);
    (#import "File").make_directory_if_it_does_not_exist("bin");
    if !file_exists(dll_destination) then copy_file(sprint("%1%2", #filepath, DLL_NAME), dll_destination);
    array_reset(*model_names);
}

build_step :: inline (message: *Message) {
    if message.kind == {
        case .TYPECHECKED;
            typechecked := cast(*Message_Typechecked) message;
            for typechecked_struct: typechecked.structs {
                code_struct := typechecked_struct.expression;
                name := code_struct.defined_type.name;
                if ORM.is_a_model(code_struct.defined_type) {
                    array_add_if_unique(*model_names, name);
                    sb_table: String_Builder;
                    sb_fk: String_Builder;
                    print_to_builder(*sb_table, "CREATE TABLE %(\n    id  INTEGER PRIMARY KEY,", name);
                    append(*sb_table, "\n    created   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,");
                    append(*sb_table, "\n    modified  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP");
                    for ORM.serializable_members_of(code_struct.defined_type) {
                        append(*sb_table, ",\n");
                        if ORM.member_is_foreign_key(it) {
                            print_to_builder(*sb_table, "    %_id  INTEGER", it.name);
                            fk_name := ORM.get_foreign_key_name_from(it);
                            on_update, on_delete: string;
                            for it.notes {
                                found, key, value := split_from_left(it, #char "=");
                                if !found continue;
                                if key == "on_update" && is_valid_fk_action(value) then on_update = replace(value, "_", " ");
                                if key == "on_delete" && is_valid_fk_action(value) then on_delete = replace(value, "_", " ");
                                is_valid_fk_action :: (value: string) -> bool { for enum_names(ORM.Foreign_Key_Action) if it == value then return true; assert(false, "Invalid Foreign_Key_Action in Cached(T) note."); return false; }
                            }


                            print_to_builder(*sb_fk, ",\n    FOREIGN KEY(%1_id) REFERENCES %2(id)%3%4",
                            /* 1 */it.name,
                            /* 2 */fk_name,
                            /* 3 */ifx on_update != "" then sprint(" ON UPDATE %", on_update),
                            /* 4 */ifx on_delete != "" then sprint(" ON DELETE %", on_delete)
                            );
                        }
                        else if it.type.type == {
                            case .BOOL; #through;
                            case .INTEGER; print_to_builder(*sb_table, "    %  INTEGER", it.name);
                            case .FLOAT;   print_to_builder(*sb_table, "    %  REAL",    it.name);
                            case .STRING;  print_to_builder(*sb_table, "    %  TEXT",    it.name);
                        }
                    }
                    append(*sb_table, builder_to_string(*sb_fk));
                    print_to_builder(*sb_table, "\n)%;\n", ifx STRICT_TABLES then " STRICT");
                    array_add(*table_schemas, builder_to_string(*sb_table));
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
XX, iterate(#string XX
    _%1: Table(s64, %1);
XX), #string XX
}
__flush_database_cache :: () {
    using context.db_cache;
XX, iterate(#string XX
    deinit(*_%1); init(*_%1); // this is probably dumb
XX), #string XX
}
XX                  );
                    sb_schema: String_Builder;
                    for table_schemas append(*sb_schema, it);
                    add_to_build(message.workspace, "DATABASE_SCHEMA :: #string DATABASE_SCHEMA_XX\n", builder_to_string(*sb_schema), "\nDATABASE_SCHEMA_XX;");
                    generated_code = true;

                    iterate :: (str: string) -> string #expand {
                        sb: String_Builder;
                        for `model_names print_to_builder(*sb, str, it);
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
#import "File_Utilities";