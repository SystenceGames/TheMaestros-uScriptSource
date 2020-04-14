class TMFarmBehavior extends Object implements(TMBehavior);

enum FarmState
{
	FS_IDLE,
	FS_MOVING_TO_CAMP,
	FS_ATTACKING_CAMP,
	FS_WAITING
};
var FarmState mState;

var TMBehaviorHelper mTMBehaviorHelper;
var TMTeamAIController 	mTeamAIController;
var TMTeamAIKnowledge 	mKnowledge;

var TMNeutralCamp mTargetCamp;

var float mTargetPopulationAsPercentOfMax;

var float mLastAttackTime;
var float ATTACK_FREQUENCY; 	// will call attack multiple times to ensure all of our spawned units are still attacking

var float mWaitDuration; 	// the current wait duration we will track. This is a fuzzed version of the target wait duration
var float mTargetWaitDuration; 	// our target wait duration

var float mTimeStartedState; 	// keep track of how long we've been in a state to do a budge
var float TIME_DURATION_FOR_STUCK;

var float mDistanceBeforeAttackMove;

var float MINIMUM_COMMANDER_HP_PERCENTAGE; 	// the lowest our commander's health can be to farm. We won't farm if our HP is below a threshold
var float MAXIMUM_CAMP_DISTANCE; 	// we won't farm if a camp is too far away

var bool mAllowedToFarmSteal; 	// when this is set to true, the bot may attempt to farm a camp that a teammate is already at

var string debugCurrentStatus;


function InitBehavior( TMTeamAIController teamAIController, TMBehaviorHelper behaviorHelper )
{
	mTeamAIController = teamAIController;
	mKnowledge = 		teamAIController.knowledge;
	mTMBehaviorHelper = behaviorHelper;

	LoadJsonSettings();

	StartIdle();
}

function LoadJsonSettings()
{
	local JsonObject json;

	json = mTMBehaviorHelper.LoadBehaviorJsonObject("farm_behavior");

	mTargetPopulationAsPercentOfMax = mTMBehaviorHelper.LoadFloatFromBehaviorJson("TargetPopulationAsPercentOfMax", json);
	mTargetWaitDuration = mTMBehaviorHelper.LoadFloatFromBehaviorJson("FarmingExtraWaitTime", json);
	mDistanceBeforeAttackMove = mTMBehaviorHelper.LoadFloatFromBehaviorJson("DistanceBeforeAttackMove", json);
	MAXIMUM_CAMP_DISTANCE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MAXIMUM_CAMP_DISTANCE", json);
	MINIMUM_COMMANDER_HP_PERCENTAGE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MINIMUM_COMMANDER_HP_PERCENTAGE", json);
	mAllowedToFarmSteal = mTMBehaviorHelper.LoadBoolFromBehaviorJson("AllowedToFarmSteal", json);
}

function int GetImportance()
{
	if( mKnowledge.IsEnemyInVisionRange() )
	{
		return 0;
	}

	// Farming isn't important if our commander is too hurt.
	if( mKnowledge.GetCommanderHealthPercentage() < MINIMUM_COMMANDER_HP_PERCENTAGE )
	{
		return 0;
	}

	if( mState == FS_ATTACKING_CAMP || mState == FS_WAITING )
	{
		return 4;
	}

	if( HasReachedTargetPopulation() )
	{
		return 0;
	}

	if( mState == FS_MOVING_TO_CAMP )
	{
		return 3;
	}

	if( HaveAvailableCampInRange() )
	{
		return 3;
	}

	return 0;
}

function FinishTask( int importance )
{
	// Just break out of the task. We can do smarter behavior later
	StartIdle();

	mTeamAIController.Log( "TMFarmBehavior::FinishTask() breaking out of farming!" );
	mTeamAIController.IssueStopCommand(mKnowledge.GetMyPawns());
	mTeamAIController.FinishBehavior( self );
	mTMBehaviorHelper.mTMEventTimer.StopEvent("Farming");
}

