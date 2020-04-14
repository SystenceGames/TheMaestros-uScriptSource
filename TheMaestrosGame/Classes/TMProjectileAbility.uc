/* TMProjectileAbility
	A TMAbility that fires a projectile.

	This class handles firing the projectile and holds necessary projectile data.
	TMProjectileAbilities need to assign the projectilespeed and particles.

	REQUIREMENTS:
	The unit's animset must have a socket called "AbilityProjectileSpawn_Socket". We will
	fire the projectile from this location/orientation.
*/
class TMProjectileAbility extends TMAbility;

var int m_DamageRadius;

var float m_ProjectileSpeed;

var ParticleSystem m_ProjectileParticle;
var ParticleSystem m_OnProjectileHitParticle;


function SetUpComponent( JsonObject inJSON, TMPawn inParent )
{
	m_DamageRadius = inJSON.GetIntValue( "radius" );
	m_ProjectileSpeed = inJSON.GetFloatValue( "projectileSpeed" );
	super.SetUpComponent( inJSON, inParent );
}

function FireAbilityProjectile( TMIAbilityObject inAbilityObject,
	optional bool inFireStraight, optional float inAngle = 0.5f ) // <=== these last parameters are bullshit. Need multiple firing functions. This is a bandaid. Need consolidated projectiles
{
	local TMAbilityProjectile proj;
	local Vector spawnLocation;
	local Rotator rot;

	// TODO: unify socket ability spawning stuff. Need to learn how to do that
	m_owner.Mesh.GetSocketWorldLocationAndRotation('AbilityProjectileSpawn_Socket',spawnLocation,rot,);	// get location and rotation
	proj = class'TMAbilityProjectile'.static.Create( inAbilityObject, m_owner.m_TMPC, m_owner.GetAllyId(), spawnLocation, rot, m_DamageRadius );
	proj.Fire( m_TargetLocation, m_ProjectileSpeed, m_ProjectileParticle, m_OnProjectileHitParticle, inFireStraight, inAngle );
}

function StopAbility()
{
	super.StopAbility();

	m_owner.bBlockActors = true;
}

function StartAbility()
{
	RotateToTarget();
	m_owner.bBlockActors = false; 	// don't block actors so that other projectile units can come in and fire
									// this is probably bad. Will revisit this
	super.StartAbility();
}

function EndAbility()
{
	m_owner.bBlockActors = true;	// same issue as earlier. Is it ok that we're turning this off? Probably not

	super.EndAbility();
}

DefaultProperties
{
	m_ProjectileSpeed = 2000; 	// can edit speed from JSON
}
