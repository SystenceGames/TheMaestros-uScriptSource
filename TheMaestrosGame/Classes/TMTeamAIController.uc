class TMTeamAIController extends UDKRTSTeamAIController implements(TMController);

var TMBehaviorHelper mTMBehaviorHelper;

const BeginnerBotDifficulty = 1;
const IntermediateBotDifficulty = 2;

var string mBotDifficulty;
var TMTeamAIKnowledge knowledge;
var TMGameInfo mTMGameInfo;

var TMBehaviorListLoader mTMBehaviorListLoader;
var array<TMBehavior> behaviors;
var TMBehavior currentBehavior;

var string commanderType;
var bool bHasDied;

var float mIntroWaitDuration;
var float mEnemyVisionRange;

var array<string> unitCacheString;
var TMJsonParser m_JsonParser;
var array<TMUnit> unitCache;

var bool bShowDebug;
var bool bBotTalk; 	// should the bots tell everyone what they're doing in chat

var private TMFOWManager mFoWManager;

const BUDGE_RANGE = 3000;
const mNumRecentBudgeLocationsToSave = 3;
var array<Vector> mRecentSafeLocations; 	// save where we've been going so we don't go back

var float RETHINK_STRATEGY_FREQUENCY;
var float DRAW_DEBUG_TEXT_FREQUENCY;

var float mWeightExponent; 	// when we weight any value, additionally take an exponent of the weight. If you raise this value above 1, the bough will make "better" weighted decisions


function PreInitialize(TMFowManager fowManager, int botDifficulty)
{
	mFoWManager = fowManager;

	if(botDifficulty == BeginnerBotDifficulty) {
		mBotDifficulty = "Beginner";
		mIntroWaitDuration = 3.0f;
	} else {
		mBotDifficulty = "Intermediate";
		mIntroWaitDuration = 2.0f;
	}
}

function Initialize()
{
	mTMGameInfo = TMGameInfo(WorldInfo.Game);

	// Set up our knowledge of the game world
	knowledge = Spawn(class'TMTeamAIKnowledge');
	knowledge.Initialize(self);

	mTMBehaviorHelper = new () class'TMBehaviorHelper';
	mTMBehaviorHelper.Initialize(self);

	LoadBotBehavior();

	InitializeBehaviors();

	currentBehavior = NONE;

	mTMBehaviorHelper.mTMEventTimer.StartEvent("Road to attack");
	mTMBehaviorHelper.mTMEventTimer.StartEvent("First contact");
	mTMBehaviorHelper.mTMEventTimer.StartEvent("Intro wait");
}

function LoadBotBehavior()
{
	local JsonObject json;

	json = mTMBehaviorHelper.LoadBehaviorJsonObject("general");

	mWeightExponent = mTMBehaviorHelper.LoadFloatFromBehaviorJson("WeightExponent", json);
	mEnemyVisionRange = mTMBehaviorHelper.LoadFloatFromBehaviorJson("EnemyVisionRange", json);
	RETHINK_STRATEGY_FREQUENCY = mTMBehaviorHelper.LoadFloatFromBehaviorJson("RETHINK_STRATEGY_FREQUENCY", json);

	mTMBehaviorListLoader = new class'TMBehaviorListLoader';
	mTMBehaviorListLoader.Setup(mTMBehaviorHelper, json);
	behaviors = mTMBehaviorListLoader.SelectOrderedBehaviorList();
}

function InitializeBehaviors()
{
	local TMBehavior iterBehavior;

	if( mTMBehaviorListLoader == none ){ return; } 	// this is none if the bot starts but the AI system hasn't been initialized yet. Just return, this is expected.

	`log(mBotDifficulty $ " selecting ordered behaviors:");

	behaviors = mTMBehaviorListLoader.SelectOrderedBehaviorList();
	foreach behaviors(iterBehavior)
	{
		`log("  " $ iterBehavior.GetName());
		iterBehavior.InitBehavior(self, mTMBehaviorHelper);
	}
}

function StartThinking()
{
	SetTimer(class'TMBehaviorHelper'.static.FuzzValue(mIntroWaitDuration), false, 'StartThinkingDelayed');
}

// Right now all TMControllers are started at the same time, the issue is that bots have a start
// advantage since they're on the server
function StartThinkingDelayed()
{
	mTMBehaviorHelper.mTMEventTimer.StopEvent("Intro wait");
	SetTimer(RETHINK_STRATEGY_FREQUENCY, true, 'RethinkStrategy');
	SetTimer(DRAW_DEBUG_TEXT_FREQUENCY, true, 'DrawCurrentBehaviorDebugText');
}

