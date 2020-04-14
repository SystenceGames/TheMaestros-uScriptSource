// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_ShowHintArrow extends SequenceAction;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.showHintArrow(true);
}

defaultproperties
{
	ObjName="ShowHintArrow"
	ObjCategory="TheMaestros"
}
