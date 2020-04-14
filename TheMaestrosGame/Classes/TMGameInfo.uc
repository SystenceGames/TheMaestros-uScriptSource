class TMGameInfo extends UDKRTSGameInfo
				dependson(TMPlatformConnection);

enum PStats
{
	PS_DEATHS,
	PS_KILLS,
	PS_ASSISTS,
	PS_UNITSKILLED,
	PS_UNITSLOST,
	PS_APM,
	PS_ACTIONS,
	PS_SPAWNED_DOUGHBOY,
	PS_SPAWNED_OILER,
	PS_SPAWNED_SPLITTER,
	PS_SPAWNED_CONDUCTOR,
	PS_SPAWNED_SNIPER,
	PS_SPAWNED_SKYBREAKER,
	PS_SPAWNED_DISRUPTOR,
	PS_SPAWNED_GRAPPLER,
	PS_SPAWNED_RAMBAM,
	PS_SPAWNED_VINECRAWLER,
	PS_SPAWNED_TURTLE,
	PS_SPAWNED_REGENERATOR,
};

const SPECTATOR_ALLY_ID = -3;
const EXIT_CONDITION_NORMATIVE="Normative";
const EXIT_CONDITION_ENTIRE_TEAM_LEFT="EntireTeamLeave";
const EXIT_CONDITION_ALL_PLAYERS_LEFT="AllPlayersLeft";
const EXIT_CONDITION_UNEXPECTED_EXIT="UnexpectedExit";
const PROCESS_STATS_TIMEOUT=10.0f;

var     class<TMAllyInfo>   tmAllyInfoClass;
var     array<TMAllyInfo>   allies;
var     array<TMController>   mAllTMControllers;
var     int                 minPlayers;				/** Minimum number of players allowed by this server. */
var     int                 numAIPlayers;			/** Number of AI players spawned by this server. */
var     int                 nextPawnId;

var int RESPAWN_TIME;
var DruHashMap m_PawnHash; /** PawnID -> Pawn hash */
var array<TMUnit> unitCache;
var array<TMPawn> mTMPawnList;
var array<TMFoWManager> fowManagers;
var array<TMStatusEffect> StatusEffectCache;
var array<string> m_unitCachedStrings;
var array<string> m_statusEffectCachedStrings;
var TMJsonParser m_JsonParser;
var AudioManager mAudioManager;
var TMPlatformConnection mPlatformConnection;
var bool bGameStarted;
var int m_iMaxNumStatusEffects;
var string m_ObjectiveText;
var bool bToldPlatformGameInitialized;

var bool bNexusIsUp;
var TMFOWRevealActor m_NexusRevealActor;

var bool mIsPracticeBattle;

struct botCommandlineOptions
{
	var string PlayerName;
	var int botDifficulty;
	var string CommanderName;
	var int allyID;
};

var array<botCommandlineOptions> listOfBotCommandlineOptions;
var string mGameGUID; /** used to keep track of server games */
var string mNodeLocalPort; /** used to keep track of server game's ports */
var string mJobId; /** used to keep track of the job used to start server games */

var TMNeutralPlayerController m_TMNeutralPlayerController;
var TMPlayerController m_TMPlayerController; // Used for Kismet functions for Tutorial

var array<string> mJsonStringBackup;
var array<string> mJsonStringBackup_SE;
var array<string> mJsonStringBackup_Global;

var array<int> m_recievedUnitCache; /** a list of all the people/"PlayerIDs" that have received the unit cache */
var array<int> m_haventReceivedUnitCache; /** a list of all the people/"PlayerIDs" that have yet to receive the unit cache, used for those who enter the game late */

var TMFOWMapInfoActor mapInfo; /** A reference to the TMMapInfoActor that allows tranformations between world space and tile space. */

var int mTeamBlueColorIndex;
var int mTeamRedColorIndex;

// Global game settings
var float mGameSpeed;

var int mLineOfSightRangeForPawns;  // Distance (in Tiles) that all pawns see by default

var TMPlayerReplicationInfo bruteKillerPRI;
var vector bruteLoc;

var string m_exitcond;

var int mShrineKillCount;
var int mDreadBeastKillCount;
var bool endGameSequenceStarted;
var float endGameTimer;
var string jsonFileName;
var array<TMPlatformRequest> platformRequests;

var bool mShouldEndGameOnServer;
var bool mDoneWaitingForStatsProcessing;

var string GAME_MODE_NAME; 	// used to tell clients which game mode we are

var TMGameInfoHelper mTMGameInfoHelper;

event PreBeginPlay()
{
	super.PreBeginPlay();
	InitializeMapInfoActor();
	endGameSequenceStarted = false;
	endGameTimer = 0;

	mTMGameInfoHelper = new class'TMGameInfoHelper'();
}

event PostBeginPlay()
{
	super.PostBeginPlay();

	m_PawnHash = class'DruHashMap'.static.Create(256);
	nextPawnId= 1; //need to init this to 1, when IDS are passed a none type is 0
	
	bGameStarted = false;
	bNexusIsUp=true; // GGHTODO: get rid of this, component should handle it
	m_exitcond=EXIT_CONDITION_UNEXPECTED_EXIT;
	self.SetTimer(0.05, true, NameOf(CheckPlatformResponse));
}

function SetGroupedMoveV2(bool enabled)
{
	local TMController iterTmController;

	foreach mAllTMControllers(iterTmController)
	{
		if (TMPlayerController(iterTmController) != None)
		{
			TMPlayerController(iterTmController).bGroupedMoveV2Enabled = enabled;
		}
	}
}

event InitGame(string Options, out string ErrorMessage)
{
	local int i;
	local botCommandlineOptions iterBotCommandlineOptions;

	minPlayers = GetIntOption( Options, "MinPlayers", 1 );
	numAIPlayers = GetIntOption( Options, "NumAIPlayers", 0 );
	mJobId = ParseOption( Options, "jobID");
	mGameGUID = ParseOption( Options, "gameGUID" );
	mNodeLocalPort = ParseOption( Options, "nodeLocalPort" );
	mIsPracticeBattle = GetIntOption( Options, "IsPracticeBattle", 0) == 1;

	for (i = 0; i < numAIPlayers; i++)
	{
		iterBotCommandlineOptions.botDifficulty = GetIntOption( Options, "bot"$i$"Difficulty", 1 );
		iterBotCommandlineOptions.allyID = GetIntOption( Options, "bot"$i$"Ally", 0 );
		iterBotCommandlineOptions.CommanderName = ParseOption( Options, "bot"$i$"CommanderName" );
		iterBotCommandlineOptions.PlayerName = ParseOption( Options, "bot"$i$"PlayerName" );
		listOfBotCommandlineOptions.AddItem(iterBotCommandlineOptions);
	}

	mPlatformConnection = new () class'TMRealPlatformConnection';
	mPlatformConnection.Setup();
	m_JsonParser = new() class'TMJsonParser';
	m_JsonParser.setup();

	mJsonStringBackup_Global = GetJsonStringsFromManifest("\\Global.json");
	ParseStartingGameStats();

	// Load GameMode info from JSON
	LoadGameModeFromJSON();

	UpdateUnits();
	UpdateStatusEffects();
	//UpdateRaces(); // Dru TODO: Refactor these lists into JSON for data-driven wins
	//UpdateCommanders();

	self.SetTimer(90.0f, false, nameof(Timeout));

	Super.InitGame( Options, ErrorMessage );

	if( minPlayers == 0 )
	{
		// We don't need to wait for any real players to connect. Just start the game
		SetTimer( 1, false, NameOf( StartMatch ) );
	}
}

function TellPlatformGameInitialized()
{
	mPlatformConnection.PostGameInitialized(mNodeLocalPort, mJobId);
	bToldPlatformGameInitialized = true;
}

event Tick(float dt)
{
	local TMPlayerController tmController;

	if(!bToldPlatformGameInitialized && mJobId != "") {
		TellPlatformGameInitialized();
	}

	if(endGameSequenceStarted)
	{
		endGameTimer+= dt/gameSpeed;

		if(endGameTimer > 1.f)
		{
			if(gameSpeed==1.f)
			{
				foreach self.AllActors(class'TMPlayerController', tmController)
				{
					tmController.ClientDesaturateScreen(true);
				}
			}
			gameSpeed = Lerp( gameSpeed, 0.1f, dt * 5.f);
			SetGameSpeed( gameSpeed );
		}

		if(endGameTimer > 14.f)
		{
			foreach self.AllActors(class'TMPlayerController', tmController)
			{
				if(tmController.TM_HUD!=none)
				{
					//tmController.TM_HUD.initEndGameOverlay();
				}
			}
			ReadyToEndGameOnServer();
		}
	}
}

function InitializeMapInfoActor()
{
	local TMFOWMapInfoActor TheMap;
	// clear previous references
	mapInfo = none;

	// find new map info actor
	foreach AllActors(class'TMFOWMapInfoActor', TheMap)
	{
		mapInfo = TheMap;
		mapInfo.Initialize();
		break;
	}
}

function CommanderDied(TMPlayerReplicationInfo tmPRI, TMPlayerReplicationInfo killerTMPRI)
{
	UpdateLastCommanderDied(tmPRI.PlayerID);

	// Save the dead commander's current army population
	tmPRI.baseUnitsEarned = tmPRI.Population;

	tmPRI.bIsCommanderDead = true;
	OnPlayerDeath(tmPRI, killerTMPRI);
}

function UpdateLastCommanderDied(int inPlayerID)
{
	local TMPlayerController tempPC;

	foreach WorldInfo.AllControllers(class'TMPlayerController', tempPC)
	{
		tempPC.ClientUpdateLastCommanderDied(inPlayerID);
	}
}

function GenericPlayerInitialization(Controller C)
{
	super.GenericPlayerInitialization(C);
	PlayerController(C).ClientSetHUD(HUDType);
}

function UpdateStats( TMPlayerReplicationInfo PlayerToUpdateStats, PStats stat )
{
	local TMPlayerController tempPC;

	++PlayerToUpdateStats.mStats[stat];

	if (WorldInfo.NetMode != NM_Standalone)
	{
		foreach WorldInfo.AllControllers(class'TMPlayerController', tempPC)
		{
			tempPC.ClientUpdateStats(PlayerToUpdateStats.PlayerID, stat);
		}
	}
}

function TimedOutWaitingForStats()
{
	`WARN("Timed out while waiting to process end game stats", true, 'dru');
	DoneWaitingForStats();
}

function ParseProcessEndGameStats(string response)
{
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			`log("Parsing ProcessEndGameStatsResponse", true, 'dru');
		} else {
			`WARN("ProcessEndGameStats returned an error: "$json.GetStringValue("error"));
		}
	}

	ClearTimer(NameOf(TimedOutWaitingForStats));
	DoneWaitingForStats();
}

function CheckPlatformResponse()
{
	local int i;
	local string response;

	if(platformRequests.Length == 0) { return; }

	for(i = 0; i < platformRequests.Length; i++) {
		response = self.mPlatformConnection.GetPlatformResponse(platformRequests[i].requestNum);
		if(response != "") {
			`log("Response JSON: " $ response, true, 'Andre');
			switch(platformRequests[i].requestType) {
				case RT_PROCESSENDGAMESTATS:
					ParseProcessEndGameStats(response);
					break;
			}
			platformRequests.RemoveItem(platformRequests[i--]);
		}
	}
}

function SendStatsIfNeeded(JsonObject endGameStatsJson)
{
	if (StartedByPlatformGameServer() || IsPracticeBattle())
	{
		SendEndGameStats(endGameStatsJson);
	} else 
	{
		DoneWaitingForStats();
	}
}