/**
 * Called from within a behavior when it has finished
 */
function FinishBehavior(TMBehavior behavior)
{
	if (behavior == currentBehavior)
	{
		currentBehavior = none;

		mTMBehaviorHelper.ClearTimers();

		RethinkStrategy();
	}
}

/**
 * Called from within a looping timer to make the AI rethink its strategy
 */
function RethinkStrategy()
{
	local TMBehavior behavior;
	
	behavior = GetMostImportantBehavior();

	if (currentBehavior == none)
	{
		Log("TMTeamAIController: Assigning new current behavior " $ behavior.GetName() );
		currentBehavior = behavior;
		mTMBehaviorHelper.SetCurrentBehavior(currentBehavior);
	}
	else if (behavior != currentBehavior)
	{
		currentBehavior.FinishTask(behavior.GetImportance());
	}
}

function DrawCurrentBehaviorDebugText()
{
	if( currentBehavior == none ){ return; }

	DrawDebugText(currentBehavior.GetDebugBehaviorStatus(), DRAW_DEBUG_TEXT_FREQUENCY + 0.1f); 	// add a little extra duration so the text doesn't flash
}

function PlayerDied()
{
	if (currentBehavior != None)
	{
		currentBehavior.FinishTask(100);
		currentBehavior = None;
	}

	StopThinking();
}

function PlayerStarted()
{
	InitializeBehaviors();
	StartThinking();
}

function StopThinking()
{
	ClearTimer('RethinkStrategy');
}

function Tick(float DeltaTime)
{
	if ( GetTMPRI().bIsCommanderDead )
	{
		super.Tick(DeltaTime);
		return;	
	}

	knowledge.CalculateClosestEnemy(); 	// maybe this should be in a knowledge.update() instead?

	if (currentBehavior != none)
	{
		currentBehavior.Update(DeltaTime);
	}

	super.Tick(DeltaTime);
}

/**
 * Issue a move command for this list of pawns
 */
function IssueMoveCommand( array<TMPawn> inPawns, Vector inLocation )
{
	inPawns[0].HandleCommand(C_Move, true, inLocation,,inPawns );

	PingBotActionToAllPlayers( inLocation, 1 );
}

function IssueStopCommand( array<TMPawn> inPawns )
{
	inPawns[0].HandleCommand(C_Stop, true,,,inPawns );
}

function AttackMovePawns(array<TMPawn> pawns, Vector to)
{
	Log( "TMTeamAIController::AttackMovePawns() attacking with " $ pawns.Length $ " pawns" );
	pawns[0].HandleCommand(C_Attack, true, to,,pawns );

	PingBotActionToAllPlayers( to, 0 );
}

function TransformPawns( array< TMPawn > inPawns, Vector inLocation )
{
	inPawns[0].HandleCommand( C_Transform, false, inLocation,, inPawns, );
}

function PingBotActionToAllPlayers( Vector inPosition, int inPingType )
{
	if( bShowDebug )
	{
		TMGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).TellClientsToSpawnBotPing( 0, inPosition, inPingType );
		TMGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).TellClientsToSpawnBotPing( 1, inPosition, inPingType );
		TMGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).TellClientsToSpawnBotPing( -3, inPosition, inPingType );
	}
}

function DrawDebugText( string inText, optional float inDuration ) 	// draws the bot's current behavior on the commander
{
	local TMPawn commander;
	local Vector offset;

	if( bShowDebug == false ){ return; }

	commander = knowledge.GetCommander();

	if( commander == none ){ return; }

	TMGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).TellClientsToDrawDebugText( inText, commander, offset, inDuration );
}

function DrawDebugCircle( Vector inOrigin, float inRadius, byte inR, byte inG, byte inB )
{
	if( bShowDebug )
	{
		TMGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).TellClientsToDrawDebugCircle( inOrigin, inRadius, inR, inG, inB );
	}
}

function DrawDebugCircleRed( Vector inOrigin, float inRadius )
{
	DrawDebugCircle( inOrigin, inRadius, 255, 0, 0 );
}

function DrawDebugCircleWhite( Vector inOrigin, float inRadius )
{
	DrawDebugCircle( inOrigin, inRadius, 255, 255, 255 );
}

function DrawDebugCircleBlue( Vector inOrigin, float inRadius )
{
	DrawDebugCircle( inOrigin, inRadius, 0, 255, 255 );
}

/**
 * Returns the TMPlayerReplicationInfo as per the TMController Interface's spec.
 */
function TMPlayerReplicationInfo GetTMPRI()
{
	return TMPlayerReplicationInfo(PlayerReplicationInfo);
}

/**
 * Returns bHasDied as per the TMController Interface's spec.
 */
