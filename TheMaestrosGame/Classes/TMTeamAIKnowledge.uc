/* TMTeamAIKnowledge
	Contains data access and collection functions which bots use to make decisions.
	Things in this class should be considered "facts". Interpretation of facts should be in behaviors.
	We will consider "player power" fact, since it is a value all the bots will share.
*/
class TMTeamAIKnowledge extends Info;

var TMTeamAIController teamAIController;

var array<TMPlayerReplicationInfo> mEnemyTMPRIs;
var array<TMPlayerReplicationInfo> mAllyTMPRIs;

var TMPlayerReplicationInfo closestEnemy;
var float closestEnemyDistanceSquared;


function Initialize(TMTeamAIController c)
{
	local array<TMController> allTMControllers;
	local TMController iterController;
	local int myAllyId;

	teamAIController = c;
	allTMControllers = TMGameInfo(WorldInfo.Game).mAllTMControllers;

	myAllyId = teamAIController.GetTMPRI().allyId;

	foreach allTMControllers(iterController)
	{
		if (iterController.GetTMPRI().allyId == myAllyId)
		{
			mAllyTMPRIs.AddItem(iterController.GetTMPRI());
		}
		else if (iterController.GetTMPRI().allyId != myAllyId && iterController.GetTMPRI().allyId != TMPlayerReplicationInfo(TMGameInfo(WorldInfo.Game).m_TMNeutralPlayerController.PlayerReplicationInfo).allyId && iterController.GetTMPRI().allyID != -3)
		{
			mEnemyTMPRIs.AddItem(iterController.GetTMPRI());
		}
	}
}

function float GetCurrentTime()
{
	return teamAIController.mTMGameInfo.WorldInfo.TimeSeconds;
}

// TAYLOR NOTE: might be able to replace this with knowledge's closest enemy var
function TMPlayerReplicationInfo GetClosestLivingEnemy()
{
	local TMPlayerReplicationInfo outTMPRI;
	local float closestDistance;
	local TMPlayerReplicationInfo tclosestEnemy;
	local float distance;
	local Vector mySmartLocation;

	mySmartLocation = GetMySmartLocation();

	closestDistance = 1000000000;

	foreach mEnemyTMPRIs(outTMPRI)
	{
		if(!outTMPRI.bIsCommanderDead)
		{
			distance = VSize( class'UDKRTSPawn'.static.SmartCenterOfGroup(outTMPRI.m_PlayerUnits) - mySmartLocation );
			if ( distance <= closestDistance )
			{
				tclosestEnemy = outTMPRI;
				closestDistance = distance;
			}
		}
	}

	return tclosestEnemy;
}

/* CalculateClosestEnemy()
	Called by TMTeamAIController to upate the two closest enemy variables
*/
function CalculateClosestEnemy()
{
	local Vector enemyPosition;
	closestEnemy = GetClosestLivingEnemy();

	if( closestEnemy == none )
	{
		return;
	}

	enemyPosition = class'UDKRTSPawn'.static.SmartCenterOfGroup( closestEnemy.m_PlayerUnits );

	closestEnemyDistanceSquared = VSizeSq( GetMySmartLocation() - enemyPosition );
}

function bool IsEnemyInVisionRange()
{
	local float visionRadiusSq;
	visionRadiusSq = teamAIController.mEnemyVisionRange * teamAIController.mEnemyVisionRange;
	return (closestEnemy != none && closestEnemyDistanceSquared <= visionRadiusSq);
}

function array<TMTransformer> GetTransformers()
{
	local array<TMTransformer> transformers;
	local TMTransformer t;

	foreach AllActors(class'TMTransformer', t)
	{
		transformers.AddItem(t);
	}

	return transformers;
}

function array<Vector> GetTransformerLocations()
{
	local array<Vector> transformerLocations;
	local array<TMTransformer> transformers;
	local TMTransformer iterTrans;

	transformers = self.GetTransformers();
	foreach transformers( iterTrans )
	{
		transformerLocations.AddItem( iterTrans.Location );
	}

	return transformerLocations;
}

function array<TMNeutralAIController> GetNeutrals()
{
	local array<TMNeutralAIController> neutrals;
	local TMNeutralAIController n;

	foreach AllActors(class'TMNeutralAIController', n)
	{
		neutrals.AddItem(n);
	}

	return neutrals;
}

function array<TMNeutralCamp> GetNeutralCamps()
{
	local array<TMNeutralCamp> camps;
	local TMNeutralCamp c;

	foreach AllActors(class'TMNeutralCamp', c)
	{
		camps.AddItem(c);
	}

	return camps;
}

// We need this function because the camps location is in the air. This grounds it
function Vector GetNeutralCampLocation( TMNeutralCamp inCamp )
{
	local TMNeutralSpawnPoint point;

	// Returns the locations of a pawn who is on the camp
	foreach inCamp.mSpots( point )
	{
		if( point.mPawnHolden != none )
		{
			return point.mPawnHolden.Location;
		}
	}

	return inCamp.Location;
}

