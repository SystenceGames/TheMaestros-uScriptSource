// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_DisableMouseInput extends SequenceAction;

event Activated()
{	
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.m_disableMouseInput = true;
}

defaultproperties
{
	ObjName="DisableMouseInput"
	ObjCategory="TheMaestros"
}
