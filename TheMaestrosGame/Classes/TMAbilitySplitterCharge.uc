class TMAbilitySplitterCharge extends TMAbility;

var int mRadius;
var int mDamage;
var int mCollisionRadius;
var float mMaxChargeTime;

var ParticleSystem mKnockupParticleSystem;


function SetUpComponent( JsonObject json, TMPawn parent )
{
	mRadius = json.GetIntValue( "aoeRadius" );
	mDamage = json.GetIntValue( "damage" );
	mCollisionRadius = json.GetIntValue( "collisionRadius" );
	mMaxChargeTime = 0.5;

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy( TMPawn newowner )
{
	local TMAbilitySplitterCharge newcomp;
	newcomp= new () class'TMAbilitySplitterCharge'( self );
	newcomp.m_owner=newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function Cleanup()
{
	m_owner.ClearAllTimers( self );
	BeginCooldown();
	super.Cleanup();
}

function StartAbility()
{
	RotateToTarget();
	super.StartAbility();
}

function CastAbility()
{
	// Make sure the ability is cast within our range
	if( VSizeSq2D( m_TargetLocation - m_owner.Location ) > m_iRange*m_iRange )
	{
		m_TargetLocation = Normal( m_TargetLocation - m_owner.Location ) * m_iRange + m_owner.Location;
	}

	m_AbilityState = AS_CASTING;

	m_owner.SetCollision( false );
	m_owner.GroundSpeed = 5*m_owner.m_Unit.m_fMoveSpeed;

	if(m_owner.IsAuthority())
	{
		SendMoveToLocation( m_TargetLocation);
	}
	m_owner.SetTimer( mMaxChargeTime, false, 'Deactivate', self );
}

function SendMoveToLocation(Vector target)
{
	local TMFastEvent fe;
	fe = class'TMMoveFE'.static.create(target,false,m_owner.pawnId,,,,false,false,true).toFastEvent();
	fe.position2 = target;
	m_owner.ReceiveFastEvent( fe );
}

function Deactivate()
{
	m_owner.SetCollision( true );
	m_owner.ClearTimer( 'Deactivate', self );
	
	super.CastAbility();
	m_owner.GroundSpeed = m_owner.m_Unit.m_fMoveSpeed;
}

function UpdateComponent(float dt)
{
	if ( m_AbilityState == AS_CASTING )
	{
		// FORCE THE MOVE SPEED TO STAY FAST
		m_owner.GroundSpeed = 5*m_owner.m_Unit.m_fMoveSpeed;

		CheckCharge();
	}

	super.UpdateComponent(dt);
}

function CheckCharge()
{
	local TMPawn tempPawn;
	local array<TMPawn> pawns;

	// Check if in range of target location
	if( IsInRange( m_owner.Location, m_TargetLocation, mCollisionRadius ) )
	{
		DoKnockup();
		return;
	}

	// Check if hit a pawn
	pawns = m_owner.m_TMPC.GetTMPawnList();
	foreach pawns( tempPawn )
	{
		if( tempPawn != none &&
			!tempPawn.IsGameObjective() &&
			TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId &&
			tempPawn.Health > 0 )
		{
			if ( IsInRange( m_owner.Location, tempPawn.Location, mCollisionRadius ) )
			{
				DoKnockup();
				return;
			}
		}
	}
}

function DoKnockup()
{
	// Do VFX
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale(mKnockupParticleSystem, m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner.Location, 5.0f, 2.0f);
	
	HitTargets();
	Deactivate();
}

function HitTargets()
{
	local TMPawn tempPawn;
	local array<TMPawn> pawns;
	local vector zeroVector;
	local vector impulse;

	// Get the impulse we'll apply to the target
	impulse.X = 0;
	impulse.Y = 0;
	impulse.Z = 1;
	impulse *= 500;

	pawns = m_owner.m_TMPC.GetTMPawnList();

	foreach pawns( tempPawn )
	{
		if( tempPawn != none &&
			tempPawn.bCanBeKnockedUp &&
			!tempPawn.IsGameObjective() &&
			TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId &&
			tempPawn.Health > 0 )
		{
			if ( IsInRange( m_owner.Location, tempPawn.Location, mRadius ) &&
				!tempPawn.m_Unit.IsStatusEffectActive( SE_SPLITTER_KNOCKUP ) )
			{
				// Add the knockback status effect to the pawn
				tempPawn.m_Unit.SendStatusEffect( SE_SPLITTER_KNOCKUP );
				tempPawn.Velocity = zeroVector;
				if(tempPawn.m_Unit.m_UnitName != "VineCrawler_Wall")
				{
					tempPawn.AddVelocity(impulse, tempPawn.Location, class'DamageType');
				}

				m_AbilityHelper.DoDamageToTarget( mDamage, tempPawn );
			}
		}
	}
}

DefaultProperties
{
	mIsRangeless = true;
	m_AbilityIndicatorStyle = AIS_DASH;

	mKnockupParticleSystem = ParticleSystem'VFX_Rosie.Particles.vfx_Gun_GroundImpact';
}
