class TMStatusEffectSplitterKnockback extends TMStatusEffectKnockback;

function TMComponent makeCopy(TMPawn newowner)
{
	local TMStatusEffectSplitterKnockback newcomp;
	newcomp= new () class'TMStatusEffectSplitterKnockback' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}
