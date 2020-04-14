// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_GetHUDLastSelected extends SequenceAction;

var string outSelected;

event Activated()
{
	outSelected = TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.lastSelected;
}

defaultproperties
{
	ObjName="GetHUDLastSelected"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Last Selected", bWriteable = true, PropertyName=outSelected)
}
