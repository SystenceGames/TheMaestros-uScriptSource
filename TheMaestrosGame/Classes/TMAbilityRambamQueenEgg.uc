class TMAbilityRambamQueenEgg extends TMProjectileAbility;

var float   mPushbackPower;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);
	
	m_DamageRadius = json.GetFloatValue( "pushbackRadius" );
	mPushbackPower = json.GetFloatValue( "pushbackPower" );
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityRambamQueenEgg newcomp;
	newcomp= new () class'TMAbilityRambamQueenEgg'(self);
	newcomp.m_owner=newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function CastAbility()
{
	local TMRambamQueenEggAbilityObject obj;
	obj = class'TMRambamQueenEggAbilityObject'.static.Create( m_AbilityHelper, TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo), m_owner.m_TMPC, m_owner.m_allyId, m_owner.m_owningPlayerId, m_owner.GetTeamColorIndex(), m_TargetLocation, m_DamageRadius, mPushbackPower );
	
	FireAbilityProjectile( obj ); 	// <= these multiple parameters are bad. Need to have a union of the projectile systems in our game

	super.CastAbility();
}

DefaultProperties
{
	m_ProjectileParticle = ParticleSystem'TM_Cocoon.RBQ_SpecAttack_PS';
	m_OnProjectileHitParticle = ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion';

	m_AbilityIndicatorStyle = AIS_AOE;
}
