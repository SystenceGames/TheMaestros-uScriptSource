// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_ClearNotifications extends SequenceAction;

var string inText;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.clearNotifications();
}

defaultproperties
{
	ObjName="ClearNotifications"
	ObjCategory="TheMaestros"
}
