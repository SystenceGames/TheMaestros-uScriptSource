// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_SinglePlayerEndGame extends SequenceAction;

var bool inVictory;

event Activated()
{
	TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.SinglePlayerEndGame(inVictory);
}

defaultproperties
{
	ObjName="SinglePlayerEndGame"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Is Victory", PropertyName=inVictory)
}
