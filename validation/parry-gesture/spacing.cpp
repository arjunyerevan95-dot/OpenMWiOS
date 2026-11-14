#include "../../apps/openmw/ios/openmw_ios_touch_model.hpp"
#include <cassert>
#include <cmath>
using namespace OpenMWIOS::Touch;
int main(){
 for(float w:{844.f,1000.f,1536.f}) {
 auto l=makeLayout(w,w*707/1536,{0,0,0,0});
 const auto& pause=l.buttons[static_cast<int>(Action::Pause)].bounds;
 assert(std::abs(pause.center.y-(l.height*.145f+pause.radius))<.01f);
 assert(inParryZone({l.width*.95f,l.height*.4f},l));
 assert(!inParryZone({l.width*.95f,l.height*.8f},l));
 auto p=profileFromLayout(l);p.customized=true;
 for(auto&b:p.buttons){b.center={.5f,.5f};b.radius=.1f;}
 applyProfile(l,p);
 for(auto&b:l.buttons){assert(std::abs(b.bounds.center.x-l.width*.5f)<.01f);assert(std::abs(b.bounds.center.y-l.height*.5f)<.01f);assert(std::abs(b.bounds.radius-l.height*.1f)<.01f);}
 }
 auto l=makeLayout(844,390,{80,47,21,47});
 assert(l.buttons[static_cast<int>(Action::Pause)].bounds.center.y>=80);
}
