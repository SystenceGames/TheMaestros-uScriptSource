// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_GetArmyPopulation extends SequenceAction;

var int outPopulation;

event Activated()
{
	outPopulation = TMPlayerReplicationInfo(TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.PlayerReplicationInfo).Population;


}

defaultproperties
{
	ObjName="GetArmyPopulation"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Int', LinkDesc="Army population for player", bWriteable = true, PropertyName=outPopulation)
}
