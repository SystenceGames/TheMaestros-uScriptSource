// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_IsCommanderSelected extends SequenceAction;

var bool outSelected;

event Activated()
{
	outSelected = false;
	if (TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.CurrentSelectedActors.Length == 1)
	{
		outSelected = TMPawn(TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.CurrentSelectedActors[0]).m_Unit.m_UnitName 
			== TMPlayerReplicationInfo(TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.PlayerReplicationInfo).commanderType;
	}
}

defaultproperties
{
	ObjName="IsCommanderSelected"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Is Selected", bWriteable = true, PropertyName=outSelected)
}
