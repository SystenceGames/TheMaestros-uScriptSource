class TMSalvatorSnake extends Pawn;


const SPAWN_TELEPORT_VFX = "C_Spawn_Teleport_VFX";

var TMSalvatorSnake mOtherSnake;
var TMPlayerController mTMPC;
var int mOwnerPawnID;
var int mAllyID;
var int mTeamColorIndex;
var int mRadius;
var float mDuration;
var bool mIsActive;

var array< TMPawn > mPawnsInMe;
var float mCheckPawnsInMeFrequency;

var Vector mDummyLocation;

function Setup( TMPawn pw, TMSalvatorSnake otherSnake, float duration, Vector inLocation )
{
	mIsActive = true;
	mOwnerPawnID = pw.pawnId;
	mTMPC = pw.m_TMPC;
	mTMPC.mSalvatorSnakes.AddItem( self );
	mAllyID = TMPlayerReplicationInfo( pw.OwnerReplicationInfo ).allyId;
	mTeamColorIndex = TMPlayerReplicationInfo( pw.OwnerReplicationInfo ).mTeamColorIndex;
	mDuration = duration;

	mOtherSnake = otherSnake;
	LoadVFX( inLocation );

	mDummyLocation.X = -6900;
	mDummyLocation.Y = -6900;
	mDummyLocation.Z = -6900;
	
	// Make sure any pawns inside the portal are in my list
	AddNearbyPawnsToPawnsInMe();

	SetTimer( mCheckPawnsInMeFrequency, true, 'CheckPawnsInMe', self );
	SetTimer( mDuration, false, 'RemoveSnake', self );
}

function TeleportPawn( TMPawn inPawn )
{
	local Vector teleportLocation;

	teleportLocation = mOtherSnake.Location + ( inPawn.Location - self.Location );
	teleportLocation.Z = inPawn.Location.Z;
	inPawn.SetCollision( false );

	SendSpawnVFX( inPawn.Location );

	mOtherSnake.AddPawn( inPawn );
	if( !inPawn.SetLocation( teleportLocation ) )
	{
		`warn( "TMSalvatorSnake::TeleportPawn() ERROR: Couldn't teleport pawn " $ inPawn.name );
		mOtherSnake.RemovePawn( inPawn );
	}

	inPawn.SendStopCommand();
	inPawn.SetCollision( true );
}

function SendSpawnVFX( Vector inLocation )
{
	local TMAbilityFE fe;
	fe = new () class'TMAbilityFE';
	fe.commandType = SPAWN_TELEPORT_VFX;
	fe.pawnId = mOwnerPawnID;
	fe.abilityLocation = inLocation;
	TMPawn( mTMPC.Pawn ).SendFastEvent( fe );
}

function AddPawn( TMPawn inPawn )
{
	inPawn.mPointToDetermineIfWeHaveSameDestination = mDummyLocation;

	if( mPawnsInMe.Find( inPawn ) == INDEX_NONE )
	{
		mPawnsInMe.AddItem( inPawn );
	}
}

function RemovePawn( TMPawn inPawn )
{
	if( mPawnsInMe.Find( inPawn ) != INDEX_NONE )
	{
		mPawnsInMe.RemoveItem( inPawn );
	}
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local TMPawn tempPawn;
	tempPawn = TMPawn( other );

	if( tempPawn == none )
	{
		return;
	}

	if( !mIsActive )
	{
		return;
	}

	if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId == mAllyID )
	{
		// The TMPawn is on my team
		if( TMPawn( mTMPC.Pawn ).IsInRange2D( tempPawn.mPointToDetermineIfWeHaveSameDestination, self.Location, mRadius ) )
		{
			// Teleport him to the other snake
			TeleportPawn( tempPawn );
			RemovePawn( tempPawn );
		}
		else
		{
			// Add the pawn to list of pawns in me
			AddPawn( tempPawn );
		}
	}
}

event UnTouch( Actor Other )
{
	local TMPawn tempPawn;
	tempPawn = TMPawn( other );

	if( tempPawn == none )
	{
		return;
	}

	if( !mIsActive )
	{
		return;
	}

	if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId == mAllyID )
	{
		// The TMPawn is on my team
		RemovePawn( tempPawn );
	}
}

function AddNearbyPawnsToPawnsInMe() 	// this is only called once when the portal is first spawned
{
	local TMPawn tempPawn;
	local array< TMPawn > mPawns;
	mPawns = mTMPC.GetTMPawnList();
	foreach mPawns( tempPawn )
	{
		if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId == mAllyID )
		{
			// The TMPawn is on my team
			if( tempPawn.IsPointInRange2D( self.Location, mRadius ) )
			{
				// Add this pawn to my list
				AddPawn( tempPawn );
			}
		}
	}
}

function CheckPawnsInMe()
{
	local int i;
	local TMPawn tempPawn;

	for( i = mPawnsInMe.Length-1; i >= 0; i-- )
	{
		tempPawn = mPawnsInMe[ i ];

		if( tempPawn != none &&
			tempPawn.Health > 0 &&
			tempPawn.mPointToDetermineIfWeHaveSameDestination != mDummyLocation )
		{
			// Check if the pawn is trying to teleport
			if( TMPawn( mTMPC.Pawn ).IsInRange2D( tempPawn.mPointToDetermineIfWeHaveSameDestination, self.Location, mRadius ) )
			{
				// Teleport him to the other snake
				TeleportPawn( tempPawn );
				RemovePawn( tempPawn );     // potential issue where list isn't properly iterated
			}
		}
	}
}

function LoadVFX( Vector inLocation )
{
	local ParticleSystem ps;

	// Setup the VFX based on the team color
	if ( mAllyID == 0 )     // Blue team
	{
		ps = ParticleSystem'VFX_Salvator.Particles.P_Portal_Blue';
	}
	else if ( mAllyID == 1) // Red team
	{
		ps = ParticleSystem'VFX_Salvator.Particles.P_Portal_Red';
	}
	else
	{
		`log("ERROR: TMSalvatorSnake could not get a valid team ID. Let Taylor know.", true, 'Taylor');
		ps = ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion';
	}

	mTMPC.m_ParticleSystemFactory.Create( ps, mAllyID, mTeamColorIndex, inLocation, mDuration );
}

function RemoveSnake()
{
	mTMPC.mSalvatorSnakes.RemoveItem( self );
	ClearTimer( 'CheckPawnsInMe', self );
	mIsActive = false;
	self.Destroy();
}

simulated event Destroyed()
{
	self.ClearAllTimers();
		bTearOff=true;
	
	super.Destroyed();
}

DefaultProperties
{
	mCheckPawnsInMeFrequency = 0.05f
	mRadius = 150   // Currently set to slightly larger than the collision radius

	bBlockActors = false
	bCollideActors=true
	bCollideWhenPlacing = false
	bCollideAsEncroacher = false
	bCollideWorld = false
	bStatic = false
	bNoDelete = false
	bMovable = true

	Begin Object  Name=CollisionCylinder
	CollisionRadius=150
	CollisionHeight=100
	AlwaysLoadOnClient=True
	CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CollisionType=COLLIDE_TouchAll
	Components.Add(CollisionCylinder)

	Physics = PHYS_Custom;
}
