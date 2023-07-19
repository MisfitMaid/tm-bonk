[Setting name="Enable Bonk! sound effect"]
bool enableBonkSound = true;

[Setting name="Enable Bonk! visual effect"]
bool enableBonkFlash = true;

[Setting min=0 max=100 name="Bonk threshold" description="How sensitive the Bonk! detection is. If you get many false positives, increase this value."]
float bonkThresh = 64.f;

[Setting min=0 max=60000 name="Bonk debounce" description="Length (in ms) to cool down before making additional Bonk! sounds."]
uint bonkDebounce = 500;

[Setting min=0 max=1 name="Bonk! chance" description="Probability of a Bonk! sound occurring once the threshold is met."]
float bonkSoundChance = 1.0f;

[Setting min=0 max=1 name="Bonk! volume"]
float bonkSoundGain = 0.4f;


void Main() {
	init();
	while (true) {
		step();
		yield();
	}
}

Audio::Sample@ bonkSound;
void init() {
	@bonkSound = Audio::LoadSample("bonk.wav");
}

float prev_speed = 0;
uint64 lastBonk = 0;

float bonkTargetThresh = 0.f;
float detectedBonkVal = 0.f;

void step() {
	try {
	if (VehicleState::GetViewingPlayer() is null) return;
	} catch { return; }
	CSceneVehicleVisState@ vis = VehicleState::ViewingPlayerState();
	if (vis is null) return;

	if (GetApp().CurrentPlayground is null || (GetApp().CurrentPlayground.UIConfigs.Length < 1)) return;
	if (GetApp().CurrentPlayground.UIConfigs[0].UISequence != CGamePlaygroundUIConfig::EUISequence::Playing) return;
#if MP4
	if (cast<CTrackManiaPlayer>(GetApp().CurrentPlayground.Players[0]).RaceState == 2) return;
#endif
	
#if TMNEXT
  	if (vis.RaceStartTime == 0xFFFFFFFF) { // in pre-race mode
		prev_speed = 0;
		lastBonk == Time::Now;
	}

#if DEPENDENCY_MLFEEDRACEDATA && DEPENDENCY_MLHOOK
	auto mlf = MLFeed::GetRaceData_V3();
	auto plf = mlf.GetPlayer_V3(MLFeed::LocalPlayersName);
	if (plf.spawnStatus != MLFeed::SpawnStatus::Spawned || (plf.LastRespawnRaceTime - plf.CurrentRaceTime) > 0) {
		prev_speed = 0;
		lastBonk == Time::Now;
		return;
	}
#endif

#elif MP4||TURBO
  	if (vis.FrontSpeed == 0) { // in pre-race mode hopefully
		prev_speed = 0;
		lastBonk == Time::Now;
	}
#endif
	
	float speed = getSpeed(vis);
	float curr_acc;
	try {
		curr_acc = Math::Max(0, (prev_speed - speed) / (g_dt/1000));
	} catch {
		curr_acc = 0;
	}
	prev_speed = speed;
	
	if (speed < 0) {
		speed *= -1.f;
		curr_acc *= -1.f;
	}
	bonkTargetThresh = (bonkThresh + prev_speed * 1.5f);
	bool mainBonkDetect = curr_acc > bonkTargetThresh;
#if TMNEXT
	if (mainBonkDetect && !vis.IsTurbo) bonk(curr_acc);
#elif MP4||TURBO
	if (mainBonkDetect) bonk(curr_acc); // IsTurbo not reported by VehicleState wrapper
#endif
}

void bonk(const float &in curr_acc) {
	detectedBonkVal = curr_acc;
	trace("DETECTED BONK @ " + Text::Format("%f", detectedBonkVal));
	if ((lastBonk + bonkDebounce) > Time::Now) return;
	
	lastBonk = Time::Now;
	if (enableBonkSound && Math::Rand(0.0f, 1.0f) <= bonkSoundChance) {
		Audio::Play(bonkSound, bonkSoundGain);
		startBonkFlash();
	}
}

float g_dt = 0;
void Update(float dt)
{
	g_dt = dt;
}

float getSpeed(CSceneVehicleVisState@ vis) {
#if TMNEXT||TURBO
	return vis.WorldVel.Length();
#elif MP4
	return vis.FrontSpeed;
#endif
}

uint lastBonkFlash = 0;
void startBonkFlash() {
	lastBonkFlash = Time::Now;
}

void Render() {
	if (!enableBonkFlash) return;
	if (lastBonkFlash + 400 < Time::Now) return;

	float w = float(Draw::GetWidth());
	float h = float(Draw::GetHeight());

	nvg::BeginPath();
	nvg::MoveTo(vec2(0,0));
	nvg::LineTo(vec2(0,0));

	nvg::BeginPath();
    nvg::Rect(0, 0, w, h);
	nvg::FillPaint(nvg::BoxGradient(vec2(0,0), vec2(w,h), h*0.2, w*0.1, vec4(0,0,0,0), vec4(1,0,0,1.f-((Time::Now - lastBonkFlash)/400.f))));
    nvg::Fill();
    nvg::ClosePath();
}

uint64 lastBonkTime() {
	return lastBonk;
}

float lastBonkScore() {
	return detectedBonkVal;
}

float currentBonkThreshold() {
	return bonkTargetThresh;
}
