// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_IsCampDead extends SequenceAction;

var TMNeutralCamp inCamp;
var bool outVal;

event Activated()
{
	outVal = inCamp.isDead();
	if (outVal)
	{
		OutputLinks[0].bHasImpulse = TRUE;
	}
}

defaultproperties
{
	ObjName="IsNeutralCampDead"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_Object', LinkDesc="Neutral Camp", PropertyName=inCamp)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Is Dead", bWriteable = true, PropertyName=outVal)
}
