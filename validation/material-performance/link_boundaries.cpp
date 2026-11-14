// Only link boundaries outside this unit. Abort if a test inadvertently uses
// NIF file decoding or stereo rendering; no tested material logic is stubbed.
#include <components/nif/controller.hpp>
#include <components/nif/data.hpp>
#include <components/stereo/stereomanager.hpp>
#include <cstdlib>
namespace Nif {
void NiPosData::read(NIFStream*) { std::abort(); }
void NiTimeController::read(NIFStream*) { std::abort(); }
void NiTimeController::post(Reader&) { std::abort(); }
void NiInterpController::read(NIFStream*) { std::abort(); }
void NiSingleInterpController::read(NIFStream*) { std::abort(); }
void NiSingleInterpController::post(Reader&) { std::abort(); }
void NiMaterialColorController::read(NIFStream*) { std::abort(); }
void NiMaterialColorController::post(Reader&) { std::abort(); }
}
namespace Stereo {
bool getStereo() { std::abort(); }
Manager& Manager::instance() { std::abort(); }
Eye Manager::getEye(const osgUtil::CullVisitor*) const { std::abort(); }
}
