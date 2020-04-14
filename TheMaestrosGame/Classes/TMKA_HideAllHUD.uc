class TMKA_HideAllHUD extends SequenceAction;

var bool bShouldHide;

event Activated()
{
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.TM_HUD.hideAllHUD( bShouldHide );

	OutputLinks[0].bHasImpulse = TRUE;
}

defaultproperties
{
	ObjName="HideAllHUD"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Should Hide", PropertyName=bShouldHide)
}
