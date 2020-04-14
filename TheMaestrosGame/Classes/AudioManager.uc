class AudioManager extends Object;

struct VOSoundCue
{
	var AudioComponent ac;
	var bool isGameVO;
};

struct VOCooldown
{
	var string unitName;
	var float doneCoolingDownGameTimeSeconds;
};

const MAX_SFX_TRACKS = 10;

var TMPlayerController mTMPC;

var array<VOSoundCue> mVOQueue;
var array<AudioComponent> mSFXBuffer;

var array<VOCooldown> VOCooldowns;

var const float VO_COOLDOWN_TIME_SECONDS;

public reliable client function Initialize(TMPlayerController pc)
{
	mTMPC = pc;
	setSoundMode(SoundMode'Audio_SoundModes.SM_Default');
}

public simulated function tick()
{
	if (mVOQueue.Length != 0 && !mVOQueue[0].ac.IsPlaying())
	{
		mVOQueue.Remove(0, 1);
		if (mVOQueue.Length != 0)
		{
			setSoundMode(SoundMode'Audio_SoundModes.SM_VoiceOver');
			mVOQueue[0].ac.Play();
		}
		else
		{
			setSoundMode(SoundMode'Audio_SoundModes.SM_Default');
		}
	}

	expireVOCooldowns();
}

function expireVOCooldowns()
{
	local int i;

	for (i = VOCooldowns.Length - 1; i >= 0; i--)
	{
		if (VOCooldowns[i].doneCoolingDownGameTimeSeconds < mTMPC.WorldInfo.TimeSeconds)
		{
			VOCooldowns.Remove(i, 1);
		}
	}
}

public reliable client function requestPlaySFX(SoundCue cue) 
{
	local AudioComponent ac;

	if (cue == none || mTMPC == none)
	{
		`log('AudioManager not initialized', true, 'am');
		`log('AudioManager not initialized', true, 'am');
		return;
	}
	ac = mTMPC.CreateAudioComponent(cue, true, true, true, mTMPC.Location, true);

	if( ac == none )
	{
		`warn( "AudioManager::requestPlaySFX() couldn't create audio component!!!" );
		return;
	}

	if (updateSFXBuffer(ac.SoundCue))
	{
		setSoundMode(SoundMode'Audio_SoundModes.SM_Default');
		ac.Play();
		mSFXBuffer.AddItem(ac);
	}
}

public reliable client function requestPlaySFXWithLocation(SoundCue cue, Vector loc) 
{
	local AudioComponent ac;

	if (cue == none || mTMPC == none)
	{
		`log('AudioManager not initialized', true, 'am');
		return;
	}
	ac = mTMPC.CreateAudioComponent(cue, true, true, true, loc, true);

	if (updateSFXBuffer(ac.SoundCue))
	{
		setSoundMode(SoundMode'Audio_SoundModes.SM_Default');
		ac.Play();
		mSFXBuffer.AddItem(ac);
	}
}

public reliable client function requestPlaySFXWithActor(SoundCue cue, Actor actor) 
{
	local AudioComponent ac;

	if (cue == none || mTMPC == none)
	{
		`log('AudioManager not initialized', true, 'am');
		return;
	}
	ac = actor.CreateAudioComponent(cue, true, true, true, actor.Location, true);

	if (ac != none && updateSFXBuffer(ac.SoundCue))
	{
		setSoundMode(SoundMode'Audio_SoundModes.SM_Default');
		ac.Play();
		mSFXBuffer.AddItem(ac);
	}
}

public reliable client function requestPlayEmitterSFX(ParticleSystem emission, Actor target)
{
	switch (emission)
	{
	case ParticleSystem'VFX_Leo.Particles.vfx_DoughBoy_Hit_Small_Red':
		requestPlaySFXWithActor(SoundCue'SFX_Dynamics.Dynamics_SFX_Doughboy_Impact_Cue', target);
		break;

	case ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion':
		requestPlaySFXWithActor(SoundCue'SFX_Dynamics.Dynamics_SFX_Shrine_Explosion', target);
		break;

	case ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_on_hit':
		requestPlaySFXWithActor(SoundCue'SFX_Dynamics.Dynamics_SFX_Robomeister_Explosion', target);
		break;
	}
}

public reliable client function requestPlayVO(SoundCue cue, bool isGameVO, bool shouldCue) 
{
	local AudioComponent ac;

	if (cue == none || mTMPC == none)
	{
		`log('AudioManager not initialized', true, 'am');
		return;
	}
	
	ac = mTMPC.CreateAudioComponent(cue, false, true, true, mTMPC.Location, true);
	if (mVOQueue.Length == 0)
	{
		if (isGameVO)
		{
			setSoundMode(SoundMode'Audio_SoundModes.SM_VoiceOver');
		}
		ac.Play();
		mVOQueue.Add(1);
		mVOQueue[0].ac = ac;
		mVOQueue[0].isGameVO = isGameVO;
	}
	else if (isGameVO && !mVOQueue[0].isGameVO)
	{
		setSoundMode(SoundMode'Audio_SoundModes.SM_VoiceOver');
		ac.Play();
		mVOQueue[0].ac.Stop();
		mVOQueue[0].ac = ac;
		mVOQueue[0].isGameVO = isGameVO;
	}
	else if (isGameVO && shouldCue)
	{
		mVOQueue.Add(1);
		mVOQueue[mVOQueue.Length - 1].ac = ac;
		mVOQueue[mVOQueue.Length - 1].isGameVO = isGameVO;
	}
}

