class TMStatusEffectInvulnerable extends TMStatusEffect;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectInvulnerable newcomp;
	newcomp= new () class'TMStatusEffectInvulnerable' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	return newcomp;
}

function Begin()
{
	m_owner.bCanBeDamaged = false;
	super.Begin();
}


function End()
{
	 m_owner.bCanBeDamaged = true;
	 super.End();
}

