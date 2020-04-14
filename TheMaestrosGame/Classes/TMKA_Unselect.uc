class TMKA_Unselect extends SequenceAction;

event Activated()
{
	local TMPlayerController pc;
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	pc.RemoveActorsSelected();
}

DefaultProperties
{
	ObjName="Unselect"
	ObjCategory="TheMaestros"
}