/* Logout
	Called when a player disconnects from a match.
*/
function Logout( Controller Exiting )
{
	local TMPlayerController tmController, tmController2;
	local TMController iterTMController;
	local TMPlayerController notExitingTMPlayerController;
	local TMPawn pawn;
	local int foundteam;
	local string loggingOutPlayerName;
	local JsonObject endGameStatsJson;
	local array<JsonObject> playerGameSummaryJsons;

	foundteam = -5;
	TMPlayerController(Exiting).mLoggingOut = true;
	TMPlayerController(Exiting).KillUnits();

	foreach WorldInfo.AllControllers(class'TMPlayerController', tmController)
	{
		if (tmController != Exiting)
		{
			notExitingTMPlayerController = tmController;
			break;
		}
	}

	foreach self.AllActors(class'TMPawn', pawn) {
		if (pawn.m_owningPlayerId == TMPlayerController(Exiting).PlayerId) 
		{
			TMPlayerController(Exiting).ServerKillPawn(pawn.pawnId);
		}
		else if (pawn.m_TMPC == Exiting && notExitingTMPlayerController != None)
		{
			// re-own every pawn who had this guy arbitrarily set as m_TMPC
			pawn.m_TMPC = notExitingTMPlayerController;
			pawn.m_Controller = notExitingTMPlayerController;
		}
	}

	loggingOutPlayerName = TMPlayerController(Exiting).GetTMPRI().PlayerName;

	self.mAllTMControllers.RemoveItem(Exiting);
	super.Logout(Exiting);

	`log("Player " $ loggingOutPlayerName $ " logged out. Players left is " $GetNumPlayers());
	// This 'say' message would be nice to have, but it causes a none. The server doesn't have a 
	// 	local player controller.
	// GetAPlayerController().Say(loggingOutPlayerName $ " left the game.");

	self.mPlatformConnection.UpdateActiveHumanPlayerCount(GetNumPlayers(), self.mNodeLocalPort, self.mJobId);

	// Below cases are all for MP games, not single player
	if ( WorldInfo.NetMode == NM_Standalone || endGameSequenceStarted )
	{
		return;
	}

	if(GetNumPlayers() == 0) 
	{
		m_exitcond=EXIT_CONDITION_ALL_PLAYERS_LEFT;

		playerGameSummaryJsons = CreatePlayerGameSummaryList(none);
		endGameStatsJson = CreateEndGameStats();

		foreach self.AllActors(class'TMPlayerController', tmController)
		{
			RestartPlayer( tmController );
			tmController.ClientEndGameInVictory(false);
		}

		SendGameAnalytics(playerGameSummaryJsons);
		SendStatsIfNeeded(endGameStatsJson);
		ReadyToEndGameOnServer(); // we are the server by virtue of being on TMGameInfo
	}
	else
	{
		foreach self.mAllTMControllers(iterTMController)
		{
			if(iterTMController == TMPlayerController(Exiting)) {
				continue;
			}
			if(foundteam == -5) {
				foundteam=iterTMController.GetTMPRI().allyId;
			}
			else if(iterTMController.GetTMPRI().allyId != foundteam) {
				return;
			}
		}

		// TODO: Merge this with TriggerEndGame when you have more time to test if that RestartPlayer matters
		m_exitcond=EXIT_CONDITION_ENTIRE_TEAM_LEFT;
		endGameSequenceStarted = true;
		// End game stats and player game summaries must be created before players are told win status, b/c they will leave
		playerGameSummaryJsons = CreatePlayerGameSummaryList(notExitingTMPlayerController.GetTMPRI().allyInfo);
		endGameStatsJson = CreateEndGameStats();

		// Let every know if they won or lost
		foreach self.AllActors(class'TMPlayerController', tmController2)
		{
			RestartPlayer( tmController2 );	// Dru TODO: Why do we do this? seems unnecessary
			if(tmController2 == TMPlayerController(Exiting)) {
				tmController2.ClientEndGameInVictory(false);
			}
			else {
				tmController2.ClientEndGameInVictory(true);
			}
		}
		SendGameAnalytics(playerGameSummaryJsons);
		SendStatsIfNeeded(endGameStatsJson);
	}
}

function SendEndGameStats(JsonObject endGameStats)
{
	local string formattedData;
	local TMPlatformRequest platformRequest;

	`log( "TMGameInfo::SendEndGameStats() sending endgame stats to platform." );
	formattedData = class'JsonObject'.static.EncodeJson( endGameStats );
	
	platformRequest.requestType = RT_PROCESSENDGAMESTATS;
	platformRequest.requestNum = mPlatformConnection.PostProcessEndGameStats(formattedData);
	platformRequests.AddItem(platformRequest);
	SetTimer(PROCESS_STATS_TIMEOUT, false, NameOf(TimedOutWaitingForStats));
}

function SendGameAnalytics(array<JsonObject> playerGameSummaryJsons)
{
	local JsonObject tempJson;

	// Send player game summaries
	foreach playerGameSummaryJsons( tempJson )
	{
		SendGraylogMessage( tempJson );
	}

	// Send game summary
	tempJson = CreateGameSummary();
	SendGraylogMessage( tempJson );
}

function SendGraylogMessage( JsonObject inGameSummary )
{
	local string formattedData;
	formattedData = class'JsonObject'.static.EncodeJson( inGameSummary );
	mPlatformConnection.PostToGraylog( formattedData );
}

function JsonObject CreateGraylogMessage(string shortMessage, string fullMessage)
{
	local JsonObject tempJson;

	tempJson = new () class'JsonObject';

	// Format the data
	tempJson.SetStringValue("version", "1.1");
	tempJson.SetStringValue("facility", "UdkGameServer");
	tempJson.SetStringValue("host", "UDK GameServer");
	tempJson.SetStringValue("short_message", shortMessage);
	tempJson.SetStringValue("full_message", fullMessage);
	tempJson.SetStringValue("timestamp", WorldInfo.TimeStamp());
	tempJson.SetStringValue("_shard", self.mPlatformConnection.GetShard());
	tempJson.SetStringValue("level", "6");

	return tempJson;
}

function float CalculateAverageCommanderLifetime(TMPlayerReplicationInfo playerTMPRI)
{
	local int i;
	local float tempFloat;

	tempFloat = 0;
	if( playerTMPRI.m_deathTimeArray.Length > 0)
	{
		for(i =0 ; i< playerTMPRI.m_deathTimeArray.Length; i++)
		{
			tempFloat += playerTMPRI.m_deathTimeArray[i];
		}
		tempFloat = tempFloat / playerTMPRI.m_deathTimeArray.Length;
	}
	else
	{
		tempFloat = WorldInfo.RealTimeSeconds;
	}

	return tempFloat;
}

function JsonObject CreatePlayerGameSummary(TMPlayerReplicationInfo playerTMPRI)
{
	local JsonObject tempJson;

	tempJson = CreateGraylogMessage("PlayerGameSummary", "Statistics for one game from one player");

	// Game Stuff
	tempJson.SetStringValue("_PlayerName", playerTMPRI.PlayerName);
	tempJson.SetBoolValue("_IsBot", (TMTeamAIController(playerTMPRI.Owner) != None) );
	tempJson.SetStringValue("_Commander", playerTMPRI.commanderType);
	tempJson.SetStringValue("_Race", playerTMPRI.race);
	tempJson.SetIntValue("_Victory", playerTMPRI.bWon ? 1 : 0);
	tempJson.SetIntValue("_Kills", playerTMPRI.mStats[PS_KILLS]);
	tempJson.SetIntValue("_Deaths", playerTMPRI.mStats[PS_DEATHS]);
	tempJson.SetIntValue("_Assists", playerTMPRI.mStats[PS_ASSISTS]);
	tempJson.SetIntValue("_AllyTeam", playerTMPRI.allyId);
	tempJson.SetFloatValue("_FirstConflictTime",playerTMPRI.m_firstConflictTime);



	tempJson.SetFloatValue("_AverageCommanderLifetime", CalculateAverageCommanderLifetime(playerTMPRI));

	// Network Stuff
	tempJson.SetIntValue("_StatAvgInBPS", playerTMPRI.StatAvgInBPS);
	tempJson.SetIntValue("_StatAvgOutBPS", playerTMPRI.StatAvgOutBPS);
	tempJson.SetIntValue("_StatMaxOutBPS", playerTMPRI.StatMaxOutBPS);
	tempJson.SetIntValue("_StatMaxInBPS", playerTMPRI.StatMaxInBPS);
	tempJson.SetIntValue("_StatPingMax", playerTMPRI.StatPingMax);
	tempJson.SetIntValue("_StatPingMin", playerTMPRI.StatPingMin);

	// Stuff from end game stats
	tempJson.SetIntValue("_APM", playerTMPRI.mStats[PS_APM]);
	tempJson.SetIntValue("_DoughboySpawned", playerTMPRI.mStats[PS_SPAWNED_DOUGHBOY]);
	tempJson.SetIntValue("_OilerSpawned", playerTMPRI.mStats[PS_SPAWNED_OILER]);
	tempJson.SetIntValue("_SplitterSpawned", playerTMPRI.mStats[PS_SPAWNED_SPLITTER]);
	tempJson.SetIntValue("_ConductorSpawned", playerTMPRI.mStats[PS_SPAWNED_CONDUCTOR]);
	tempJson.SetIntValue("_SniperSpawned", playerTMPRI.mStats[PS_SPAWNED_SNIPER]);
	tempJson.SetIntValue("_SkybreakerSpawned", playerTMPRI.mStats[PS_SPAWNED_SKYBREAKER]);
	tempJson.SetIntValue("_DisruptorSpawned", playerTMPRI.mStats[PS_SPAWNED_DISRUPTOR]);
	tempJson.SetIntValue("_GrapplerSpawned", playerTMPRI.mStats[PS_SPAWNED_GRAPPLER]);
	tempJson.SetIntValue("_RambamSpawned", playerTMPRI.mStats[PS_SPAWNED_RAMBAM]);
	tempJson.SetIntValue("_VinecrawlerSpawned", playerTMPRI.mStats[PS_SPAWNED_VINECRAWLER]);
	tempJson.SetIntValue("_RegeneratorSpawned", playerTMPRI.mStats[PS_SPAWNED_REGENERATOR]);
	tempJson.SetIntValue("_TurtleSpawned", playerTMPRI.mStats[PS_SPAWNED_TURTLE]);
	tempJson.SetIntValue("_UnitsKilled", playerTMPRI.mStats[PS_UNITSKILLED]);
	tempJson.SetIntValue("_UnitsLost", playerTMPRI.mStats[PS_UNITSLOST]);

	// other stuff
	tempJson.SetStringValue("_SessionToken", playerTMPRI.SessionToken);
	tempJson.SetStringValue("_GameGUID", mGameGUID);

	return tempJson;
}

function array<JsonObject> CreatePlayerGameSummaryList(TMAllyInfo winningAllyInfo)
{
	local TMPlayerReplicationInfo tempTMPRI;
	local array<JsonObject> playerGameSummaryJsons;

	// Creates the game summary for every player
	// Set every player's win status and build their analytics json blob
	foreach self.AllActors(class'TMPlayerReplicationInfo', tempTMPRI)
	{
		// This shouldn't happen, but add the check to be safe.
		if (tempTMPRI == none)
		{
			continue;
		}

		if ( tempTMPRI.Owner != m_TMNeutralPlayerController )
		{
			if (winningAllyInfo != None && tempTMPRI.allyInfo == winningAllyInfo)
			{
				tempTMPRI.bWon = true;
				tempTMPRI.allyInfo.bWon = true;
			}
			else
			{
				tempTMPRI.bWon = false;
				tempTMPRI.allyInfo.bWon = false;
			}

			playerGameSummaryJsons.AddItem( CreatePlayerGameSummary(tempTMPRI) );
		}
	}

	return playerGameSummaryJsons;
}

function int WinningAllyId()
{
	local TMAllyInfo iterAllyInfo;

	foreach AllActors(class'TMAllyInfo', iterAllyInfo)
	{
		if (iterAllyInfo.bWon)
		{
			return iterAllyInfo.allyIndex;
		}
	}

	return -1;
}

function JsonObject CreateGameSummary()
{
	local JsonObject tempJson;

	tempJson = CreateGraylogMessage("GameSummary", "Statistics for one game");

	tempJson.SetStringValue("_MapName", WorldInfo.GetMapName(false));
	tempJson.SetIntValue("_GameLengthSeconds", WorldInfo.TimeSeconds);
	tempJson.SetIntValue("_GameLengthRealSeconds", WorldInfo.RealTimeSeconds);
	tempJson.SetIntValue("_NumHumanPlayers", self.minPlayers);
	tempJson.SetIntValue("_NumBots", self.numAIPlayers);
	tempJson.SetStringValue("_ExitCondition", self.m_exitcond);
	tempJson.SetIntValue("_ShrineDestroyed", self.mShrineKillCount);
	tempJson.SetIntValue("_DreadBeastKilled", self.mDreadBeastKillCount);
	tempJson.SetIntValue("_WinningAllyId", self.WinningAllyId());

	tempJson.SetStringValue("_GameGUID", mGameGUID);

	return tempJson;
}

