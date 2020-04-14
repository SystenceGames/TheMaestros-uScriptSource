/* TMAbilityPopSpring
	Places a PopSpring at a location.
*/
class TMAbilityPopSpring extends TMProjectileAbility;


function SetUpComponent( JsonObject inJSON, TMPawn inParent )
{
	super.SetUpComponent( inJSON, inParent );
}

function CastAbility()
{
	local TMPopSpring object;
	object = class'TMPopSpring'.static.Create( m_AbilityHelper, m_owner.m_TMPC, m_owner.m_allyId, m_owner.m_owningPlayerId, m_owner.GetTeamColorIndex(), m_TargetLocation, m_owner.rotation, m_DamageRadius );
	
	FireAbilityProjectile( object, true );

	super.CastAbility();
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityPopSpring newcomp;
	newcomp= new () class'TMAbilityPopSpring'(self);
	newcomp.m_owner=newowner;
	return newcomp;
}

DefaultProperties
{
	m_ProjectileParticle = ParticleSystem'VFX_Popspring.PopSpring_Telegraph_VFX';
}
