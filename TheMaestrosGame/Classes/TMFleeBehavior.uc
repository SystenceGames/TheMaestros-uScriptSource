class TMFleeBehavior extends Object implements(TMBehavior);

enum FleeState
{
	FS_WAITING,
	FS_FLEEING
};
var FleeState mState;

var TMBehaviorHelper 	mTMBehaviorHelper;
var TMTeamAIController 	mTeamAIController;
var TMTeamAIKnowledge 	mKnowledge;

var float mFleeStartTime;
var float mIntervalStartTime;

var float DANGER_RADIUS;
var float ENEMY_POWER_RATIO_TO_FLEE; 	// ratio between enemy power to team power that causes flee to trigger
var float ENEMY_POWER_RATIO_TO_BE_NERVOUS; 	// ratio between enemy power to team power that causes flee to register some importance
var float TARGET_FLEE_DISTANCE; 		// distance we look away from enemy for a safe flee location
var float MINIMUM_FLEE_DISTANCE;
var float CALCULATE_FLEE_INTERVAL; 	 	// how frequently we recalculate danger
var float MINIMUM_FLEE_DURATION;

var bool SHOULD_BOT_BE_BAD; 	// if this is true the bot will purposely gimp himself
var float BAD_BOT_RATIO_TO_NOT_FLEE;

var string debugCurrentStatus;


function InitBehavior( TMTeamAIController inTeamAiController, TMBehaviorHelper behaviorHelper )
{
	mTeamAIController = inTeamAiController;
	mKnowledge = 		inTeamAiController.knowledge;

	mTMBehaviorHelper = behaviorHelper;

	LoadJsonSettings();

	mState = FS_WAITING;
}

function int GetImportance()
{
	local float teamPower, enemyPower;
	local float dangerRatio;
	local Vector myLocation;

	// Don't stop "fleeing" if we just issued a move command. Finish out the flee duration.
	if( mState == FS_FLEEING &&
		mKnowledge.GetCurrentTime() - mFleeStartTime < MINIMUM_FLEE_DURATION )
	{
		return 5;
	}

	/* We recalculate danger every GetImportance(). This is expensive. We can do it less
	frequently if we want in the future by using the CALCULATE_FLEE_INTERVAL timer. */
	myLocation = mKnowledge.GetCommanderLocation();

	teamPower = mKnowledge.GetAllyPowerInArea( myLocation, DANGER_RADIUS );
	enemyPower = mKnowledge.GetEnemyPowerInArea( myLocation, DANGER_RADIUS );
	dangerRatio = enemyPower / teamPower;

	if( SHOULD_BOT_BE_BAD )
	{
		// Don't try to flee from other bots, only players
		if( mKnowledge.closestEnemy.mIsBot )
		{
			return 0;
		}

		// If closest enemy within 1250 units, don't flee
		if( mKnowledge.closestEnemy != none && mKnowledge.closestEnemyDistanceSquared <= (1250*1250) )
		{
			return 0;
		}

		// Flee if the enemy is weaker than us within a range
		if( dangerRatio >= ENEMY_POWER_RATIO_TO_FLEE && dangerRatio < BAD_BOT_RATIO_TO_NOT_FLEE )
		{
			debugCurrentStatus = "(DUMB BOT) The enemy is weaker than me, don't hurt them.";
			return 4;
		}

		// Fleeing isn't important. The enemy is either much weaker than us, or the enemy is stronger
		return 0;
	}

	if( dangerRatio >= ENEMY_POWER_RATIO_TO_FLEE )
	{
		debugCurrentStatus = "Enemy is much stronger!";
		return 4;
	}

	if( dangerRatio >= ENEMY_POWER_RATIO_TO_BE_NERVOUS )
	{
		debugCurrentStatus = "Enemy is making me nervous.";
		return 3;
	}

	return 0;
}

function FinishTask( int importance )
{
	mTeamAIController.Log( "TMFleeBehavior::FinishTask() breaking out of fleeing!" );

	mState = FS_WAITING;

	mTeamAIController.FinishBehavior( self );
}

function LoadJsonSettings()
{
	local JsonObject json;

	json = mTMBehaviorHelper.LoadBehaviorJsonObject("flee_behavior");

	DANGER_RADIUS = mTMBehaviorHelper.LoadFloatFromBehaviorJson("DANGER_RADIUS", json);
	ENEMY_POWER_RATIO_TO_FLEE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("ENEMY_POWER_RATIO_TO_FLEE", json);
	ENEMY_POWER_RATIO_TO_BE_NERVOUS = mTMBehaviorHelper.LoadFloatFromBehaviorJson("ENEMY_POWER_RATIO_TO_BE_NERVOUS", json);
	SHOULD_BOT_BE_BAD = mTMBehaviorHelper.LoadBoolFromBehaviorJson("SHOULD_BOT_BE_BAD", json);
	BAD_BOT_RATIO_TO_NOT_FLEE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("BAD_BOT_RATIO_TO_NOT_FLEE", json);
}

