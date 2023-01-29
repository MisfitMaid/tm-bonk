[Setting name="Enable Bonk! sound effect"]
bool enableBonkSound = true;

[Setting name="Enable Bonk! visual effect"]
bool enableBonkFlash = true;

[Setting min=0 max=100 name="Bonk threshold" description="How sensitive the Bonk! detection is. If you get many false positives, increase this value."]
float bonkThresh = 64.f;

[Setting min=0 max=60000 name="Bonk debounce" description="Length (in ms) to cool down before making additional Bonk! sounds."]
uint bonkDebounce = 5000;

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
	@bonkSound = Audio::LoadSample("bonk.mp3");
}

float prev_speed = 0;
uint64 lastBonk = 0;
void step() {
	if (VehicleState::GetViewingPlayer() is null) return;
	CSceneVehicleVisState@ vis = VehicleState::ViewingPlayerState();
	
#if TMNEXT
  	if (vis.RaceStartTime == 0xFFFFFFFF) { // in pre-race mode
		prev_speed = 0;
		lastBonk == Time::Now;
	}
#elif MP4||TURBO
  	if (vis.FrontSpeed == 0) { // in pre-race mode hopefully
		prev_speed = 0;
		lastBonk == Time::Now;
	}
#endif
	
	float speed = getSpeed(vis);
	float curr_acc;
	try {
		curr_acc = ((speed - prev_speed) / (g_dt/1000));
	} catch {
		curr_acc = 0;
	}
	prev_speed = speed;
	
	if (speed < 0) {
		speed *= -1.f;
		curr_acc *= -1.f;
	}
#if TMNEXT
	if (curr_acc < (bonkThresh*-1.f) && !vis.IsTurbo && !vis.InputIsBraking) bonk(curr_acc);
#elif MP4||TURBO
	if (curr_acc < (bonkThresh*-1.f) && !vis.InputIsBraking) bonk(curr_acc); // IsTurbo not reported by VehicleState wrapper
#endif
}

void bonk(const float &in curr_acc) {
	if ((lastBonk + bonkDebounce) > Time::Now) return;
	
	lastBonk = Time::Now;
	if (enableBonkSound) {
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
	return Math::Distance(vec3(0,0,0), vis.WorldVel);
}

uint lastBonkFlash = 0;
void startBonkFlash() {
	lastBonkFlash = Time::Now;
}

void Render() {
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
