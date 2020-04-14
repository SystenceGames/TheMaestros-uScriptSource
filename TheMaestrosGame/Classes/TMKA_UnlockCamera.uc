// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_UnlockCamera extends SequenceAction;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.UnlockCamera();
}

defaultproperties
{
	ObjName="UnlockCamera"
	ObjCategory="TheMaestros"
}
