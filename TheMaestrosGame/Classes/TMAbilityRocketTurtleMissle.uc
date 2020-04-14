class TMAbilityRocketTurtleMissle extends TMAbility;

const MISSILE_HIT = "C_TurtleProjectileLanded";

var int     mDamage;
var float   mRadius;

var float           mProjectileSpeed;
var ParticleSystem  mProjectileParticle;
var ParticleSystem  mProjectileOnHitParticle;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mProjectileSpeed =  json.GetFloatValue( "projSpeed" );
	mRadius =           json.GetIntValue( "radius" );
	mDamage =           json.GetIntValue( "damage" );

	mProjectileParticle =       ParticleSystem'VFX_Turtle.Particles.P_Turtle_Egg';
	mProjectileOnHitParticle =  ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion';

	mSpawnAbilityProjectileTime = 0.325;    // When I tested the projectile time, it was around 0.3

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityRocketTurtleMissle newcomp;
	newcomp= new () class'TMAbilityRocketTurtleMissle'(self);
	newcomp.m_owner=newowner;
	newcomp.mProjectileParticle = mProjectileParticle;
	newcomp.mProjectileOnHitParticle = mProjectileOnHitParticle;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function ReceiveFastEvent( TMFastEvent fe )
{
	if ( fe.commandType == ANIMATION_SPAWN_ABILITY_PROJECTILE)
	{
		ShootMissile();
	}

	super.ReceiveFastEvent( fe );
}

function StartAbility()
{
	RotateToTarget();
	super.StartAbility();
}

function CastAbility()
{
	ShootMissile();
	super.CastAbility();
}

function ShootMissile()
{
	local Vector spawnLocation;
	local Rotator rot;	
	local TMProjectileTurtleRocket proj;
	m_owner.Mesh.GetSocketWorldLocationAndRotation('ProjectileSpawn',spawnLocation,rot,);
	proj = m_owner.Spawn( class'TMProjectileTurtleRocket',,,spawnLocation, m_owner.Rotation );
	proj.SetupTurtleProjectile( mProjectileParticle, mProjectileOnHitParticle, m_owner.m_TMPC, mDamage, mRadius, m_owner );
	proj.SetAbilityHelper( m_AbilityHelper );
	proj.FireTurtleRocket( m_TargetLocation );

	// TESTING DIFFERENT PROJECTILE FIRING SPEEDS
	/*
	if ( proj.FireLobbedProjectile( m_TargetLocation, VSize(m_owner.Location - m_TargetLocation ) * 100, 0.1f ) )
	{
		`log( "LOBBED AT FULL DISTANCE", true, 'Taylor' );
	}
	
	if ( proj.FireLobbedProjectile( m_TargetLocation, VSize( m_owner.Location - m_TargetLocation ) * 5, 0.1f ) )
	{
		`log( "LOBBED AT 0% DISTANCE", true, 'Taylor' );
	}
	else if ( proj.FireLobbedProjectile( m_TargetLocation, VSize(m_owner.Location - m_TargetLocation ) * 1.5, 0.1f ) )
	{
		`log( "LOBBED AT 150% DISTANCE", true, 'Taylor' );
	}
	else if ( proj.FireLobbedProjectile( m_TargetLocation, VSize(m_owner.Location - m_TargetLocation ) * 0.5, 0.1f ) )
	{
		`log( "LOBBED AT HALF DISTANCE", true, 'Taylor' );
	}
	else if ( proj.FireLobbedProjectile( m_TargetLocation, VSize(m_owner.Location - m_TargetLocation ), 0.1f ) )
	{
		`log( "LOBBED AT FULL DISTANCE", true, 'Taylor' );
	}
	else
	{
		`log( "NO LOB VALUES WORKED", true, 'Taylor' );
		proj.Destroy();
	}
	*/
	
	super.CastAbility();
}

DefaultProperties
{
	m_AbilityIndicatorStyle = AIS_AOE;
}
