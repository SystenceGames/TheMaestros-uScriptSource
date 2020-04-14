class TMStatusEffectCreepKillHeal extends TMStatusEffect;

var float mHealPercentage;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);

	mHealPercentage = json.GetFloatValue("healAsPercentageOfMax");
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectCreepKillHeal newcomp;
	newcomp= new () class'TMStatusEffectCreepKillHeal' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function Begin()
{
	HealUnit();

	super.Begin();
}

// Basic stacking, just reset the timer back to max
function StackStatusEffect(TMStatusEffectFE seFE)
{
	m_owner.ClearTimer('End', self);
	Begin();
}

function HealUnit()
{
	local float healAmount;

	healAmount = m_owner.m_Unit.m_Data.health * mHealPercentage;
	m_owner.HealDamage( healAmount, TMPlayerController( m_owner.OwnerReplicationInfo.Owner ), class'DamageType' );
}
