[Setting category="Bonk!s" name="Enable Bonk! sound effect"]
bool enableBonkSound = true;

[Setting category="Bonk!s" name="Enable Bonk! visual effect"]
bool enableBonkFlash = true;

[Setting category="Bonk!s" min=0 max=100 name="Bonk threshold" description="How sensitive the Bonk! detection is. If you get many false positives, increase this value."]
float bonkThresh = 16.f;

[Setting name="bonk wheels on ground sensitivity (higher is lower)" drag min=1 max=10]
float wheels_contacting_sensitivity = 4;

[Setting name="bonk wheels off ground sensitivity (higher is lower)" drag min=1 max=10]
float wheels_in_air_sensitivity = 4;

[Setting category="Bonk!s" min=0 max=60000 name="Bonk debounce" description="Length (in ms) to cool down before making additional Bonk! sounds."]
uint bonkDebounce = 500;

[Setting category="Bonk!s" min=0 max=1 name="Bonk! chance" description="Probability of a Bonk! sound occurring once the threshold is met."]
float bonkSoundChance = 1.0f;

[Setting category="Bonk!s" min=0 max=1 name="Bonk! volume"]
float bonkSoundGain = 0.4f;

[Setting name="debug" hidden]
bool debug = false;
