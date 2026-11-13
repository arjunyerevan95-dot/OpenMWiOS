#include "apps/openmw/ios/openmw_ios_touch_model.hpp"
#include <cassert>
#include <iostream>
using namespace OpenMWIOS::Touch;
int main() {
 assert(supportedProfileControlCount(12)); assert(supportedProfileControlCount(13));
 assert(!supportedProfileControlCount(11)); assert(!supportedProfileControlCount(14));
 auto layout=makeLayout(844,390,{0,47,21,47});
 Point attack{}; for(auto& b:layout.buttons) if(b.action==Action::Attack) attack=b.bounds.center;
 Ownership o;
 auto a=o.begin(1,attack,layout); assert(a && a->action==Action::Attack);
 assert(drivesLook(*a));
 auto drag=o.move(1,{attack.x+20,attack.y-10}); assert(drag && drivesLook(*drag));
 assert(drag->lastPoint.x==attack.x && o.bindings().at(1).action==Action::Attack);
 // Find empty right-side gameplay surface, independent of actual layout geometry.
 Point aim{}; bool found=false;
 for(int y=30;y<350&&!found;y+=10) for(int x=440;x<790&&!found;x+=10) {
  auto b=o.begin(2,{float(x),float(y)},layout);
  if(b && b->role==Role::Look) { aim={float(x),float(y)}; found=true; }
  else o.end(2);
 }
 assert(found);
 auto look=o.move(2,{aim.x+30,aim.y+15}); assert(look && drivesLook(*look));
 assert(o.bindings().at(1).action==Action::Attack);
 o.end(2); assert(o.bindings().at(1).action==Action::Attack);
 assert(o.end(1)->action==Action::Attack); assert(o.bindings().empty());
 assert(!drivesLook({Role::Button,Action::Jump,{},{}}));
 o.begin(1,attack,layout); o.clear(); assert(!o.move(1,attack));
 Point parry{},jump{};
 for(auto& b:layout.buttons) {if(b.action==Action::Parry)parry=b.bounds.center; if(b.action==Action::Jump)jump=b.bounds.center;}
 auto formerParry=o.begin(3,parry,layout); assert(formerParry && formerParry->role==Role::Look);
 assert(o.begin(4,jump,layout)->action==Action::Jump);
 assert(drivesLook(*o.move(3,{parry.x+20,parry.y})));
 o.end(3); assert(o.bindings().at(4).action==Action::Jump); o.clear();
 std::cout<<"PASS held Attack drag, independent swipe, release and cancellation\n";
}
