#include <stdio.h>
#include <string.h>

typedef struct
{
    const char* site;
    int value;
    const char* context;
} blend_event;

static const char* classify(const blend_event* events, int count)
{
    const blend_event* osg_enable = NULL;
    const blend_event* gl4es_enable = NULL;
    const blend_event* common = NULL;
    int replay = 0;
    for (int index = 0; index < count; ++index)
    {
        const blend_event* event = &events[index];
        if (!strcmp(event->site, "osg") && event->value == 1 && !osg_enable)
            osg_enable = event;
        else if (!strcmp(event->site, "gl4es") && event->value == 1 && !gl4es_enable)
            gl4es_enable = event;
        else if (!strcmp(event->site, "replay"))
            replay = 1;
        else if (!strcmp(event->site, "common") && !common)
            common = event;
    }
    if (osg_enable && !gl4es_enable)
        return "route-not-exercised";
    if (gl4es_enable && common && strcmp(gl4es_enable->context, common->context))
        return "different-context";
    if (gl4es_enable && common && gl4es_enable->value == 1 && common->value == 0)
        return replay ? "render-list-replay" : "later-disable";
    return "consistent";
}

static void report(const char* name, const blend_event* events, int count)
{
    printf("%s=%s\n", name, classify(events, count));
}

int main(void)
{
    const blend_event enable_only[] = {
        { "osg", 1, "A" }, { "gl4es", 1, "A" }, { "common", 1, "A" }
    };
    const blend_event enable_disable[] = {
        { "osg", 1, "A" }, { "gl4es", 1, "A" }, { "gl4es", 0, "A" }, { "common", 0, "A" }
    };
    const blend_event different_context[] = {
        { "osg", 1, "A" }, { "gl4es", 1, "A" }, { "common", 0, "B" }
    };
    const blend_event replay[] = {
        { "osg", 1, "A" }, { "gl4es", 1, "A" }, { "replay", 0, "A" }, { "common", 0, "A" }
    };
    const blend_event missing_route[] = {
        { "osg", 1, "A" }, { "common", 0, "A" }
    };
    report("enable-only", enable_only, 3);
    report("enable-disable", enable_disable, 4);
    report("different-context", different_context, 3);
    report("render-list", replay, 4);
    report("missing-route", missing_route, 2);
    return 0;
}
