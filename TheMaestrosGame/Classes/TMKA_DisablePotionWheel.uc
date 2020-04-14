// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_DisablePotionWheel extends SequenceAction;

event Activated()
{	
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	tmpc.TM_HUD.parentHUD.SetRadialPotionMenuDisabled( true );
}

defaultproperties
{
	ObjName="DisablePotionWheel"
	ObjCategory="TheMaestros"
}
