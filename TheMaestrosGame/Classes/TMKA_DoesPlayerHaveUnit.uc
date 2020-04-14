// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_DoesPlayerHaveUnit extends SequenceAction;

var string inUnitName;
var bool outVal;

event Activated()
{
	local TMPawn tempPawn;
	local array<TMPawn> pawnList;

	outVal = false;

	pawnList = TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.GetTMPawnList();
	foreach pawnList( tempPawn )
	{
		if( tempPawn.m_Unit.m_UnitName == inUnitName )
		{
			outVal = true;
			OutputLinks[0].bHasImpulse = TRUE;
			return;
		}
	}
}

defaultproperties
{
	ObjName="DoesPlayerHaveUnit"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Unit name", PropertyName=inUnitName)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Does player have?", bWriteable = true, PropertyName=outVal)
}
