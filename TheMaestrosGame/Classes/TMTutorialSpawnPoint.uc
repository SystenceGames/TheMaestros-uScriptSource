class TMTutorialSpawnPoint extends TMNeutralSpawnPoint;

var bool firstTime;
var() bool bCanBeHitByNuke;

event PostBeginPlay()
{
	super.PostBeginPlay();
}

event Tick(float dt)
{
	local TMPlayerController pc;
	local TMGameInfo tmgi;
	super.Tick(dt);

	tmgi = TMGameInfo(WorldInfo.Game);

	if (!tmgi.bGameStarted)
	{
		return;
	}

	pc = TMPlayerController(tmgi.GetALocalPlayerController());
	if(firstTime && pc != none)
	{
		mPawnHolden = tmgi.RequestUnit(mSpawnType, TMPlayerReplicationInfo(pc.PlayerReplicationInfo), Location, false, Location, none, true);
		mPawnHolden.SendFastEvent(class'TMFastEventSpawn'.static.create(mPawnHolden.pawnId, Location, true));
		mPawnHolden.bCanBeHitByNuke = bCanBeHitByNuke;
		firstTime = false;
	}
}

DefaultProperties
{
	bStatic = false
	mShouldSpawnBaseUnits = false;
	firstTime = true;
	bCanBeHitByNuke = false;
}
