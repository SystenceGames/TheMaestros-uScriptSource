class TMStatusEffectRegeneratorHeal extends TMStatusEffect;

var int mHealAmount;
var float m_fIntervalDuration;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);

	m_fDuration = json.GetFloatValue("duration");
	mHealAmount = json.GetIntValue("healPerTick");
	m_fIntervalDuration = 1 / json.GetFloatValue("ticksPerSecond");
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectRegeneratorHeal newcomp;
	newcomp= new () class'TMStatusEffectRegeneratorHeal' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	newcomp.mHealAmount = mHealAmount;
	newcomp.m_fIntervalDuration = m_fIntervalDuration;
	return newcomp;
}

function Begin()
{
	TickHeal();
	m_owner.SetTimer(m_fIntervalDuration, true, 'TickHeal', self);

	super.Begin();
}

// Basic stacking, just reset the timer back to max
function StackStatusEffect(TMStatusEffectFE seFE)
{
	mHealAmount += mHealAmount;
}

function TickHeal()
{
	m_owner.HealDamage( mHealAmount, TMPlayerController( m_owner.OwnerReplicationInfo.Owner ), class'DamageType' );
}

function End()
{
	m_owner.ClearTimer('TickHeal', self);
	super.End();
}

DefaultProperties
{
}

