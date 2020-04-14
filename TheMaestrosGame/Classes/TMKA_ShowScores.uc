// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_ShowScores extends SequenceAction;

event Activated()
{
	//TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.TM_HUD.showScoreboard(true);
}

defaultproperties
{
	ObjName="ShowScores"
	ObjCategory="TheMaestros"
}
