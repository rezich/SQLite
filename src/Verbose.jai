#import "Print_Color";
#import "String";

COLOR_SCHEME :: struct {
    QUERY_TEXT      :: Console_Color.MAGENTA;
    QUERY_PARAMETER :: Console_Color.HI_CYAN;
    QUERY_RULER     :: Console_Color.BG_BLUE;
    OPEN_FOR_NAME   :: Console_Color.YELLOW;
    OPEN_FOR_RULER  :: Console_Color.BG_YELLOW;
}

MINIMUM_OPEN_FOR_HEADER_AND_FOOTER_WIDTH :: 40;

#add_context sqlite_verbose: struct {
    statement: string;
    parameter_count: int;
    parameters: [100] string;
    open_for_begin: Apollo_Time;
};

verbose_begin :: (statement: string) {
    context.sqlite_verbose.statement = statement;
}

verbose_bind :: (param: $T) {
    using context.sqlite_verbose;
    #if #run type_info(T).type == .ENUM    then
        parameters[parameter_count] = tprint("% [%]", cast,force(s64) param, param);
    else
    #if #run type_info(T).type == .POINTER then
        parameters[parameter_count] = "NULL";
    else
    #if #run type_info(T).type == .BOOL    then
        parameters[parameter_count] = tprint("% [%]", ifx param then 1, ifx param then "TRUE" else "FALSE");
    else
    #if #run type_info(T).type == .STRING  then
        parameters[parameter_count] = tprint("\"%\"", param);
    else
        parameters[parameter_count] = tprint("%", param);
    parameter_count += 1;
}

verbose_end :: () {
    using context.sqlite_verbose;
    parameter_index := 0;
    for split(statement, "\n") {
        if open_for_begin != .{} {
            print_color(" ", color=COLOR_SCHEME.OPEN_FOR_RULER);
        }
        print_color(" ", color=COLOR_SCHEME.QUERY_RULER);
        write_string(" ");
        for split(it, "?") {
            with_console_color(COLOR_SCHEME.QUERY_TEXT, write_string(trim_left(it, "0123456789")));
            if parameter_index < parameter_count then with_console_color(COLOR_SCHEME.QUERY_PARAMETER, write_string(parameters[it_index]));
            parameter_index += 1;
        }
        write_string("\n");
    }
    parameter_count = 0;
    statement = "";
}

verbose_begin_open_for :: (name: string) {
    using context.sqlite_verbose;
    open_for_begin = current_time_monotonic();
    write_string("\n");
    print_color(" ", color=COLOR_SCHEME.OPEN_FOR_RULER);
    print_color(" %\n", ifx name else "(unnamed block)", color=COLOR_SCHEME.OPEN_FOR_NAME);
}

verbose_end\ _open_for :: (name: string) {
    using context.sqlite_verbose;
    end := current_time_monotonic();
    seconds := cast(float) to_nanoseconds(end-open_for_begin) / cast(float) 1_000_000_000;
    print_color(" ", color=COLOR_SCHEME.OPEN_FOR_RULER); write_string("\n");
    print_color(" ", color=COLOR_SCHEME.OPEN_FOR_RULER);
    print_color(" %\n", ifx name else "(unnamed block)", color=COLOR_SCHEME.OPEN_FOR_NAME);
    with_console_color(COLOR_SCHEME.OPEN_FOR_RULER, write_string(tprint("    % seconds ", seconds)));

    write_string("\n\n");
    open_for_begin = .{};
}
