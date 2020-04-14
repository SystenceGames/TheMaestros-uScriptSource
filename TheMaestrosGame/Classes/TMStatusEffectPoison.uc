class TMStatusEffectPoison extends TMStatusEffect;

var int m_iDamage;
var float m_fIntervalDuration;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);

	m_fDuration = json.GetFloatValue("duration");
	m_iDamage = json.GetIntValue("damage");
	m_fIntervalDuration = 1 / json.GetFloatValue("ticksPerSecond");
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectPoison newcomp;
	newcomp= new () class'TMStatusEffectPoison' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	newcomp.m_iDamage = m_iDamage;
	newcomp.m_fIntervalDuration = m_fIntervalDuration;
	return newcomp;
}

function Begin()
{
	TickDamage();
	m_owner.SetTimer(m_fIntervalDuration, true, 'TickDamage', self);

	super.Begin();
}


function TickDamage()
{
	m_owner.TakeDamage(m_iDamage, TMPlayerController(m_owner.OwnerReplicationInfo.Owner), m_owner.Location, m_owner.Location, class'DamageType');	
}

function End()
{
	m_owner.ClearTimer('TickDamage', self);
	super.End();
}

DefaultProperties
{
}