public reliable client function requestPlayMapTrack(SoundCue mapsAmbientSoundCue)
{
	local AudioComponent ac;

	if (mTMPC == none)
	{
		`WARN("AudioManager not initialized, could not play Map Track");
		return;
	}
	
	if (mapsAmbientSoundCue != none)
	{
		ac = mTMPC.CreateAudioComponent(mapsAmbientSoundCue, true, true, true, mTMPC.Location, true);
		setSoundMode(SoundMode'Audio_SoundModes.SM_Default');
		ac.bAlwaysPlay = true;
		ac.bShouldRemainActiveIfDropped = true;
		ac.Play();
		mSFXBuffer.AddItem(ac);
	}
	else
	{
		`WARN("No track found for map in requestPlayMapTrack()");
	}
}

function bool shouldPlayCharacterVO(string character) 
{
	local VOCooldown iterVOCooldown;

	foreach VOCooldowns(iterVOCooldown)
	{
		if (iterVOCooldown.unitName == character)
		{
			return false;
		}
	}

	return true;
}

public reliable client function requestPlayCharacterVO(ECommand command, String character)//, bool isCommander)
{
	local int selection;
	local VOCooldown tempVOCooldown;

	if (!shouldPlayCharacterVO(character))
	{
		return;
	}

	`log("Playing VO for character:"$character$" at time: "$mTMPC.WorldInfo.TimeSeconds, true, 'dru');

	switch (command)
	{
	case C_Move:
		if (character == "TinkerMeister")
		{
			selection = Rand(4);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Move_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Move_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Move_2_1_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Move_2_2_Cue', false, false);
				break;
			}
		}
		else if (character == "Rosie")
		{
			selection = Rand(4);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Move_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Move_3_1_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Move_2_1_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Move_2_2_Cue', false, false);
				break;
			}
		}
		else if (character == "RoboMeister")
		{
			requestPlayVO(SoundCue'VO_Robomeister.Robomeister_Move', false, false);
		}
		else if (character == "Salvator")
		{
			requestPlayVO(SoundCue'VO_Salvator.Salvator_Move', false, false);
		}
		else if (character == "HiveLord")
		{
			selection = Rand(4);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Move_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Move_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Move_3_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Move_4_Cue', false, false);
				break;
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[1])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Conductor.Conductor_Move', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[2])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[3])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[4])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Oiler.Oiler_Move', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[5])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Skybreaker.Skybreaker_Move', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[0])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Doughboy.Doughboy_Move', false, false);
			}
		}
		break;

	case C_Attack:
		if (character == "TinkerMeister")
		{
			selection = Rand(4);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Attack_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Attack_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Attack_2_1_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Attack_2_2_Cue', false, false);
				break;
			}
		}
		else if (character == "Rosie")
		{
			selection = Rand(6);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Attack_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Attack_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Attack_2_1_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Attack_2_2_Cue', false, false);
				break;
			case 4:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Attack_3_1_Cue', false, false);
				break;
			case 5:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Attack_3_2_Cue', false, false);
				break;
			}
		}
		else if (character == "RoboMeister")
		{
			requestPlayVO(SoundCue'VO_Robomeister.Robomeister_Attack', false, false);
		}
		else if (character == "Salvator")
		{
			requestPlayVO(SoundCue'VO_Salvator.Salvator_Attack', false, false);
		}
		else if (character == "HiveLord")
		{
			selection = Rand(3);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Attack_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Attack_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Attack_3_Cue', false, false);
				break;
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[1])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Conductor.Conductor_Attack', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[2])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[3])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[4])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Oiler.Oiler_Attack', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[5])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Skybreaker.Skybreaker_Attack', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[0])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Doughboy.Doughboy_Attack', false, false);
			}
		}
		break;

	case C_SelectUnit:
		if (character == "TinkerMeister")
		{
			selection = Rand(6);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Select_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Select_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Select_2_2_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Select_2_2_Cue', false, false);
				break;
			case 4:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Select_3_1_Cue', false, false);
				break;
			case 5:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Select_3_2_Cue', false, false);
				break;
			}
		}
		else if (character == "Rosie")
		{
			selection = Rand(7);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_2_1_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_2_2_Cue', false, false);
				break;
			case 4:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_3_1_Cue', false, false);
				break;
			case 5:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_4_1_Cue', false, false);
				break;
			case 6:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Select_4_2_Cue', false, false);
				break;
			}
		}
		else if (character == "RoboMeister")
		{
			requestPlayVO(SoundCue'VO_Robomeister.Robomeister_Select', false, false);
		}
		else if (character == "Salvator")
		{
			requestPlayVO(SoundCue'VO_Salvator.Salvator_Select', false, false);
		}
		else if (character == "HiveLord")
		{
			selection = Rand(3);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Select_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Select_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Select_3_Cue', false, false);
				break;
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[1])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Conductor.Conductor_Select', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[2])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[3])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[4])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Oiler.Oiler_Select', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[5])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Skybreaker.Skybreaker_Select', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[0])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Doughboy.Doughboy_Select', false, false);
			}
		}
		break;

	case C_Die:
		if (character == "TinkerMeister")
		{
			selection = Rand(2);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Death_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Death_1_2_Cue', false, false);
				break;
			}
		}
		else if (character == "Rosie")
		{
			requestPlayVO(SoundCue'VO_Rosie.Rosie_Death_1_1_Cue', false, false);
		}
		else if (character == "RoboMeister")
		{
			requestPlayVO(SoundCue'VO_Robomeister.Robomeister_Death', false, false);
		}
		else if (character == "Salvator")
		{
			requestPlayVO(SoundCue'VO_Salvator.Salvator_Death', false, false);
		}
		else if (character == "HiveLord")
		{
			requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Death_Cue', false, false);
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[1])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Conductor.Conductor_Death', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[2])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[3])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[4])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Oiler.Oiler_Death', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[5])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[0])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Doughboy.Doughboy_Death', false, false);
			}
		}
		break;

	case C_Ability1:
		if (character == "TinkerMeister")
		{
			selection = Rand(4);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Special_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Special_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Special_2_1_Cue', false, false);
				break;
			case 3:
				requestPlayVO(SoundCue'VO_Tinkermeister.Tinkermeister_Special_2_2_Cue', false, false);
				break;
			}
		}
		else if (character == "Rosie")
		{
			selection = Rand(3);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Special_1_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Special_1_2_Cue', false, false);
				break;
			case 2:
				requestPlayVO(SoundCue'VO_Rosie.Rosie_Special_2_1_Cue', false, false);
				break;
			}
		}
		else if (character == "RoboMeister")
		{
		}
		else if (character == "Salvator")
		{
			requestPlayVO(SoundCue'VO_Salvator.Salvator_Special', false, false);
		}
		else if (character == "HiveLord")
		{
			selection = Rand(2);
			switch (selection)
			{
			case 0:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Special_1_Cue', false, false);
				break;
			case 1:
				requestPlayVO(SoundCue'VO_HiveLord.HiveLord_Special_2_Cue', false, false);
				break;
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[1])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Conductor.Conductor_Special', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[2])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[3])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[4])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[5])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[0])
		{
		}
		break;

	case C_Transform:
		if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[1])
		{
			if (TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).race == "Teutonian")
			{
				requestPlayVO(SoundCue'VO_Conductor.Conductor_Transform', false, false);
			}
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[2])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[3])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[4])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[5])
		{
		}
		else if (character == TMPlayerReplicationInfo(mTMPC.PlayerReplicationInfo).raceUnitNames[0])
		{
		}

		break;
	}

	tempVOCooldown.unitName = character;
	tempVOCooldown.doneCoolingDownGameTimeSeconds = mTMPC.WorldInfo.TimeSeconds + VO_COOLDOWN_TIME_SECONDS;
	VOCooldowns.AddItem(tempVOCooldown);
}

public reliable client function setSoundMode(SoundMode sm)
{
	mTMPC.SetSoundMode(sm.Name);
}

private function bool updateSFXBuffer(SoundCue sc)
{
	local bool trackExists;
	local int i;

	trackExists = false;
	i = 0;
	
	for (i=0; i<mSFXBuffer.length; i++)
	{
		if (sc != none && mSFXBuffer[i] != none && mSFXBuffer[i].SoundCue == sc && !trackExists && !mSFXBuffer[i].IsPlaying())
		{
			mSFXBuffer[i].Play();
			trackExists = true;  
		}
		else if (mSFXBuffer[i] != none && !mSFXBuffer[i].IsPlaying() && mSFXBuffer.Length < MAX_SFX_TRACKS)
		{
			mSFXBuffer.Remove(i, 1);
			i--;
		}
	}

	if (!trackExists && sc != none) 
	{
		return true;
	}

	return false;
}

DefaultProperties
{
	VO_COOLDOWN_TIME_SECONDS = 20.0f
}
