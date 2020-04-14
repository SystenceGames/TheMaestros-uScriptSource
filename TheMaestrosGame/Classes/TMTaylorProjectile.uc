class TMTaylorProjectile extends Projectile;


enum ProjectileType
{
	PT_LOB,
	PT_STRAIGHT
};
var ProjectileType mType;

var TMParticleSystem  		mTMParticleSystem;
var ParticleSystem          mProjectileParticle;
var ParticleSystem          mOnHitParticle;

var TMPlayerController      mTMPC;
var int                     mAllyID;
var int                     mTeamColorIndex;

var TMPawn  mTarget;
var vector  mTargetLocation;

var float   mUpdateFrequency;
var float  	MAX_PROJECTILE_FLIGHT_TIME;


simulated function SetupProjectile( ParticleSystem inProjectileParticle, ParticleSystem inOnHitParticle, TMPlayerController inTMPC, int inAllyId )
{
	mProjectileParticle =   inProjectileParticle;
	mOnHitParticle =        inOnHitParticle;
	
	mTMPC =     inTMPC;
	mAllyID =   inAllyId;
	mTeamColorIndex = TMPlayerReplicationInfo( mTMPC.PlayerReplicationInfo ).mTeamColorIndex;
}

simulated function bool FireLobbedProjectile( vector inTargetLocation, float inLobSpeed, float inAngle )
{
	local vector tossVelocity;

	if ( SuggestTossVelocity( tossVelocity, inTargetLocation, Location, inLobSpeed,, inAngle ) )
	{
		Velocity = tossVelocity;
	}
	else
	{
		`warn( "TMTaylorProjectile::FireLobbedProjectile() couldn't lob projectile! Launching a straight projectile instead." );
		return FireStraightProjectile(inTargetLocation, inLobSpeed);
	}

	PlayFiringVFX();

	SetPhysics( PHYS_Falling );
	mType = PT_LOB;

	SetTimer( mUpdateFrequency, true, 'CheckIfHit', self );
	SetTimer( MAX_PROJECTILE_FLIGHT_TIME, false, 'HitTarget', self );
	
	return true;
}

simulated function bool FireStraightProjectile( vector inTargetLocation, float inSpeed )
{
	local Vector targetVel;
	local Rotator rot;

	// Rotate to target location
	rot = Rotator(mTargetLocation - Location);
	rot.Pitch = 0;
	rot.Roll = 0;
	SetRotation( rot );

	targetVel = Normal( inTargetLocation - location );
	Velocity = targetVel * inSpeed;

	PlayFiringVFX();

	SetPhysics( PHYS_Projectile );
	mType = PT_STRAIGHT;

	SetTimer( mUpdateFrequency, true, 'CheckIfHit', self );
	SetTimer( MAX_PROJECTILE_FLIGHT_TIME, false, 'HitTarget', self );
	
	return true;
}

simulated function CheckIfHit()
{
	local float distance;
	
	if ( mType == PT_LOB )
	{
		distance = 2500;    // 50 squared

		if( VSizeSq( mTargetLocation - Location ) < distance ||
			Location.z < mTargetLocation.z )
		{
			ClearTimer( 'CheckIfHit', self );
			ClearTimer( 'HitTarget', self );
			HitTarget();
		}
	}
	else if( mType == PT_STRAIGHT )
	{
		distance = 2500;

		if( VSizeSq2D( mTargetLocation - Location ) < distance )
		{
			ClearTimer( 'CheckIfHit', self );
			ClearTimer( 'HitTarget', self );
			HitTarget();
		}
	}
}

simulated function HitTarget()
{
	PlayOnHitVFX();
	Destroy();
}

simulated function PlayFiringVFX()
{
	if( mTMPC.IsClient() )
	{
		mTMParticleSystem = mTMPC.m_ParticleSystemFactory.CreateAttachedToActor( mProjectileParticle, mAllyID, mTeamColorIndex, self, Location, 30, Rotation );
	}
}

simulated function PlayOnHitVFX()
{
	if( mOnHitParticle == none )
	{
		return;
	}

	mTMPC.m_ParticleSystemFactory.Create( mOnHitParticle, mAllyID, mTeamColorIndex, mTargetLocation, 2 );
}

simulated event Destroyed()
{
	if( mTMParticleSystem != none )
	{
		mTMParticleSystem.Destroy();
	}
}

DefaultProperties
{
	Begin Object Name=CollisionCylinder
		CollisionRadius = 10
		CollisionHeight = 10
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bCollideActors = false;
	bCollideWorld = false


	mUpdateFrequency = 0.1;
	MAX_PROJECTILE_FLIGHT_TIME = 2.0f; 	// Just as a backup in case a projectile never lands
}
