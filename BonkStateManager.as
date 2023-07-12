
[Setting name="pipe?"]
bool pipe_enabled = true;

[Setting name="bonk wheels on ground sensitivity (higher is lower)" drag min=1 max=10]
float wheels_on_the_bus = 2;

[Setting name="bonk wheels off ground sensitivity (higher is lower)" drag min=1 max=10]
float wheels_off_the_bus = 4;

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
        if (getCurrentRunTime() < 1000) {
            return;
        }

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
            Audio::Play(pipeSound, 0.3);
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
            (lastPipeTime < Time::Now - 1000) && 
            (prevVelLength > 10) &&
            (vLen > 3) && 
            Math::Abs(vdtUp) > (vLen * 0.1) && 
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
                (vdtdt.Length() > wheels_on_the_bus))
                || 
                ((wheelContactCount != 4 && prevWheelContactCount != 4) && 
                (vdtdt.Length() > wheels_off_the_bus))
            )
            ) {
            lastBonkTime = Time::Now;
            Audio::Play(bonkSound, 0.5);
            startBonkFlash();
            lastBonkVdtdt = vdtdt;
        }
        // drawVec3(visState, lastBonkVdtdt, vec4(1, 0, 0, 1));
        prevVelLength = vLen;
        prevVel = v;
        prevWheelContactCount = wheelContactCount;
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

    int notContactCheck(CSceneVehicleVisState@ visState, EPlugSurfaceMaterialId surface) {
        return 
            (visState.FLGroundContactMaterial != surface ? 1 : 0) +
            (visState.FRGroundContactMaterial != surface ? 1 : 0) +
            (visState.RLGroundContactMaterial != surface ? 1 : 0) +
            (visState.RRGroundContactMaterial != surface ? 1 : 0);
    }

    CSmArenaClient@ getPlayground() {
        return cast < CSmArenaClient > (GetApp().CurrentPlayground);
    }
     
    int getCurrentGameTime() {
        return getPlayground().Interface.ManialinkScriptHandler.GameTime;
    }

    int getCurrentRunTime() {
        return getCurrentGameTime() - getPlayerStartTime();
    }

    int getPlayerStartTime() {
        return getPlayer().StartTime;
    }

        CSmPlayer@ getPlayer() {
        auto playground = getPlayground();
        if (playground!is null) {
            if (playground.GameTerminals.Length > 0) {
                CGameTerminal @ terminal = cast < CGameTerminal > (playground.GameTerminals[0]);
                CSmPlayer @ player = cast < CSmPlayer > (terminal.GUIPlayer);
                if (player!is null) {
                    return player;
                }   
            }
        }
        return null;
    }

#endif
}