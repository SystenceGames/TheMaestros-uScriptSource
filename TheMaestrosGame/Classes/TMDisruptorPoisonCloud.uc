class TMDisruptorPoisonCloud extends PAWN;


var TMPawn mOwner;
var TMPlayerController mTMPC;
var int mAllyID;
var int mTeamColorIndex;
var ENetMode mNetMode;
var int m_iRadius;
var float m_fDuration;
var IntPoint fowLocation;
var vector m_vPoisonLocation;
var bool mIsActive;

var array< TMPawn > mPawnsInMe;
var float mUpdatePoisonFrequency;


simulated function InitPoisonCloud( TMPawn pw, int radius, float duration, float updateInterval )
{
	mIsActive = true;

	mOwner = pw;
	mTMPC = pw.m_TMPC;
	mAllyID = TMPlayerReplicationInfo( pw.OwnerReplicationInfo ).allyId;
	mTeamColorIndex = TMPlayerReplicationInfo( pw.OwnerReplicationInfo ).mTeamColorIndex;
	mNetMode = pw.WorldInfo.NetMode;

	m_vPoisonLocation = pw.Location;
	m_iRadius = radius;
	m_fDuration = duration;
	
	Load_VFX();

	// Check if anyone is already inside me
	InitialCheckPoison();

	SetTimer( mUpdatePoisonFrequency, true, 'UpdatePoison', self );
	SetTimer(m_fDuration, false, 'Remove_Poison_Cloud', self);
}

simulated event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
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

	if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId != mAllyID )
	{
		// The TMPawn isn't on my team, poison him
		PoisonPawn( tempPawn );
	}
}

simulated event UnTouch( Actor Other )
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

	if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId != mAllyID )
	{
		mPawnsInMe.RemoveItem( tempPawn );
	}
}

simulated function PoisonPawn( TMPawn inPawn )
{
	if( inPawn.IsGameObjective() )
	{
		return;
	}

	inPawn.m_unit.SendStatusEffect( SE_DISRUPTOR_POISON );

	if( mPawnsInMe.Find( inPawn ) == INDEX_NONE )
	{
		mPawnsInMe.AddItem( inPawn );
	}
}

simulated function InitialCheckPoison()
{
	local TMPawn tempPawn;
	local array< TMPawn > mPawns;
	mPawns = mTMPC.GetTMPawnList();
	foreach mPawns( tempPawn )
	{
		if( tempPawn.IsPointInRange2D( self.Location, 100 ) )
		{
			if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId != mAllyID )
			{
				// The TMPawn isn't on my team, poison him
				PoisonPawn( tempPawn );
			}
		}
	}
}

simulated function UpdatePoison()
{
	local TMPawn tempPawn;
	foreach mPawnsInMe( tempPawn )
	{
		tempPawn.m_Unit.SendStatusEffect( SE_DISRUPTOR_POISON );
	}
}

simulated function Load_VFX()
{
	local ParticleSystem poison;

	if ( mAllyID == 0 ) // Blue team
	{
		poison = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonTrail_Blue';
	}
	else if ( mAllyID == 1)  // Red team
	{
		poison = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonTrail_Red';
	}
	else
	{
		`log("ERROR: TMDisruptorPoisonCloud could not get a valid team ID. Let Taylor know.", true, 'Taylor');
		poison = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Muzzle_Special_Projectile';
	}

	mTMPC.m_ParticleSystemFactory.CreateWithScale(poison, mAllyID, mTeamColorIndex, m_vPoisonLocation, 2.0f, m_fDuration);
}

simulated function Remove_Poison_Cloud()
{
	ClearTimer( 'UpdatePoison', self );
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
	mUpdatePoisonFrequency = 0.1f;

	bTearOff = true
	bBlockActors = false
	bCollideActors=true
	bCollideWhenPlacing = false
	bCollideAsEncroacher = false
	bCollideWorld = false
	bStatic = false
	bNoDelete = false
	bMovable = true

	Begin Object  Name=CollisionCylinder
	CollisionRadius=100
	CollisionHeight=100
	AlwaysLoadOnClient=True
	CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CollisionType=COLLIDE_TouchAll
	Components.Add(CollisionCylinder)

	Physics = PHYS_Custom;
}
