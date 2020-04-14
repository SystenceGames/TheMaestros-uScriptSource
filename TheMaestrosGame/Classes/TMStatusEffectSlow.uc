class TMStatusEffectSlow extends TMStatusEffect;

var float m_SlowValue;
var float m_OriginalSpeed;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_SlowValue = float(json.GetIntValue("percent"))/100.0f;

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectSlow newcomp;
	newcomp= new () class'TMStatusEffectSlow' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	newcomp.m_SlowValue = m_SlowValue;
	newcomp.m_OriginalSpeed = m_OriginalSpeed;
	return newcomp;
}

function Begin()
{
	if( !m_owner.bCanBeDamaged )
	{
		return;
	}

	m_OriginalSpeed = m_owner.m_Unit.m_fMoveSpeed;
	m_owner.GroundSpeed *= m_SlowValue;

	super.Begin();
}



function End()
{
	m_owner.GroundSpeed = m_OriginalSpeed;

	super.End();
}

DefaultProperties
{
}
