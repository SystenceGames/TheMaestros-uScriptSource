class TMNeutralCamp extends UDKRTSNeutralCamp
	placeable
	ClassGroup(Common)
	hidecategories(Collision);

var() array<TMNeutralSpawnPoint> mSpots;
var bool mRespawning;
var() int mRespawnInterval;
var() float mChaseRadius;
var() bool bCanBeHitByNuke;
var bool mFirstFullTick;
var() int mBaseCampHealth;
var() int m_spawnDelay;
var TMGameInfo mGameInfo;

var TMNeutralPlayerController mNeutralController;

var bool mIsDead;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	mGameInfo = TMGameInfo(WorldInfo.Game);	
}

function bool ShouldReset()
{
	local int i;

	if (ContainsNonNeutral())
	{
		return true;
	}

	for(i = 0; i < mSpots.Length; ++i)
	{
		if ( !class'UDKRTSPawn'.static.IsValidPawn( mSpots[i].mPawnHolden) )
		{
			return true;
		}
	}

	return false;
}

function SoftReset()
{
	local int i;
	local Vector homeLocation;
	local TMPawn pawn;

	for(i = 0; i < mSpots.Length; ++i)
	{
		pawn = mSpots[i].mPawnHolden;
		homeLocation = TMNeutralAIController(mSpots[i].mPawnHolden.Controller).mHome;
		homeLocation.Z = pawn.Location.Z;
		pawn.SetLocation(homeLocation);
		pawn.Health = pawn.HealthMax;
	}
}

simulated event Reset()
{
	local int i;

	if ( !ShouldReset() )
	{
		SoftReset();
		return;
	}

	StopSpawnTimer();

	for(i = 0; i < mSpots.Length; ++i)
	{
		if ( mSpots[i].mPawnHolden != None )
		{
			mSpots[i].mPawnHolden.Destroy();
			mSpots[i].mPawnHolden = None;
		}
	}
	if(m_spawnDelay != 0 && self.IsAuthority())
	{
		mRespawning = true;
		SetTimer(m_spawnDelay, false, NameOf(SpawnUnits), );
	}
	else
	{
		SpawnUnits();
	}
}

simulated function bool ContainsNonNeutral()
{
	local TMNeutralSpawnPoint iterSpawnPoint;
	
	foreach mSpots( iterSpawnPoint )
	{
		if ( iterSpawnPoint != None && iterSpawnPoint.mSpawnType != "Slender" &&
			iterSpawnPoint.mSpawnType != "Droplet" && 
			iterSpawnPoint.mSpawnType != "Droplet_Tutorial" )
		{
			return true;
		}
	}

	return false;
}

simulated event Tick(float dt)
{
	local int i;
	local bool dead;
	super.Tick(dt);

	if (!IsAuthority())
	{
		return;
	}
	if (mRespawning)
	{
		return;
	}
	if (!mGameInfo.bGameStarted)
	{
		return;
	}

	if (mFirstFullTick)
	{
		if (m_spawnDelay <= 0)
		{
			SpawnUnits();			
		}
		else
		{
			mRespawning = true;
			SetTimer(m_spawnDelay, false, NameOf(SpawnUnits), );
		}
	}
	else
	{
		dead = true;
		for(i = 0; i < mSpots.Length; ++i)
		{
			if(mSpots[i].mPawnHolden != None && mSpots[i].mPawnHolden.Health > 0)
			{
				dead = false;
				mIsDead = dead;
				return;
			}
		}
   		mIsDead = dead;
		StartSpawnTimer();
	}

	mFirstFullTick = false; // you're only first once
}

function bool IsDead()
{
	return mIsDead;
}

function StartSpawnTimer()
{
	mRespawning = true;
	SetTimer(mRespawnInterval, false, NameOf(SpawnUnits), );
}

function StopSpawnTimer()
{
	mRespawning = false;
	ClearTimer( NameOf(SpawnUnits) );
}

function bool IsAuthority()
{
	return ((WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone));
}

reliable server function SetController(TMNeutralPlayerController pController)
{
	mNeutralController = pController;
}