function string GameOutcomeFor(TMPlayerReplicationInfo tempTMPRI)
{
	if (self.m_exitcond != EXIT_CONDITION_ENTIRE_TEAM_LEFT && self.m_exitcond != EXIT_CONDITION_NORMATIVE)
	{
		return "None";
	}
	if (tempTMPRI.allyId == class'TMGameInfo'.const.SPECTATOR_ALLY_ID)
	{
		return "None";
	}
	if (tempTMPRI.bWon)
	{
		return "Won";
	}
	
	return "Lost";
}

function JsonObject CreateEndGamePlayerStats()
{
	local JsonObject playerStatsJson;
	local JsonObject playerStatJson;
	local TMPlayerReplicationInfo tempTMPRI;

	playerStatsJson = new () class'JsonObject';
	foreach AllActors( class'TMPlayerReplicationinfo', tempTMPRI )
	{
		if (tempTMPRI.Owner != m_TMNeutralPlayerController)
		{
			playerStatJson = new class'JsonObject';

			playerStatJson.SetStringValue("PlayerName", tempTMPRI.PlayerName);
			playerStatJson.SetStringValue("Outcome", GameOutcomeFor(tempTMPRI));
			playerStatJson.SetStringValue("Commander", tempTMPRI.commanderType);
			playerStatJson.SetStringValue("Race", tempTMPRI.race);
			playerStatJson.SetIntValue("AllyId", tempTMPRI.allyId);
			if (tempTMPRI.mIsBot)
			{
				playerStatJson.SetIntValue("IsBot", 1);
			}
			else
			{
				playerStatJson.SetIntValue("IsBot", 0);
			}
			playerStatJson.SetIntValue("Kills", tempTMPRI.mStats[PS_KILLS]);
			playerStatJson.SetIntValue("Deaths", tempTMPRI.mStats[PS_DEATHS]);
			playerStatJson.SetIntValue("Assists", tempTMPRI.mStats[PS_ASSISTS]);

			playerStatsJson.ObjectArray.AddItem(playerStatJson);
		}
	}

	return playerStatsJson;
}

function JsonObject CreateEndGameStats()
{
	local JsonObject endGameStatsJson;

	endGameStatsJson = new () class'JsonObject';

	endGameStatsJson.SetStringValue("MapName", WorldInfo.GetMapName(false));
	endGameStatsJson.SetIntValue("GameLengthSeconds", WorldInfo.TimeSeconds);
	endGameStatsJson.SetIntValue("GameLengthRealSeconds", WorldInfo.RealTimeSeconds);
	endGameStatsJson.SetIntValue("NumHumanPlayers", self.minPlayers);
	endGameStatsJson.SetIntValue("NumBots", self.numAIPlayers);
	endGameStatsJson.SetStringValue("ExitCondition", self.m_exitcond);
	endGameStatsJson.SetObject("PlayerStats", CreateEndGamePlayerStats());
	endGameStatsJson.SetStringValue("GameGUID", mGameGUID);

	return endGameStatsJson;
}

