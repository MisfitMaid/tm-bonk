#if TMNEXT
bool isIceSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Ice ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::RoadIce ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Snow ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Concrete);
}

bool isPlasticSurface(EPlugSurfaceMaterialId surface) {
  return surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Plastic;
}

bool isDirtSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Dirt ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::DirtRoad);
}

bool isTarmacSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Concrete ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Asphalt ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::RoadSynthetic ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::TechMagnetic ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::TechSuperMagnetic);
}

bool isGrassSurface(EPlugSurfaceMaterialId surface) {
  return (surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Grass ||
    surface == CSceneVehicleVisState::EPlugSurfaceMaterialId::Green);
}

bool isPlasticDirtOrGrass(EPlugSurfaceMaterialId surface) {
  return isPlasticSurface(surface) ||
    isDirtSurface(surface) ||
    isGrassSurface(surface);
}
#endif