/* GetLivingAllies
	Returns all allies that currently have units.
*/
function array<TMPlayerReplicationInfo> GetLivingAllies()
{
	local TMPlayerReplicationInfo iterTMPRI;
	local array<TMPlayerReplicationInfo> livingAllies;

	foreach mAllyTMPRIs( iterTMPRI )
	{
		if( teamAIController.GetTMPRI().playerID != iterTMPRI.playerID &&
			iterTMPRI.bIsCommanderDead == false )
		{
			livingAllies.AddItem( iterTMPRI );
		}
	}

	return livingAllies;
}

function int GetLivingAlliesCount()
{
	local array<TMPlayerReplicationInfo> livingAllies;
	livingAllies = GetLivingAllies();
	return livingAllies.length;
}

function int GetPopulation()
{
	return teamAIController.GetTMPRI().Population;
}

function int GetDoughboyCount()
{
	local int doughboyCount;
	local TMPawn tempPawn;
	local array< TMPawn > myPawns;
	myPawns = GetMyPawns();

	foreach myPawns( tempPawn )
	{
		if( tempPawn.m_UnitType == "DoughBoy" )
		{
			doughboyCount++;
		}
	}

	return doughboyCount;
}

function Vector GetMySmartLocation(optional out float stdDeviation)
{
	local array< TMPawn > myPawns;
	myPawns = GetMyPawns();
	return class'UDKRTSPawn'.static.SmartCenterOfGroup( myPawns, stdDeviation );
}

function Vector GetPlayerSmartLocation(TMPlayerReplicationInfo inPlayer, optional out float stdDeviation)
{
	return class'UDKRTSPawn'.static.SmartCenterOfGroup( GetPawnsForPlayer(inPlayer) );
}

function array<TMPawn> GetMyPawns()
{
	return GetPawnsForPlayer( TMPlayerReplicationInfo(teamAIController.PlayerReplicationInfo) );
}

function int GetMyPawnCount()
{
	local array<TMPawn> pawns;
	pawns = GetMyPawns();
	return pawns.Length;
}

function array<TMPawn> GetPawnsForPlayer( TMPlayerReplicationInfo inPlayerReplicationInfo )
{
	local array<TMPawn> pawnList;
	pawnList = inPlayerReplicationInfo.m_PlayerUnits;
	RemoveInvalidPawnsFromList( pawnList );
	return pawnList;
}

function array<TMPawn> GetMyBasicUnits()
{
	local array<TMPawn> basicUnits;
	local array<TMPawn> playerUnits;
	local TMPawn iterPawn;
	local string basicUnitName;

	basicUnitName = TMPlayerReplicationInfo(teamAIController.PlayerReplicationInfo).raceUnitNames[0];
	playerUnits = TMPlayerReplicationInfo(teamAIController.PlayerReplicationInfo).m_PlayerUnits;

	RemoveInvalidPawnsFromList(playerUnits);

	foreach playerUnits(iterPawn)
	{
		if (iterPawn.m_UnitType == basicUnitName)
		{
			basicUnits.AddItem(iterPawn);
		}
	}

	return basicUnits;
}

function array<TMPlayerReplicationInfo> GetPlayersInArea( Vector inAreaOrigin, int inAreaRadius, int inAllyID )
{
	local TMController controller;
	local Vector playerLocation;
	local array<TMPlayerReplicationInfo> playersInArea;

	foreach teamAIController.mTMGameInfo.mAllTMControllers( controller )
	{
		if( controller.GetTMPRI().allyID == inAllyID && controller.GetTMPRI().m_PlayerUnits.length > 0 )
		{
			playerLocation = class'UDKRTSPawn'.static.SmartCenterOfGroup( controller.GetTMPRI().m_PlayerUnits );

			if( VSize( inAreaOrigin - playerLocation ) <= inAreaRadius )
			{
				playersInArea.AddItem( controller.GetTMPRI() );
			}
		}
	}

	return playersInArea;
}

function array<Vector> GetAllyLocations()
{
	local TMPlayerReplicationInfo iterTMPRI;
	local array<Vector> allyLocations;

	foreach mAllyTMPRIs( iterTMPRI )
	{
		if( iterTMPRI.PlayerID != teamAIController.GetTMPRI().PlayerID &&
			!iterTMPRI.bIsCommanderDead )
		{
			allyLocations.AddItem( class'UDKRTSPawn'.static.SmartCenterOfGroup( iterTMPRI.m_PlayerUnits ) );
		}
	}

	return allyLocations;
}

function array<Vector> GetEnemyLocations()
{
	local TMPlayerReplicationInfo tempEnemy;
	local array<Vector> enemyLocations;

	foreach mEnemyTMPRIs( tempEnemy )
	{
		if( !tempEnemy.bIsCommanderDead )
		{
			enemyLocations.AddItem( class'UDKRTSPawn'.static.SmartCenterOfGroup( tempEnemy.m_PlayerUnits ) );
		}
	}

	return enemyLocations;
}