// int/enum commandType eventually
// Dru TODO: Eventually send only team number instead of pawn? (most commands are multipawn anyways)
/**
 * Values left None/0/null will not be sent, conserves bandwidth considerably
*/
function HandleFastEvent(TMPlayerReplicationInfo replicationInfo, TMPawn pawn, TMFastEvent fe, bool isInternal)
{
	local TMPlayerController PC;
	local TMPlayerController pickOne;

	//// Dru TODO: This should no longer always be internal, double check this is being checked somewhere
	// pass every event to users for now (midterm)
	isInternal = true;

	// check validity **********
	// we only check validity if this isn't an internal call
	if(!isINternal)
	{
		if(pawn.OwnerReplicationInfo.GetTeamNum() != replicationInfo.GetTeamNum())
		{
			// Event not verified, just return
			//`log("Ali - Event not verified");
			return;
		}   
	}
	
	//pass fe back to playerController
	foreach self.WorldInfo.AllControllers(class'TMPlayerController', PC)
	{
		pickOne = PC;
		PC.ServerPassFastEventToClient(fe);
	}

	if (WorldInfo.NetMode == NM_DedicatedServer) // only execute the command once on the server
	{
		if(pickOne == none)
		{
			`warn("Taylor: We don't have a proper player controller set! Couldn't process fast event. Tell Taylor");
			return;
		}
		pickOne.GotFastEvent(fe);
	}
}

function array<string> arrayElementSplit( array<string> arrayin) {
	local array<string> arrayout;
	local int indexin, subindexin;
	local int subarraylen;
	local string temp;
	
	for(indexin = 0; indexin < arrayin.Length; indexin++) {
		if(len(arrayin[indexin]) > 400) {
			subarraylen = (len(arrayin[indexin]) / 400);
			for(subindexin = 0; subindexin < subarraylen; subindexin++) {
				temp = mid(arrayin[indexin], subindexin * 400, 400);
				arrayout.AddItem(temp);
			}
			temp = mid(arrayin[indexin], subarraylen * 400);
		} else {
			temp = arrayin[indexin];
		}
		temp $= "!s!h!i!t!b!a!l!l!s!";
		arrayout.AddItem(temp);
	}
	return arrayout;
}

function array<string> arrayElementCompress( array<string> arrayin) {
	local array<string> arrayout;
	local string temp;
	local int indexin;

	for(indexin = 0; indexin < arrayin.Length; indexin++) {
		temp $= arrayin[indexin];
		if("!s!h!i!t!b!a!l!l!s!" == right(temp, 19)) {
			temp = left(temp, len(temp) - 19);
			arrayout.AddItem(temp);
			temp = "";
		}
	}

	return arrayout;
}

/* LoadGameModeFromJSON
	Loads the GameMode JSON from the game mode's jsonFileName
*/
function LoadGameModeFromJSON()
{
	local string tempString;

	tempString = m_JsonParser.LoadJsonString( jsonFileName );
	ParseGameModeJSON( m_JsonParser.getJsonFromString( tempString ) );
}

/* ParseGameModeJSON
	Parses a JSON to fill in the game mode's data.
	Any game mode that wants custom data needs to override this function.
*/
function ParseGameModeJSON( JsonObject inJsonObject )
{
	// To be used by other classes
}

function SetGlobalSettings()
{
	local TMController controller;
	local JsonObject globalSettingJson;
	local int i;
	local int maxSpawns;

	for(i = 0; i < mJsonStringBackup_Global.Length; ++i)
	{
		globalSettingJson = class'JSONObject'.static.DecodeJson(mJsonStringBackup_Global[i]);
		if(globalSettingJson.GetStringValue("name") == "GlobalSettings.json")
		{
			maxSpawns = globalSettingJson.GetIntValue("TeamLives");
			mLineOfSightRangeForPawns = int(globalSettingJson.GetIntValue("ViewRadius") * mapInfo.sightScale);

			foreach self.mAllTMControllers(controller)
			{
				controller.GetTMPRI().allyInfo.score = maxSpawns;
			}
		}
	}

	m_ObjectiveText = "Deplete Enemy Respawns";
}

function UpdateUnits()
{
	local array<JsonObject> jsonObj;
	local int i;
	mJsonStringBackup = LoadUnitJsons();

	for(i=0;i<mJsonStringBackup.Length;i++)
	{
		jsonObj.AddItem(m_JsonParser.getJsonFromString(mJsonStringBackup[i]));
	}

	SendUnitCacheToAllClients();
	buildUnitCache(jsonObj);
}

function UpdateStatusEffects()
{
	local array<JsonObject> jsonObj;
	local int i;
	mJsonStringBackup_SE = GetJsonStringsFromManifest("\\StatusEffectsmanifest.json");

	for(i=0;i<mJsonStringBackup_SE.Length;i++)
	{
		jsonObj.AddItem(m_JsonParser.getJsonFromString(mJsonStringBackup_SE[i]));
	}

	SendStatusEffectCacheToAllClients();
	buildStatusEffectCache(jsonObj);
}

function SendUnitCacheToAllClients()
{
	local TMPlayerController controller;
	local TMTeamAIController aiController;

	mJsonStringBackup = self.arrayElementSplit(mJsonStringBackup);

	foreach self.AllActors(class'TMPlayerController', controller)
	{
		SendUnitCacheTo(controller);	
	}

	foreach self.AllActors(class'TMTeamAIController', aiController)
	{
		SendUnitCacheToAI(aiController);	
	}

	mJsonStringBackup = self.arrayElementCompress(mJsonStringBackup);
}


function SendUnitCacheToAI(TMTeamAIController aiController)
{
	local int i;
	if(aiController!=none)
	{
		// tell all the clients about it
		for(i=0;i<mJsonStringBackup.Length;i++)
		{
			aiController.setUnitCacheString(mJsonStringBackup[i],i, mJsonStringBackup.Length);
		}

		aiController.initBuildUnitCache();
	}
}

function SendUnitCacheTo(TMPlayerController controller)
{
	local int i;
	if(controller!=none)
	{
		// tell all the clients about it
		for(i=0;i<mJsonStringBackup.Length;i++)
		{
			controller.setUnitCacheString(mJsonStringBackup[i],i, mJsonStringBackup.Length);
		}

		controller.initBuildUnitCache();
	}
}

function SendStatusEffectCacheToAllClients()
{
	local TMPlayerController controller;

	mJsonStringBackup_SE = self.arrayElementSplit(mJsonStringBackup_SE);

	foreach self.AllActors(class'TMPlayerController', controller)
	{
		SendStatusEffectCacheTo(controller);	
	}

	mJsonStringBackup_SE = self.arrayElementCompress(mJsonStringBackup_SE);
}

function SendStatusEffectCacheTo(TMPlayerController controller)
{
	local int i;
	if(controller!=none)
	{
		// tell all the clients about it
		for(i=0;i<mJsonStringBackup_SE.Length;i++)
		{
			controller.setStatusEffectCacheString(mJsonStringBackup_SE[i],i, mJsonStringBackup_SE.Length);
		}
		
		controller.initBuildStatusEffectCache();
	}
}

function array<string> LoadUnitJsons()
{
	local array<string> jsonStringArray;
	local array<string> filesArray;
	local string manifestPath;
	local string manifestFile;
	local array<string> raceManifestPaths;

	raceManifestPaths.AddItem("\\" $  "Teutonian" $ "manifest.json");
	raceManifestPaths.AddItem("\\" $  "Tenshii" $ "manifest.json");
	raceManifestPaths.AddItem("\\" $  "Alchemist" $ "manifest.json");

	foreach raceManifestPaths(manifestPath)
	{
		filesArray = GetJsonStringsFromManifest(manifestPath);
		foreach filesArray(manifestFile)
		{
			jsonStringArray.AddItem(manifestFile);
		}
	}

	return jsonStringArray;
}

function array<string> GetJsonStringsFromManifest(string manifestPath)
{
	local JsonObject json;
	local array<string> jsonStringArray;
	local int count;
	local string jsonID;

	json = m_JsonParser.loadJSON(manifestPath ,true);
	count = 0;
	if(json != none)
	{
		while(true)
		{
			jsonID = "j" $ string(count);
			if(json.HasKey(jsonID))
			{
				jsonID = json.GetStringValue(jsonID);
				jsonID = m_JsonParser.LoadJsonString(jsonID);
				if(jsonID != "")
				{
					jsonStringArray.AddItem(jsonID);
				}
				else
				{
					break;
				}
			}
			else
			{
				break;
			}
			count++;
		}
	}

	return jsonStringArray;
}

function buildUnitCache(array<JsonObject> json)
{
	local int i;
	local TMUnit unit;

	unitCache.Remove(0, unitCache.Length); // reset the array
	for(i=0;i<json.Length;i++) {
		unit = new () class 'TMUnit';
		unit.LoadUnitData(json[i]);
		unitCache.AddItem(unit);
	}
}

function buildStatusEffectCache(array<JsonObject> statusEffectJson)
{
	// CREATE EVERY STATUS EFFECT
	local int i;

	// Reset the array (sometime this gets initialized twice!)
	statusEffectCache.Remove(0, statusEffectCache.Length);

	m_iMaxNumStatusEffects = statusEffectJson.Length;

	// Create space in the array for all of the status effects
	statusEffectCache.Add(m_iMaxNumStatusEffects);  // NOTE: I need to do this since the cache is index specific

	for(i=0;i<statusEffectJson.Length;i++)
	{
		AddStatusEffect( statusEffectJson[i] );
	}
}

// Dru TODO: Refactor to not be duplicate of TMPlayerController.AddStatusEffect()
function AddStatusEffect(JsonObject json)
{
	local JsonObject jsonObjectSE;
	local TMComponent comp;
	local int statusEffectEnum;
	local string statusEffect;

	jsonObjectSE = GetStatusEffectJson( json );

	if ( jsonObjectSE == none )
	{
		`log( "ERROR: Got an unexpected status effect. Check 'GetStatusEffectJson' for valid status effects", true, 'TMGameInfo' );
	}

	statusEffect = jsonObjectSE.GetStringValue( "name" );

	switch (statusEffect)
	{
	case "DisruptorPoison":
		comp = new() class'TMStatusEffectPoison';   // Taylor TODO: switch to Disruptor Poison
		statusEffectEnum = SE_DISRUPTOR_POISON;
		break;
	case "GrapplerSpeed":
		comp = new() class'TMStatusEffectSpeed';     // Taylor TODO: switch to Grappler Speed
		statusEffectEnum = SE_GRAPPLER_SPEED;
		break;
	case "OilerSlow":
		comp = new() class'TMStatusEffectSlowTar';  // Taylor TODO: switch to Oiler Slow
		statusEffectEnum = SE_OILER_SLOW;
		break;
	case "RegeneratorHeal":
		comp = new() class'TMStatusEffectRegeneratorHeal';
		statusEffectEnum = SE_REGENERATOR_HEAL;
		break;
	case "CreepKillHeal":
		comp = new() class'TMStatusEffectCreepKillHeal';
		statusEffectEnum = SE_CREEPKILL_HEAL;
		break;
	case "SplitterKnockup":
		comp = new() class'TMStatusEffectStunned';    // Taylor TODO: make this Knockup
		statusEffectEnum = SE_SPLITTER_KNOCKUP;
		break;
	case "PopspringKnockup":
		comp = new() class'TMStatusEffectPopspringKnockup';
		statusEffectEnum = SE_POPSPRING_KNOCKUP;
		break;
	case "TimeFreeze":
		comp = new() class'TMStatusEffectFrozen';   // Taylor TODO: make Time Freeze?
		statusEffectEnum = SE_TIME_FREEZE;
		break;
	case "RamBamQueenKnockback":
		comp = new() class'TMStatusEffectKnockback';
		statusEffectEnum = SE_RAMBAMQUEEN_KNOCKBACK;
		break;
	case "GrapplerKnockback":
		comp = new() class'TMStatusEffectKnockback';
		statusEffectEnum = SE_GRAPPLER_KNOCKBACK;
		break;
	default:
		`WARN( "Status Effect cache got an invalid status effect:"$statusEffect, true, 'TMGameInfo' );
		return;
	}

	jsonObjectSE.SetIntValue( "StatusEffectEnumValue", statusEffectEnum );
	comp.SetUpComponent( jsonObjectSE, none );
	statusEffectCache.Remove( statusEffectEnum, 1 );
	statusEffectCache.InsertItem( statusEffectEnum, comp ); // use the enum value for the index
}

// Need this function because our status effect objects in json are wrapped by the name. This is a temp fix
function JsonObject GetStatusEffectJson( JsonObject json )
{
	local JsonObject tempJson;

	tempJson = json.getObject( "DisruptorPoison" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "GrapplerSpeed" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "OilerSlow" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "RegeneratorHeal" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "CreepKillHeal" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "SplitterKnockup" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "PopspringKnockup" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "TimeFreeze" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.GetObject( "RamBamQueenKnockback" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.GetObject( "GrapplerKnockback" );
	if ( tempJson != none )
	{
		return tempJson;
	}

	`warn( "TMPlayerController::GetStatusEffectJson() missing json name for status effect!!!" );
}

function InitTMPRI(TMPlayerReplicationInfo tmpri, int allyId, int isSpectator, string PlayerName, string sessionToken, string Commander)
{
	local int i;
	local JsonObject json;

	if (Len(playerName) != 0)
	{
		tmPRI.PlayerName = playerName;
	}
	if (Len(sessionToken) != 0)
	{
		tmPRI.SessionToken = sessionToken;
	}

	if (isSpectator==1)
	{
		
		allyId = SPECTATOR_ALLY_ID;
		`log("Spectator joined the game ", true, 'Ali');
	}

	tmPRI.allyInfo = GetCreateAllyInfoForId(allyId);
	tmPRI.allyId = allyId;

	if ( Len(Commander) != 0 )
	{
		tmPRI.commanderType = Commander;
	}

	SetupRaceAndUnits(tmPRI);

	//this will init the data we will need for spawning pop cap etc
	for(i= 0;i < mJsonStringBackup_Global.Length ;i++)
	{
		json = class'JsonObject'.static.DecodeJson( mJsonStringBackup_Global[i] );
		if( json.GetStringValue("name") == "Teutonian" && tmPRI.race == "Teutonian")
		{
			// Allows number of starting base units to be set per-map in the editor (for tutorial, etc.)
			if ( TMMapInfo(WorldInfo.GetMapInfo()).mNumStartingBaseUnits == -1 )
			{
				tmPRI.m_startingUnits = json.GetIntValue("StartingUnits");
			}
			else
			{
				tmPRI.m_startingUnits = TMMapInfo(WorldInfo.GetMapInfo()).mNumStartingBaseUnits;
			}
			tmPRI.UnitsPerNeutral = json.GetIntValue("NeutralGain");
			tmPRI.PopulationCap = json.GetIntValue("PopulationCap");
		}
		else if( json.GetStringValue("name") == "Alchemist" &&  tmPRI.race == "Alchemist")
		{
			// Allows number of starting base units to be set per-map in the editor (for tutorial, etc.)
			if ( TMMapInfo(WorldInfo.GetMapInfo()).mNumStartingBaseUnits == -1 )
			{
				tmPRI.m_startingUnits = json.GetIntValue("StartingUnits");
			}
			else
			{
				tmPRI.m_startingUnits = TMMapInfo(WorldInfo.GetMapInfo()).mNumStartingBaseUnits;
			}
			tmPRI.UnitsPerNeutral = json.GetIntValue("NeutralGain");
			tmPRI.PopulationCap = json.GetIntValue("PopulationCap");
		}
	}
	

	if (allyId == 0)
	{
		tmPRI.mTeamColorIndex = mTeamBlueColorIndex++;
	}
	else if (allyId == 1)
	{
		tmPRI.mTeamColorIndex = mTeamRedColorIndex++;
	}
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local PlayerController newPlayer;
	local int allyId;
	local int isSpectator;
	local string playerName;
	local string sessionToken;
	local TMPlayerReplicationInfo tmPRI;
	local TMPlayerController tmPC;
	local string commander;
	local string steamName;
	local string tmName;

	allyId = GetIntOption( Options, "Ally", 0 );
	isSpectator = GetIntOption( Options, "SpectatorOnly", 0 );

	// Check if we have a steam name
	steamName = ParseOption( Options, "Name" );
	tmName = ParseOption( Options, "PlayerName" );

	// Only use the steam name if the TMName isn't set
	if( tmName != "" ) {
		playerName = tmName;
	} else {
		playerName = steamName;
	}

	sessionToken = ParseOption( Options, "SessionToken" );
	commander = ParseOption( Options, "Commander" );
	newPlayer = super.Login(Portal, Options, UniqueID, ErrorMessage);

	tmPRI = TMPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
	tmPC = TMPlayerController(NewPlayer);

	// Check for tutorial-specific commander choices
	if( IsTutorial() ) {
		commander = GetCommanderForTutorial();
	}

	InitTMPRI(tmPRI, allyId, isSpectator, playerName, sessionToken, commander);

	tmPC.PlayerId = NewPlayer.PlayerReplicationInfo.PlayerID;
	tmPC.m_allyId = tmPRI.allyId;
	m_TMPlayerController = tmPC;

	if (Len(commander) != 0)
	{
		TMPlayerController(NewPlayer).commanderType = commander;
	}

	if ( !WorldInfo.GetMapInfo().IsA('TMMapInfo') )
	{
		`WARN("MAP INFO NOT SET TO TMMapInfo IN EDITOR, PLEASE SET");
	}
	
	return newPlayer;
}

function SetupRaceAndUnits(TMPlayerReplicationInfo tmPRI)
{
	local array<string> raceUnitNames;
	local int i;

	tmPRI.race = GetRaceNameForCommander(tmPRI.commanderType);
	raceUnitNames = GetUnitNamesForRace(tmPRI.race);
	for (i = 0; i < raceUnitNames.Length; ++i)
	{
		tmPRI.raceUnitNames[i] = raceUnitNames[i];
	}
}

function string GetRaceNameForCommander(string commanderName)
{
	local array<string> teutonianCommanders;
	local array<string> alchemistCommanders;

	teutonianCommanders.AddItem("TinkerMeister");
	teutonianCommanders.AddItem("Rosie");
	teutonianCommanders.AddItem("RoboMeister");

	alchemistCommanders.AddItem("Salvator");
	alchemistCommanders.AddItem("HiveLord");
	alchemistCommanders.AddItem("RamBamQueen");
	alchemistCommanders.AddItem("Taylor");

	if (teutonianCommanders.Find(commanderName) != INDEX_NONE)
	{
		return "Teutonian";
	}
	else if (alchemistCommanders.Find(commanderName) != INDEX_NONE)
	{
		return "Alchemist";
	}
	
	`warn("NO RACE DEFINED FOR COMMANDER:"$commanderName);
}

function array<string> GetUnitNamesForRace(string raceName)
{
	local array<string> raceUnitNames;

	if (raceName == "Teutonian")
	{
		raceUnitNames[0] = "DoughBoy";
		raceUnitNames[1] = "Conductor";
		raceUnitNames[2] = "Sniper";
		raceUnitNames[3] = "Splitter";
		raceUnitNames[4] = "Oiler";
		raceUnitNames[5] = "Skybreaker";
	}
	else if (raceName == "Alchemist")
	{
		raceUnitNames[0] = "RamBam";
		raceUnitNames[1] = "Disruptor";
		raceUnitNames[2] = "Grappler";
		raceUnitNames[3] = "VineCrawler";
		raceUnitNames[4] = "Turtle";
		raceUnitNames[5] = "Regenerator";
	}
	else
	{
		`warn("NO UNITS DEFINED FOR RACE:"$raceName);
	}
	
	return raceUnitNames;
}

/**
 * Gets the AllyInfo for the given Id or creates it if it doesn't yet exist
 */
function TMAllyInfo GetCreateAllyInfoForId(int allyId)
{
	local bool allyExists;
	local TMAllyInfo ally;
	local TMPlayerController tempTMPC;
	local int i;

	allyExists = false;
	for ( i=0; i < allies.Length; i++ )
	{
		if(allies[i].allyIndex == allyId) {
			ally = allies[i];
			allyExists = true;
			break;
		}
	}

	if(!allyExists)
	{
		ally = Spawn(tmAllyInfoClass);
		ally.allyIndex = allyId;
		allies.AddItem(ally);
		foreach WorldInfo.AllControllers(class'TMPlayerController', tempTMPC)
		{
			tempTMPC.mAllyInfos.addItem(ally);
		}
	}

	return ally;
}

//
// Called after a successful login. This is the first place
// it is safe to call replicated functions on the PlayerController.
//
event PostLogin( PlayerController NewPlayer ) 
{
	local TMPlayerController NewPlayerController;

	NewPlayerController = TMPlayerController(NewPlayer);

	if (mapInfo != none)
	{
		NewPlayerController.mapInfo = mapInfo;                // server
		if (WorldInfo.NetMode == NM_DedicatedServer && NewPlayerController.m_allyId != SPECTATOR_ALLY_ID)
		{
			NewPlayerController.SetFoWManager( GetFowManagerFor( NewPlayerController.m_allyId ) );
		}
		NewPlayerController.ClientInitializeMap(mapInfo, NewPlayerController.m_allyId);     // client
		NewPlayerController.ClientSetGameMode(GAME_MODE_NAME);
		NewPlayerController.mGameMode = GAME_MODE_NAME; 	// set the game mode name on the server also
	}

	// update player count
	if (NewPlayer.PlayerReplicationInfo.bOnlySpectator)
	{
		NumSpectators++;

		// Dru TODO: Why are spectators initialized at a different time than other players?
		NewPlayerController.ClientInitializeMatch(SPECTATOR_ALLY_ID);      // allyindex is set to -3 for spectators 
		
		TMPlayerReplicationInfo(NewPlayerController.PlayerReplicationInfo).allyId = SPECTATOR_ALLY_ID;

		//if ( bGameStarted )
		//{
			m_haventReceivedUnitCache.AddItem( NewPlayer.PlayerReplicationInfo.PlayerID ); // Same as tmpc.PlayerId, somewhere up the chain
			self.SetTimer(1/10,true, NameOf( CheckForLateComersUnitCacheConfirmation ) );
		//}
		//super.PostLogin(NewPlayer);
	}
	else if (WorldInfo.IsInSeamlessTravel() || NewPlayer.HasClientLoadedCurrentWorld())
	{
		NumPlayers++;
	}
	else
	{
		NumTravellingPlayers++;
	}
	
	`log("Player " $TMPlayerController(newPlayer).GetTMPRI().PlayerName$ " joined. Active Human Players is now " $GetNumPlayers());
	self.mPlatformConnection.UpdateActiveHumanPlayerCount(GetNumPlayers(), self.mNodeLocalPort, self.mJobId);

	mJsonStringBackup = self.arrayElementSplit(mJsonStringBackup);
		
	SendUnitCacheTo(NewPlayerController);

	mJsonStringBackup = self.arrayElementCompress(mJsonStringBackup);

	NewPlayerController.InitAudioManager();

	if( !NewPlayer.PlayerReplicationInfo.bOnlySpectator && NumPlayers >= minPlayers ) 
	{
		self.SetTimer(1/10, true, NameOf( CheckUnitCacheConfirmationsToStartGame ));
	}
}

function TMFoWManager GetFowManagerFor(int AllyId)
{
	local TMFowManager fowManager;

	foreach fowManagers(fowManager)
	{
		if (fowManager.GetAllyID() == AllyId)
		{
			return fowManager;
		}
	}

	if( AllyId == SPECTATOR_ALLY_ID )
	{
		fowManager = Spawn(class'TMFOWManagerSpectator', self);
	}
	else
	{
		fowManager = Spawn(class'TMFOWManagerDedicatedServer', self);
	}

	fowManager.Initialize(mapInfo, AllyId);
	fowManagers.AddItem(fowManager);

	return fowManager;
}

function CheckForLateComersUnitCacheConfirmation()
{
	local int i;
	local TMPlayerController iterController;

	if ( !bGameStarted )
	{
		return;
	}

	foreach m_recievedUnitCache( i )
	{
		if ( INDEX_NONE != m_haventReceivedUnitCache.Find( i ) && i != -1 )
		{
			m_haventReceivedUnitCache.RemoveItem( i );
			foreach WorldInfo.AllControllers( class'TMPlayerController', iterController )
			{
				if ( iterController.PlayerId == i )
				{
					iterController.Player.CurrentNetSpeed = 80000;
					iterController.Player.ConfiguredInternetSpeed = 80000;
					iterController.Player.ConfiguredLanSpeed = 80000;
					iterController.ClientInitializeMatch(TMPlayerReplicationInfo(iterController.PlayerReplicationInfo).allyId);
					Super.PostLogin( iterController );
				}
			}
		}
	}

	if ( m_haventReceivedUnitCache.Length == 0 )
	{
		ClearTimer( NameOf( CheckForLateComersUnitCacheConfirmation ) );
	}
}

function CheckUnitCacheConfirmationsToStartGame()
{
	local TMPlayerController iterController;

	if ( bGameStarted )
	{
		ClearTimer( NameOf( CheckUnitCacheConfirmationsToStartGame ) );		
		return;
	}

	if ( m_recievedUnitCache.Length < minPlayers )
	{
		return; // not enough stuff in the unit cache
	}

	// make sure they're non-spectatorPlayers, and valid
	ForEach WorldInfo.AllControllers(class'TMPlayerController', iterController) 
	{
		if ( iterController.GetTMPRI().allyId != SPECTATOR_ALLY_ID )
		{   
			if ( m_recievedUnitCache.Find( iterController.PlayerId ) == INDEX_NONE && iterController.PlayerId != INDEX_NONE )
			{
				return; // If you ever find a non-spectator player whose ID isn't in the cache, you're not done yet
			}
		}
	}

	ClearTimer( NameOf( CheckUnitCacheConfirmationsToStartGame ) ); // if we got here, we're good, don't call us anymore
	GetThePartyStarted(); // Start the game
}

/** Starts the game for real by calling super.PostLogin() on the playercontrollers */
function GetThePartyStarted()
{
	local TMPlayerController iterController;

	ForEach WorldInfo.AllControllers(class'TMPlayerController', iterController) {

		// only start players whose unitCache Confirmations have been received
		if ( ( m_recievedUnitCache.Find( iterController.PlayerId ) != INDEX_NONE && iterController.PlayerId != INDEX_NONE ) || 
			( iterController.PlayerId == INDEX_NONE && m_recievedUnitCache.Find( iterController.PlayerId ) == INDEX_NONE ) )
		{
			if ( iterController.PlayerReplicationInfo != None && iterController.PlayerReplicationInfo.Team != None) {
				//`log("Ali - PostLogin for "@iterController.Name);

				/* These numbers are necessary to increase our bandwidth cap, otherwise our lag will be enormous! */
				iterController.Player.CurrentNetSpeed = 80000;
				iterController.Player.ConfiguredInternetSpeed = 80000;
				iterController.Player.ConfiguredLanSpeed = 80000;
				iterController.ClientInitializeMatch(TMPlayerReplicationInfo(iterController.PlayerReplicationInfo).allyId);
				Super.PostLogin( iterController );
			}
			else if(iterController.PlayerReplicationInfo.bOnlySpectator)
			{
				iterController.Player.CurrentNetSpeed = 80000;
				iterController.Player.ConfiguredInternetSpeed = 80000;
				iterController.Player.ConfiguredLanSpeed = 80000;
				iterController.ClientInitializeMatch(TMPlayerReplicationInfo(iterController.PlayerReplicationInfo).allyId);
				Super.PostLogin( iterController );
			}
		}
	}
	self.ClearTimer('CheckForUnitCacheConfirmation');
}

