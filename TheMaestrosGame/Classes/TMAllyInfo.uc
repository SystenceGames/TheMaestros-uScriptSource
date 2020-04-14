class TMAllyInfo extends Info;

var repnotify int allyIndex;
var repnotify bool bWon;
var repnotify int score;
var TMFOWVisibilityMask visibilityMask; /** The visibility mask that tells where this ally has vision. */

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	if (WorldInfo.NetMode == NM_Client)
	{
		TMPlayerController(GetALocalPlayerController()).AddAllyInfo(self);
	}
}

replication
{
	if (bNetDirty)
		allyIndex, score, bWon;
}

// Not sure if this is necessary? Just safe - Dru
simulated event Destroyed()
{
	super.Destroyed();
	TMPlayerController(GetALocalPlayerController()).RemoveAllyInfo(self);
}

DefaultProperties
{
	bAlwaysRelevant=true
	bHidden=false
	bOnlyOwnerSee=false
	score=0
	TickGroup=TG_DuringAsyncWork
	RemoteRole=ROLE_SimulatedProxy
	NetUpdateFrequency=1
}
