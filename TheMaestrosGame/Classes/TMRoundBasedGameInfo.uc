class TMRoundBasedGameInfo extends TMGameInfo;

var int mMaxScore;
var float mEndRoundCeremonyTime;

var bool mEndRoundSequenceStarted;
var float endRoundTimer;

var float mStartingPopulationPercentage;

/**
 * Passing in a None killerTMPRI is a signal that the Commander was killed in order to restart them only
 */
function CommanderDied(TMPlayerReplicationInfo tmPRI, TMPlayerReplicationInfo killerTMPRI)
{
	local TMPlayerController tmpc;
	
	UpdateLastCommanderDied(tmPRI.PlayerID);

	tmPRI.bIsCommanderDead = true;

	tmpc = TMPlayerController(tmPRI.Owner);

	if ( killerTMPRI != None )
	{
		OnPlayerDeath(tmPRI, killerTMPRI);
	}
	else
	{
		tmpc.ClientDesaturateScreen(true);
		tmpc.ClientDecideStartSpectating( false );
	}
}

/* SpawnStartingUnits
	Spawns a set number of starting units.
 */
function SpawnStartingUnits( TMController inTMPC, TMPawn inCommander )
{
	SpawnBaseUnitsAround( inCommander, inTMPC.GetTMPRI().PopulationCap * mStartingPopulationPercentage, inCommander.Location );
}

/** Round Should End when all players on this team are dead */
function bool ShouldRoundEnd(TMPlayerReplicationInfo playerWhoJustDied)
{
	local TMController tempTMController;
	local TMPlayerReplicationInfo tempTMPRI;

	if (mEndRoundSequenceStarted)
	{
		return false;
	}

	if ( !bNexusIsUp )
	{
		return true;
	}

	foreach mAllTMControllers(tempTMController)
	{
		tempTMPRI = tempTMController.GetTMPRI();
	
		if ( tempTMPRI.Owner != m_TMNeutralPlayerController )
		{
			if(tempTMPRI.allyInfo.allyIndex == playerWhoJustDied.allyInfo.allyIndex)
			{
				if(!tempTMPRI.bIsCommanderDead)
				{
					return false;
				}
			}
		}
	}
	
	return true;
}

/** Game Should End when a round is about to end that would put the team at mMaxScore */
function bool ShouldGameEnd(TMPlayerReplicationInfo playerWhoJustDied)
{
	local TMAllyInfo outAllyInfo;
	local TMAllyInfo enemyAllyInfo;
	
	if ( ShouldRoundEnd( playerWhoJustDied ) == false )
	{
		return false;
	}

	foreach AllActors(class'TMAllyInfo', outAllyInfo)
	{
		if ( outAllyInfo != playerWhoJustDied.allyInfo && outAllyInfo.allyIndex != class'TMGameInfo'.const.SPECTATOR_ALLY_ID ) // Dru TODO: Maybe don't give specs allyInfo to begin w/?
		{
			enemyAllyInfo = outAllyInfo;
			break;
		}
	}

	if ( enemyAllyInfo != None && enemyAllyInfo.score >= mMaxScore )
	{
		return true;
	}

	return false;
}

/* override ParseGameModeJSON
	Parses a JSON to fill in the game mode's data.
	Any game mode that wants custom data needs to override this function.
*/
function ParseGameModeJSON( JsonObject inJsonObject )
{
	mStartingPopulationPercentage = inJsonObject.GetFloatValue( "startingPopulationPercentage" );
}

/** maxRounds will be the number of teamlives divided by players, rounded - Dru's first pass */
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
			mMaxScore = globalSettingJson.GetIntValue("MaxRounds");

			foreach self.mAllTMControllers(controller)
			{
				controller.GetTMPRI().allyInfo.score = 0;
			}
		}
	}

	m_ObjectiveText = "First to"@mMaxScore@"Wins";
}

