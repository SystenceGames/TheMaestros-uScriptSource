class TMKA_DisableHUD extends SequenceAction;

var bool bShouldDisable;

event Activated()
{
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.TM_HUD.disableAll( bShouldDisable );

	OutputLinks[0].bHasImpulse = TRUE;
}

defaultproperties
{
	ObjName="DisableAllHUD"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Should Disable", PropertyName=bShouldDisable)
}