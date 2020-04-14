/* TMWanderBehavior
	Behavior where the bot will wander around the map. Intended to slow down the bots.
*/
class TMWanderBehavior extends Object implements(TMBehavior);

var TMBehaviorHelper mTMBehaviorHelper;
var TMTeamAIController 	mTeamAIController;
var TMTeamAIKnowledge 	mKnowledge;

var bool mIsWandering;

var float WANDER_DURATION;
var float MAX_DURATION_PER_MOVE; 	// max amount of time per move location to wander
var float mCurrentWanderTime;

var float ENEMY_SIGHT_RADIUS;
var float MAXIMUM_WANDER_RANGE;
var float MINIMUM_WANDER_RANGE;
var float DISTANCE_TO_TRANSLATE; 	// we will translate our center point based on points of interest
var float MAX_ALLY_LOCATION_WEIGHT_SCALAR; 	// we'll scale the weight of ally locations using this number. Higher is more likely to be selected
var float MAX_ENEMY_LOCATION_WEIGHT_SCALAR; 	// we'll scale the weight of enemy locations using this number. Higher is more likely to be selected
var float ALLY_POWER_RATIO_FAVOR_ENEMIES; 	// if we have at least this ally power ratio we'll move closer to enemies
var float TEAM_POWER_RADIUS; 	// radius to calculate team power

// These values will change as the bot situation changes
var float mCurrentAllyLocationWeightScalar;
var float mCurrentEnemyLocationWeightScalar;

var array<Vector> recentlyVisitedList;
var int MAX_RECENTLY_VISITED_LIST_SIZE;

var bool SHOULD_BOT_BE_BAD; 	// if this is true, the bot will charge towards danger when they have a worse army, but aimlessly wander when they have a winning army. Fun 10/10 noobs love it

var string debugCurrentStatus;


function InitBehavior( TMTeamAIController teamAIController, TMBehaviorHelper behaviorHelper )
{
	mTeamAIController = teamAIController;
	mKnowledge = 		teamAIController.knowledge;

	mTMBehaviorHelper = behaviorHelper;

	LoadJsonSettings();
}

function LoadJsonSettings()
{
	local JsonObject json;

	json = mTMBehaviorHelper.LoadBehaviorJsonObject("wander_behavior");

	ENEMY_SIGHT_RADIUS = mTMBehaviorHelper.LoadFloatFromBehaviorJson("ENEMY_SIGHT_RADIUS", json);
	WANDER_DURATION = mTMBehaviorHelper.LoadFloatFromBehaviorJson("WANDER_DURATION", json);
	MAXIMUM_WANDER_RANGE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MAXIMUM_WANDER_RANGE", json);
	MINIMUM_WANDER_RANGE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MINIMUM_WANDER_RANGE", json);
	DISTANCE_TO_TRANSLATE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("DISTANCE_TO_TRANSLATE", json);
	MAX_ALLY_LOCATION_WEIGHT_SCALAR = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MAX_ALLY_LOCATION_WEIGHT_SCALAR", json);
	MAX_ENEMY_LOCATION_WEIGHT_SCALAR = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MAX_ENEMY_LOCATION_WEIGHT_SCALAR", json);
	ALLY_POWER_RATIO_FAVOR_ENEMIES = mTMBehaviorHelper.LoadFloatFromBehaviorJson("ALLY_POWER_RATIO_FAVOR_ENEMIES", json);
	SHOULD_BOT_BE_BAD = mTMBehaviorHelper.LoadBoolFromBehaviorJson("SHOULD_BOT_BE_BAD", json);
	TEAM_POWER_RADIUS = mTMBehaviorHelper.LoadFloatFromBehaviorJson("TEAM_POWER_RADIUS", json);	
}

function int GetImportance()
{
	if( mKnowledge.IsEnemyInVisionRange() )
	{
		return 0;
	}

	return 2;
}

function FinishTask( int importance )
{
	mIsWandering = false;

	mTeamAIController.Log( "TMWanderBehavior::FinishTask() stopping wandering." );
	mTeamAIController.FinishBehavior( self );
	mTMBehaviorHelper.mTMEventTimer.StopEvent("Wandering");
}

function Update( float dt )
{
	mTMBehaviorHelper.Update(dt);

	if( mIsWandering == false )
	{
		StartWandering();
	}
	else
	{
		mCurrentWanderTime += dt;

		mTeamAIController.DrawDebugCircleRed(mKnowledge.GetMySmartLocation(), ENEMY_SIGHT_RADIUS);
		mTeamAIController.DrawDebugCircleBlue(mKnowledge.GetMySmartLocation(), MINIMUM_WANDER_RANGE);
	}
}

function StartWandering()
{
	mTMBehaviorHelper.mTMEventTimer.StartEvent("Wandering");
	mIsWandering = true;

	WanderToLocation();
}

function WanderToLocation()
{
	mTMBehaviorHelper.MoveArmyToLocation( ChooseWanderLocation() );

	mTeamAiController.SetTimer( MAX_DURATION_PER_MOVE, false, NameOf( MaxMoveDurationElapsed ), self);
}

