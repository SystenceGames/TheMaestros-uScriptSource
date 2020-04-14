class TMAttackBehavior extends Object implements(TMBehavior);

enum AttackBehaviorState
{
	ABS_IDLE,
	ABS_MOVING_TO_ENEMY,
	ABS_ATTACKING
};

var TMBehaviorHelper mTMBehaviorHelper;
var AttackBehaviorState mState;
var TMTeamAIController mTeamAIController;
var TMTeamAIKnowledge mKnowledge;
var TMPlayerReplicationInfo mEnemyTMPRIToAttack;
var TMPlayerReplicationInfo mTMPRI;
var Vector mEnemysPosition;
var float DISTANCE_TO_ATTACK_FROM;
var float MOVE_TICK_RATE;
var float ATTACK_TICK_RATE;
var float RECALC_CLOSEST_ENEMY_RATE; 	// how frequently to check for a new closest enemy
var float mTimeInState;
var float AGGRO_RANGE;
var float AGGRO_RANGE_SQUARED;
var float DISENGAGE_DISTANCE;
var float DISENGAGE_DISTANCE_SQUARED;
var float ABILITY_CAST_FREQUENCY;

///// 5/15/18 make bots smarter /////
/* If you constantly spam attack moves, there's a chance the attack component can get
	in a bad state where the pawn looks really dumb. Most players overcome this by
	issuing a move command. The true fix would be to fix the attack component. We will
	do that at a later date. In the mean time this hacky fix will issue a move command 
	after every X attack moves. This makes the bots not look as dumb.
*/
var int NUMBER_ATTACK_MOVES_TO_TRY;
var int mCurrentAttackMoveCount;

var string debugCurrentStatus;


function InitBehavior(TMTeamAIController teamAIController, TMBehaviorHelper behaviorHelper)
{
	mTeamAIController = teamAIController;
	mKnowledge = mTeamAIController.knowledge;
	mTMPRI = mTeamAIController.GetTMPRI();
	mTMBehaviorHelper = behaviorHelper;

	LoadJsonSettings();

	AGGRO_RANGE_SQUARED = AGGRO_RANGE * AGGRO_RANGE;
	DISENGAGE_DISTANCE_SQUARED = DISENGAGE_DISTANCE * DISENGAGE_DISTANCE;

	mState = ABS_IDLE;
}

function int GetImportance()
{
	if( mState == ABS_MOVING_TO_ENEMY )
	{
		// If we are chasing an enemy and he's out of disengage range, not important
		if( mKnowledge.closestEnemy != none && mKnowledge.closestEnemyDistanceSquared > DISENGAGE_DISTANCE_SQUARED )
		{
			return 0;
		}

		// If we are chasing an enemy and he's out of aggro range, drop importance
		if( mKnowledge.closestEnemy != none && mKnowledge.closestEnemyDistanceSquared > AGGRO_RANGE_SQUARED )
		{
			return 2;
		}

		return 3;
	}
	
	if( mState == ABS_ATTACKING )
	{
		return 4;
	}

	if( mKnowledge.closestEnemy != none && mKnowledge.closestEnemyDistanceSquared <= AGGRO_RANGE_SQUARED )
	{
		return 3;
	}

	return 0;
}

function LoadJsonSettings()
{
	local JsonObject json;

	json = mTMBehaviorHelper.LoadBehaviorJsonObject("attack_behavior");

	AGGRO_RANGE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("AGGRO_RANGE", json);
	DISTANCE_TO_ATTACK_FROM = mTMBehaviorHelper.LoadFloatFromBehaviorJson("DISTANCE_TO_ATTACK_FROM", json);
	ABILITY_CAST_FREQUENCY = mTMBehaviorHelper.LoadFloatFromBehaviorJson("ABILITY_CAST_FREQUENCY", json);
	DISENGAGE_DISTANCE = mTMBehaviorHelper.LoadFloatFromBehaviorJson("DISENGAGE_DISTANCE", json);
}

function FinishTask(int importance)
{
	BeginIdleState();

	mTeamAIController.Log( "TMAttackBehavior: FinishTask called! Switching to ABS_IDLE." );
	CleanMeUp();
	mTeamAIController.FinishBehavior( self );
}

function Update(float dt)
{
	mTMBehaviorHelper.Update(dt);

	switch ( mState )
	{
		case ABS_IDLE:
			HandleIdleState();
			break;
		case ABS_MOVING_TO_ENEMY:
			// Waiting for TeamAIController callback
			mTeamAIController.DrawDebugCircleRed(mKnowledge.GetMySmartLocation(), DISTANCE_TO_ATTACK_FROM);
			mTeamAIController.DrawDebugCircleWhite(mKnowledge.GetMySmartLocation(), AGGRO_RANGE);
			break;
		case ABS_ATTACKING:
			HandleAttackingState();
			break;
	}

	// Let's try not doing this. We're going to trust movement
	// CheckIfStuck();
}

function NotifyMoveComplete( Vector inLocation )
{
	mTeamAiController.ClearTimer( NameOf( MoveToEnemy ), self );
	mTeamAiController.ClearTimer( NameOf( BeginMovingToEnemyState ), self );

	BeginAttackingState();
}

