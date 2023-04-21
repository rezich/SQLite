// This file and all of its contents will likely be removed in the very near future.

Model_Info :: struct {
    name: string;
    plural: string;
    fields: Table(string, *Field_Info);
}
Field_Info :: struct {
    tag: enum {
        INTEGER;
        FLOAT;
        BOOL;
        STRING;

        FOREIGN_KEY;
        ONE_TO_MANY;
    }
    name: string;
}
Field_Info_Integer :: struct {
    using #as info: Field_Info;
}
Field_Info_Float :: struct {
    using #as info: Field_Info;
}
Field_Info_Bool :: struct {
    using #as info: Field_Info;
}
Field_Info_String :: struct {
    using #as info: Field_Info;
}
Field_Info_Foreign_Key :: struct {
    using #as info: Field_Info;
    foreign_table: string;
}
Field_Info_One_To_Many :: struct {
    using #as info: Field_Info;
    foreign_key: string;
}

model_infos: Table(string, Model_Info);

#scope_file
#import "Hash_Table";
