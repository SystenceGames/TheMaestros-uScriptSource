class TMNeutralAIController extends TMAIController;

const TARGET_UPDATE_INTERVAL = 0.25f;

var vector mHome;
var float mChaseRadiusSq;
var float mSearchRadiusSq;
var TMNeutralCamp mNeutralCamp;
var TMPawn mCurrentTarget;
var TMPawn mPreviousTarget;
var bool mActive;
var bool mMovingBackHome;
var bool mShouldSpawnBaseUnits;

event PostBeginPlay()
{
	super.PostBeginPlay();
	m_timeSinceLastAttack = 0;
	SetTimer(TARGET_UPDATE_INTERVAL + 0.05f * ((Rand( 100 ) - 50) / 50.f), true, 'SetClosestTarget');

}
function NotifyTakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	m_timeSinceLastAttack = 0;
	/*
	if (TMPawn(DamageCauser) != None)
	{
		PropagateRetaliation(TMPawn(DamageCauser));
	}
	*/
	//super.NotifyTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	//Retaliate();
	mActive = true;
	mMovingBackHome = false;

	PropagateRetaliation();
}

function Retaliate()
{
	local TMAttackFE lAttackFE;
	local TMPawn lControllerPawn;

	lControllerPawn = TMPawn(Pawn);

	// If this controller has a pawn AND the neutral's target has changed AND this pawn is alive AND this pawn is not stunned, then we send a command
	if(lControllerPawn != none && mCurrentTarget != mPreviousTarget && lControllerPawn.Health > 0 && !lControllerPawn.bStunned)
	{
		mPreviousTarget = mCurrentTarget;
		if(lControllerPawn.Role == ROLE_Authority)
		{
			lAttackFE = class'TMAttackFE'.static.create(mCurrentTarget, lControllerPawn.pawnId);
			lControllerPawn.SendFastEvent(lAttackFE);
		}
	}
}


function SetClosestTarget()
{
	mCurrentTarget = FindClosestTargetWithinRadius();
}

function TMPawn FindClosestTargetWithinRadius()
{
	local float lMinDistanceSq;
	local float lDistanceSq;
	local float lDistanceFromHomeSq;
	local TMPawn lIterator;
	local TMPawn lResult;
	local TMPawn lMyPawn;
	local float searchRadius;

	searchRadius = Sqrt(mSearchRadiusSq);
	
	lResult = none;
	lMyPawn = TMPawn(Pawn);
	
	lMinDistanceSq = 999999999;

	//foreach AllActors(class'TMPawn', lIterator)
	foreach CollidingActors(class'TMPawn', lIterator, searchRadius)
	{
		if ((lIterator.m_allyId != lMyPawn.m_allyId) && lIterator.Health > 0)
		{
			lDistanceFromHomeSq = VSizeSq(lIterator.Location - mHome);
			// Filter out all units out of the search radius
			if(lDistanceFromHomeSq <= mSearchRadiusSq)
			{   
				lDistanceSq = VSizeSq(lMyPawn.Location - lIterator.Location);

				if(lDistanceSq < lMinDistanceSq)
				{
					lResult = lIterator;
					lMinDistanceSq = lDistanceSq;
				}
			}
		}
	}

	return lResult;
}