function CleanMeUp()
{
	SetAbilityCastOn(false);
	mTeamAIController.ClearTimer( NameOf( MoveToEnemy ), self );
	mTeamAiController.ClearTimer( NameOf( BeginMovingToEnemyState ), self );
	mTeamAIController.ClearTimer( NameOf( AttackEnemy ), self );
}

function ResetStuckTimer()
{
	mTimeInState = mTeamAIController.mTMGameInfo.WorldInfo.TimeSeconds;
}

function CheckIfStuck()
{
	if( mTeamAIController.mTMGameInfo.WorldInfo.TimeSeconds - mTimeInState >= 30 )
	{
		// We've been stuck in this state
		mState = ABS_IDLE;
		CleanMeUp();
		mTeamAIController.MoveToSafeLocation();
	}
}

function BeginAttackingState()
{
	ResetStuckTimer();

	mEnemyTMPRIToAttack = mTeamAIController.knowledge.closestEnemy;
	if (mEnemyTMPRIToAttack == None)
	{
		FinishTask(100);
		return;
	}

	mCurrentAttackMoveCount = 0;
	mState = ABS_ATTACKING;
	mTeamAiController.SetTimer( ATTACK_TICK_RATE, true, NameOf( AttackEnemy ), self);
}

function HandleIdleState()
{
	BeginMovingToEnemyState();

	mTMBehaviorHelper.mTMEventTimer.StopEvent("Road to attack");
}

function BeginMovingToEnemyState()
{
	ResetStuckTimer();

	mEnemyTMPRIToAttack = mTMBehaviorHelper.GetClosestEnemy( mKnowledge.GetMySmartLocation(), mKnowledge.mEnemyTMPRIs );
	if (mEnemyTMPRIToAttack == None)
	{
		FinishTask(100);
		return;
	}
	else
	{
		mTeamAIController.Log( "TMAttackBehavior: Moving to enemy!!!" );
		mState = ABS_MOVING_TO_ENEMY;
		mTeamAiController.SetTimer( MOVE_TICK_RATE, true, NameOf( MoveToEnemy ), self);
		mTeamAiController.SetTimer( RECALC_CLOSEST_ENEMY_RATE, false, NameOf( BeginMovingToEnemyState ), self);
		SetAbilityCastOn(false);
		debugCurrentStatus = "Moving to enemy.";
	}
}

function MoveToEnemy()
{
	mEnemysPosition = class'UDKRTSPawn'.static.SmartCenterOfGroup( mEnemyTMPRIToAttack.m_PlayerUnits );
	mTMBehaviorHelper.MoveArmyToLocation( mEnemysPosition, DISTANCE_TO_ATTACK_FROM );
}

function BeginIdleState()
{
	mState = ABS_IDLE;

	ResetStuckTimer();
	CleanMeUp();

	debugCurrentStatus = "Idle.";
}

function HandleAttackingState()
{
	if (mEnemyTMPRIToAttack == None || mEnemyTMPRIToAttack.bIsCommanderDead)
	{
		FinishTask(100);
	}
}

function AttackEnemy()
{
	local array<TMPawn> myPawns;

	mTMBehaviorHelper.mTMEventTimer.StopEvent("First contact");

	if (mEnemyTMPRIToAttack == none || mEnemyTMPRIToAttack.bIsCommanderDead)
	{
		FinishTask(100);
		return;
	}

	debugCurrentStatus = "Attacking enemy.";

	/* TEMP attack move bad case
		If we've issued a lot of attack move commands, we might get stuck.
		Restart the state loop (causes a move command) to break this ugly
		case.
	*/
	mCurrentAttackMoveCount = mCurrentAttackMoveCount + 1;
	if( mCurrentAttackMoveCount > NUMBER_ATTACK_MOVES_TO_TRY )
	{
		mTeamAIController.Log("RESTARTING ATTACK SEQUENCE.");
		BeginMovingToEnemyState();
		return;
	}

	myPawns = mKnowledge.GetMyPawns();
	mTeamAIController.IssueStopCommand(myPawns); 	// stop first, just in case any are stuck or frozen from being stunned
	mTeamAIController.AttackMovePawns( myPawns, class'UDKRTSPawn'.static.SmartCenterOfGroup( mEnemyTMPRIToAttack.m_PlayerUnits ));
	SetAbilityCastOn(true);
}

function string GetName()
{
	return "AttackBehavior";
}

function bool ShouldKeepArmyCentered()
{
	return true;
}

function SetAbilityCastOn(bool isIsOn)
{
	local TMPawn tempPawn;
	local array<TMPawn> myPawns;

	myPawns = mKnowledge.GetMyPawns();

	foreach myPawns( tempPawn )
	{
		TMPlayerAIController( tempPawn.Controller ).SetupAIAbilityStrategy(ABILITY_CAST_FREQUENCY);
		TMPlayerAIController( tempPawn.Controller ).SetAttackingState( isIsOn );
	}
}

function string GetDebugBehaviorStatus()
{
	return "ATTACKING: " $ debugCurrentStatus;
}

DefaultProperties
{
	MOVE_TICK_RATE = 0.5f;
	ATTACK_TICK_RATE = 1.0f;
	RECALC_CLOSEST_ENEMY_RATE = 3f;

	NUMBER_ATTACK_MOVES_TO_TRY = 5;
}
