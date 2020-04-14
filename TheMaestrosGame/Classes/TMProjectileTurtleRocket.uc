class TMProjectileTurtleRocket extends TMTaylorProjectile;

var TMAbilityHelper m_AbilityHelper; 	// TODO: have this be a part of something else
var int mDamage;
var int mRadius;

var TMPawn mOwnerPawn;
var TMAbilityTargetPainter mAbilityTargetPainter;


simulated function SetupTurtleProjectile( ParticleSystem inProjectileParticle, ParticleSystem inOnHitParticle, TMPlayerController inTMPC, int inDamage, int inRadius, TMPawn inOwnerPawn )
{
	mDamage = inDamage;
	mRadius = inRadius;

	mOwnerPawn = inOwnerPawn;

	super.SetupProjectile( inProjectileParticle, inOnHitParticle, inTMPC, inOwnerPawn.GetAllyId() );
}

simulated function SetAbilityHelper( TMAbilityHelper inAbilityHelper )
{
	m_AbilityHelper = inAbilityHelper;
}

simulated function FireTurtleRocket( vector inTargetLocation )
{
	local vector launchVector;

	mTargetLocation = inTargetLocation;

	launchVector.Z = 1500;

	self.Velocity = launchVector;

	PlayFiringVFX();
	SetPhysics( PHYS_Falling );
	mType = PT_LOB;

	SetTimer( mUpdateFrequency, true, 'CheckRocketTrajectory', self );

	// Set the ability target painter
	mAbilityTargetPainter = new class'TMAbilityTargetPainter'();
	mAbilityTargetPainter.SetupAbilityTargetPainter( mOwnerPawn, mTargetLocation, mRadius );
}

simulated function CheckRocketTrajectory()
{
	local vector newVelocity;

	if ( Location.Z > 750 )
	//if ( Velocity.Z <= 0 )
	{
		//`log( "FIRING!", true, 'TMProjectileTurtleRocket' );
		ClearTimer( 'CheckRocketTrajectory', self );

		Velocity.X = 0;
		Velocity.Y = 0;
		Velocity.Z = 0;

		SuggestTossVelocity( newVelocity, mTargetLocation, Location, 2000, Velocity.Z,,,, self.GetGravityZ() );

		/*
		newVelocity = Normal( mTargetLocation - Location );
		newVelocity *= 1000;
		*/
		Velocity = newVelocity;
		SetTimer( mUpdateFrequency, true, 'CheckIfHit', self );
	}
}

simulated function CheckIfHit()
{
	if ( Location.Z < mTargetLocation.Z )
	{
		//`log( "Depth hit", true, 'Taylor_TMProjectileTurtleRocket' );
		
		if ( !self.SetLocation( mTargetLocation ) )
		{
			`log( "SetLocation failed", true, 'Taylor_TMProjectileTurtleRocket' );
		}
		//Location = mTargetLocation;     // this is potentially dangerous. We'll see
		ClearTimer( 'CheckIfHit', self );
		HitTarget();
		return;
	}

	super.CheckIfHit();
}

simulated function HitTarget()
{
	// Clean up ability paint
	mAbilityTargetPainter.Cleanup();

	m_AbilityHelper.DoDamageInRadius( mDamage, mRadius, mTargetLocation );

	super.HitTarget();
}

simulated event Destroyed()
{
	if( mAbilityTargetPainter != none )
	{
		mAbilityTargetPainter.Cleanup();
	}

	super.Destroyed();
}

DefaultProperties
{
}
