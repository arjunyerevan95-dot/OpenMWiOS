#include "../../components/myguiplatform/viewportfit.hpp"
#include <iostream>
#include <stdexcept>
#include <vector>

void check(bool condition) { if (!condition) throw std::runtime_error("viewport fit invariant failed"); }
int main()
{
    using namespace MyGUIPlatform;
    struct Case { const char* name; int width, height; SafeArea safe; };
    const std::vector<Case> cases = {
        {"phone 2.17:1", 844, 390, {62.f/844, 0, 1-62.f/844, 1-21.f/390}},
        {"phone increased GUI scale", 675, 312, {62.f/844, 0, 1-62.f/844, 1-21.f/390}},
        {"narrow landscape", 640, 360, {}}, {"small logical viewport", 422, 195, {}},
        {"tablet", 1024, 768, {}}, {"narrow portrait", 360, 640, {}},
        {"normal desktop", 1280, 800, {}}, {"rotated safe area", 390, 844, {0, 62.f/844, 1, 1-21.f/844}}
    };
    for (const auto& test : cases)
    {
        // Exercise multiple measured/content heights, including longer localized level descriptions.
        for (int contentHeight : {450, 490, 620})
        {
            const auto f = fitViewport(test.width, test.height, 448, contentHeight, test.safe);
            check(f.scale > 0 && f.scale <= 1);
            const int left = (f.width-448)/2, top = (f.height-contentHeight)/2;
            check(f.left + left*f.scale >= test.safe.left*test.width);
            check(f.top + top*f.scale >= test.safe.top*test.height);
            check(f.left + (left+448)*f.scale <= test.safe.right*test.width+1);
            check(f.top + (top+contentHeight)*f.scale <= test.safe.bottom*test.height+1);
            // Both attribute columns, all four rows, and the confirmation footer must map back to their targets.
            for (int col=0; col<2; ++col) for (int row=0; row<4; ++row)
            {
                const int x=left+110+col*186, y=top+contentHeight-120+row*20;
                const int px=static_cast<int>(std::lround(f.left+x*f.scale));
                const int py=static_cast<int>(std::lround(f.top+y*f.scale));
                check(std::abs(f.toLayerX(px)-x) <= 2 && std::abs(f.toLayerY(py)-y) <= 2);
            }
            const int footerY=top+contentHeight-18;
            check(std::abs(f.toLayerY(static_cast<int>(std::lround(f.top+footerY*f.scale)))-footerY)<=2);
        }
        std::cout << test.name << ": bounds and all eight targets + footer pass\n";
    }
    check(fitViewport(1280,800,448,490,{}).scale == 1);
    check(fitViewport(1024,768,448,490,{}).scale == 1);
    check(fitViewport(844,390,448,490,{0,0,0,0}).scale > 0);
    std::cout << "Native size, safe-area validation and resize matrix pass\n";
}
