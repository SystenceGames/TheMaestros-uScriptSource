class TMStatusEffectSpeed extends TMStatusEffect;

var float m_BuffValue;
var float m_OriginalSpeed;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_BuffValue = 1.0f+float(json.GetIntValue("percent"))/100.0f;

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectSpeed newcomp;
	newcomp= new () class'TMStatusEffectSpeed' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function Begin()
{
	m_OriginalSpeed = m_owner.m_Unit.m_fMoveSpeed;
	m_owner.GroundSpeed *= m_BuffValue;
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
