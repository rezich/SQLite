// Most of this is garbage that should probably be cleaned the f up.

prebuild_step :: (w: Workspace) {
    options := get_build_options(w);
    DLL_NAME :: "sqlite3.dll";
    dll_destination := sprint("%1/%2", options.output_path, DLL_NAME);
    log(dll_destination);
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
                // get all Model
                if is_subclass_of(code_struct.defined_type, "Model") {
                    name_lower := copy_string(name);
                    to_lower_in_place(name_lower);
                    plural := tprint("%1%2", name_lower, "s");
                    for note: code_struct.notes if begins_with(note.text, NOTE_PLURAL) then plural = slice(note.text, NOTE_PLURAL.count, note.text.count);
                    model_info: *Model_Info;
                    _model_info: Model_Info;
                    _model_info.name = name;
                    _model_info.plural = plural;
                    model_info = table_set(*model_infos, name, _model_info);
                    if array_add_if_unique(*model_names, name) {
                        log_verbose("Model: % | plural: %\n", name, plural);
                        code_struct_type_info := code_struct.defined_type;
                        for member: code_struct_type_info.members {
                            if member.type.type == {
                                 case .INTEGER;
                                    field_info := New(Field_Info_Integer);
                                    field_info.tag = .INTEGER;
                                    field_info.name = member.name;
                                    table_set(*model_info.fields, member.name, field_info);
                                    log_verbose("  field: INTEGER %", member.name);
                                 case .FLOAT;
                                    field_info := New(Field_Info_Float);
                                    field_info.tag = .FLOAT;
                                    field_info.name = member.name;
                                    table_set(*model_info.fields, member.name, field_info);
                                    log_verbose("  field: FLOAT %", member.name);
                                 case .BOOL;
                                    field_info := New(Field_Info_Bool);
                                    field_info.tag = .BOOL;
                                    field_info.name = member.name;
                                    table_set(*model_info.fields, member.name, field_info);
                                    log_verbose("  field: BOOL %", member.name);
                                case .STRING;
                                    field_info := New(Field_Info_String);
                                    field_info.tag = .STRING;
                                    field_info.name = member.name;
                                    table_set(*model_info.fields, member.name, field_info);
                                    log_verbose("  field: STRING %", member.name);
                                case .POINTER;
                                    field_info := New(Field_Info_Foreign_Key);
                                    field_info.tag = .FOREIGN_KEY;
                                    field_info.name = member.name;
                                    fk_model := (cast(*Type_Info_Struct) ((cast(*Type_Info_Pointer) (member.type)).pointer_to)).name;
                                    log_verbose("  field: FOREIGN_KEY % -> %", member.name, fk_model);
                                    field_info.foreign_table = fk_model;
                                    table_set(*model_info.fields, member.name, field_info);
                                case .ARRAY;
                                    array_info := cast(*Type_Info_Array) member.type;
                                    assert(array_info.array_type == .RESIZABLE && array_info.element_type.type == .POINTER, ERROR_FIELD_DECLARATION);
                                    fk := name_lower;
                                    for note: member.notes if begins_with(note, NOTE_FOREIGN_KEY) then fk = slice(note, NOTE_FOREIGN_KEY.count, note.count);
                                    field_info := New(Field_Info_One_To_Many);
                                    field_info.tag = .ONE_TO_MANY;
                                    field_info.name = member.name;
                                    field_info.foreign_key = fk;
                                    table_set(*model_info.fields, member.name, field_info);
                                    log_verbose("  field: ONE_TO_MANY % <- %", member.name, field_info.foreign_key);
                            }
                        }
                    }
                }
            }
        
        case .PHASE;
            phase := cast(*Message_Phase) message;
            if phase.phase == .TYPECHECKED_ALL_WE_CAN {
                if !generated_code {
                    quick_sort(model_names, compare_strings);
                    add_to_build(message.workspace, #string XX
Database_Cache :: struct {
XX, iterate(#string XX
    _%1: Table(s64, %1);
XX), #string XX
}
XX                  );
                    database_schema_builder: String_Builder; defer free_buffers(*database_schema_builder);
                    for name: model_names {
                        foreign_key_builder: String_Builder; defer free_buffers(*foreign_key_builder);
                        model := table_find_pointer(*model_infos, name);
                        print_to_builder(*database_schema_builder, "CREATE TABLE %(\n    id  INTEGER PRIMARY KEY,", name);
                        append(*database_schema_builder, "\n    created   TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,");
                        append(*database_schema_builder, "\n    modified  TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP");
                        for field: model.fields {
                            if field.tag == .ONE_TO_MANY then continue;
                            append(*database_schema_builder, ",\n");
                            if field.tag == {
                                case .INTEGER; print_to_builder(*database_schema_builder, "    %  INTEGER", field.name);
                                case .FLOAT; print_to_builder(*database_schema_builder, "    % REAL", field.name);
                                case .BOOL; print_to_builder(*database_schema_builder, "    %  INTEGER", field.name);
                                case .STRING; print_to_builder(*database_schema_builder, "    %  TEXT", field.name);
                                case .FOREIGN_KEY;
                                    fk_field := cast(*Field_Info_Foreign_Key) field;
                                    print_to_builder(*database_schema_builder, "    %_id  INTEGER", field.name);
                                    print_to_builder(*foreign_key_builder, ",\n    FOREIGN KEY(%_id) REFERENCES %(id)", field.name, fk_field.foreign_table);
                            }
                        }
                        append(*database_schema_builder, builder_to_string(*foreign_key_builder));
                        print_to_builder(*database_schema_builder, tprint("\n)%;\n", ifx STRICT_TABLES then " STRICT"));
                    }
                    database_schema := builder_to_string(*database_schema_builder);
                    log_verbose(database_schema);
                    add_to_build(message.workspace, "database_schema :: #string XX\n", database_schema, "\nXX;");

                    model_infos_builder: String_Builder; defer free_buffers(*model_infos_builder);
                    append(*model_infos_builder, "set_model_infos :: () {\n");
                    #if NAMESPACE != "" then append(*model_infos_builder, tprint("    using %;\n", NAMESPACE));
                    for name: model_names {
                        model := table_find_pointer(*model_infos, name);
                        append(*model_infos_builder, "    {\n");
                        print_to_builder(*model_infos_builder, #string XX
        model_info: *Model_Info;
        _model_info: Model_Info;
        _model_info.name = "%1";
        _model_info.plural = "%2";
        model_info = table_set(*%3model_infos, "%1", _model_info);
XX,                     name, model.plural, ifx NAMESPACE != "" then tprint("%.", NAMESPACE));
                        for field: model.fields {
                            append(*model_infos_builder, "        {\n");
                            if field.tag == {
                                case .INTEGER;
                                    print_to_builder(*model_infos_builder, #string XX
                field_info := New(Field_Info_Integer);
                field_info.tag = .INTEGER;
                field_info.name = "%1";
                table_set(*model_info.fields, "%1", field_info);
XX,                                 field.name);
                                case .FLOAT;
                                    print_to_builder(*model_infos_builder, #string XX
                field_info := New(Field_Info_Float);
                field_info.tag = .FLOAT;
                field_info.name = "%1";
                table_set(*model_info.fields, "%1", field_info);
XX,                                 field.name);
                                case .BOOL;
                                    print_to_builder(*model_infos_builder, #string XX
                field_info := New(Field_Info_Bool);
                field_info.tag = .BOOL;
                field_info.name = "%1";
                table_set(*model_info.fields, "%1", field_info);
XX,                                 field.name);
                                case .STRING;
                                    print_to_builder(*model_infos_builder, #string XX
                field_info := New(Field_Info_String);
                field_info.tag = .STRING;
                field_info.name = "%1";
                table_set(*model_info.fields, "%1", field_info);
XX,                                 field.name);
                                case .FOREIGN_KEY;
                                    fk_field := cast(*Field_Info_Foreign_Key) field;
                                    print_to_builder(*model_infos_builder, #string XX
                field_info := New(Field_Info_Foreign_Key);
                field_info.tag = .FOREIGN_KEY;
                field_info.name = "%1";
                field_info.foreign_table = "%2";
                table_set(*model_info.fields, "%1", field_info);
XX,                                 field.name, fk_field.foreign_table);
                                case .ONE_TO_MANY;
                                    otm_field := cast(*Field_Info_One_To_Many) field;
                                    print_to_builder(*model_infos_builder, #string XX
                field_info := New(Field_Info_One_To_Many);
                field_info.tag = .ONE_TO_MANY;
                field_info.name = "%1";
                field_info.foreign_key = "%2";
                table_set(*model_info.fields, "%1", field_info);
XX,                                 field.name, otm_field.foreign_key);
                            }
                            append(*model_infos_builder, "        }\n");
                        }
                        //append(*model_infos_builder, "        field_info := New(Field_Info);\n");
                        append(*model_infos_builder, "    }\n");
                    }
                    append(*model_infos_builder, "}");
                    model_infos_string := builder_to_string(*model_infos_builder);
                    add_to_build(message.workspace, model_infos_string);
                    generated_code = true;

                    iterate :: (str: string) -> string #expand {
                        sb: String_Builder; defer free_buffers(*sb);
                        for `model_names print_to_builder(*sb, str, it);
                        return builder_to_string(*sb);
                    }
                    add_to_build :: (w: Workspace, args: ..Any) {
                        sb: String_Builder; defer free_buffers(*sb);
                        for args print_to_builder(*sb, tprint("%", it));
                        add_build_string(builder_to_string(*sb), w);
                    }
                }
            }
    }
}

#scope_file

ERROR_FIELD_DECLARATION :: "Model fields can only be integers, floats, bools, strings, pointer-to-other-models, and resizable-array-of-pointer-to-other-models.";
NOTE_PLURAL ::"plural=";
NOTE_FOREIGN_KEY :: "fk=";

model_names: [..] string;
generated_code := false;

log_verbose :: (data: string, args: ..Any) { #if VERBOSE log(data, ..args); }


#import "Basic";
#import "Compiler";
#import "String";
#import "Sort";
#import "File_Utilities";
#import "Hash_Table";
