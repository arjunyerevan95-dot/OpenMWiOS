#include "apps/openmw/mwrender/occlusionculling.hpp"
#include <osg/Geometry>
#include <osg/Group>
#include <osg/AlphaFunc>
#include <cassert>
int main(){
 osg::ref_ptr<osg::Geometry> g = new osg::Geometry;
 osg::ref_ptr<osg::Vec3Array> v=new osg::Vec3Array;
 v->push_back({0,0,0}); v->push_back({2,0,0}); v->push_back({0,2,0});
 g->setVertexArray(v); g->addPrimitiveSet(new osg::DrawArrays(GL_TRIANGLES,0,3));
 osg::ref_ptr<osg::Group> root=new osg::Group, mid=new osg::Group;
 root->addChild(mid);mid->addChild(g);
 auto m=MWRender::buildSimplifiedMesh(root,1,0.2);
 assert(m.indices.size()==3 && m.vertices.size()==3);
 for(unsigned i=0;i<3;++i) assert(m.vertices[i]==(*v)[i]);
 root->getOrCreateStateSet()->setAttribute(new osg::AlphaFunc);
 assert(MWRender::buildSimplifiedMesh(root,8,1).indices.empty());
 root->getOrCreateStateSet()->removeAttribute(osg::StateAttribute::ALPHAFUNC);
 root->getOrCreateStateSet()->setMode(GL_BLEND,osg::StateAttribute::ON);
 assert(MWRender::buildSimplifiedMesh(root,8,1).indices.empty());
 root->getOrCreateStateSet()->setMode(GL_BLEND,osg::StateAttribute::OFF);
 assert(MWRender::buildSimplifiedMesh(root,8,1).indices.size()==3);
 // Triangle cap removes whole original primitives without creating coverage.
 g->removePrimitiveSet(0,g->getNumPrimitiveSets());
 osg::ref_ptr<osg::DrawElementsUInt> many=new osg::DrawElementsUInt(GL_TRIANGLES);
 for(unsigned i=0;i<1100;++i){many->push_back(0);many->push_back(1);many->push_back(2);}
 g->addPrimitiveSet(many);
 auto capped=MWRender::buildSimplifiedMesh(root,1,.1);
 assert(capped.indices.size()==1024*3 && capped.vertices.size()==3);
 for(unsigned i=0;i<3;++i) assert(capped.vertices[i]==(*v)[i]);
}
