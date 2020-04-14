class TMFOWManagerSpectator extends TMFoWManagerCommon implements(TMFOWManager);

function bool IsLocationVisible(Vector loc)
{
	return true;
}

function bool IsPawnHidden(TMPawn pawn)
{
	return false;
}
