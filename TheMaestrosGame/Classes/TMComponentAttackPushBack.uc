class TMComponentAttackPushBack extends TMComponentAttack;

var int m_iKnockbackPower;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json,parent);
	m_iKnockbackPower = json.GetIntValue("knockback");
}


function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentAttackPushBack newcomp;
	newcomp= new () class'TMComponentAttackPushBack' (self);
	newcomp.m_owner=newowner;
	newcomp.m_iDamage = m_iDamage;
	newcomp.m_iRange = m_iRange;
	newcomp.m_iDamage = m_iDamage;
	newcomp.m_rateOfFire = m_rateOfFire;
	newcomp.m_iKnockbackPower = m_iKnockbackPower;
	return newcomp;
}


simulated function DoPassiveAbility()
{
	local vector impulse;

	if( m_Target.m_UnitType == "Nexus" || m_Target.m_UnitType == "Brute" ) { return; }

	if((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone))
	{
		impulse = Normal(m_Target.Location - m_owner.Location);
		impulse *= m_iKnockbackPower;
		impulse.Z = 0;
		m_Target.AddVelocity(impulse, m_Target.Location, class'DamageType');
		//TMPawn(m_Target).m_Unit.SendStatusEffect(SE_STUNNED);
	}
}


DefaultProperties
{
}
