class TMStatusEffectInstantDamage extends TMStatusEffect;

var float Damage;

function Begin()
{
	m_owner.TakeDamage(Damage, TMPlayerController(m_owner.OwnerReplicationInfo.Owner), m_owner.Location, m_owner.Location, class'DamageType');
	super.Begin();
}

DefaultProperties
{
	Damage=25;
}
