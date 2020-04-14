// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_LockCamera extends SequenceAction;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.LockCameraToCommander();
}

defaultproperties
{
	ObjName="LockCamera"
	ObjCategory="TheMaestros"
}
