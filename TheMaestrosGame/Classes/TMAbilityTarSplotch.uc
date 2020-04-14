/* TMAbilityTarSplotch
	The tarsplotch ability fires a tarsplotch that slows nearby enemies.
	If you cast the ability on a location that already has a tarsplotch
	it will be set on fire.

	NOTE: to make the fire work, we actually launch an entirely new tar
	splotch. When the new tarsplotch hits the ground it will just sit
	over the top of the old one. We have to do this for VFX consistency
	since the tarsplotch animation has an animated fade effect. Luckily
	having 2 tarsplotched sitting in the same spot has no extra benefit.
	The same amount of slow will be applied.
*/
class TMAbilityTarSplotch extends TMProjectileAbility;

var float 	m_Duration;
var int 	m_FireDamage;
var float 	m_CheckFrequency;

var ParticleSystem m_OilProjectileParticle;
var ParticleSystem m_OnOilProjectileHitParticle;
var ParticleSystem m_FireProjectileParticle;
var ParticleSystem m_OnFireProjectileHitParticle;


function SetUpComponent( JsonObject inJSON, TMPawn inParent )
{
	super.SetUpComponent( inJSON, inParent );
	
	m_Duration 			= inJSON.GetFloatValue( "tarDuration" );
	m_DamageRadius 		= inJSON.GetIntValue( "tarRadius" );
	m_FireDamage 		= inJSON.GetIntValue( "damage" );
	m_CheckFrequency 	= inJSON.GetFloatValue( "checkTarInterval" );
}

function CastAbility()
{
	local bool isOnFire;
	local TMTarSplotch tarSplotch;

	// See if there is a tarsplotch that can ignite and is in range
	isOnFire = false;
	foreach m_owner.m_TMPC.m_TarSplotches( tarSplotch )
	{
		if( tarSplotch.CanIgnite() &&
			m_owner.IsInRange2D( m_TargetLocation, tarSplotch.m_Location, m_DamageRadius ) )
		{
			m_TargetLocation = tarSplotch.m_Location; 	// my cast location will now be this tarsplotch
			tarSplotch.Ignite();	// so that we can't ignite it again
			isOnFire = true;
			break;
		}
	}

	LaunchTarSplotch( isOnFire );
	
	super.CastAbility();
}

function LaunchTarSplotch( bool inIsOnFire )
{
	local TMTarSplotch tarSplotch;

	// Create the ability object
	tarSplotch = class'TMTarSplotch'.static.Create( m_AbilityHelper, m_owner.m_TMPC, m_owner.m_allyId, m_owner.m_owningPlayerId, m_owner.GetTeamColorIndex(), m_TargetLocation, m_Duration, m_DamageRadius, m_CheckFrequency, m_FireDamage, inIsOnFire );
	m_owner.m_TMPC.m_TarSplotches.AddItem( tarSplotch );

	// Assign the proper projectile particles
	if( !inIsOnFire )
	{
		// Normal tar particles
		m_ProjectileParticle = m_OilProjectileParticle;
		m_OnProjectileHitParticle = m_OnOilProjectileHitParticle;
	}
	else
	{
		// Flame particles
		m_ProjectileParticle = m_FireProjectileParticle;
		m_OnProjectileHitParticle = m_OnFireProjectileHitParticle;
	}

	// Fire the projectile
	FireAbilityProjectile( tarSplotch );
}

function TMComponent makeCopy( TMPawn newowner )
{
	local TMAbilityTarSplotch newcomp;
	newcomp = new () class'TMAbilityTarSplotch'(self);
	newcomp.m_owner = newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

DefaultProperties
{
	m_AbilityIndicatorStyle = AIS_TAR;

	// Assign custom particles for TarSplotch, since there are two types of projectiles we can fire
	m_OilProjectileParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Muzzle_Special_Projectile';
	m_OnOilProjectileHitParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Default_Hit';
	m_FireProjectileParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Projectile_FlameGoo';
	m_OnFireProjectileHitParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Default_Hit_fire';
}
