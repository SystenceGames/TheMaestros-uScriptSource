class TMAbilityShotgunBlast extends TMAbility;

var float   mPushbackPower;
var float   mBlastAngle;    // the angle for the spread, in radians
var int     mDamage;

var Vector  mBlastOrigin;
var Vector  mBlastTarget;
var Vector  mBlastTargetLeft;
var Vector  mBlastTargetRight;

// The left and right angle of the blast in radians
var float   mLeftAngle;
var float   mRightAngle;

var ParticleSystem SHOTGUN_PARTICLESYSTEM;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mPushbackPower =    json.GetFloatValue( "pushbackPower" );
	mDamage =           json.GetIntValue( "damage" );

	mBlastAngle = 45 * DegToRad;

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityShotgunBlast newcomp;
	newcomp= new () class'TMAbilityShotgunBlast'(self);
	newcomp.m_owner=newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function StartAbility()
{
	RotateToTarget();
	super.StartAbility();
}

function CastAbility()
{
	InitBlastVariables();

	// Spawn particle effects	
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithRotationAndScale(SHOTGUN_PARTICLESYSTEM, m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner.Location, m_owner.Rotation, 10.0f);

	//ShowDebug(); Taylor TODO: have this be part of a testing system instead
	PushbackPawns();

	super.CastAbility();
}

function Cleanup()
{
	m_owner.ClearAllTimers( self );
	m_owner.bBlockActors = true;
	super.Cleanup();
}

function InitBlastVariables()
{
	local Vector toBlastTarget;
	local float blastAngleCoord;

	mBlastOrigin = m_owner.Location;
	toBlastTarget = m_TargetLocation - mBlastOrigin;
	blastAngleCoord = Atan2( toBlastTarget.Y, toBlastTarget.X );

	mBlastTarget = Normal( m_TargetLocation - mBlastOrigin ) * m_iRange + mBlastOrigin;
	mLeftAngle = blastAngleCoord + mBlastAngle / 2;
	mRightAngle = mLeftAngle - mBlastAngle;
	mBlastTargetLeft = GetPositionOnBlastRadius( mLeftAngle );
	mBlastTargetRight = GetPositionOnBlastRadius( mRightAngle );
}

// Takes in an angle in radians
function Vector GetPositionOnBlastRadius( float inAngle )
{
	local Vector position;
	position.X = Cos( inAngle );
	position.Y = Sin( inAngle );
	
	position = Normal( position ) * m_iRange + mBlastOrigin;

	return position;
}

function PushbackPawns()
{
	local TMPawn tempPawn;
	local array<TMPawn> pawnList;
	local float angle;
	local Vector velocity;
	pawnList = m_owner.m_TMPC.GetTMPawnList();

	// Check if hit a pawn
	foreach pawnList( tempPawn )
	{
		if( tempPawn != none &&
			!tempPawn.IsGameObjective() &&
			TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId )
		{
			if( IsInRange( m_owner.Location, tempPawn.Location, m_iRange ) )
			{
				// Get the target's angle on our blast circle
				angle = Atan2( tempPawn.Location.Y - m_owner.Location.Y, tempPawn.Location.X - m_owner.Location.X );

				if( angle < mLeftAngle &&
					angle > mRightAngle )
				{
					// Push back the pawn
					m_AbilityHelper.KnockbackTarget( tempPawn, m_owner.Location, mPushbackPower, SE_GRAPPLER_KNOCKBACK );
					m_AbilityHelper.DoDamageToTarget( mDamage, tempPawn );
				}
			}
		}
	}

	// Push myself backwards
	m_owner.bBlockActors = false;
	velocity = Normal( m_owner.location - m_TargetLocation ) * mPushbackPower;
	m_owner.GetForcePushed( velocity );
	m_owner.SetTimer( 0.25, false, 'TurnOnCollision', self );
}

function TurnOnCollision()
{
	m_owner.bBlockActors = true;
}

// TEMP SHOWDEBUG for JPatt to check particles
function ShowDebug()
{
	m_owner.SetTimer( mDebugTickFrequency, true, 'ShowDebugTick', self );
	m_owner.SetTimer( mDebugDuration, false, 'HideDebug', self );
}

function ShowDebugTick()
{
	// Draw the range of the shotgun blast
	m_owner.GetActor().DrawDebugCylinder( mBlastOrigin, mBlastOrigin, m_iRange, 32, 255, 255, 0 );

	// Draw a center line, plus the left and right bounding lines
	m_owner.GetActor().DrawDebugLine( mBlastOrigin, mBlastTargetLeft, 255, 255, 0 );
	m_owner.GetActor().DrawDebugLine( mBlastOrigin, mBlastTargetRight, 255, 255, 0 );
}

DefaultProperties
{
	m_AbilityIndicatorStyle = AIS_DASH;    // TODO: Create new ability indicator
	
	// Don't try to run to the cast location
	mIsRangeless = true;

	mDebugDuration = 3;

	SHOTGUN_PARTICLESYSTEM = ParticleSystem'VFX_Rosie.BlastmeisterVFX_Ability';
}
