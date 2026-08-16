#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "shader_hacks.h"

static int validate_shader(char* shader)
{
    char* converted = ShaderHacks(shader);
    int result = 0;

    if (strstr(converted, "uniform bool useAdvancedShader = false;") != NULL)
        result = 10;
    else if (strstr(converted, "uniform bool useAdvancedShader;") == NULL)
        result = 11;
    else if (strstr(converted, "if(!useAdvancedShader)") == NULL)
        result = 12;

    if (converted != shader)
        free(converted);
    return result;
}

int main(void)
{
    char vertex[] =
        "#version 120\n"
        "uniform bool useAdvancedShader = false;\n"
        "void main()\n"
        "{\n"
        "    if(!useAdvancedShader) gl_Position = vec4(0.0);\n"
        "}\n";
    char fragment[] =
        "#version 120\n"
        "uniform bool useAdvancedShader = false;\n"
        "void main()\n"
        "{\n"
        "    if(!useAdvancedShader) gl_FragColor = vec4(1.0);\n"
        "}\n";

    int vertex_result = validate_shader(vertex);
    int fragment_result = validate_shader(fragment);
    if (vertex_result != 0)
        return vertex_result;
    if (fragment_result != 0)
        return fragment_result + 10;

    puts("debug uniform initializer removed; declaration and references preserved");
    return 0;
}