function OnPlayerDeath(TMPlayerReplicationInfo tmPRI, TMPlayerReplicationInfo killerTMPRI)
{
	local TMPlayerReplicationInfo tempTMPRI;
	local TMPlayerController tmpc;
	local TMController tmController;
	local array<TMPlayerReplicationInfo> assistPlayers;
	local TMAllyInfo tempAllyInfo;
	local TMAllyInfo scoringAllyInfo;
	local bool bShouldGameEnd;
	tmController = TMController(tmPRI.Owner);
	tmpc = TMPlayerController(tmPRI.Owner);

	tmController.PlayerDied();

	tmPRI.KillAllMyUnits(None);

	if (tmpc != None) // none if bot
	{
		tmpc.ClientDesaturateScreen(true);
		tmpc.ClientDecideStartSpectating( false );
	}

	UpdateStats(killerTMPRI, PS_KILLS);
	UpdateStats(tmPRI, PS_DEATHS);
	assistPlayers=tmPRI.AssignAssists(killerTMPRI);
	foreach assistPlayers(tempTMPRI) {
		UpdateStats(tempTMPRI, PS_ASSISTS);
	}

	if ( ShouldRoundEnd(tmPRI) )
	{
		bShouldGameEnd = false;

		foreach allies(tempAllyInfo) {
			if ( tempAllyInfo.allyIndex != tmPRI.allyId && 
				 tempAllyInfo.allyIndex != class'TMGameInfo'.const.SPECTATOR_ALLY_ID)
			{
				scoringAllyInfo = tempAllyInfo;
			}
		}

		if ( scoringAllyInfo != None)
		{
			scoringAllyInfo.score++;

			bShouldGameEnd = ShouldGameEnd(tmPRI);
		}				

		if( bShouldGameEnd )
		{
			TriggerEndGame(scoringAllyInfo);
		}
		else
		{
			StartFinishingRound(tmPRI);
		}
	}
	else
	{
		SendPlayerDeathNotification(tmPRI, killerTMPRI);
	}
	
	tmPRI.bNotRespawning = true; // go into allied spectator mode
}

function ResetNeutralCamps()
{
	local TMNeutralCamp outCamp;

	foreach AllActors(class'TMNeutralCamp', outCamp)
	{
		outCamp.Reset();
	}
}

function StartRound()
{
	local Controller outController;
	local TMPlayerReplicationInfo tmPRI;
	local PlayerStart tempPlayerStart;

	// restart neutral camps
	ResetNeutralCamps();

	bNexusIsUp = true;

	foreach WorldInfo.AllNavigationPoints(class'PlayerStart', tempPlayerStart)
	{
		tempPlayerStart.isInUse = false; // reset all initial spawn points so that you can spawn there again
	}

	// respawn all players
	foreach WorldInfo.AllControllers(class'Controller', outController)
	{
		tmPRI = TMPlayerReplicationInfo(outController.PlayerReplicationInfo);

		if ( tmPRI != None && tmPRI.Owner != m_TMNeutralPlayerController && !tmPRI.bOnlySpectator)
		{
			TMController(outController).SetHasDied(false);
			RestartPlayer(outController);
			
			if(TMPlayerController(outController) != None)
			{
				TMPlayerController(outController).ServerLoseAllPotions();
				TMPlayerController(outController).ClearAbilityObjects();
				TMPlayerController(outController).ClearAbilityProjectiles();
				TMPlayerController(outController).ClientSpawnDestructableNexus();
			}
		}
	}
}

function StartFinishingRound(TMPlayerReplicationInfo diedPlayerTMPRI)
{
	//local TMAllyInfo outAllyInfo;
	local TMPlayerController outTMPC;
	local int mEndRoundCeremonyTimeMillis;

	mEndRoundCeremonyTimeMillis = mEndRoundCeremonyTime * 1000;

	// Send a "Won Round"/"Lost Round" message to all players
	foreach AllActors(class'TMPlayerController', outTMPC)
	{
		if ( outTMPC.GetTMPRI().allyInfo == diedPlayerTMPRI.allyInfo )
		{
			outTMPC.ClientPlayNotification( "Allied team has lost the round", mEndRoundCeremonyTimeMillis);
			outTMPC.ClientEndRoundInVictory(false);
		}
		else
		{
			outTMPC.ClientPlayNotification( "Allied team has won the round", mEndRoundCeremonyTimeMillis);			
			outTMPC.ClientEndRoundInVictory(true);
		}
	}

	// End Round Ceremony
	mEndRoundSequenceStarted = true;

	// Set a timer to clean up the round
	//SetTimer(mEndRoundCeremonyTime, , NameOf(EndFinishingRound), );
}

