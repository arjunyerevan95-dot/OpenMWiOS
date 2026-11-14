#include "../../apps/openmw/ios/openmw_ios_menu_touch.hpp"
#include <cassert>
#include <cmath>
#include <iostream>
using OpenMWIOS::Touch::MenuTouch;
int main()
{
    MenuTouch g;
    assert(!g.begin(0, 0, 0));
    assert(g.begin(1, 100, 200));
    assert(!g.begin(2, 200, 300));
    assert(g.move(2, 500, 500) == 0);
    assert(g.move(1, 102, 201) == 0);
    assert(g.finish(1, false));
    assert(!g.finish(1, false));
    g.begin(1, 100, 200);
    assert(g.move(1, 100, 164) == -1);
    assert(g.move(1, 100, 128) == -1);
    assert(g.move(1, 100, 164) == 1);
    assert(!g.finish(1, false));
    g.begin(1, 100, 200);
    assert(g.move(1, 64, 200) == -1);
    assert(g.move(1, 28, 210) == -1); // locked horizontal axis
    assert(g.x() == 100 && g.y() == 200); // hover remains original widget
    assert(!g.finish(1, false));
    g.begin(1, 0, 0);
    assert(!g.finish(1, true));
    g.begin(1, 0, 0); g.cancel();
    assert(!g.owns(1) && !g.finish(1, false));
    g.begin(2, 0, 0);
    assert(std::abs(g.move(2, 0, 9) - 0.25f) < 0.001f);
    assert(!g.finish(2, false));
    g.begin(3, 100, 100, 10.0);
    assert(g.move(3, 103, 100, 10.2) == 0 && !g.dragging());
    assert(g.move(3, 120, 100, 10.5) == 0 && g.dragging());
    assert(g.move(3, 150, 125, 10.6) == 0 && g.dragging());
    assert(g.currentX() == 150 && g.currentY() == 125);
    assert(!g.finish(3, false) && !g.dragging());
    g.begin(4, 0, 0, 10.0);
    g.move(4, 30, 0, 10.1); // a quick scroll never changes to drag later
    g.move(4, 60, 0, 11.0);
    assert(!g.dragging());
    g.cancel();
    g.begin(5, 0, 0, 10.0); g.move(5, 30, 0, 10.5);
    assert(g.dragging());
    assert(!g.finish(5, true) && !g.dragging());
    g.begin(6, 0, 0, 10.0); g.move(6, 30, 0, 10.5);
    assert(g.dragging()); g.cancel(); assert(!g.dragging());
    std::cout << "PASS menu tap/select, natural vertical/horizontal drag, axis lock, cancellation, single ownership\n";
}
