class TMKA_HideCursor extends SequenceAction;

var bool bShouldHide;

event Activated()
{
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.TM_HUD.hideCursor( bShouldHide );

	OutputLinks[0].bHasImpulse = TRUE;
}

defaultproperties
{
	ObjName="HideCursor"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Should Hide", PropertyName=bShouldHide)
}
