#include "../../apps/openmw/ios/openmw_ios_use_gesture.hpp"
#include <cassert>
using OpenMWIOS::Touch::UseGesture;
int main() {
 UseGesture g; using E=UseGesture::End;
 assert(g.begin(1,0)); assert(!g.begin(2,0)); assert(!g.update(.2));
 assert(g.finish(2,.2,false)==E::None); assert(g.finish(1,.2,false)==E::Tap);
 assert(g.begin(1,1)); assert(g.update(1.4)); assert(!g.update(1.5)); assert(g.finish(1,1.6,false)==E::Drop);
 assert(g.begin(1,2)); assert(g.finish(1,2.1,true)==E::None);
 assert(g.begin(1,3)); assert(g.update(3.4)); assert(g.finish(1,3.5,true)==E::Drop);
 assert(g.begin(1,4)); assert(g.finish(1,4.8,false)==E::None); // stalled frame: no accidental pickup
 assert(g.begin(1,5)); assert(g.update(5.4)); g.cancel(); assert(!g.touch()); assert(!g.update(6));
}
