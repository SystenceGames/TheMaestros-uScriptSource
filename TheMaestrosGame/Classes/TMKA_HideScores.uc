// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_HideScores extends SequenceAction;

event Activated()
{
	//TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.showScoreboard(false);
}

defaultproperties
{
	ObjName="HideScores"
	ObjCategory="TheMaestros"
}