function Update( float dt )
{
	mTMBehaviorHelper.Update(dt);

	switch( mState )
	{
		case FS_IDLE:
			UpdateIdle();
			break;
		case FS_MOVING_TO_CAMP:
			UpdateMovingToCamp();
			break;
		case FS_ATTACKING_CAMP:
			UpdateAttackingCamp();
			break;
		case FS_WAITING:
			UpdateWaiting();
			break;
	}

	mTeamAIController.DrawDebugCircleWhite(mKnowledge.GetMySmartLocation(), MAXIMUM_CAMP_DISTANCE);
}

function NotifyMoveComplete( Vector inLocation )
{
	StartAttackingCamp();
}

function StartState( FarmState inState )
{
	mState = inState;
}

function StartIdle()
{
	mTeamAIController.Log( "TMFarmBehavior: Starting idle!" );
	StartState( FS_IDLE );
	debugCurrentStatus = "Idle.";
}

function UpdateIdle()
{
	if( HasReachedTargetPopulation() || HaveAvailableCampInRange() == false )
	{
		mTeamAIController.FinishBehavior( self );
	}
	else
	{
		mTargetCamp = FindBestCamp();
		StartMovingToCamp();
	}
}

function StartMovingToCamp()
{
	mTMBehaviorHelper.MoveArmyToLocation( mKnowledge.GetNeutralCampLocation( mTargetCamp ), mDistanceBeforeAttackMove );
	StartState( FS_MOVING_TO_CAMP );
	ResetStuckTimer();
	mTMBehaviorHelper.mTMEventTimer.StartEvent("Farming");
	mTMBehaviorHelper.mTMEventTimer.StartEvent("  Farm: Moving");
	debugCurrentStatus = "Moving to camp.";
}

function UpdateMovingToCamp()
{
	if( mTargetCamp.mIsDead )
	{
		// The camp I was running towards died
		mTargetCamp = FindBestCamp();
		StartMovingToCamp();
	}

	mTeamAIController.DrawDebugCircleRed(mKnowledge.GetMySmartLocation(), mDistanceBeforeAttackMove);

	// If we've been traveling for a long enough time, we might be stuck
	CheckIfStuck();
}

function ResetStuckTimer()
{
	mTimeStartedState = mKnowledge.GetCurrentTime();
}

function CheckIfStuck()
{
	if( mKnowledge.GetCurrentTime() - mTimeStartedState >= TIME_DURATION_FOR_STUCK )
	{
		// We've been stuck in this state
		StartWaiting();
		mTeamAIController.MoveToSafeLocation();
	}
}

function StartAttackingCamp()
{
	AttackCamp();
	StartState( FS_ATTACKING_CAMP );
	mTMBehaviorHelper.mTMEventTimer.StopEvent("  Farm: Moving");
	mTMBehaviorHelper.mTMEventTimer.StartEvent("  Farm: Attacking");
	debugCurrentStatus = "Attacking camp.";
}

function AttackCamp()
{
	local array< TMPawn > myPawns;
	myPawns = mKnowledge.GetMyPawns();

	mTeamAIController.Log( "TMFarmBehavior: Attacking neutral camp " $ mTargetCamp );
	mTeamAIController.AttackMovePawns( myPawns, mKnowledge.GetNeutralCampLocation( mTargetCamp ) );
	mLastAttackTime = mKnowledge.GetCurrentTime();
}

function UpdateAttackingCamp()
{
	if( mTargetCamp == none || mTargetCamp.mIsDead )
	{
		mTeamAIController.Log( "TMFarmBehavior: Camp " $ mTargetCamp.name $ " is dead!" );
		mTargetCamp = none;
		StartWaiting();
	}
	else
	{
		// Attack the camp again with our full army if we haven't attacked in a while
		if( mKnowledge.GetCurrentTime() - mLastAttackTime > ATTACK_FREQUENCY )
		{
			AttackCamp();
		}
	}
}

function StartWaiting()
{
	mTimeStartedState = mKnowledge.GetCurrentTime();

	mTeamAIController.IssueStopCommand( mKnowledge.GetMyPawns() );

	mWaitDuration = mTMBehaviorHelper.FuzzValue(mTargetWaitDuration);

	StartState( FS_WAITING );
	mTMBehaviorHelper.mTMEventTimer.StopEvent("  Farm: Attacking");
	mTMBehaviorHelper.mTMEventTimer.StartEvent("  Farm: Waiting");
	debugCurrentStatus = "Waiting.";
}

