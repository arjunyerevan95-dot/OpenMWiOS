#ifndef OPENMW_MYGUIPLATFORM_VIEWPORTFIT_H
#define OPENMW_MYGUIPLATFORM_VIEWPORTFIT_H

#include <algorithm>
#include <cmath>

namespace MyGUIPlatform
{
    // Fractions of the full logical viewport, independent of drawable density and GUI scale.
    struct SafeArea
    {
        float left = 0, top = 0, right = 1, bottom = 1;
    };

    struct ViewportFit
    {
        int width, height;
        float scale, left, top;

        int toLayerX(int x) const { return static_cast<int>(std::floor((x - left) / scale)); }
        int toLayerY(int y) const { return static_cast<int>(std::floor((y - top) / scale)); }
    };

    inline ViewportFit fitViewport(int viewWidth, int viewHeight, int contentWidth, int contentHeight, SafeArea safe)
    {
        viewWidth = std::max(viewWidth, 1);
        viewHeight = std::max(viewHeight, 1);
        if (!(safe.left >= 0 && safe.top >= 0 && safe.right <= 1 && safe.bottom <= 1
                && safe.right > safe.left && safe.bottom > safe.top))
            safe = {};
        const float availableWidth = std::max((safe.right - safe.left) * viewWidth, 1.f);
        const float availableHeight = std::max((safe.bottom - safe.top) * viewHeight, 1.f);
        // Preserve native size when it fits. The padding keeps borders and the footer inside the safe rectangle.
        const int width = std::max(static_cast<int>(std::ceil(availableWidth)), contentWidth + 16);
        const int height = std::max(static_cast<int>(std::ceil(availableHeight)), contentHeight + 16);
        const float scale = std::min({ 1.f, availableWidth / width, availableHeight / height });
        return { width, height, scale, safe.left * viewWidth + (availableWidth - width * scale) / 2,
            safe.top * viewHeight + (availableHeight - height * scale) / 2 };
    }
}
#endif
