// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_DisableInput extends SequenceAction;

event Activated()
{	
	if(TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.m_disableInput) {
		TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.m_disableInput=false;
	}
	else {
		TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.m_disableInput=true;
	}
}

defaultproperties
{
	ObjName="DisableInput"
	ObjCategory="TheMaestros"
}
