// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_BlinkAbilityBar extends SequenceAction;

var int val;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.blinkAbility(val);
}

defaultproperties
{
	ObjName="BlinkAbilityBar"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Int', LinkDesc="Ability Number", PropertyName=val)
}