//function CheckForUnitCacheConfirmation()
//{
//	local TMPlayerController iterController;
//	if( m_recievedUnitCache.Length >= minPlayers)
//	{
//		ForEach WorldInfo.AllControllers(class'TMPlayerController', iterController) {
//			if ( iterController.PlayerReplicationInfo != None && iterController.PlayerReplicationInfo.Team != None) {
//				//`log("Ali - PostLogin for "@iterController.Name);

//				/* These numbers are necessary to increase our bandwidth cap, otherwise our lag will be enormous! */
//				iterController.Player.CurrentNetSpeed = 80000;
//				iterController.Player.ConfiguredInternetSpeed = 80000;
//				iterController.Player.ConfiguredLanSpeed = 80000;

//				iterController.ClientInitializeMatch(TMPlayerReplicationInfo(iterController.PlayerReplicationInfo).allyId);

//				Super.PostLogin( iterController );
//			}
//			else if(iterController.PlayerReplicationInfo.bOnlySpectator)
//			{
//				iterController.Player.CurrentNetSpeed = 80000;
//				iterController.Player.ConfiguredInternetSpeed = 80000;
//				iterController.Player.ConfiguredLanSpeed = 80000;
//				iterController.ClientInitializeMatch(TMPlayerReplicationInfo(iterController.PlayerReplicationInfo).allyId);
//				Super.PostLogin( iterController );
//			}
//		}
//		self.ClearTimer('CheckForUnitCacheConfirmation');
//	}
//}

function Vector GetSpawnAround(Vector SpawnLocation, float ext) {
	local Vector newSpawn;
	local Actor hitactor;
	local Vector traceStart;
	local Vector traceEnd;
	local Vector hitNormal;
	local float angle;
	local int radtemp, i;
	local bool collide;
	local Vector Extent;
	local Vector newloc;
	local bool block;
	local BlockingVolume BlockingVolume;

	radtemp=0;
	angle=0;
	newSpawn.Z=0;
	
	Extent.X=ext;
	Extent.Y=ext;
	Extent.Z=1;
	SpawnLocation.Z+=Extent.Z/2;
	block=false;
	collide=false;
	i=0;
	while(i < 100) {
		i++;
		newloc.X=SpawnLocation.X + Cos(angle) * radtemp;
		newloc.Y=SpawnLocation.Y + Sin(angle) * radtemp;
		newloc.Z=SpawnLocation.Z;

		traceStart.X = newloc.X;
		traceStart.Y = newloc.Y;
		traceStart.Z = 10000.0f;

		traceEnd.X = newloc.X;
		traceEnd.Y = newloc.Y;
		traceEnd.Z = -10000.0f;

		ForEach TraceActors( class'Actor', hitactor, newSpawn, hitNormal, traceEnd, traceStart, Extent,, TRACEFLAG_Bullet) {
			if((hitactor.IsA('StaticMeshActor') && !hitactor.bCanStepUpOn) || (hitactor.IsA('TMPawn') && Pawn(hitactor).Health > 0)) {
				collide=true;
				break;
			}
		}
		if(collide==false) {
			Trace(newSpawn, hitNormal, newloc, SpawnLocation, false,,, TRACEFLAG_Blocking);

			ForEach TraceActors( class'BlockingVolume', BlockingVolume, newSpawn, hitNormal, newloc, SpawnLocation,,, TRACEFLAG_Blocking) {
				block=true;
				break;
			}   
			if(block==false) {
				Trace(newSpawn, hitNormal, traceEnd, traceStart, false,,,);

				return newSpawn;
			}
		}
		block=false;
		collide=false;
		
		if(angle >= 2 * PI || radtemp == 0) {
			angle=0;
			if(TMPawn(hitactor) != None) {
				radtemp+=2*TMPawn(hitactor).GetCollisionRadius();
			}
			else {
				radtemp+=ext;
			}
			if(radtemp > 10000) {
				return newSpawn;
			}
		}
		else {
			if(TMPawn(hitactor) != None) {
				angle+=2*TMPawn(hitactor).GetCollisionRadius()/radtemp;
			}
			else {
				angle+=ext/radtemp;
			}
		}
	}
	`Warn("Unable to spawn unit within given iterations!");
	return Vect(0,0,0);
}

function TMPawn RequestUnit(string unitType, TMPlayerReplicationInfo ownerReplicationInfo, Vector SpawnLocation, bool IsRallyPointValid, Vector locationRallyPoint, Actor actorRallyPoint, optional bool dontUseRadialSpawn)
{
	local int i, j;
	local TMPawn pawn;
	local string cacheName;
	local TMController tmController;

	for(i = 0; i < unitCache.Length; ++i)
	{
		cacheName = unitCache[i].m_UnitName;
		if(cacheName == unitType)
		{
			if(ownerReplicationInfo.Population + unitCache[i].m_Data.mPopulationCost > ownerReplicationInfo.PopulationCap)
			{
				// Tell this client that he's already at max pop
				foreach mAllTMControllers(tmController)
				{
					if(tmController.GetTMPRI().PlayerID == ownerReplicationInfo.PlayerID)
					{
						TMPlayerController(tmController).ClientTriedToGetUnitAtMaxPop();
					}
				}

				return none;
			}
			else
			{
				if(!dontUseRadialSpawn)
				{
					SpawnLocation=GetSpawnAround(SpawnLocation, unitCache[i].m_Data.m_skeletalMesh.Bounds.SphereRadius * unitCache[i].m_scale);
				}

				//offset = unitCache[i].m_Data.m_skeletalMesh.Bounds.SphereRadius;

				//SpawnLocation = SpawnLocation + Vect(0.0f, 0.0f, 1.0f) * offset;

				// SpawnLocation.Z += unitCache[i].m_Data.m_skeletalMesh.Bounds.SphereRadius * unitCache[i].m_scale * 0.5; //// Dru TODO: Shouldn't need 1.5f anymore, I don't think, with radial spawn
				SpawnLocation.Z += unitCache[i].m_Data.m_skeletalMesh.Bounds.BoxExtent.Z * unitCache[i].m_scale;

				pawn = RequestTMPawn(ownerReplicationInfo, SpawnLocation, isRallyPointValid, locationRallyPoint, actorRallyPoint);

				if( pawn == none )
				{
					`warn( "TMGameInfo::RequestUnit() ERROR: RequestTMPawn returned a bad pawn!" );
					return none;
				}

				ownerReplicationInfo.Population += unitCache[i].m_Data.mPopulationCost;
				pawn.SetupUnit(unitCache[i]); // first set up the unit here on the server
				pawn.m_UnitType = unitType; // setting the unit's type will let clients set their unit
				



				// Hide the pawn for FoW, i'll be set to visible if it should be
				//pawn.Hide();

				// GGH:
				// pawn.m_UpdateHash = true;
				m_PawnHash.PutByIntKey(pawn.pawnId, pawn);
				mTMPawnList.AddItem(pawn);

				if (!pawn.IsPawnNeutral(pawn) && pawn.m_UnitType != "Nexus" && pawn.m_UnitType != "Brute")
				{
					switch(unitType) {
					case "doughboy": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_DOUGHBOY );
						break;
					case "oiler": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_OILER );
						break;
					case "splitter": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_SPLITTER );
						break;
					case "conductor": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_CONDUCTOR );
						break;
					case "sniper": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_SNIPER );
						break;
					case "skybreaker": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_SKYBREAKER );
						break;
					case "disruptor": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_DISRUPTOR );
						break;
					case "grappler": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_GRAPPLER );
						break;
					case "rambam": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_RAMBAM );
						break;
					case "vinecrawler": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_VINECRAWLER );
						break;
					case "turtle": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_TURTLE );
						break;
					case "Regenerator": 
						UpdateStats( ownerReplicationInfo, PS_SPAWNED_REGENERATOR );
						break;
					}

					for(j = 0; j < ArrayCount(ownerReplicationInfo.raceUnitNames); j++)
					{
						if(ownerReplicationInfo.raceUnitNames[j] == unitType)
						{
							ownerReplicationInfo.mUnitCount[j]++;
							break;
						}
					}
				}

				return pawn;
			}
		}
	}
	
	`WARN("no unitType of type " @ unitType @ " found in buildableUnits. RequestUnit()");
	return None;
}

function TMPawn RequestTMPawn(TMPlayerReplicationInfo RequestingReplicationInfo, Vector SpawnLocation, bool IsRallyPointValid, Vector RallyPoint, Actor RallyPointActorReference, optional TMPawn existingPawn)
{
	local TMPawn TMPawn;
	local UDKRTSAIController UDKRTSAIController;

	if (RequestingReplicationInfo == None)
	{
		return None;
	}
	if(existingPawn != None) {
		TMPawn = existingPawn;
	}
	else {
		TMPawn = Spawn(class'TMPawn',,, SpawnLocation,,,true);
		//TMPawn.Hide();      // hide newly spawned pawns in order to not flash under FoW for enemies // commented out again because it broke attack - dru
	}
	if (TMPawn != None)
	{
		TMPawn.pawnId = nextPawnId;
		TMPawn.sightRadiusTiles = mLineOfSightRangeForPawns;

		nextPawnId++;
		
		if (TMPawn.bDeleteMe)
		{
			`Warn(Self$":: RequestPawn:: Deleted newly spawned pawn, refund player his money?");
		}
		else
		{
			TMPawn.SetOwnerReplicationInfo(RequestingReplicationInfo);
			TMPawn.SetOwningPlayerId(RequestingReplicationInfo.PlayerID);
			TMPawn.ServerSetPawnController();
			TMPawn.SetAllyId(RequestingReplicationInfo.allyId);
			if(TMPawn.OwnerReplicationInfo == m_TMNeutralPlayerController.PlayerReplicationInfo)
			{
				TMPawn.ControllerClass = class'TMNeutralAIController';
			}
			TMPawn.SpawnDefaultController();

			UDKRTSAIController = UDKRTSAIController(TMPawn.Controller);
			if (UDKRTSAIController != None)
			{
				if (RallyPointActorReference != None)
				{
					`WARN("Not Yet Implemented: Rally-to-Actor.");
				}
				else if (IsRallyPointValid)
				{
					UDKRTSAIController.MoveToPoint(RallyPoint);
				}
			}
		}
	}

	return TMPawn;
}

function PlayerController SpawnPlayerController(vector SpawnLocation, rotator SpawnRotation)
{

	return Spawn(class'TMPlayerController',,, SpawnLocation, SpawnRotation);

}

reliable server function PrintPawnz()
{
	local array<HashMapEntry> table;
	local HashMapEntry entry;
	table = m_PawnHash.getTable();

	foreach table(entry)
	{
		if(entry.value != None)
		{
			`log(string(entry.key) @ TMPawn(entry.value).m_UnitType @ string(TMPawn(entry.value).pawnId), true, 'Graham');
		}
	}
}

