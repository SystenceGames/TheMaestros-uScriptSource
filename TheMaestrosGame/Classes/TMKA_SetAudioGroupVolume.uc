class TMKA_SetAudioGroupVolume extends SequenceAction;

var string inAudioGroupName;
var float inVolumeName;

event Activated()
{
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.SetAudioGroupVolume( Name(inAudioGroupName), inVolumeName );

	OutputLinks[0].bHasImpulse = TRUE;
}

defaultproperties
{
	ObjName="SetAudioGroupVolume"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Audio Group Name", PropertyName=inAudioGroupName)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Float', LinkDesc="Volume", PropertyName=inVolumeName)
}