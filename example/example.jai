OUTPUT_NAME :: "example";
OUTPUT_PATH :: "bin";
ENTRY_POINT :: "src/Main.jai";

#run {
    w := compiler_create_workspace("Actual program");
    if !w { print("Workspace creation failed.\n"); return; }

    options := get_build_options(w);
    options.output_executable_name = OUTPUT_NAME;
    options.output_path = OUTPUT_PATH;
    options.text_output_flags = 0;
    set_build_options(options, w);

    compiler_begin_intercept(w);
    add_build_file(ENTRY_POINT, w);

    SQL.prebuild_step(w);

    while true {
        message := compiler_wait_for_message();
        if !message || message.kind == .COMPLETE then break;
        SQL.build_step(message);
    }

    compiler_end_intercept(w);
    set_build_options_dc(.{do_output=false, write_added_strings=false});
}

#import "Basic";
#import "Compiler";
SQL :: #import,dir "../../SQLite"(FROM_METAPROGRAM=true);
