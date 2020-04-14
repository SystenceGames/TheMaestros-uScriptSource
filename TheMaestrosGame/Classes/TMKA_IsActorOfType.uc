// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_IsActorOfType extends SequenceAction;

var TMPawn inActor;
var String inType;
var bool outVal;

event Activated()
{
	outVal = inActor.m_UnitType == inType;
	if (outVal)
	{
		OutputLinks[0].bHasImpulse = TRUE;
	}
}

defaultproperties
{
	ObjName="IsActorOfType"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Object', LinkDesc="Actor", PropertyName=inActor)
	VariableLinks(1) = (ExpectedType=class'SeqVar_String', LinkDesc="Type", PropertyName=inType)
	VariableLinks(2) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Is Type", bWriteable = true, PropertyName=outVal)
}

