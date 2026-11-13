#include "../../apps/openmw/ios/openmw_ios_parry_gesture.hpp"
#include <cassert>
using OpenMWIOS::Touch::ParryGesture;
int main() {
 int playerQueries=0;
 auto query=[&] { ++playerQueries; return true; };
 using OpenMWIOS::Touch::weaponReadyForInput;
 assert(!weaponReadyForInput(true,true,false,false,query)); // loading before world exists
 assert(!weaponReadyForInput(false,false,false,false,query)); // initial menu, no player
 assert(!weaponReadyForInput(true,false,true,false,query)); // loading save
 assert(!weaponReadyForInput(false,true,true,false,query));
 assert(!weaponReadyForInput(false,false,true,true,query)); // inventory/modal
 assert(playerQueries==0);
 assert(weaponReadyForInput(false,false,true,false,query));
 assert(playerQueries==1);
 assert(!weaponReadyForInput(false,false,true,false,[]{return false;}));

 ParryGesture g; float x=0,y=0;
 g.begin(1,100,100,1); assert(!g.pressed(1.02,true)); g.finish(1,1.04,false); assert(g.pressed(1.05,true)); assert(!g.pressed(1.2,true));
 g.begin(2,100,100,2); assert(g.pressed(2.1,true)); assert(g.pressed(3,true)); g.finish(2,3.1,false); assert(!g.pressed(3.1,true));
 g.begin(3,100,100,4); assert(!g.move(3,103,102,x,y)); assert(g.move(3,110,104,x,y)); assert(x==10 && y==4); assert(!g.pressed(4.2,true)); g.finish(3,4.3,false); assert(!g.pressed(4.3,true));
 g.begin(4,100,100,5); assert(g.pressed(5.1,true)); assert(g.move(4,111,100,x,y)); assert(!g.pressed(5.2,true));
 g.begin(5,0,0,6); assert(!g.pressed(6.2,false)); assert(!g.pressed(6.3,true));
 g.begin(6,0,0,7); g.finish(6,7.01,true); assert(!g.pressed(7.02,true));
 g.begin(7,0,0,8); assert(g.pressed(8.1,true));g.cancel();assert(!g.pressed(8.2,true));
}