function bool HasDied()
{
	return bHasDied;
}

/**
 * Sets bHasDied as per the TMController Interface's spec.
 */
function SetHasDied(bool HasDied)
{
	bHasDied = HasDied;
}

/**
 * Getters & Setters for CommanderType as per the TMController Interface's spec.
 */
function string GetCommanderType()
{
	return commanderType;
}

function SetCommanderType(string unitTypeOfCommander)
{
	commanderType = unitTypeOfCommander;
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

function TMBehavior GetMostImportantBehavior()
{
	local int currentHighestImportance, tempImportance;
	local TMBehavior currentMostImportantBehavior, iterBehavior;

	currentHighestImportance = -1;

	foreach behaviors(iterBehavior)
	{
		tempImportance = iterBehavior.GetImportance();

		if( tempImportance > currentHighestImportance )
		{
			currentHighestImportance = tempImportance;
			currentMostImportantBehavior = iterBehavior;
		}
	}

	return currentMostImportantBehavior;
}

reliable client function setUnitCacheString(string jsonString, int index, int arraylen)
{
	if (m_JsonParser == None)
	{
		m_JsonParser = new() class'TMJsonParser';
		m_JsonParser.setup();
	}

	if(self.unitCacheString.Length != arraylen) {
		self.unitCacheString.Length=arraylen;
	}

	self.unitCacheString[index]=jsonString;
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

reliable client function initBuildUnitCache()
{
	local array<JsonObject> jsonObj;
	local int i;

	unitCacheString = arrayElementCompress(unitCacheString);

	for(i=0;i<unitCacheString.Length;i++)
	{
		jsonObj.AddItem(m_JsonParser.getJsonFromString(unitCacheString[i]));
	}

	buildUnitCache(jsonObj);
}

// TODO: maybe move this to our helper?
function MoveToSafeLocation()
{
	local array< TMPawn > myPawns;
	local array< TMNeutralCamp > camps;
	local TMNeutralCamp tempCamp;
	local array<Vector> locationsToCheck;
	local array<Vector> safeLocationsInRange;
	local Vector destination, recentLocation;
	local int safeLocationIndex;
	local bool foundRecentLocation;

	Log("TMTeamAIController: Moving to safe location!");
	myPawns = knowledge.GetMyPawns();

	camps = knowledge.GetNeutralCamps();
	foreach camps(tempCamp)
	{
		locationsToCheck.AddItem(knowledge.GetNeutralCampLocation( tempCamp ));
	}

	safeLocationsInRange = mTMBehaviorHelper.GetLocationsInRange(knowledge.GetMySmartLocation(), locationsToCheck, BUDGE_RANGE );

	// Move to a safe location not in our recent list
	while(safeLocationsInRange.Length > 0)
	{
		safeLocationIndex = Rand( safeLocationsInRange.Length );
		destination = safeLocationsInRange[safeLocationIndex];

		// Make sure our chosen destination isn't in our recent safe location list
		foreach mRecentSafeLocations(recentLocation)
		{
			if( recentLocation.X == destination.X &&
				recentLocation.Y == destination.Y &&
				recentLocation.Z == destination.Z )
			{
				safeLocationsInRange.Remove(safeLocationIndex, 1);
				foundRecentLocation = true;
				break;
			}
		}

		if(foundRecentLocation)
		{
			foundRecentLocation = false;
			continue;
		}

		// We are going to use this location
		mRecentSafeLocations.AddItem(destination);
		while(mRecentSafeLocations.Length > mNumRecentBudgeLocationsToSave )
		{
			mRecentSafeLocations.Remove(0, 1);
		}

		IssueMoveCommand( myPawns, destination );
	}
}

function TMFOWManager GetFoWManager()
{
	return mFoWManager;
}

function DelayedRestartPlayer()
{
	mTMGameInfo.RestartPlayer(self);
}

function RespawnIn(float seconds)
{
	SetTimer(seconds, false, NameOf(DelayedRestartPlayer));
}

function Log( string inMessage )
{
	local PlayerController pc;

	if( bShowDebug )
	{
		`log( inMessage );
	}

	if( bBotTalk )
	{
		`log("(" $ GetTMPRI().PlayerName $ "): " $ inMessage);

		// Tell all players what I'm doing
		foreach AllActors(class'PlayerController', pc)
		{
			pc.Say("(" $ GetTMPRI().PlayerName $ "): " $ inMessage);
			break;
		}
	}
}

DefaultProperties
{
	DRAW_DEBUG_TEXT_FREQUENCY = 0.2f;

	bHasDied = false;

	bShowDebug = false;
	bBotTalk = false;
}
