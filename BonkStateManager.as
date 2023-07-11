class BonkStateManager {
    Audio::Sample@ pipeSound;
    Audio::Sample@ bonkSound; 

    BonkStateManager() {
        @pipeSound = Audio::LoadSample("pipe.wav");
        @bonkSound = Audio::LoadSample("bonk.wav");
    }

    float pi = 3.141592653589793238462643383279502884197;
    float pi2 = pi / 2;
    float pi4 = pi / 4;
    float pi10 = pi / 10; 

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


    int minGap = 1000; 

    float ROOFHIT_VEL_CHANGE_THRESH = 0.4;
    
    int prevWheelContactCount;
    vec4 prevSuspensionParams;

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

        vec3 v = visState.WorldVel;
        vec3 vNorm = v.Normalized();
        float vLen = v.Length();

        vec4 suspensionParams = vec4(
            visState.FLDamperLen,
            visState.FRDamperLen, 
            visState.RLDamperLen,
            visState.RRDamperLen
        );

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
            Audio::Play(pipeSound, 0.3);
            return;
        }
        
        vec3 vdt = v - prevVel; 
        vdt = vdt - visState.Up * (Math::Dot(vdt, visState.Up));

        if (Math::Dot(vdt, visState.Dir) > 0) {
            vdt = vdt - visState.Dir * (Math::Dot(vdt, visState.Dir));
        }

        float vdtL = vdt.Length();
        vec3 vdtdt = vdt - prevVdt;




        // Case: roofhit
        // Is the force opposite in direction to the up vector? 
        // Also we only want to roofhit when we are pointing down - otherwise it will be overdone and not funny
        if (
            (lastPipeTime < Time::Now - 1000) && 
            (prevVelLength > 10) &&
            (vLen > 3) && 
            vdtL > (vLen * 0.1) && 
            pipeCountDown == -1 && 
            (Math::Dot(visState.Up, vec3(0, -1, 0)) > 0) &&
            sumWheelContactCountArr() == 0
            ) {
                pipeCountDown = 3;
            }
        if (
            (lastBonkTime < Time::Now - 1000) && 
            (prevVelLength > 10) &&
            (
                (wheelContactCount == 4 && prevWheelContactCount == 4 && 
                (vdtdt.Length() > 2))
                || 
                ((wheelContactCount != 4 && prevWheelContactCount != 4) && 
                (vdtdt.Length() > 4))
            )
            ) {
            lastBonkTime = Time::Now;
            Audio::Play(bonkSound, 0.5);
            startBonkFlash();
            lastBonkVdtdt = vdtdt;
        }
        // drawVec3(visState, vec3(0, -1, 0), vec4(1, 0, 0, 1));


        prevVelLength = vLen;
        prevVel = v;
        prevWheelContactCount = wheelContactCount;
        prevSuspensionParams = suspensionParams;
        prevVdt = vdt;
        idx = (idx + 1) % 10;
        return;
    }

    bool getBonk() {
        return this.bonk;
    }

    int sumWheelContactCountArr() {
        int r = 0;
        for (int i = 0; i < 10; i++) {
            r += wheelContactCountArr[i];
        }
        print(r);
        return r;
    }

    int andContactCheck(CSceneVehicleVisState@ visState, EPlugSurfaceMaterialId surface) {
        return 
            (visState.FLGroundContactMaterial == surface ? 1 : 0) +
            (visState.FRGroundContactMaterial == surface ? 1 : 0) +
            (visState.RLGroundContactMaterial == surface ? 1 : 0) +
            (visState.RRGroundContactMaterial == surface ? 1 : 0);
    }

    int notContactCheck(CSceneVehicleVisState@ visState, EPlugSurfaceMaterialId surface) {
        return 
            (visState.FLGroundContactMaterial != surface ? 1 : 0) +
            (visState.FRGroundContactMaterial != surface ? 1 : 0) +
            (visState.RLGroundContactMaterial != surface ? 1 : 0) +
            (visState.RRGroundContactMaterial != surface ? 1 : 0);
    }


}