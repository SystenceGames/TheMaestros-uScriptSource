class TMProjectileMagicMissiles extends TMTaylorProjectile;


var int mRadius;
var int mDamage;

var TMPawn mOwnerPawn;
var TMAbilityTargetPainter mAbilityTargetPainter;


simulated function SetupMagicMissiles( TMPawn inOwnerPawn, ParticleSystem inProjectileParticle, ParticleSystem inOnHitParticle, int inRadius, int inDamage )
{
	mOwnerPawn = inOwnerPawn;
	mRadius = inRadius;
	mDamage = inDamage;

	super.SetupProjectile( inProjectileParticle, inOnHitParticle, mOwnerPawn.m_TMPC, inOwnerPawn.GetAllyId() );
}

simulated function FireMissiles( vector inTargetLocation )
{
	local vector launchVector;

	mTargetLocation = inTargetLocation;

	launchVector.Z = 1500;

	self.Velocity = launchVector;

	PlayFiringVFX();
	SetPhysics( PHYS_Falling );
	mType = PT_LOB;

	// Set the ability target painter
	mAbilityTargetPainter = new class'TMAbilityTargetPainter'();
	mAbilityTargetPainter.SetupAbilityTargetPainter( mOwnerPawn, mTargetLocation, mRadius );
	

	SetTimer( mUpdateFrequency, true, 'CheckEggTrajectory', self );
}

simulated function CheckMissileTrajectory()
{
	local vector newVelocity;

	if ( Location.Z > 750 )
	//if ( Velocity.Z <= 0 )
	{
		//`log( "FIRING!", true, 'TMProjectileTurtleRocket' );
		ClearTimer( 'CheckMissileTrajectory', self );

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
	local TMPawn tempPawn;
	local array< TMPawn > allPawnsList;
	local array< TMPawn > hitPawnsList;
	local int damageToDeal;

	// Check if the missile hits any pawns
	allPawnsList = mTMPC.GetTMPawnList();
	foreach allPawnsList( tempPawn )
	{
		// If the pawn is in range of the explosion
		if( tempPawn != none &&
			( VSizeSq( tempPawn.Location - mTargetLocation ) < mRadius*mRadius ) )
		{
			// Check if actor is bad guy
			if ( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId != mAllyID )
			{
				// Add him to my list of pawns I'm going to damage
				hitPawnsList.AddItem( tempPawn );
			}
		}
	}

	// TODO: make the particle effects that happen be badass and hint at what the ability is doing

	// Do damage to each pawn
	if( hitPawnsList.Length > 0 )
	{
		damageToDeal = mDamage / hitPawnsList.Length;
		`log( "TMProjectileMagicMissiles: Dealing " $damageToDeal$ " to " $hitPawnsList.Length$ ". Original damage: " $mDamage );
		foreach hitPawnsList( tempPawn )
		{
			tempPawn.TakeDamage( damageToDeal, mTMPC, tempPawn.Location, tempPawn.Location, class'DamageType' );
		}
	}

	super.HitTarget();

	// Clean up ability paint
	mAbilityTargetPainter.Cleanup();
}
