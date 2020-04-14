/* TMAbilityProjectile
	A projectile that starts an ability object when it lands.
 */

class TMAbilityProjectile extends TMTaylorProjectile; 	// TODO: unify projectiles

var TMIAbilityObject m_AbilityObject;
var TMTargetReticle m_TargetReticle;

var int m_DamageRadius;


static function TMAbilityProjectile Create( TMIAbilityObject inAbilityObject, TMPlayerController inTMPC, int inAllyId, Vector inSpawnLocation, Rotator inSpawnRotation, int inDamageRadius )
{
	local TMAbilityProjectile proj;
	proj = inTMPC.Spawn( class'TMAbilityProjectile',,, inSpawnLocation, inSpawnRotation );
	proj.mTMPC = inTMPC;
	proj.mAllyID = inAllyId;
	proj.m_AbilityObject = inAbilityObject;
	proj.m_DamageRadius = inDamageRadius;
	return proj;
}

// TODO: have just ONE fire function. Have projectiles handle specific firing logic

simulated function Fire( Vector inTargetLocation, float inProjectileSpeed, ParticleSystem inProjectileParticle, ParticleSystem inOnHitParticle,
	optional bool inFireStraight, optional float inAngle = 0.5f ) // <=== these last parameters are bullshit. Need multiple firing functions. This is a bandaid. Need consolidated projectiles
{
	mTMPC.m_AbilityProjectiles.AddItem( self );

	mTargetLocation = inTargetLocation;
	mProjectileParticle = inProjectileParticle;
	mOnHitParticle = inOnHitParticle;

	SetupTargetReticle();

	if( inFireStraight )
	{
		FireStraightProjectile( inTargetLocation, inProjectileSpeed );
	}
	else
	{
		FireLobbedProjectile( inTargetLocation, inProjectileSpeed, inAngle );
	}
}

simulated function SetupTargetReticle()
{
	local Rotator zeroRot;
	
	// Spawn our target reticle
	m_TargetReticle = class'TMTargetReticle'.static.Create(
		mTargetLocation,
		zeroRot,
		m_DamageRadius,
		mTMPC,
		m_AbilityObject.GetAllyID(),
		m_AbilityObject.GetTeamColorIndex() );
}

simulated function HitTarget()
{
	mTMPC.m_AbilityProjectiles.RemoveItem( self );
	m_AbilityObject.Start();

	super.HitTarget();
}

simulated event Destroyed()
{
	if( m_TargetReticle != none ) {
		m_TargetReticle.Cleanup();
		m_TargetReticle.Destroy();
	}

	super.Destroyed();
}