/* IsLocationBeingTargeted
	This functions returns true if any other commanders have a move command issued in the target area
*/
function bool IsLocationBeingTargeted( Vector inLocation, float inRadius )
{
	local TMPlayerReplicationInfo repInfo;
	local Vector tempLocation;
	local array< Vector > targetLocations;

	// Add each ally's target move location
	foreach mAllyTMPRIs( repInfo )
	{
		if( repInfo.PlayerID != teamAIController.GetTMPRI().PlayerID )
		{
			if( repInfo.m_PlayerUnits.Length > 0 )
			{
				targetLocations.AddItem( repInfo.m_PlayerUnits[ 0 ].GetMoveComponent().m_TargetLocation );
			}
		}
	}

	// Add each enemy's target move location
	foreach mEnemyTMPRIs( repInfo )
	{
		if( repInfo.m_PlayerUnits.Length > 0 )
		{
			targetLocations.AddItem( repInfo.m_PlayerUnits[ 0 ].GetMoveComponent().m_TargetLocation );
		}
	}

	foreach targetLocations( tempLocation )
	{
		if( VSize( inLocation - tempLocation ) < inRadius )
		{
			return true;
		}
	}

	return false;
}

function TMPawn GetCommander()
{
	local TMPawn iterPawn;
	local TMPawn freshestDeadCommander; 	// keep track of this, because sometimes our m_PlayerUnits array saves dead commanders

	// Look for a living commander, or return our most recently dead command
	foreach teamAIController.GetTMPRI().m_PlayerUnits(iterPawn)
	{
		if( iterPawn.IsCommander() )
		{
			if( iterPawn.Health > 0 )
			{
				return iterPawn; 	// we've got a live one!
			}

			freshestDeadCommander = iterPawn;
		}
	}

	return freshestDeadCommander;
}

function Vector GetCommanderLocation()
{
	return GetCommander().location;
}

// returns your commander's HP as a value between 0 and 1
function float GetCommanderHealthPercentage()
{
	local TMPawn commander;

	commander = GetCommander();

	if( commander == none )
	{
		`warn("Couldn't find commander! Assuming he's dead.");
		return 0;
	}

	return float(commander.Health) / float(commander.HealthMax);
}

/* GetPlayerPower
	Gets a player's power rating for their army. Returns between 0f and 1f
*/
function float GetPlayerPower( TMPlayerReplicationInfo inPlayer )
{
	local array<TMPawn> pawnList;
	local TMPawn tempPawn;
	local float power;

	pawnList = GetPawnsForPlayer( inPlayer );

	foreach pawnList( tempPawn )
	{
		power += GetPawnPower( tempPawn, inPlayer.PopulationCap );
	}

	return power;
}

function float GetPawnPower( TMPawn inPawn, int inPopulationCap )
{
	local float powerScale;

	if( inPawn.IsCommander() )
	{
		powerScale = 10; 	// commander power scale
	}
	else if( inPawn.IsDreadbeast() )
	{
		powerScale = 6; 	// dreadbeast power scale
	}
	else
	{
		powerScale = 10 * inPawn.PopulationCost / inPopulationCap; 	// normal unit power scale
	}

	return powerScale * inPawn.Health / float( inPawn.HealthMax );
}

/* GetPowerInArea
	Returns a power value for a team in an area.
	Currently it only adds the power of a unit if that entire team's smart center is in the radius.
*/
private function float GetPowerInArea( Vector inAreaOrigin, int inAreaRadius, int inAllyID )
{
	local float power;
	local TMPlayerReplicationInfo tempPlayer;
	local array<TMPlayerReplicationInfo> playersInArea;

	playersInArea = GetPlayersInArea( inAreaOrigin, inAreaRadius, inAllyID );

	foreach playersInArea( tempPlayer )
	{
		power += GetPlayerPower( tempPlayer );
	}

	return power;
}

function float GetAllyPowerInArea( Vector inAreaOrigin, int inAreaRadius )
{
	return GetPowerInArea( inAreaOrigin, inAreaRadius, teamAIController.GetTMPRI().allyID );
}

function float GetEnemyPowerInArea( Vector inAreaOrigin, int inAreaRadius )
{
	local int enemyAllyID;
	enemyAllyID = Abs( teamAIController.GetTMPRI().allyID - 1 );
	return GetPowerInArea( inAreaOrigin, inAreaRadius, enemyAllyID );
}


///// Helper Functions /////

function RemoveInvalidPawnsFromList( out array< TMPawn > inOutPawnArray )
{
	local int i;
	for( i = inOutPawnArray.Length-1; i >= 0; i-- )
	{
		if(false == class'UDKRTSPawn'.static.IsValidPawn(inOutPawnArray[i]))
		{
			inOutPawnArray.Remove( i, 1 );
		}
	}
}

DefaultProperties
{
	bAlwaysRelevant=true
	bHidden=false
}
