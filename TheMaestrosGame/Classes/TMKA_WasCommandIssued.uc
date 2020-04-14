class TMKA_WasCommandIssued extends SequenceAction;

var string inCommandName;
var bool outVal;
var Ecommand cats;

event Activated()
{
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	if ( /*tmpc.m_bLookingForCommand && */GetEnum(enum'ECommand', tmpc.m_CommandImLookingFor) == Name(inCommandName) && tmpc.m_bReceivedCommandImLookingFor )
	{
		outVal = true;
		OutputLinks[0].bHasImpulse = TRUE;

		//???
		tmpc.StopLookingForCommand();
	}
	else
	{
		tmpc.StartLookingForCommand(inCommandName);
	}
}

defaultproperties
{
	ObjName="WasCommandIssued"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Command Name", PropertyName=inCommandName)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Was Command Issued", bWriteable = true, PropertyName=outVal)
}
