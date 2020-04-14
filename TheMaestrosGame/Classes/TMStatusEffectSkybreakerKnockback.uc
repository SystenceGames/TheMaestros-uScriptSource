class TMStatusEffectSkybreakerKnockback extends TMStatusEffectKnockback;

function TMComponent makeCopy(TMPawn newowner)
{
	local TMStatusEffectSkybreakerKnockback newcomp;
	newcomp= new () class'TMStatusEffectSkybreakerKnockback' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}
