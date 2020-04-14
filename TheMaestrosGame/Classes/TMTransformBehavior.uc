class TMTransformBehavior extends Object implements(TMBehavior);

enum TransformState
{
	TS_IDLE,
	TS_MOVING_TO_TRANSFORM,
	TS_TRANSFORMING
};
var TransformState mState;

var TMBehaviorHelper mTMBehaviorHelper;
var TMTeamAIController 	mTeamAIController;
var TMTeamAIKnowledge 	mKnowledge;

var Vector mTargetTransformerLocation;

var float DISTANCE_BEFORE_TRANSFORM;

var float mTransformingStartTime;
var float mTransformDuration;

var float CLOSEST_TRANSFORM_DISTANCE_FUZZ;

var float TIME_BETWEEN_TRANSFORM_BEHAVIORS; 	// time before trying transform again
var float mLastTranformTime;

var float mMaxTransformDistance;

var string debugCurrentStatus;


function InitBehavior(TMTeamAIController teamAIController, TMBehaviorHelper behaviorHelper)
{
	mTeamAIController = teamAIController;
	mKnowledge = mTeamAIController.knowledge;
	mTMBehaviorHelper = behaviorHelper;

	LoadJsonSettings();

	mState = TS_IDLE;
}

function int GetImportance()
{
	if( mKnowledge.IsEnemyInVisionRange() )
	{
		return 0;
	}

	if( mTeamAIController.WorldInfo.TimeSeconds - mLastTranformTime < TIME_BETWEEN_TRANSFORM_BEHAVIORS )
	{
		return 0;
	}

	if( mState == TS_TRANSFORMING )
	{
		return 3;
	}

	if( mKnowledge.GetDoughboyCount() > 6 && HaveTransformPointInRange() )
	{
		return 3;
	}

	return 0;
}

function FinishTask(int importance)
{
	// Just break out of the task. We can do smarter behavior later
	mState = TS_IDLE;
	debugCurrentStatus = "Idle.";

	mLastTranformTime = mTeamAIController.WorldInfo.TimeSeconds;

	mTeamAIController.FinishBehavior( self );
}

function LoadJsonSettings()
{
	local JsonObject json;

	json = mTMBehaviorHelper.LoadBehaviorJsonObject("transform_behavior");

	mMaxTransformDistance = mTMBehaviorHelper.LoadFloatFromBehaviorJson("MaxTransformDistance", json);
}

function NotifyMoveComplete( Vector inLocation )
{
	StartTransforming();
}

function Update(float dt)
{
	mTMBehaviorHelper.Update(dt);

	switch( mState )
	{
	case TS_IDLE:
		UpdateIdle();
		break;
	case TS_MOVING_TO_TRANSFORM:
		// Waiting for callback. In future check if we're under attack???
		mTeamAIController.DrawDebugCircleBlue(mKnowledge.GetMySmartLocation(), DISTANCE_BEFORE_TRANSFORM);
		mTeamAIController.DrawDebugCircleWhite(mKnowledge.GetMySmartLocation(), mMaxTransformDistance);
		break;
	case TS_TRANSFORMING:
		UpdateTransforming();
		break;
	}
}

function UpdateIdle()
{
	if( mKnowledge.GetDoughboyCount() < 4 ) 	// Taylor TODO: make this smarter
	{
		mTeamAIController.FinishBehavior( self );
	}
	else
	{
		StartMovingToNearestTransform();
	}
}

function StartMovingToNearestTransform()
{
	if( HaveTransformPointInRange() == false )
	{
		FinishTask(100);
		return;
	}

	mTargetTransformerLocation = FindNearestTransformPoint();
	mTeamAIController.Log( "TMTransformBehavior: Moving to nearest transform" );
	debugCurrentStatus = "Moving to transform point";

	mTMBehaviorHelper.MoveArmyToLocation( mTargetTransformerLocation, DISTANCE_BEFORE_TRANSFORM );
	mState = TS_MOVING_TO_TRANSFORM;

	mTMBehaviorHelper.mTMEventTimer.StartEvent("Transforming");
}

function StartTransforming()
{
	local array< TMPawn > basicUnits;
	basicUnits = mKnowledge.GetMyBasicUnits();

	mTeamAIController.Log( "TMTransformBehavior: starting transform!!!" );
	debugCurrentStatus = "Transforming units.";
	mState = TS_TRANSFORMING;

	mTeamAIController.TransformPawns( basicUnits, mTargetTransformerLocation );
	mTransformingStartTime = mKnowledge.GetCurrentTime();
	mTransformDuration = basicUnits.Length / 2; 	// wait a half second for each pawn we have. This is dumb
}

function UpdateTransforming()
{
	if( mKnowledge.GetCurrentTime() - mTransformingStartTime > mTransformDuration )
	{
		mTeamAIController.Log( "TMTransformBehavior: done transforming!!!" );
		mState = TS_IDLE;
		FinishTask(100);

		mTMBehaviorHelper.mTMEventTimer.StopEvent("Transforming");
	}
}

function Vector FindNearestTransformPoint()
{
	local TMTransformer 		tempTrans;
	local array<TMTransformer> 	transList;
	local array<Vector> 		locationList;

	transList = mKnowledge.GetTransformers();

	foreach transList( tempTrans )
	{
		locationList.AddItem( tempTrans.Location );
	}

	return mTMBehaviorHelper.SelectNearestLocation( mKnowledge.GetMySmartLocation(), mMaxTransformDistance, locationList );
}

function bool HaveTransformPointInRange()
{
	local array<Vector> transLocations;
	local Vector iterLocation;
	local float sqRange;
	local Vector armyLocation;

	transLocations = mKnowledge.GetTransformerLocations();
	sqRange = mMaxTransformDistance * mMaxTransformDistance;
	armyLocation = mKnowledge.GetMySmartLocation();

	foreach transLocations(iterLocation)
	{
		if( VSizeSq( armyLocation - iterLocation ) < sqRange )
		{
			return true;
		}
	}

	return false;
}

function string GetName()
{
	return "TransformBehavior";
}

function bool ShouldKeepArmyCentered()
{
	return true;
}

function string GetDebugBehaviorStatus()
{
	return "TRANSFORMING: " $ debugCurrentStatus;
}

defaultproperties
{
	DISTANCE_BEFORE_TRANSFORM = 500;
	CLOSEST_TRANSFORM_DISTANCE_FUZZ = 0.3f;
	TIME_BETWEEN_TRANSFORM_BEHAVIORS = 10; 	// wait this many seconds before trying a transform again
}
