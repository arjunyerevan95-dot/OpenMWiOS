#include "MaskedOcclusionCulling.h"
#include <cassert>
int main() {
 auto* c=MaskedOcclusionCulling::Create(); assert(c);
 c->SetResolution(512,256);c->SetNearClipPlane(.1);c->ClearBuffer();
 assert(c->TestRect(-.1,-.1,.1,.1,10)!=MaskedOcclusionCulling::OCCLUDED);
 const float v[]={-1.5,-1.5,0,2,1.5,-1.5,0,2,1.5,1.5,0,2,-1.5,1.5,0,2};
 const unsigned i[]={0,1,2,0,2,3};
 c->RenderTriangles(v,i,2,nullptr,MaskedOcclusionCulling::BACKFACE_NONE,MaskedOcclusionCulling::CLIP_PLANE_ALL);
 assert(c->TestRect(-.1,-.1,.1,.1,10)==MaskedOcclusionCulling::OCCLUDED);
 assert(c->TestRect(-.1,-.1,.1,.1,1)!=MaskedOcclusionCulling::OCCLUDED);
 c->ClearBuffer(); assert(c->TestRect(-.1,-.1,.1,.1,10)!=MaskedOcclusionCulling::OCCLUDED);
 MaskedOcclusionCulling::Destroy(c);
}
