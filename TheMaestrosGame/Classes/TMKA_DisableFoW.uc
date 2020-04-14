class TMKA_DisableFoW extends SequenceAction;

event Activated()
{
	local TMPlayerController tmpc;
	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.FoWDisable();
}

defaultproperties
{
	ObjName="DisableFoW"
	ObjCategory="TheMaestros"
}