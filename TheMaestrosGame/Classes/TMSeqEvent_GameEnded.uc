class TMSeqEvent_GameEnded extends SequenceEvent;

event Activated()
{
    local TMPlayerController PC;
    PC = TMPlayerController(GetWorldInfo().GetALocalPlayerController());
	PC.ClientEndGameInVictory(true);
}

DefaultProperties
{
	ObjName="GameEnded"    //Kismet Event Name
	ObjCategory="TMGame"    //Kismet Event Menu Category
	bPlayerOnly=false
}