function Update( float dt )
{
	mTMBehaviorHelper.Update(dt);

	if( mState == FS_WAITING )
	{
		mFleeStartTime = mKnowledge.GetCurrentTime();
		StartFleeing();
	}
	else if( mState == FS_FLEEING )
	{
		// Start fleeing again if the interval triggers and we're still in danger
		if( mKnowledge.GetCurrentTime() - mIntervalStartTime > CALCULATE_FLEE_INTERVAL )
		{
			StartFleeing();
		}

		mTeamAIController.DrawDebugCircleRed(mKnowledge.GetCommanderLocation(), DANGER_RADIUS);
		mTeamAIController.DrawDebugCircleWhite(mKnowledge.GetCommanderLocation(), TARGET_FLEE_DISTANCE);
		mTeamAIController.DrawDebugCircleBlue(mKnowledge.GetCommanderLocation(), MINIMUM_FLEE_DISTANCE);
	}
}

function StartFleeing()
{
	local Vector enemyDirection;
	local Vector targetFleeLocation;
	local Vector myLocation;

	mTeamAIController.Log( "TMFleeBehavior: Fleeing!!!" );

	mState = FS_FLEEING;
	mIntervalStartTime = mKnowledge.GetCurrentTime();

	enemyDirection = GetEnemyDirection();
	// mTeamAIController.Log( "TMFleeBehavior: The enemy is towards X:" $ enemyDirection.X $ " Y:" $ enemyDirection.Y );

	myLocation = mKnowledge.GetCommanderLocation();
	targetFleeLocation = (-enemyDirection) * TARGET_FLEE_DISTANCE + myLocation;
	// mTeamAIController.Log( "TMFleeBehavior: Fleeing to location X:" $ targetFleeLocation.X $ " Y:" $ targetFleeLocation.Y );
	// mTeamAIController.Log( "TMFleeBehavior: (My location is: X:" $ myLocation.X $ " Y:" $ myLocation.Y $ ")" );

	mTMBehaviorHelper.MoveArmyToLocation( GetNearestSafeLandmark( targetFleeLocation ) );
}

private function Vector GetEnemyDirection()
{
	local Vector sumEnemyDirection;
	local Vector tempEnemyLocation;
	local Vector myLocation;
	local array<Vector> enemyLocations;

	enemyLocations = mKnowledge.GetEnemyLocations();
	myLocation = mKnowledge.GetCommanderLocation();

	foreach enemyLocations( tempEnemyLocation )
	{
		sumEnemyDirection += Normal( tempEnemyLocation - myLocation );
	}

	return Normal( sumEnemyDirection );
}

/* GetNearestSafeLandmark
	Returns the position of the closest safe landmark to inTargetPoint
	Safe landmarks: teammates, transformers, neutral camps
*/
private function Vector GetNearestSafeLandmark( Vector inTargetPoint )
{
	local array<Vector> safeLocations;
	local TMPlayerReplicationInfo tempAlly;
	local TMTransformer tempTrans;
	local array<TMTransformer> transformers;
	local TMNeutralCamp tempCamp;
	local array<TMNeutralCamp> camps;

	foreach mKnowledge.mAllyTMPRIs( tempAlly )
	{
		if( tempAlly.PlayerID != mTeamAIController.GetTMPRI().PlayerID )
		{
			safeLocations.AddItem( class'UDKRTSPawn'.static.SmartCenterOfGroup( tempAlly.m_PlayerUnits ) );
		}
	}

	transformers = mKnowledge.GetTransformers();
	foreach transformers( tempTrans )
	{
		safeLocations.AddItem( tempTrans.Location );
	}

	camps = mKnowledge.GetNeutralCamps();
	foreach camps( tempCamp )
	{
		safeLocations.AddItem( mKnowledge.GetNeutralCampLocation( tempCamp ) );
	}

	return mTMBehaviorHelper.GetClosestLocationNotInRadius( inTargetPoint, safeLocations, mKnowledge.GetCommanderLocation(), MINIMUM_FLEE_DISTANCE );
}

function NotifyMoveComplete( Vector inLocation )
{
	// Keep running until another behavior is more important
	StartFleeing();
}

function string GetName()
{
	return "FleeBehavior";
}

function bool ShouldKeepArmyCentered()
{
	return false;
}

function string GetDebugBehaviorStatus()
{
	return "FLEEING: " $ debugCurrentStatus;
}

defaultproperties
{
	DANGER_RADIUS = 1500;
	ENEMY_POWER_RATIO_TO_FLEE = 2.5f;
	ENEMY_POWER_RATIO_TO_BE_NERVOUS = 1.5f;
	TARGET_FLEE_DISTANCE = 3000;
	MINIMUM_FLEE_DISTANCE = 1000;
	CALCULATE_FLEE_INTERVAL = 0.5f;
	MINIMUM_FLEE_DURATION = 5f;
}
