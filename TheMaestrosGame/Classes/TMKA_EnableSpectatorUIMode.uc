class TMKA_EnableSpectatorUIMode extends SequenceAction;

var bool bShouldHaveSpectatorUI;

event Activated()
{
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.TM_HUD.spectatorMode( bShouldHaveSpectatorUI );

	OutputLinks[0].bHasImpulse = TRUE;
}

defaultproperties
{
	ObjName="EnableSpectatorUI"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Should Be Spectator UI Mode", PropertyName=bShouldHaveSpectatorUI)
}
