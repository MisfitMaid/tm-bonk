
class BonkStateManager {
    Audio::Sample@ pipeSound;
    Audio::Sample@ bonkSound; 

    BonkStateManager() {
        @pipeSound = Audio::LoadSample("pipe.wav");
        @bonkSound = Audio::LoadSample("bonk.wav");
    }

#if TMNEXT

    int idx = 0;

    bool bonk;
    bool pipe;

    vec3 prevVel;
    vec3 prevVelNorm;
    float prevVelLength;
    vec3 prevVdt;

    uint64 lastBonkTime;
    uint64 lastPipeTime = 0;
    vec3 lastBonkVdtdt;

    int prevWheelContactCount;

    array<int> wheelContactCountArr(10);

    int pipeCountDown = -1;

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

        int wheelContactCount = notContactCheck(visState, EPlugSurfaceMaterialId::XXX_Null);
        wheelContactCountArr[idx] = wheelContactCount;

        if (pipeCountDown > 0) {
            if (wheelContactCount == 0) {
                pipeCountDown -= 1;
            } else {
                pipeCountDown = -1;
            } 
        } else if (pipeCountDown == 0) {
            pipeCountDown = -1;
            lastPipeTime = Time::Now;
            Audio::Play(pipeSound, pipeSoundGain);
            return;
        }
        
        vec3 vdt = v - prevVel; 
        float vdtUp = Math::Dot(vdt, visState.Up);
        vdt = vdt - visState.Up * vdtUp;
        if (Math::Dot(vdt, visState.Dir) > 0) {
            vdt = vdt - visState.Dir * (Math::Dot(vdt, visState.Dir));
        }

        vec3 vdtdt = vdt - prevVdt;

        // Case: roofhit
        // Is the force opposite in direction to the up vector? 
        // Also we only want to roofhit when we are pointing down - otherwise it will be overdone and not funny
        // We also check to make sure we were falling for at least 10 frames beforehand, plus we start this countdown
        // to ensure that we don't touch the ground with any wheel for 3 frames after. 
        if (
            (lastPipeTime < Time::Now - pipeDebounce) && 
            (prevVelLength > 10) &&
            (vLen > 3) && 
            Math::Abs(vdtUp) > (vLen * 0.1) && 
            pipeCountDown == -1 && 
            (Math::Dot(visState.Up, vec3(0, -1, 0)) > 0.9) &&
            sumWheelContactCountArr() == 0 && 
            mainBonkDetect
            ) {
                pipeCountDown = 3;
            }
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

    int notContactCheck(CSceneVehicleVisState@ visState, EPlugSurfaceMaterialId surface) {
        return 
            (visState.FLGroundContactMaterial != surface ? 1 : 0) +
            (visState.FRGroundContactMaterial != surface ? 1 : 0) +
            (visState.RLGroundContactMaterial != surface ? 1 : 0) +
            (visState.RRGroundContactMaterial != surface ? 1 : 0);
    }

#endif
}