class TMSoundSettings extends Object;

// Between 0 and 1, how loud the game volume should be
var float volumePercentage;

const FILE_NAME = "SoundSettings.bin";


function SaveSettings() {
	local bool wasSuccessful;
	wasSuccessful = class'Engine'.static.BasicSaveObject(self, FILE_NAME, true, 1);

	if( !wasSuccessful ) {
		`warn( "TMSoundSettings::SaveFile() could not save file!" );
	}
}

static function TMSoundSettings LoadSettings() {
	local TMSoundSettings soundSettings;
	local bool wasSuccessful;
	
	soundSettings = new class'TMSoundSettings'();
	wasSuccessful = class'Engine'.static.BasicLoadObject(soundSettings, FILE_NAME, true, 1);

	if( !wasSuccessful ) {
		`warn( "TMSoundSettings::LoadFile() could not load save file!" );
	}

	return soundSettings;
}

static function string LoadVolumeCommand() {
	local TMSoundSettings soundSettings;

	soundSettings = LoadSettings();

	if( soundSettings.volumePercentage > 1 )
	{
		soundSettings.volumePercentage = 1;
	}
	if( soundSettings.volumePercentage < 0 )
	{
		soundSettings.volumePercentage = 0;
	}

`log("Changing game volume! " $ soundSettings.volumePercentage);
	return "ModifySoundClass Master Vol=" $ soundSettings.volumePercentage;
}

DefaultProperties
{
	volumePercentage = 0.5f;
}
