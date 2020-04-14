// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_RotateHintArrow extends SequenceAction;

var int inRotation;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.rotateHintArrow(inRotation);
}

defaultproperties
{
	ObjName="RotateHintArrow"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Int', LinkDesc="Rotation", PropertyName=inRotation)
}