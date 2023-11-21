class BonkStateManager {
    Audio::Sample@ bonkSound; 

    BonkStateManager() {
        @bonkSound = Audio::LoadSample("bonk.wav");
    }

#if TMNEXT||MP4

    int idx = 0;

    bool bonk;

    vec3 prevVel;
    vec3 prevVelNorm;
    float prevVelLength;
    vec3 prevVdt;

    uint64 lastBonkTime;
    vec3 lastBonkVdtdt;

    int prevWheelContactCount;

    array<int> wheelContactCountArr(10);

    void drawVec3(CSceneVehicleVisState@ visState, vec3 v, vec4 c) {
        nvg::BeginPath();
        nvg::MoveTo(Camera::ToScreenSpace(visState.Position));
        nvg::LineTo(Camera::ToScreenSpace(visState.Position + v));
        nvg::StrokeColor(c);
        nvg::Stroke();
        nvg::ClosePath();
    }
    /* To be called once per frame. */ 
    void handleBonkCall(CSceneVehicleVisState@ visState) {
        /* 🎶 business logic 🎶 */ 
        if (debug) // i tried really-ish hard to make this actually follow the car lmao, couldn't grok it 
            drawVec3(visState, lastBonkVdtdt, vec4(1, 0, 0, 1));

        vec3 v = visState.WorldVel;
        float vLen = v.Length();

#if TMNEXT
        int wheelContactCount = notContactCheck(visState, EPlugSurfaceMaterialId::XXX_Null);
#elif MP4
        int wheelContactCount = notContactCheck(visState);
#endif
        wheelContactCountArr[idx] = wheelContactCount;
        
        vec3 vdt = v - prevVel; 
        float vdtUp = Math::Dot(vdt, visState.Up);
        vdt = vdt - visState.Up * vdtUp;
        if (Math::Dot(vdt, visState.Dir) > 0) {
            vdt = vdt - visState.Dir * (Math::Dot(vdt, visState.Dir));
        }

        vec3 vdtdt = vdt - prevVdt;

        if (
            (lastBonkTime < Time::Now - bonkDebounce) && 
            (prevVelLength > 10) &&
            mainBonkDetect && 
            (
                (wheelContactCount == 4 && prevWheelContactCount == 4 && 
                (vdtdt.Length() > wheels_contacting_sensitivity))
                || 
                ((wheelContactCount != 4 && prevWheelContactCount != 4) && 
                (vdtdt.Length() > wheels_in_air_sensitivity))
            )
            ) {
            lastBonkTime = Time::Now;
            Audio::Play(bonkSound, bonkSoundGain);
            startBonkFlash();
            if (debug) {
                print("Bonk intensity: " + tostring(vdtdt.Length()));
                lastBonkVdtdt = vdtdt.Normalized(); // helps make rendering cleaner - this + tracing the length is all that's needed. 
            }
        }
        
        prevVelLength = vLen;
        prevVel = v;
        prevWheelContactCount = wheelContactCount;
        prevVdt = vdt;
        idx = (idx + 1) % 10;
        return;
    }

    int sumWheelContactCountArr() {
        int r = 0;
        for (int i = 0; i < 10; i++) {
            r += wheelContactCountArr[i];
        }
        print(r);
        return r;
    }
#endif

#if TMNEXT
    int notContactCheck(CSceneVehicleVisState@ visState, EPlugSurfaceMaterialId surface) {
        return 
            (visState.FLGroundContactMaterial != surface ? 1 : 0) +
            (visState.FRGroundContactMaterial != surface ? 1 : 0) +
            (visState.RLGroundContactMaterial != surface ? 1 : 0) +
            (visState.RRGroundContactMaterial != surface ? 1 : 0);
    }
#elif MP4
    int notContactCheck(CSceneVehicleVisState@ visState) {
        return
            (visState.FLGroundContact ? 1 : 0) +
            (visState.FRGroundContact ? 1 : 0) +
            (visState.RLGroundContact ? 1 : 0) +
            (visState.RRGroundContact ? 1 : 0);
    }
#endif
}