function EndFinishingRound()
{
	local TMPlayerController tmController;

	// stop sequence/ceremony
	mEndRoundSequenceStarted = false;
	endRoundTimer = 0.f;

	foreach self.AllActors(class'TMPlayerController', tmController)
	{
		tmController.ClientDecideStartSpectating( false );
		tmController.ClientDesaturateScreen(false);
		//tmController.ClientHideHud(false);
	}
	SetGameSpeed( 1.f );

	// kill everybody
	KillAllPlayers();
	KillNexus();

	WorldInfo.ForceGarbageCollection(true);

	// Restart
	StartRound();
}

event Tick(float dt)
{
	local TMPlayerController tmController;
	if(mEndRoundSequenceStarted)
	{
		endRoundTimer += dt/gameSpeed;

		if(endRoundTimer > 1.f)
		{
			if(gameSpeed==1.f)
			{
				foreach self.AllActors(class'TMPlayerController', tmController)
				{
					tmController.ClientDecideStartSpectating( false );
					tmController.ClientDesaturateScreen(true);
					//tmController.ClientHideHud(true);
					if (WorldInfo.NetMode != NM_DedicatedServer)
					{
						tmController.FoWDisable();
					}
				}
			}
			gameSpeed = Lerp( gameSpeed, 0.1f, dt * 5.f);
			SetGameSpeed( gameSpeed );
		}

		if(endRoundTimer > 3.f)
		{
			foreach self.AllActors(class'TMPlayerController', tmController)
			{
				if(tmController.TM_HUD!=none)
				{
					//tmController.TM_HUD.initEndGameOverlay();
				}
			}
			EndFinishingRound();
		}
	}
	
	super.Tick(dt);
}


function bool ShouldPlayerRestart(TMPlayerReplicationInfo tmPRI)
{
	return false;
}

function DoNexusKilledEffect( TMPawn inKiller )
{
	local int robberIndex;
	local int robbedIndex;
	local TMAllyInfo robberTeam;
	local TMAllyInfo robbedTeam;
	local int i;
	local TMPlayerController cont;
	local TMPlayerReplicationInfo aLosersTMPRI;

	if(!bNexusIsUp)
	{
		return;
	}

	if(m_NexusRevealActor != None)
	{
		m_NexusRevealActor.bApplyFogOfWar = false;
	}

	bNexusIsUp = false;

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

	// Call function in TMPCs
	foreach WorldInfo.AllControllers(class'TMPlayerController', cont)
	{
		cont.TurnOffRevealer();

		if ( cont.GetTMPRI().allyInfo == robbedTeam )
		{
			aLosersTMPRI = cont.GetTMPRI();
		}
	}

	if (mEndRoundSequenceStarted)
	{
		return;
	}

	robberTeam.score++;

	if(robberTeam != none)
	{
		if ( ShouldGameEnd( aLosersTMPRI ) )
		{
			TriggerEndGame( robberTeam );
		}
		else
		{
			StartFinishingRound( aLosersTMPRI );
		}
	}
}

function KillNexus()
{
	local TMPlayerController iterTMPC;

	foreach WorldInfo.AllControllers(class'TMPlayerController', iterTMPC)
	{
		iterTMPC.ClientKillNexus();
	}
}

function KillAllPlayers()
{
	local TMPlayerReplicationInfo tempTMPRI;

	foreach self.AllActors(class'TMPlayerReplicationInfo', tempTMPRI)
	{
		if ( tempTMPRI.Owner != m_TMNeutralPlayerController && !tempTMPRI.bIsCommanderDead)
		{
			tempTMPRI.DestroyAllMyUnits();
		}
	}
}

DefaultProperties
{
	mEndRoundCeremonyTime = 3.0f;
	m_ObjectiveText="Win X Rounds"

	jsonFileName = "GameModes\\\\RoundBased.json"
}
