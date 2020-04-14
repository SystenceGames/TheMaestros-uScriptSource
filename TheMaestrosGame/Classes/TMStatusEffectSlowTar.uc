class TMStatusEffectSlowTar extends TMStatusEffectSlow;

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectSlowTar newcomp;
	newcomp= new () class'TMStatusEffectSlowTar' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	newcomp.m_SlowValue = m_SlowValue;
	newcomp.m_OriginalSpeed = m_OriginalSpeed;
	return newcomp;
}

DefaultProperties
{
}