function NotifyMoveComplete( Vector inLocation )
{
	WanderToLocation();
}

function MaxMoveDurationElapsed()
{
	if( mTMBehaviorHelper.IsCurrentBehavior(self) )
	{
		WanderToLocation();
	}
}

/* ChooseWanderLocation
	Returns the position of a close landmark to wander to.
	Usually the wander location is a safe location, like a transform point or teammate.
	Sometimes situations may cause the bot to favor enemy locations, for example if the bot has an army advantage.
*/
private function Vector ChooseWanderLocation()
{
	local Vector centerPoint, targetLocation;
	local array<Vector> transformerLocations, allyLocations, enemyLocations;

	allyLocations = mKnowledge.GetAllyLocations();
	enemyLocations = mKnowledge.GetEnemyLocations();
	transformerLocations = mKnowledge.GetTransformerLocations();

	centerPoint = ChooseWanderLocationCenterPoint();

	// Remove our recently visited locations from the list
	allyLocations = mTMBehaviorHelper.RemoveLocationsFromList(recentlyVisitedList, allyLocations);
	enemyLocations = mTMBehaviorHelper.RemoveLocationsFromList(recentlyVisitedList, enemyLocations);
	transformerLocations = mTMBehaviorHelper.RemoveLocationsFromList(recentlyVisitedList, transformerLocations);

	targetLocation = mTMBehaviorHelper.SelectNearestLocationWithScalars(centerPoint, MAXIMUM_WANDER_RANGE, MINIMUM_WANDER_RANGE,
																		transformerLocations, 1,
																		allyLocations, mCurrentAllyLocationWeightScalar,
																		enemyLocations, mCurrentEnemyLocationWeightScalar);
	recentlyVisitedList.AddItem(targetLocation);
	if( recentlyVisitedList.length > MAX_RECENTLY_VISITED_LIST_SIZE )
	{
		recentlyVisitedList.Remove(0, 1);
	}

	return targetLocation;
}

function Vector ChooseWanderLocationCenterPoint()
{
	local float allyPower, enemyPower;
	local float allyPowerRatio;
	local Vector closestEnemyLocation;

	closestEnemyLocation = mKnowledge.GetPlayerSmartLocation(mKnowledge.closestEnemy);

	allyPower = mKnowledge.GetAllyPowerInArea( mKnowledge.GetMySmartLocation(), TEAM_POWER_RADIUS );
	enemyPower = mKnowledge.GetEnemyPowerInArea( closestEnemyLocation, TEAM_POWER_RADIUS );

	// Make sure enemy power isn't zero so we can divide with it
	if(enemyPower == 0) {
		enemyPower = 0.01f;
	}

	allyPowerRatio = allyPower / enemyPower;

	// Decisions if the bot is trying to be bad
	if( SHOULD_BOT_BE_BAD )
	{
		if( allyPowerRatio < 1 )
		{
			debugCurrentStatus = "I CAN LOSE! Wandering to enemy";
			mCurrentAllyLocationWeightScalar = 1;
			mCurrentEnemyLocationWeightScalar = MAX_ENEMY_LOCATION_WEIGHT_SCALAR;
			return GetLocationInDirectionFromArmy(closestEnemyLocation);
		}
		else
		{
			debugCurrentStatus = "Wandering randomly.";
			mCurrentAllyLocationWeightScalar = MAX_ALLY_LOCATION_WEIGHT_SCALAR;
			mCurrentEnemyLocationWeightScalar = 1;
			return mKnowledge.GetMySmartLocation();
		}
	}

	// Smart bot behavior
	if( allyPowerRatio > ALLY_POWER_RATIO_FAVOR_ENEMIES )
	{
		debugCurrentStatus = "Favoring enemy location.";
		mCurrentAllyLocationWeightScalar = 1;
		mCurrentEnemyLocationWeightScalar = MAX_ENEMY_LOCATION_WEIGHT_SCALAR;
		return GetLocationInDirectionFromArmy(closestEnemyLocation);
	} else {
		debugCurrentStatus = "Sticking with my team.";
		mCurrentAllyLocationWeightScalar = MAX_ALLY_LOCATION_WEIGHT_SCALAR;
		mCurrentEnemyLocationWeightScalar = 1;
		return mKnowledge.GetMySmartLocation();
	}
}

function Vector GetLocationInDirectionFromArmy(Vector inTargetLocation)
{
	local Vector direction;

	direction = Normal(inTargetLocation - mKnowledge.GetMySmartLocation());
	return mKnowledge.GetMySmartLocation() + direction * DISTANCE_TO_TRANSLATE;
}

function string GetName()
{
	return "WanderBehavior";
}

function bool ShouldKeepArmyCentered()
{
	return true;
}

function string GetDebugBehaviorStatus()
{
	return "WANDERING: " $ debugCurrentStatus;
}

defaultproperties
{
	MAX_DURATION_PER_MOVE = 10;  	// 10 second buffer if we get stuck

	MAX_RECENTLY_VISITED_LIST_SIZE = 4;
}
