class TMDMGameInfo extends TMGameInfo;

var int mMaxScore;

function bool ShouldPlayerRestart(TMPlayerReplicationInfo tmPRI)
{
	return true;
}

/** basically, we undo the work done at a higher level, by setting score to 0.  Then we give ourselves a mMaxScore to check against later */
function SetGlobalSettings()
{
	local TMController controller;
	local JsonObject globalSettingJson;
	local int i;

	super.SetGlobalSettings();

	for(i = 0; i < mJsonStringBackup_Global.Length; ++i)
	{
		globalSettingJson = class'JSONObject'.static.DecodeJson(mJsonStringBackup_Global[i]);
		if(globalSettingJson.GetStringValue("name") == "GlobalSettings.json")
		{
			mMaxScore = globalSettingJson.GetIntValue("TeamLives");

			foreach self.mAllTMControllers(controller)
			{
				controller.GetTMPRI().allyInfo.score = 0;
			}
		}
	}

	m_ObjectiveText = "First to"@mMaxScore@"Kills";
}

function bool ShouldGameEnd(TMPlayerReplicationInfo playerWhoJustDied)
{
	local Controller outController;
	local TMPlayerReplicationInfo tmpri;	

	foreach WorldInfo.AllControllers( class'Controller', outController )
	{
		tmpri = TMPlayerReplicationInfo(outController.PlayerReplicationInfo);

		if (tmpri != None)
		{
			if ( tmpri.allyInfo != playerWhoJustDied.allyInfo && tmpri.allyInfo.score >= mMaxScore )
			{
				return true;
			}
		}
	}

	return false;
}

function OnPlayerDeath(TMPlayerReplicationInfo tmPRI, TMPlayerReplicationInfo killerTMPRI)
{
	local TMPlayerReplicationInfo tempTMPRI;
	local TMPlayerController tmpc;
	local array<TMPlayerReplicationInfo> assistPlayers;
	local Controller outController;
	local TMController tmController;
	tmController = TMController(tmPRI.Owner);
	tmpc = TMPlayerController(tmPRI.Owner);
	
	tmController.PlayerDied();

	tmPRI.KillAllMyUnits(None);

	if ( tmpc != None ) // None if bot 
	{
		tmpc.ClientDesaturateScreen(true);
	}

	// Update your stats
	UpdateStats(killerTMPRI, PS_KILLS);
	UpdateStats(tmPRI, PS_DEATHS);
	assistPlayers=tmPRI.AssignAssists(killerTMPRI);
	foreach assistPlayers(tempTMPRI) {
		UpdateStats(tempTMPRI, PS_ASSISTS);
	}

	if (killerTMPRI != None && killerTMPRI != tmPRI)
	{
		killerTMPRI.allyInfo.score++;
	}
	else // Prettymuch covers the "killunits()" case
	{
		foreach WorldInfo.AllControllers( class'Controller', outController )
		{
			if (TMPlayerReplicationInfo(outController.PlayerReplicationInfo) != None &&
				TMPlayerReplicationInfo(outController.PlayerReplicationInfo).allyInfo != None &&
				TMPlayerReplicationInfo(outController.PlayerReplicationInfo).allyInfo != tmPRI.allyInfo)
			{
				TMPlayerReplicationInfo(outController.PlayerReplicationInfo).allyInfo.score++;
				break;
			}
		}
	}

	if( ShouldGameEnd(tmPRI) )
	{
		TriggerEndGame(killerTMPRI.allyInfo);
		return;
	}

	SendPlayerDeathNotification(tmPRI, killerTMPRI);

	tmController.RespawnIn(RESPAWN_TIME);
}

function DoNexusKilledEffect( TMPawn inKiller )
{
	local int robberIndex;
	local int robbedIndex;
	local TMAllyInfo robberTeam;
	local TMAllyInfo robbedTeam;
	local int i;
	local TMPlayerController cont;

	if(!bNexusIsUp)
	{
		return;
	}

	if(m_NexusRevealActor != None)
	{
		m_NexusRevealActor.bApplyFogOfWar = false;
	}

	bNexusIsUp = false;

	// Call function in TMPCs
	foreach WorldInfo.AllControllers(class'TMPlayerController', cont)
	{
		cont.TurnOffRevealer();
	}

	robberIndex = inKiller.m_allyId;
	robbedIndex = (robberIndex - 1) * (robberIndex - 1);

	// Identify the teams (ally index != index in array)
	for(i=0; i < allies.Length; i++)
	{
		if(allies[i].allyIndex == robberIndex)
		{
			robberTeam = allies[i];
		}
		else if(allies[i].allyIndex == robbedIndex)
		{
			robbedTeam = allies[i];
		}
	}


	if(robbedTeam != none && robberTeam != none)
	{
		robberTeam.score++;

		if ( robberTeam.score >= mMaxScore )
		{
			TriggerEndGame(robberTeam);
		}
		if ( robbedTeam.score > 0 ) // the score displays incorrectly when we have negative numbers
		{
			robbedTeam.score--;
		}
	}
}

DefaultProperties
{
	m_ObjectiveText="Score X Kills"
}
