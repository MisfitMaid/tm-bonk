[Setting min=0 max=100]
float bonkThresh = 64.f;

[Setting min=0]
uint bonkDebounce = 1000;

[Setting]
bool enableBonkSound = true;

[Setting min=0 max=1]
float bonkSoundGain = 1.0f;

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
	CSceneVehicleVisState@ vis = VehicleState::GetVis(GetApp().GameScene, VehicleState::GetViewingPlayer()).AsyncState;
	
	if (vis.RaceStartTime == 0xFFFFFFFF) { // in pre-race mode
		prev_speed = 0;
		lastBonk == Time::Now;
	}
	
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
	if (curr_acc < (bonkThresh*-1.f)) bonk(curr_acc);
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
