// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_BlinkSelectBar extends SequenceAction;

var int val;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.blinkSelect(val);
}

defaultproperties
{
	ObjName="BlinkSelectBar"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Int', LinkDesc="Selection Number", PropertyName=val)
}