exec function PrintUnitCacheStrings()
{
	local string str;
	
	`log("Number: "@mJsonStringBackup.Length);

	foreach mJsonStringBackup(str)
	{
		`log(str, true, 'Dru');
	}
}

function Timeout() {
	local TMPlayerController tmController;
	if(bGameStarted) {
		return;
	}
	m_exitcond="Timeout";
	foreach self.AllActors(class'TMPlayerController', tmController)
	{
			RestartPlayer( tmController );
			tmController.ClientEndGameInVictory(false);
	}
	
	if (WorldInfo.NetMode == NM_DedicatedServer) {
		ForceEndGameOnServer();
	}
	self.ClearTimer(nameof(Timeout));
}

function ForceEndGameOnServer()
{
	DoneWaitingForStats();
	ReadyToEndGameOnServer();
}

function ReadyToEndGameOnServer()
{
	mShouldEndGameOnServer = true;
	TryEndGameOnServer();
}

function DoneWaitingForStats()
{
	mDoneWaitingForStatsProcessing = true;
	TryEndGameOnServer();
}

/** Should only be called by ReadyToEndGameOnServer() or DoneWaitingForStats() */
function TryEndGameOnServer()
{
	if (mShouldEndGameOnServer && mDoneWaitingForStatsProcessing)
	{
		EndGameOnServer();
	}
}

/** This should only be called by TryEndGameOnServer */
function EndGameOnServer()
{
	if ( WorldInfo.NetMode == NM_DedicatedServer )
	{
		ConsoleCommand("Quit");
	}
}

function ParseStartingGameStats()
{
	local array<JsonObject> jsonArray; 
	local int i;
	i = 0;
	
	for(i = 0; i < mJsonStringBackup_Global.Length ; i++)
	{
		jsonArray.AddItem(  class'JSONObject'.static.DecodeJson( mJsonStringBackup_Global[i] ) );
	}

	for(i = 0; i < jsonArray.Length ; i++)
	{
		if(jsonArray[i].GetStringValue("name") == "GlobalSettings.json")
		{
			mGameSpeed = jsonArray[i].GetFloatValue("GameSpeed");
			self.WorldInfo.Game.SetGameSpeed(mGameSpeed);
		}
	}
}

function SetClientsObjectiveText(string text)
{
	local TMPlayerController outController;

	foreach WorldInfo.AllControllers(class'TMPlayerController', outController)
	{
		outController.ClientSetObjectiveText(text);
	}
}

function SetClientsGameStartTime()
{
	local TMPlayerController outController;

	foreach WorldInfo.AllControllers(class'TMPlayerController', outController)
	{
		outController.SetGameStartTime();
	}
}

function StartMatch()
{
	local TMController iterController;
	local TMPlayerController iterTMPC;
	local TMTeamAIController iterTAIC;

	//SendUnitCacheToAllClients();
	SendStatusEffectCacheToAllClients();

	// Spawn the "Neutral" team
	m_TMNeutralPlayerController = Spawn(class'TMNeutralPlayerController');
	if(!ChangeTeam(m_TMNeutralPlayerController, NumPlayers, true))
	{
		`log("ChangeTeam for the NeutralPlayerController failed. Team Index "@NumPlayers, true, 'Lang');
	}
	UDKRTSPlayerReplicationInfo(m_TMNeutralPlayerController.PlayerReplicationInfo).PopulationCap = 999;
	m_TMNeutralPlayerController.PlayerReplicationInfo.PlayerName = "A monster";

	Super.StartMatch();

	foreach WorldInfo.AllControllers(class'TMTeamAIController', iterTAIC)
	{
		mAllTMControllers.AddItem(iterTAIC);
	}

	foreach WorldInfo.AllControllers(class'TMPlayerController', iterTMPC)
	{
		mAllTMControllers.AddItem(iterTMPC);
	}

	// Initialize the bots (they rely on all players being set up before they initialize their knowledge)
	foreach mAllTMControllers( iterController )
	{
		if( TMTeamAIController( iterController ) != none )
		{
			TMTeamAIController( iterController ).Initialize();
		}
	}

	SetGlobalSettings();

	bGameStarted = true;

	SetClientsGameStartTime();
	SetClientsObjectiveText(m_ObjectiveText);
}

function StartBots()
{
	CreateBots();
	
	super.StartBots();
}

function CreateBots()
{
	local int i;
	local botCommandlineOptions iterBot;

	// Spawn all the AI player controllers
	for (i = 0; i < numAIPlayers; ++i)
	{
		iterBot = listOfBotCommandlineOptions[i];
		CreateBot(iterBot.CommanderName, NumPlayers + i + 1, iterBot.allyID, iterBot.PlayerName, iterBot.botDifficulty);
	}
}

function TMTeamAIController CreateBot(string BotCommanderType, int BotTeam, int BotAllyId, string botPlayerName, int botDifficulty)
{
	local TMTeamAIController bot;
	
	bot = Spawn(class'TMTeamAIController');
	if (bot != None)
	{
		bot.GetTMPRI().PlayerID = BotTeam; 	// I'm pretty sure this is unique... Dru, what do you think? -Taylor
		ChangeTeam(bot, BotTeam, true);
		InitTMPRI(bot.GetTMPRI(), BotAllyId, 0, botPlayerName, "1234567", BotCommanderType);
		bot.GetTMPRI().mIsBot = true;
		bot.PreInitialize(GetFowManagerFor(BotAllyId), botDifficulty);
	}

	return bot;
}

function SendPlayerDeathNotification(TMPlayerReplicationInfo killedTMPRI, TMPlayerReplicationInfo killerTMPRI)
{
	local TMPlayerController iterPC;
	local string KilledByNotification;

	if (killedTMPRI == None)
	{
		`WARN("A None killedTMPRI was passed to SendPlayerDeathNotification", true, 'dru');
		return;
	}

	foreach WorldInfo.AllControllers(class'TMPlayerController', iterPC)
	{
		//Text notification
		KilledByNotification = "";

		if (killerTMPRI == iterPC.PlayerReplicationInfo     //Killer is iterating PC
			&& killedTMPRI != iterPC.PlayerReplicationInfo                         //Dead is not iterating PC
			&& killedTMPRI != killerTMPRI)          //Dead is not killer
		{
			KilledByNotification = "You Have Killed"@killedTMPRI.PlayerName;
			iterPC.ClientRegisterKill();
		}
		else if (killedTMPRI != iterPC.PlayerReplicationInfo)                        //Dead is not iterating PC
		{
			if (killedTMPRI == killerTMPRI)         //Edits notification if killed by neutral (self)
			{
				KilledByNotification = killedTMPRI.PlayerName@"Has Been Killed";
			}
			else
			{
				KilledByNotification = killerTMPRI.PlayerName@"Has Killed"@killedTMPRI.PlayerName;
			}
			
			if (killedTMPRI == m_TMNeutralPlayerController.PlayerReplicationInfo )
			{
				`WARN("Neutral killed a neutral?");
			}
			else if ( killedTMPRI.PlayerName == "" )
			{
				GetScriptTrace();
				`WARN("THERE WAS A FIREFIGHT. A.K.A, that weird killed notification bug occurred with this object:"$killedTMPRI);
			}
		}

		if (KilledByNotification != "")
		{
			iterPC.ClientPlayNotification(KilledByNotification, 2000);

			//Audio notification
			if (killedTMPRI.PlayerName != iterPC.PlayerReplicationInfo.PlayerName)
			{
				if (killedTMPRI.allyInfo == TMPlayerReplicationInfo(iterPC.PlayerReplicationInfo).allyInfo)
				{
					iterPC.ClientPlayVO(SoundCue'VO_Main.Male_AlliedCommanderFalled_Cue', true, true);
				}
				else
				{
					iterPC.ClientPlayVO(SoundCue'VO_Main.Male_EnemyCommanderFallen_Cue', true, true);
				}
			}
		}
	}
}

/* OnKilledUnit
	Called when a pawn kills another unit.
*/
function OnKilledUnit( TMPawn inKiller, TMPawn inDeadPawn )
{
	// See if we killed a neutral pawn. (Includes brute and nexus kills)
	if( inDeadPawn.IsPawnNeutral( inDeadPawn ) )
	{
		if( inDeadPawn.m_UnitType == "Nexus" )
		{
			OnKilledNexus( inKiller );
		}
		else if( inDeadPawn.m_UnitType == "Brute" || inDeadPawn.m_UnitType == "Brute_Tutorial" )
		{
			OnKilledBrute( inKiller, inDeadPawn.location );
		}
		else if( TMNeutralAIController( inDeadPawn.Controller ).mShouldSpawnBaseUnits )
		{
			// Spawn base units
			SpawnBaseUnitsAround( inKiller, inKiller.m_Controller.GetTMPRI().UnitsPerNeutral, inDeadPawn.Location );
		}
	}
	else
	{
		// Register the player unit kill we just got
		UpdateStats( TMPlayerReplicationInfo(inKiller.OwnerReplicationInfo), PS_UNITSKILLED );
	}
}

