#include "../../apps/openmw/ios/openmw_ios_parry_gesture.hpp"
#include "../../apps/openmw/ios/openmw_ios_touch_model.hpp"
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
 g.begin(1,900,300,1); assert(g.pressed(1,true));
 assert(!g.move(1,200,800,x,y)); assert(g.pressed(1.2,true));
 g.finish(1,1.3,false); assert(!g.pressed(1.3,true));
 g.begin(2,900,300,2); assert(g.pressed(2,true)); g.finish(2,2.01,true); assert(!g.pressed(2.01,true));
 g.begin(3,900,300,3); assert(!g.pressed(3,false)); assert(!g.pressed(3.1,true));
 using namespace OpenMWIOS::Touch;
 auto layout=makeLayout(1000,500,{});
 assert(inParryZone({990,150},layout));
 assert(!inParryZone({990,480},layout));
 assert(!inParryZone({500,150},layout));
 assert(!inParryZone({0,0},Layout{}));
 auto inset=makeLayout(844,390,{0,47,21,47});
 assert(inParryZone({790,120},inset));
 assert(!inParryZone({790,350},inset));
 Ownership owner;
 // Empty upper-right gap, lower-right aim, and left movement coexist.
 auto parry=owner.begin(10,{990,150},layout,true);
 assert(parry && parry->role==Role::Parry && !drivesLook(*parry));
 assert(!owner.begin(11,{990,150},layout,true));
 auto aim=owner.begin(12,{800,480},layout,true);
 assert(aim && aim->role==Role::Look && drivesLook(*aim));
 auto move=owner.begin(13,{100,400},layout,true);
 assert(move && move->role==Role::Movement);
 auto drag=owner.move(10,{500,450}); assert(drag && drag->role==Role::Parry && !drivesLook(*drag));
 owner.end(10); assert(owner.begin(14,{990,150},layout,true)->role==Role::Parry);
 Ownership menu; assert(!menu.begin(15,{990,150},layout,false));
}
