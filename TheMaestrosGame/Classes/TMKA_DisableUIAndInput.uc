class TMKA_DisableUIAndInput extends SequenceAction;

event Activated()
{
	local TMPlayerController pc;
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());
	//pc.TM_HUD.hideHud(true);
	pc.m_disableInput = true;
}

DefaultProperties
{
	ObjName="DisableUIAndInput"
	ObjCategory="TheMaestros"
}