/* SpawnBaseUnitsAround
	TMPawn 	inOwner - 			pawn who will own the units. Also the pawn where the units will spawn.
	int 	inNumUnits - 		number of units to spawn
	Vector 	inSourcePosition - 	position where the units are created from.
		Example: if you kill a neutral to get base units, the source position is the neutral's position
*/
function SpawnBaseUnitsAround( TMPawn inOwner, int inNumUnits, Vector inSourcePosition )
{
	local TMPlayerReplicationInfo playerInfo;
	local TMPawn spawnedPawn;
	local int i;

	playerInfo = TMPlayerReplicationinfo( inOwner.OwnerReplicationInfo );

	// Spawn the base units
	for (i = 0; i < inNumUnits; i++)
	{
		spawnedPawn = RequestUnit( playerInfo.raceUnitNames[0], playerInfo,
			inOwner.Location, false, inOwner.Location, None);
			
		if(spawnedPawn != none)
		{
			inOwner.SendFastEvent( class'TMFastEventSpawn'.static.create(spawnedPawn.pawnId, inSourcePosition, false, TMPlayerReplicationInfo(spawnedPawn.OwnerReplicationInfo).PlayerID ) );
		}
	}
}

function OnPlayerDeath(TMPlayerReplicationInfo tmPRI, TMPlayerReplicationInfo killerTMPRI)
{
	local TMPlayerReplicationInfo tempTMPRI;
	local TMPlayerController tmpc;
	local array<TMPlayerReplicationInfo> assistPlayers;
	local TMController tmController;
	tmController = TMController(tmPRI.Owner);
	tmpc = TMPlayerController(tmPRI.Owner);

	tmController.PlayerDied();

	tmPRI.KillAllMyUnits(None);

	if ( tmpc != None ) // if not bot
	{
		tmpc.ClientDesaturateScreen(true);
		tmpc.ClientDecideStartSpectating( true );
	}

	SendPlayerDeathNotification(tmPRI, killerTMPRI);

	// Update your stats
	UpdateStats(killerTMPRI, PS_KILLS);
	UpdateStats(tmPRI, PS_DEATHS);
	assistPlayers=tmPRI.AssignAssists(killerTMPRI);
	foreach assistPlayers(tempTMPRI) {
		UpdateStats(tempTMPRI, PS_ASSISTS);
	}

	if( ShouldGameEnd(tmPRI) )
	{
		TriggerEndGame(killerTMPRI.allyInfo);
		return;
	}

	if ( ShouldPlayerRestart(tmPRI) )
	{
		tmPRI.allyInfo.score--;
	
		if ( tmPRI.allyInfo.score == 0 )
		{
			SendNoRespawnsLeftForTeamNotification(tmPRI.allyInfo);
		}

		tmController.RespawnIn(RESPAWN_TIME);
	}
	else if ( tmPRI.allyInfo.score == 0 )
	{
		tmPRI.bNotRespawning = true;
		SendNoRespawnsLeftForPlayerNotification(tmpri);
	}
}

function TriggerEndGame(TMAllyInfo winningAllyInfo)
{
	local JsonObject endGameStatsJson;
	local array<JsonObject> playerGameSummaryJsons;

	if ( endGameSequenceStarted ) // don't fire twice
	{
		return;
	}

	`log( "TMGameInfo::TriggerEndGame() end game triggered!" );

	endGameSequenceStarted = true;
	m_exitcond=EXIT_CONDITION_NORMATIVE;

	// End game stats and player game summaries must be created before players are told win status
	playerGameSummaryJsons = CreatePlayerGameSummaryList(winningAllyInfo);
	endGameStatsJson = CreateEndGameStats();

	// Let every know if they won or lost
	TellClientsEndGameInVictory();
	
	SendGameAnalytics(playerGameSummaryJsons);
	SendStatsIfNeeded(endGameStatsJson);
}

function TellClientsEndGameInVictory()
{
	local TMPlayerReplicationInfo tempTMPRI;

	// Tell every player to get the hell out
	// 	We keep this isolated in case any other issues arise. Make sure every player gets booted
	foreach self.AllActors(class'TMPlayerReplicationInfo', tempTMPRI)
	{
		// This shouldn't happen, but add the check to be safe.
		if (tempTMPRI == none || tempTMPRI.Owner == none) // saw the owner none in a log
		{
			continue;
		}

		if ( tempTMPRI.Owner != m_TMNeutralPlayerController )
		{
			TMPlayerController(tempTMPRI.Owner).ClientEndGameInVictory(tempTMPRI.bWon);
		}
	}
}

function bool IsPracticeBattle()
{
	return mIsPracticeBattle;
}

function bool StartedByPlatformGameServer()
{
	return WorldInfo.NetMode == NM_DedicatedServer && self.mGameGUID != "" && self.mNodeLocalPort != "";
}

// NOTE: battle practice is considered a tutorial
function bool IsTutorial()
{
	local string mapName;
	mapName = WorldInfo.GetMapName();
	ReplaceText(mapName, "uedpie", ""); // remove potential "uedpie" prefix the editor can cause

	if( mapName == "tm_tutorial1_kismet" ||
		mapName == "tm_tutorial2_kismet" ||
		mapName == "tm_tutorial3" )
	{
		return true;
	}

	if( IsPracticeBattle() )
	{
		return true;
	}

	return false;
}

function string GetCommanderForTutorial()
{
	local string mapName;
	local string commander;

	mapName = WorldInfo.GetMapName();
	ReplaceText(mapName, "uedpie", ""); // remove potential "uedpie" prefix the editor can cause

	// Choose the proper commander for the tutorial
	switch( mapName )
	{
		case "tm_tutorial1_kismet":
			commander = "RoboMeister";
			break;
		case "tm_tutorial2_kismet":
			commander = "RoboMeister";
			break;
		case "tm_tutorial3":
			commander = "RamBamQueen";
			break;
		default:
			commander = "TinkerMeister";
	}

	return commander;
}

function SendNoRespawnsLeftForPlayerNotification(TMPlayerReplicationInfo playerWithoutRespawns)
{
	local TMPlayerController tmpc;
	
	tmpc = TMPlayerController( playerWithoutRespawns.Owner );

	if ( tmpc == None )
	{
		return;
	}

	tmpc.ClientPlayNotification("You have no respawns left!", 2000);
}

/**
 * Sends a notification 
 * @param allyInfoWithNoRespawns - the allyinfo of the team that no longer has respawns
 */
//function SendTeamNoRespawnsNotification(TMPlayerReplicationInfo playerWithNoRespawns)
function SendNoRespawnsLeftForTeamNotification(TMAllyInfo allyInfoWithNoRespawns)
{
	local TMplayerController outController;

	foreach WorldInfo.AllControllers(class'TMPlayerController', outController)
	{
		if ( outController.GetTMPRI().allyInfo == allyInfoWithNoRespawns )
		{
			outController.ClientPlayNotification("Friendly Team has no respawns left!", 2000);
		}
		else
		{
			outController.ClientPlayNotification("Enemy Team has no respawns left!", 2000);
		}
	}
}

function bool ShouldPlayerRestart(TMPlayerReplicationInfo tmPRI)
{
	if(tmPRI.allyInfo.score > 0)
	{
		return true;
	}

	return false;
}

function bool ShouldGameEnd(TMPlayerReplicationInfo playerWhoJustDied)
{
	local TMPlayerReplicationInfo tempTMPRI;

	if(playerWhoJustDied.allyInfo.score > 0)
	{
		return false;
	}

	foreach AllActors(class'TMPlayerReplicationInfo', tempTMPRI )
	{
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

function TellClientsToSpawnPing(int allyId, Vector loc, int type)
{
	local TMPlayerController tmPC;

	foreach self.WorldInfo.AllControllers(class'TMPlayerController', tmPC)
	{
		tmPC.ClientSpawnPing(allyId, loc, type);
	}
}

function TellClientsToSpawnBotPing(int allyId, Vector loc, int type)
{
	local TMPlayerController tmPC;

	foreach self.WorldInfo.AllControllers(class'TMPlayerController', tmPC)
	{
		tmPC.ClientSpawnBotPing(allyId, loc, type);
	}
}

function TellClientsToDrawDebugCircle( Vector inOrigin, float inRadius, byte inR, byte inG, byte inB )
{
	local TMPlayerController tmPC;

	foreach self.WorldInfo.AllControllers(class'TMPlayerController', tmPC)
	{
		tmPC.ClientDrawDebugCircle(inOrigin, inRadius, inR, inG, inB);
	}
}

function TellClientsToDrawDebugText( string inText, TMPawn inAttachPawn, Vector inOffset, optional float inDuration )
{
	local TMPlayerController tmPC;

	foreach self.WorldInfo.AllControllers(class'TMPlayerController', tmPC)
	{
		tmPC.ClientDrawDebugTextOnPawn(inText, inAttachPawn, inOffset, inDuration);
	}
}

function RestartPlayer(Controller NewPlayer)
{
	local TMPawn Commander, startingPawn;
	local TMUnit unit;
	local Vector spawnLocation;
	local int TeamNum;
	local TMController tmcont;

	if(TMNeutralPlayerController(NewPlayer) != None)
	{
		return;
	}

	if(TMPlayerController(NewPlayer) != None && TMPlayerController(NewPlayer).mLoggingOut)
	{
		return;
	}

	tmcont = TMController(NewPlayer);
	if(tmcont != None)
	{
		if(tmcont.HasDied()) // respawn, use our respawn selection algo
		{
			spawnLocation = FindRespawnForPlayer(tmcont);
		}
		else // first spawn, use the chosen one
		{   
			// figure out the team number and find the start spot
			TeamNum = ((NewPlayer.PlayerReplicationInfo == None) || (NewPlayer.PlayerReplicationInfo.Team == None)) ? 255 : NewPlayer.PlayerReplicationInfo.Team.TeamIndex;
			spawnLocation = FindPlayerStart(NewPlayer, TeamNum).Location;
			tmcont.SetHasDied(true); // not well named, lol
		}
	}

	Commander = RequestUnit(tmcont.GetTMPRI().commanderType, TMPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo), spawnLocation, false, spawnLocation, None);
	
	if(TMPlayerController(tmcont) != None)
	{
		// Dru TODO: Move bIsDead to TMPRI
		TMPlayerController(tmcont).bIsDead = false;
		TMPlayerController(tmcont).ClientInitRespawn();

		TMPlayerController(tmcont).ServerLoseAllPotions();
	}

	//for some reason it gave me an error when i tried using the commander....weird
	startingPawn = Commander;
	Commander.SendFastEvent( class'TMFastEventSpawn'.static.create(startingPawn.pawnId,startingPawn.Location,true,  tmcont.GetTMPRI().PlayerID));
	NewPlayer.Pawn = Commander; // Dru TODO: Consider deleting this and letting the work happen solely and consistently in SetupUnit() so client & server are same
	
//// Dru TODO: this is fucking dumb, I need to fix this along with the ServerRestartPlayer in the wrong state
	// since we no longer posses the commander, we need to manually change state.
	if ( GetStateName() == 'PendingMatch')
	{
		GotoState('PlayerWalking');
	}

	SpawnStartingUnits( NewPlayer, startingPawn );

	// hack to make sure groundspeed doesn't get reset
	// may not be necessary if we don't call super of this function
	foreach unitCache(unit)
	{
		if(Commander != none) {
			if (unit.m_UnitName == Commander.m_UnitType)
			{
				Commander.GroundSpeed = unit.m_Data.moveSpeed;
			}
		}
	}
	
	TMPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).ResetAntagonists();
	TMPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo).bNotRespawning = false;

	tmcont.PlayerStarted();
}

/* SpawnBaseUnitsAround
	Spawn our earned number of base units. When the game first starts you won't have any
	base units earned, so you'll spawn with zero.
 */
function SpawnStartingUnits( TMController inTMPC, TMPawn inCommander )
{
	SpawnBaseUnitsAround( inCommander, inTMPC.GetTMPRI().baseUnitsEarned, inCommander.Location );
}

function Vector FindRespawnForPlayer(TMController cont)
{
	local TMPawn pawn;
	local TMPlayerReplicationInfo repInfo;
	local PlayerStart P;
	local PlayerStart bestLocation;
	local float size;
	local float bestRating;
	local float newRating;
	local bool firstRun;

	`log("Finding respawn point for player", true, 'Graham');
	
	firstRun = true;
	bestRating = 0;

	foreach WorldInfo.AllNavigationPoints(class'PlayerStart', P)
	{
		newRating = 0;
		if(firstRun)
		{
			// makes it safe for when there are no enemy pawns
			firstRun = false;
			bestLocation = P;
		}

		// calc start point's rating 
		foreach AllActors(class'TMPawn', pawn)
		{
			repInfo = cont.GetTMPRI();

			// make the spawn less desirable if the pawn is hostile
			if(repInfo != None && pawn.m_allyId != repInfo.allyId && !pawn.IsPawnNeutral(pawn))
			{
				size = VSize(P.Location - pawn.Location);
				if(size < 1000.f) // USE REAL RANGE
				{
					newRating -= 10000.f;
				}
				else
				{
					newRating += size;
				}
			}
		}

		// compare and set if appropriate
		if(newRating >= bestRating)
		{
			bestLocation = P;
			bestRating = newRating;
		}
	}

	return bestLocation.Location;
}