function UpdateWaiting()
{
	if( mKnowledge.GetCurrentTime() - mTimeStartedState > mWaitDuration )
	{
		mTMBehaviorHelper.mTMEventTimer.StopEvent("  Farm: Waiting");
		mTMBehaviorHelper.mTMEventTimer.StopEvent("Farming");
		
		FinishTask( 100 );
	}
}

function TMNeutralCamp FindBestCamp()
{
	local TMNeutralCamp closestCamp;

	closestCamp = SelectNearestCampToFarm(MAXIMUM_CAMP_DISTANCE);

	mTeamAIController.Log( "TMFarmBehavior: Closest camp is " $ closestCamp.name );

	return closestCamp;
}

function bool HaveAvailableCampInRange()
{
	local array<TMNeutralCamp> camps;
	local TMNeutralCamp iterCamp;

	camps = mKnowledge.GetNeutralCamps();

	// Look for available camps that are in range
	foreach camps(iterCamp)
	{
		if( IsCampUnavailableToFarm(iterCamp) )
		{
			continue;
		}

		if( mTMBehaviorHelper.IsArmyInRange(iterCamp.Location, MAXIMUM_CAMP_DISTANCE) )
		{
			return true;
		}
	}

	return false;
}

function bool IsCampBeingFarmed( TMNeutralCamp inCamp )
{
	// This camp is "being farmed" if another player has clicked within 1000 units of it
	return mKnowledge.IsLocationBeingTargeted( mKnowledge.GetNeutralCampLocation( inCamp ), 1000 );
}

function bool IsCampUnavailableToFarm( TMNeutralCamp inCamp )
{
	// If we can't farm steal and it's currently being farmed, this camp is unavailable
	if( mAllowedToFarmSteal == false && IsCampBeingFarmed(inCamp) ){
		return true;
	}

	return (
			inCamp.mIsDead ||
			inCamp.ContainsNonNeutral() 	// special camps like brute or nexus
		);
}

function TMNeutralCamp SelectNearestCampToFarm(float inFalloffRadius, bool inAllowFarmStealing = False)
{
	local float distance, weight;
	local array<int> weights;
	local Vector origin;
	local TMNeutralCamp iterCamp;
	local int selectedIndex;
	local array<TMNeutralCamp> camps;
	local int i;

	origin = mKnowledge.GetMySmartLocation();
	camps = mKnowledge.GetNeutralCamps();

	// Remove any camps that won't be considered
	for( i = camps.Length - 1; i >= 0; i-- )
	{
		if( IsCampUnavailableToFarm(camps[i]) )
		{
			camps.Remove( i, 1 );
		}
	}

	// Assign weights. Modify weights for camps with teammates
	foreach camps(iterCamp)
	{
		distance = VSize(iterCamp.Location - origin);
		weight = inFalloffRadius - distance;

		// Punish the weight if the camp is being farmed by a teammate
		if( IsCampBeingFarmed( iterCamp ) )
		{
			weight = 1;
		}

		weights.AddItem( weight );
	}

	if( weights.Length != camps.Length )
	{
		`warn("SelectNearestCamp() weights list doesn't match camp list size.");
		return camps[0];
	}

	`log("Selecting index for best camp");
	selectedIndex = mTMBehaviorHelper.MakeWeightedSelection(weights, mTeamAIController.mWeightExponent);

	return camps[selectedIndex];
}

function bool HasReachedTargetPopulation()
{
	return mTeamAIController.GetTMPRI().Population >= (mTeamAIController.GetTMPRI().PopulationCap * mTargetPopulationAsPercentOfMax);
}

function string GetName()
{
	return "FarmBehavior";
}

function bool ShouldKeepArmyCentered()
{
	return true;
}

function string GetDebugBehaviorStatus()
{
	return "FARMING: " $ debugCurrentStatus;
}

defaultproperties
{
	ATTACK_FREQUENCY = 5;
	TIME_DURATION_FOR_STUCK = 30;
}
