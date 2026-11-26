#ifndef OPENMW_COMPONENTS_SETTINGS_CATEGORIES_HUD_H
#define OPENMW_COMPONENTS_SETTINGS_CATEGORIES_HUD_H

#include <components/settings/settingvalue.hpp>

#include <osg/Math>
#include <osg/Vec2f>
#include <osg/Vec3f>

#include <cstdint>
#include <string>
#include <string_view>

namespace Settings
{
    struct HUDCategory : WithIndex
    {
        using WithIndex::WithIndex;

        static constexpr int sMinScale = 70;
        static constexpr int sMaxScale = 130;
        static constexpr int sDefaultScale = 100;

        SettingValue<bool> mCrosshair{ mIndex, "HUD", "crosshair" };
        SettingValue<bool> mMouseEmulationCursor{ mIndex, "HUD", "mouse emulation cursor" };
        SettingValue<int> mIosScale{ mIndex, "HUD", "ios scale", makeClampSanitizerInt(sMinScale, sMaxScale) };
    };
}

#endif
