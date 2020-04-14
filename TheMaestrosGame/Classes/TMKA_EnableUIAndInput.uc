class TMKA_EnableUIAndInput extends SequenceAction;

event Activated()
{
	local TMPlayerController pc;
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());
	//pc.TM_HUD.hideHud(false);
	pc.m_disableInput = false;
}

DefaultProperties
{
	ObjName="EnableUIAndInput"
	ObjCategory="TheMaestros"
}