function PropagateRetaliation()
{
	local TMNeutralSpawnPoint lSpawnPoint;
	local TMNeutralAIController lPawnController;

	foreach mNeutralCamp.mSpots(lSpawnPoint)
	{
		if(lSpawnPoint.mPawnHolden != none && lSpawnPoint.mPawnHolden != TMPawn(Pawn))
		{
			
			lPawnController = TMNeutralAIController(lSpawnPoint.mPawnHolden.Controller);
			if( lPawnController != none )
			{
				lPawnController.mActive = true;
				lPawnController.mMovingBackHome = false;
			}
		}
	}

	/*
	local TMNeutralSpawnPoint lSpawnPoint;
	local TMPawn lPawnOfController;
	local TMAttackFE lAttackFE;
	local TMNeutralAIController lPawnController;

	foreach mNeutralCamp.mSpots(lSpawnPoint)
	{
		if(lSpawnPoint.mPawnHolden != none && lSpawnPoint.mPawnHolden != TMPawn(Pawn))
		{
			lPawnOfController = lSpawnPoint.mPawnHolden;
			lPawnController = TMNeutralAIController(lSpawnPoint.mPawnHolden.Controller);
			
			if(lPawnController.mAIState != TAS_ATTACKING)
			{
				lPawnController.mTarget = target;
				lAttackFE = class'TMAttackFE'.static.create(target, lPawnOfController.pawnId);
				lPawnOfController.SendFastEvent(lAttackFE);
				lPawnController.mAIState = TAS_ATTACKING;
			}
		}
	}
	*/
}

function Tick(float dt)
{
	local TMPawn lTMPawnOfController;
	local vector lPawnFeetLocation;
	local TMMoveFE lMoveFE;
	local TMStopFE lStopFE;



	if( m_timeSinceLastAttack <= 100)
	{
		m_timeSinceLastAttack += dt;
	}

	lTMPawnOfController = TMPawn(Pawn);


	// This is a big performance hit. So replaced with SetClosestTarget periodic call
	//mCurrentTarget = FindClosestTargetWithinRadius();

	if(mCurrentTarget == none && mActive && lTMPawnOfController.NotInteruptingCommand())
	{
		mActive = false;
		mPreviousTarget = none;
		if(!mMovingBackHome)
		{
			lPawnFeetLocation = lTMPawnOfController.Mesh.Bounds.Origin;
			lPawnFeetLocation.Z -= lTMPawnOfController.Mesh.Bounds.BoxExtent.Z;
			if(VSizeSq(lPawnFeetLocation - mHome) >= 36)   // Error tolerence is 6
			{
				mMovingBackHome = true;
				lMoveFE = class'TMMoveFE'.static.create(mHome, false, lTMPawnOfController.pawnId);
				lStopFE = class'TMStopFE'.static.create(lTMPawnOfController.pawnId);
				lTMPawnOfController.SendFastEvent(lStopFE);
				lTMPawnOfController.SendFastEvent(lMoveFE);
			}
		}
	}

	if(mActive)
	{
		Retaliate();
	}

	super.Tick(dt);

	/*
	lTMPawnOfController = TMPawn(Pawn);

	if(!lTMPawnOfController.bStunned)
	{
		testVector = mHome;
		testVector.Z = lTMPawnOfController.Location.Z;
		test = VSizeSq(lTMPawnOfController.Location - testVector);

		if(mTarget != none)  // if someone attacked me
		{
			if(test > mChaseRadiusSq || mTarget.Health <= 0)   // if I have chased too far or the attacker is dead, I go home
			{
				GoBackHomeAndForgetWhoAttackedMe(lTMPawnOfController);
			}
		}
	}
	*/
}


function GoBackHomeAndForgetWhoAttackedMe(TMPawn inPawnOfController)
{
	/*
	local TMStopFE lStopFE;
	local TMMoveFE lMoveFE;
	local vector testVector;
	
	
	if(mAIState != TAS_RETURNING)   // and if I am not already returning
	{
		// I go back to my spot and forget who attacked me
		lStopFE = class'TMStopFE'.static.create(inPawnOfController.pawnId);
		testVector = mHome;
		testVector.Z = inPawnOfController.Location.Z;
		lMoveFE = class'TMMoveFE'.static.create(testVector, false, inPawnOfController.pawnId);
		inPawnOfController.SendFastEvent(lStopFE);
		inPawnOfController.SendFastEvent(lMoveFE);
		mTarget = none;
		mAIState = TAS_RETURNING;
	}
	*/
}

DefaultProperties
{
	mChaseRadiusSq = 360000;
	mCurrentTarget = none;
	mPreviousTarget = none;
	mActive = false;
	mMovingBackHome = false;
	mShouldSpawnBaseUnits = true;
}
