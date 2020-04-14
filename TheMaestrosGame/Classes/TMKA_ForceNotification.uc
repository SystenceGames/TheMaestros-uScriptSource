// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_ForceNotification extends SequenceAction;

var string inText;
var int time;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.forceNotification(inText, time);
}

defaultproperties
{
	ObjName="ForceNotification"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Text", PropertyName=inText)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Int', LinkDesc="Time", PropertyName=time)
}