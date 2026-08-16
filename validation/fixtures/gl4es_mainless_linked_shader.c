#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "string_utils.h"

static int run_legacy_path(void)
{
    char helper[] =
        "vec4 helperFunction(vec4 value)\n"
        "{\n"
        "    return value;\n"
        "}\n";

    /* This is the pre-fix production expression. It must fault for the fixture. */
    return strchr(gl4es_find_string_nc(helper, "main"), '{') != NULL;
}

static int run_fixed_path(void)
{
    const char* entry_text =
        "void main()\n"
        "{\n"
        "    gl_Position = vec4(0.0);\n"
        "}\n";
    char helper[] =
        "vec4 helperFunction(vec4 value)\n"
        "{\n"
        "    return value;\n"
        "}\n";
    char malformed[] = "void main()";
    const char clip_insert[] = "\n_gl4es_ClipVertex = gl_Position;";
    int capacity = (int)strlen(entry_text) + (int)strlen(clip_insert) + 32;
    char* entry = malloc((size_t)capacity);
    char* body;

    if (!entry)
        return 10;
    strcpy(entry, entry_text);

    if (gl4es_find_string_opening_brace(helper, "main") != NULL) {
        free(entry);
        return 11;
    }
    if (gl4es_find_string_opening_brace(malformed, "main") != NULL) {
        free(entry);
        return 12;
    }

    body = gl4es_find_string_opening_brace(entry, "main");
    if (!body) {
        free(entry);
        return 13;
    }

    entry = gl4es_inplace_insert(body + 1, clip_insert, entry, &capacity);
    if (!strstr(entry, "{\n_gl4es_ClipVertex = gl_Position;")) {
        free(entry);
        return 14;
    }

    puts("main-less helper skipped; entry-point shader transformed");
    free(entry);
    return 0;
}

int main(int argc, char** argv)
{
    if (argc != 2)
        return 2;
    if (strcmp(argv[1], "legacy") == 0)
        return run_legacy_path();
    if (strcmp(argv[1], "fixed") == 0)
        return run_fixed_path();
    return 3;
}
