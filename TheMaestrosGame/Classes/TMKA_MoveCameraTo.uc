// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_MoveCameraTo extends SequenceAction;

var int inX;
var int inY;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.SetCameraDestination(inX, inY);
}

defaultproperties
{
	ObjName="MoveCameraTo"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Int',LinkDesc="X",PropertyName=inX)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Int',LinkDesc="Y",PropertyName=inY)
}