function SpawnUnits()
{
	local int i;
	local rotator rotate;
	local vector unitY;
	local vector start;
	local vector end;
	local vector homeNormal;
	local vector homePos;
	local Terrain hitActor;
	
	rotate.Pitch = 0;
	rotate.Roll = 0;

	unitY.X = 0;
	unitY.Y = 1;
	unitY.Z = 0;

	for(i = 0; i < mSpots.Length; ++i)
	{
		if( mSpots[i] == none )
		{
			`warn( "TMNeutralCamp::SpawnUnits() camp " $ name $ " had a bad TMNeutralSpawnPoint in mSpots. Removing camp." );
			mSpots.Remove(i, 1);
			i--;
			continue;
		}
		
		mSpots[i].mPawnHolden = mGameInfo.RequestUnit(mSpots[i].mSpawnType, TMPlayerReplicationInfo(mGameInfo.m_TMNeutralPlayerController.PlayerReplicationInfo), mSpots[i].Location, false, Vect(0.f,0.f,0.f), None, true);
		mSpots[i].mPawnHolden.SendFastEvent(  class'TMFastEventSpawn'.static.create( mSpots[i].mPawnHolden.pawnId ,  mSpots[i].mPawnHolden.Location , true) );
		mSpots[i].mPawnHolden.bCanBeHitByNuke = bCanBeHitByNuke;

		//redo this if we want to have the set healths for 1v1 and 2v2
		/*
		if(IsAuthority() &&( mSpots[i].mSpawnType == "Brute" || mSpots[i].mSpawnType == "Nexus" ))
		{
			playerCount = TMGameInfo(WorldInfo.Game).NumBots + TMGameInfo(WorldInfo.Game).NumPlayers;
			if(playerCount <= 2 && mSpots[i].mPawnHolden.m_Unit.m_BruteNexus1v1Health != 0)
			{
				mSpots[i].mPawnHolden.Health = (mSpots[i].mPawnHolden.m_Unit.m_BruteNexus1v1Health / 2);
				mSpots[i].mPawnHolden.HealthMax = mSpots[i].mPawnHolden.m_Unit.m_BruteNexus1v1Health;
				mSpots[i].mPawnHolden.m_Unit.m_Data.health = mSpots[i].mPawnHolden.m_Unit.m_BruteNexus1v1Health;
			}
			else if(playerCount <=4 && mSpots[i].mPawnHolden.m_Unit.m_BruteNexus2v2Health != 0)
			{
				mSpots[i].mPawnHolden.Health = (mSpots[i].mPawnHolden.m_Unit.m_BruteNexus2v2Health / 2);
				mSpots[i].mPawnHolden.HealthMax = mSpots[i].mPawnHolden.m_Unit.m_BruteNexus2v2Health;
				mSpots[i].mPawnHolden.m_Unit.m_Data.health = mSpots[i].mPawnHolden.m_Unit.m_BruteNexus2v2Health;
			}
			else if( mSpots[i].mPawnHolden.m_Unit.m_BruteNexus3v3Health != 0)
			{
				mSpots[i].mPawnHolden.Health = ( mSpots[i].mPawnHolden.m_Unit.m_BruteNexus3v3Health / 2);
				mSpots[i].mPawnHolden.HealthMax = mSpots[i].mPawnHolden.m_Unit.m_BruteNexus3v3Health;
				mSpots[i].mPawnHolden.m_Unit.m_Data.health = mSpots[i].mPawnHolden.m_Unit.m_BruteNexus3v3Health;
			}
		}
		*/

		if(mBaseCampHealth != 0)
		{
			mSpots[i].mPawnHolden.Health = mBaseCampHealth;
		}
			
		rotate.Yaw = mSpots[i].mInitialRotation * DegToUnrRot;

		start = mSpots[i].Location;
		end = mSpots[i].Location;
		end.Z -= 100000;
		foreach TraceActors(class'Terrain', hitActor, homePos, HomeNormal, end, start)
		{
			if(mSpots[i].mPawnHolden != none)
			{
				TMNeutralAIController(mSpots[i].mPawnHolden.Controller).FocusSpot = mSpots[i].mPawnHolden.Location + 10 * Normal(unitY >> rotate);
				TMNeutralAIController(mSpots[i].mPawnHolden.Controller).mNeutralCamp = self;
				TMNeutralAIController(mSpots[i].mPawnHolden.Controller).mHome = homePos;
				TMNeutralAIController(mSpots[i].mPawnHolden.Controller).mShouldSpawnBaseUnits = mSpots[i].mShouldSpawnBaseUnits;
				TMNeutralAIController(mSpots[i].mPawnHolden.Controller).mChaseRadiusSq = mChaseRadius * mChaseRadius;
				TMNeutralAIController(mSpots[i].mPawnHolden.Controller).mSearchRadiusSq = (mChaseRadius + 100) * (mChaseRadius + 100);
				break;
			}
		}
	}

	mRespawning = false;
}

defaultproperties
{
	mChaseRadius = 600;

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_NavP'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Navigation"
	End Object
	Components.Add(Sprite)

	Begin Object Class=ArrowComponent Name=Arrow
		ArrowColor=(R=150,G=200,B=255)
		ArrowSize=0.5
		bTreatAsASprite=True
		HiddenGame=true
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Navigation"
	End Object
	Components.Add(Arrow)

	Begin Object Class=CylinderComponent Name=CollisionCylinder LegacyClassName=NavigationPoint_NavigationPointCylinderComponent_Class
		CollisionRadius=+0050.000000
		CollisionHeight=+0050.000000
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	Begin Object Class=PathRenderingComponent Name=PathRenderer
	End Object
	Components.Add(PathRenderer)

	bHidden=FALSE

	bCollideWhenPlacing=true

	bCollideActors=false
	mFirstFullTick=true
	// NavigationPoints are generally server side only so we don't need to worry about client simulation
	bForceAllowKismetModification=true
	mRespawnInterval=1
	mBaseCampHealth = 0;
	bCanBeHitByNuke=false;
	bNoDelete=true;
} 