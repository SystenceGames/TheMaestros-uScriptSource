// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_EnableMouseInput extends SequenceAction;

event Activated()
{	
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.m_disableMouseInput = false;
}

defaultproperties
{
	ObjName="EnableMouseInput"
	ObjCategory="TheMaestros"
}
