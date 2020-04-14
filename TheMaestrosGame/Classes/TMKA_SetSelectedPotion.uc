// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_SetSelectedPotion extends SequenceAction;

var string inPotionName;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.SetPotion(inPotionName);
}

defaultproperties
{
	ObjName="SetSelectedPotion"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Text", PropertyName=inPotionName)
}
