[Setting name="Enable Bonk! sound effect"]
bool enableBonkSound = true;

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
	
	float speed = vis.FrontSpeed;
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
	if (curr_acc < (bonkThresh*-1.f) && !vis.InputIsBraking) bonk(curr_acc);
}

void bonk(const float &in curr_acc) {
	if ((lastBonk + bonkDebounce) > Time::Now) return;
	
	lastBonk = Time::Now;
	if (enableBonkSound) {
		Audio::Play(bonkSound, bonkSoundGain);
	}
}

float g_dt = 0;
void Update(float dt)
{
	g_dt = dt;
}
