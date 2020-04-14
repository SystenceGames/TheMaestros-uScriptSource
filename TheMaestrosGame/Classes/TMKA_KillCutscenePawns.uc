class TMKA_KillCutscenePawns extends SequenceAction;

event Activated()
{
	local TMPlayerController pc;
	local TMPawn pawnItr;
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	foreach pc.AllActors(class'TMPawn', pawnItr)
	{
		if(pawnItr.m_UnitType != "RoboMeister" && pawnItr.OwnerReplicationInfo == pc.PlayerReplicationInfo)
		{
			pc.TellServerToKillPawn(pawnItr.pawnId);
		}
	}
}

DefaultProperties
{
	ObjName="KillCutscenePawns"
	ObjCategory="TheMaestros"
}
