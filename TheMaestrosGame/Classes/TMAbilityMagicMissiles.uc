class TMAbilityMagicMissiles extends TMAbility;


var float           mProjectileSpeed;
var ParticleSystem  mProjectileParticle;
var ParticleSystem  mProjectileOnHitParticle;

var int mDamage;
var int mRadius;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mProjectileSpeed =  json.GetFloatValue( "projSpeed" );
	mProjectileParticle =       ParticleSystem'VFX_Turtle.Particles.P_Turtle_Egg';
	mProjectileOnHitParticle =  ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion';

	mDamage = json.GetFloatValue( "damage" );
	mRadius = json.GetFloatValue( "radius" );

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityMagicMissiles newcomp;
	newcomp= new () class'TMAbilityMagicMissiles'(self);
	newcomp.m_owner=newowner;
	newcomp.mProjectileParticle = mProjectileParticle;
	newcomp.mProjectileOnHitParticle = mProjectileOnHitParticle;
	return newcomp;
}

function Cleanup()
{
	super.Cleanup();
	m_owner.ClearAllTimers( self );
}

function StopAbility()
{
	if( m_AbilityState == AS_PLAYING_ANIMATION || m_AbilityState == AS_CASTING )
	{
		m_AbilityState = AS_IDLE;
		m_owner.UpdateUnitState( TMPS_IDLE );
		m_owner.m_bIsAbilityReady = true;
		//m_owner.bBlockActors = true;
		return;
	}

	super.StopAbility();
}

function ReceiveFastEvent( TMFastEvent fe )
{
	if ( fe.commandType == ANIMATION_SPAWN_ABILITY_PROJECTILE )
	{
		ShootMissiles();
	}

	super.ReceiveFastEvent( fe );
}

function CastAbility()
{
	m_owner.UpdateUnitState( TMPS_JUGGERNAUT );
	m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, "C_StopAttack" ) );

	RotateToTarget();

	m_AbilityState = AS_CASTING;

	TODOIntegrate_DoAbilityAnimation();

	super.CastAbility();
}

function ShootMissiles()
{
	local Vector spawnLocation;
	local Rotator rot;	
	local TMProjectileMagicMissiles proj;
	m_owner.Mesh.GetSocketWorldLocationAndRotation( 'ProjectileSpawn',spawnLocation,rot );
	proj = m_owner.Spawn( class'TMProjectileMagicMissiles',,,spawnLocation, m_owner.Rotation );
	proj.SetupMagicMissiles( m_owner, mProjectileParticle, mProjectileOnHitParticle, mRadius, mDamage );
	proj.FireMissiles( m_TargetLocation );

	BeginCooldown();
	m_owner.UpdateUnitState( TMPS_IDLE );
}

DefaultProperties
{
	m_AbilityIndicatorStyle = AIS_AOE;
}