function RemovePawnFromAllTMPawnLists(int pawnId)
{
	local TMPlayerController cont;
	local int i;
	local TMPawn targetPawn;
	
	targetPawn = none;
	for(i = 0; i < mTMPawnList.Length; ++i)
	{
		if(mTMPawnList[i].pawnId == pawnId)
		{
			targetPawn = mTMPawnList[i];
			break;
		}
	}
	
	if(targetPawn == none)
	{
		return;
	}

	foreach WorldInfo.AllControllers( class'TMPlayerController', cont )
	{
		cont.ClientRemoveTMPawnFromTMPawnList(pawnID);
	}

	mTMPawnList.RemoveItem(targetPawn);
	//`log(targetPawn@" is removed from server list", true, 'Lang');
}

function RemovePawnFromAllHashes(int pawnID)
{
	if(m_PawnHash.GetByIntKey(pawnID) == None)
	{
		// the pawn has already been removed
		// this check is needed because there are delayed removal calls from clients
		return;
	}

	RemovePawnFromAllClientHashes(pawnId);

	RemovePawnFromAllFoWHashes(pawnId);
	
	m_PawnHash.RemoveByIntKey(pawnID);
}

function RemovePawnFromAllClientHashes(int pawnID)
{
	local TMPlayerController cont;

	foreach WorldInfo.AllControllers( class'TMPlayerController', cont )
	{
		cont.ClientRemovePawnFromHash(pawnID);
	}
}

function RemovePawnFromAllFoWHashes(int pawnID)
{
	local TMFowManager fowManager;

	foreach fowManagers(fowManager)
	{
		if (WorldInfo.NetMode == NM_DedicatedServer)
		{
			fowManager.RemoveFromVisiblePawns(pawnID);
		}
	}
}

function NavigationPoint FindPlayerStart( Controller Player, optional byte InTeam, optional string IncomingName )
{
	local NavigationPoint N, BestStart;
	local TMPlayerReplicationInfo repInfo;

	if(Player != None && TMController(Player) != None)
	{
		repInfo = TMController(Player).GetTMPRI();
		return ChoosePlayerStart(Player, repInfo.allyId);
	}

	if ( (BestStart == None) && (Player == None) )
	{
		// no playerstart found, so pick any NavigationPoint to keep player from failing to enter game
		`log("Warning - PATHS NOT DEFINED or NO PLAYERSTART with positive rating");
		ForEach AllActors( class 'NavigationPoint', N )
		{
			BestStart = N;
			break;
		}
	}

	return BestStart;
}

function PlayerStart ChoosePlayerStart( Controller Player, optional byte InTeam )
{
	local PlayerStart P, BestStart;
	local float BestRating, NewRating;

	NewRating = 0.f;
	BestRating = 0.f;

	// Find best playerstart
	foreach WorldInfo.AllNavigationPoints(class'PlayerStart', P)
	{
		NewRating = RatePlayerStart(P,TMController(Player).GetTMPRI().allyId,Player);
		if ( NewRating >= BestRating )
		{
			BestRating = NewRating;
			BestStart = P;
		}
	}

	if(BestStart == None)
	{
		`warn("No BestStart found! Assigning first PlayerStart in world");
		foreach WorldInfo.AllNavigationPoints(class'PlayerStart', P)
		{
			BestStart = p;
			break;
		}
	}
	
	BestStart.isInUse = true;
	return BestStart;
}

function float RatePlayerStart(PlayerStart P, byte Team, Controller Player)
{
	// local float Rating;
	if ( !P.bEnabled )
	{
		return -100.f;
	}
	else
	{
		if(!p.isInUse && p.AllyIndex == Team)
		{
			return 100.f;
		}
		else
		{
			return -100.f;
		}
	}
}

function TMPawn GetPawnByID(int pawnId)
{
	return TMPawn(m_PawnHash.GetByIntKey(pawnId));
	
	return none;
}

function OnKilledNexus( TMPawn inKiller )
{
	local TMPlayerController iterPC;
	local TMPlayerReplicationinfo iterTMPRI;
	local TMPlayerReplicationinfo killerTMPRI;

	// Increment shrine kill count for analytics
	mShrineKillCount++;

	// Do shrine effect for the game mode
	DoNexusKilledEffect( inKiller ); 	// TODO: once we separate TMGameInfo from being an actual game mode, we can probably just get rid of this part

	killerTMPRI = TMPlayerReplicationinfo( inKiller.OwnerReplicationInfo );

	// Send out player notifications
	foreach WorldInfo.AllControllers( class'TMPlayerController', iterPC )
	{
		iterTMPRI = iterPC.GetTMPRI();

		// Give frontend notification
		iterPC.shrineDestroyed( iterTMPRI.allyInfo.allyIndex, killerTMPRI.allyInfo.allyIndex );

		// Do UI notification and sound notification
		if( killerTMPRI.allyInfo.allyIndex == iterTMPRI.allyInfo.allyIndex )
		{
			if( killerTMPRI.mTeamColorIndex == iterTMPRI.mTeamColorIndex ) //(TMPawn(Killer.Pawn).OwnerReplicationInfo.PlayerName == iterPC.PlayerReplicationInfo.PlayerName)
			{															// TODO: okay so my color check is kinda BS, but it's WAAAY better than player name, right?
				iterPC.ClientPlayNotification("You Have Destroyed The Shrine!", 2000);
			}
			else
			{
				iterPC.ClientPlayNotification("Your Team Has Destroyed The Shrine!", 2000);
			}
			iterPC.ClientPlayVO(SoundCue'VO_Main.Male_TeamDestroyedShrine_Cue', true, true);
		}
		else
		{
			iterPC.ClientPlayNotification("The Enemy Has Destroyed The Shrine!", 2000);
			iterPC.ClientPlayVO(SoundCue'VO_Main.Male_EnemyDestroyedShrine_Cue', true, true);
		}
	}
}

// GameMode specific effect for killing the nexus
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

		// Attempt to take a life from the other team
		if( robbedTeam.score > 0 )
		{
			robbedTeam.score--;
		}
	}

	foreach WorldInfo.AllControllers(class'TMPlayerController', cont)
	{
		cont.ClientSpawnDestructableNexus();
	}
}

function OnKilledBrute( TMPawn inKiller, Vector inBruteLocation )
{
	local TMPlayerController iterPC;
	local TMPlayerReplicationinfo killerTMPRI;
	local Vector effectLoc;
	local TMPawn pw;

	// Update kill count for analytics
	mDreadBeastKillCount++;

	killerTMPRI = TMPlayerReplicationInfo( inKiller.OwnerReplicationInfo );
	//SetTimer( 1.0f, false, 'SpawnConvertedBrute', self ); // This was an attempt to fix the offset spawning

	pw = RequestUnit("ConvertedBrute", killerTMPRI, inBruteLocation, false, inBruteLocation, None, true);
	if( pw != none)
	{
		pw.SendFastEvent(class'TMFastEventSpawn'.static.create( pw.pawnId, pw.Location, true ) );
	}

	// Do UI, VFX, and audio notifications
	foreach WorldInfo.AllControllers(class'TMPlayerController', iterPC)
	{
		if( killerTMPRI.allyInfo.allyIndex == TMPlayerReplicationInfo( iterPC.PlayerReplicationInfo ).allyInfo.allyIndex )
		{
			if( killerTMPRI.mTeamColorIndex == TMPlayerReplicationInfo( iterPC.PlayerReplicationInfo ).mTeamColorIndex ) //(TMPawn(Killer.Pawn).OwnerReplicationInfo.PlayerName == iterPC.PlayerReplicationInfo.PlayerName)
			{															// TODO: okay so my color check is kinda BS, but it's WAAAY better than player name, right?
				iterPC.ClientPlayNotification("You Have Tamed The Dreadbeast!", 2000);
			}
			else
			{
				iterPC.ClientPlayNotification("Your Team Has Tamed The Dreadbeast!", 2000);
			}
			iterPC.ClientPlayVO(SoundCue'VO_Main.Male_TeamTamedBeast_Cue', true, true);
		}
		else
		{
			iterPC.ClientPlayNotification("The Enemy Has Unleashed The Dreadbeast!", 2000);
			iterPC.ClientPlayVO(SoundCue'VO_Main.Male_EnemyUnleashedBeast_Cue', true, true);
		}

		effectLoc = inBruteLocation;
		effectLoc.Z -= 300;
		iterPC.ClientSpawnBruteParticles(inKiller.m_allyId, inKiller.GetTeamColorIndex(), effectLoc);
	}
}

function SpawnConvertedBrute()
{
	local TMPawn pw;
	
	pw = RequestUnit("ConvertedBrute", bruteKillerPRI, bruteLoc, false, bruteLoc, None, true);
	if( pw != none)
	{
		pw.SendFastEvent(class'TMFastEventSpawn'.static.create(pw.pawnId, pw.Location, true) );
	}
}

function BroadcastTransformEffect(int tid, int aID)
{
	local TMPlayerController tmpc;
	
	foreach self.WorldInfo.AllControllers(class'TMPlayerController', tmpc)
	{
		tmpc.PlayTransformEffect(tid, aID);
	}
}

function BroadcastPotionEffect(int tID, int aID, int pID)
{
	local TMPlayerController tmpc;

	foreach self.WorldInfo.AllControllers(class'TMPlayerController', tmpc)
	{
		tmpc.PlayPotionEffect(tID, aID, pID);
	}
}

function int GetPopulationCost(string unitType)
{
	local int i;

	for(i = 0; i < unitCache.Length; ++i)
	{
		if(unitType == unitCache[i].m_UnitName)
		{
			return unitCache[i].m_Data.mPopulationCost;
		}
	}

	return 0;
}

// Taylor TODO: move this to someplace where everyone can use it. Or just leave it here...
function bool IsAuthority()
{
	return ((WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone));
}

exec function ShowEndGameVictory()
{
	TriggerEndGame( m_TMPlayerController.mAllyInfos[0] );
	m_TMPlayerController.ClientEndGameInVictory( true );
}

exec function ShowEndGameLoss()
{
	TriggerEndGame( m_TMPlayerController.mAllyInfos[0] );
	m_TMPlayerController.ClientEndGameInVictory( false );
}

exec function SwitchToRealPlatformConnection()
{
	mPlatformConnection = new class'TMRealPlatformConnection'();
	mPlatformConnection.Setup();
}

exec function SwitchToMockablePlatformConnection()
{
	mPlatformConnection = new class'TMMockablePlatformConnection'();
	mPlatformConnection.Setup();
}

exec function SwitchToFakePlatformConnection()
{
	mPlatformConnection = new class'TMMockPlatformConnection'();
	mPlatformConnection.Setup();
}

defaultproperties
{
	HUDType=class'TheMaestrosGame.TMHUD'
	PlayerControllerClass=class'TheMaestrosGame.TMPlayerController'
	PlayerReplicationInfoClass=class'TMPlayerReplicationInfo'
	tmAllyInfoClass=Class'TMAllyInfo'
	RESPAWN_TIME = 3.f;
	
	mTeamBlueColorIndex=0
	mTeamRedColorIndex=0
	m_ObjectiveText="Eliminate Enemy Respawns"
	mLineOfSightRangeForPawns=8;

	mShrineKillCount = 0
	mDreadBeastKillCount = 0

	jsonFileName = "GameModes\\\\Default.json"

	GAME_MODE_NAME = "Default";
}
