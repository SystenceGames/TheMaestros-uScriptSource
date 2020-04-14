class TMComponentDecay extends TMComponent;

var float m_timeDecay;
var float m_currentTime;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_timeDecay = json.GetFloatValue("time");
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentDecay cd;
	cd = new () class'TMComponentDecay';
	cd.m_owner = newowner;
	cd.m_timeDecay = m_timeDecay;
	cd.m_currentTime = m_timeDecay;
	cd.m_owner.b_hasDecay = true;
	return cd;
}

function UpdateComponent(float dt)
{
	m_currentTime -= dt;
	if(m_currentTime <=0 && m_owner.Health > 0)
	{
		m_owner.TakeDamage(99999, m_owner.Controller, m_owner.Location, m_owner.Location, class'DamageType',,m_owner);
	}
}


DefaultProperties
{
}
