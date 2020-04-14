class TMStatusEffectCommanderKnockback extends TMStatusEffectKnockback;

function TMComponent makeCopy(TMPawn newowner)
{
	local TMStatusEffectCommanderKnockback newcomp;
	newcomp= new () class'TMStatusEffectCommanderKnockback' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}
