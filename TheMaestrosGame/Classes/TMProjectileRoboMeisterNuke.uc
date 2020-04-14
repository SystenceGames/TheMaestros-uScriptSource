class TMProjectileRoboMeisterNuke extends TMProjectile;

var int mCollisionRadius;
var int mExplosionRadius;
var int mSightRadius;
var float mDamagePercentage;
var int mMaxDamage;
var bool mIsTriggered;

var TMFOWRevealActor mRevealPawn;

var bool mHitTarget;


simulated function UpdateNuke()
{
//	local TMPawn tempPawn;
//	local array<TMPawn> pawns;
//	local TMAbilityFE fe;

	

	/*if ( !IsAuthority() )
	{
		return;
	}*/

	if ( mIsTriggered )
	{
		return;
	}

	mRevealPawn.SetLocation( Location + Velocity * (class'TMFOWManagerClient'.static.GetFoWUpdateInterval()) );

	if(m_owner.m_TMPC.bCameraFollowNuke)
	{
		TMCamera(m_owner.m_TMPC.PlayerCamera).LerpTo( Location + Velocity * 2.f * (class'TMFOWManagerClient'.static.GetFoWUpdateInterval()), 3, 0);
	}

}

simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local TMPawn tempPawn;
	local TMAbilityFE fe;

	if(m_owner == none || !self.IsAuthority())
	{
		return;
	}

	if ( mHitTarget  || !m_owner.IsAuthority())
	{
		return;
	}

	tempPawn = TMPawn(Other);
	if( tempPawn != none &&
		!tempPawn.IsGameObjective() &&
			( !m_owner.IsPawnNeutral( tempPawn ) || tempPawn.bCanBeHitByNuke ) &&
			TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId &&
			tempPawn.Health > 0 )
		{
			
			
			fe = new () class'TMAbilityFE';
			fe.commandType = "C_RoboMeister_Nuke_Hit";
			fe.pawnId = m_owner.pawnId;
			m_owner.SendFastEvent(fe);
			mIsTriggered = true;
			mHitTarget = true;
			return;
			ExplodeNuke();
			return;
	}
}

simulated function FireNuke(Vector targetLocation, TMPawn owningpawn, ParticleSystem ps, float projSpeed, float damagePercentage, int maxDamage, int explosionRadius, int collisionRadius, int sightRadius)
{
	local Vector direction;
	

	mOriginalLocation = targetLocation;
	m_owner = owningpawn;
	mDamagePercentage = damagePercentage;
	mMaxDamage = maxDamage;
	m_speed = projSpeed;
	m_LastKnownLocation = targetLocation;
	direction = Normal( m_LastKnownLocation - m_owner.Location );
	mHitTarget = false;
	bApplyFow = true;

	// Make sure direction is non-zero. NOTE: this will probably never ever happen.
	if ( direction.X == 0 &&
		direction.Y == 0 &&
		direction.Z == 0 )
	{
		direction = Normal( Vector( m_owner.Rotation ) );   // just shoot it in front of you
	}

	Velocity += direction * m_speed;
	SetTimer(1/10,true,'UpdateNuke');
	mExplosionRadius = explosionRadius;
	mCollisionRadius = collisionRadius;
	mSightRadius = sightRadius;
	mIsTriggered = false;

	SetTimer( 10.0f, false, 'Cleanup', self );     // destroy after 10 seconds. This is bad :( should be doing a bounds check, but our BB isn't working

	mRevealPawn = m_owner.Spawn( class'TMFOWRevealActorStatic',,, m_owner.Location,,, true);
	mRevealPawn.Setup( TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyInfo.allyIndex, m_owner.m_Controller.GetFoWManager(), mSightRadius, true );

	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc = WorldInfo.MyEmitterPool.SpawnEmitter( ps, Location, Rotation,self, );
		AttachComponent(psc);
	}
}

simulated function ExplodeNuke()
{
	local TMPawn tempPawn;
	local array<TMPawn> pawns;
	//local TMAbilityFE fe;

	DoOnHitVFX();

	//fe = new () class'TMAbilityFE';
	//fe.commandType = "C_RoboMeister_Nuke_Hit";
	//fe.pawnId = m_owner.pawnId;
	//m_owner.SendFastEvent(fe);

	pawns = m_owner.m_TMPC.GetTMPawnList();

	foreach pawns( tempPawn )
	{
		if( tempPawn != none &&
			!tempPawn.IsGameObjective() &&
			TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId &&
			tempPawn.Health > 0 )
		{
			if ( IsInRange( Location, tempPawn.Location, mExplosionRadius ) )
			{
				tempPawn.TakeDamage( GetDamage(tempPawn),m_owner.Controller, tempPawn.Location, tempPawn.Location, class'DamageType',,m_owner);
			}
		}
	}

	Cleanup();
}

function int GetDamage( TMPawn target )
{
	local int dam;
	dam = target.HealthMax*mDamagePercentage;

	if ( dam > mMaxDamage )
	{
		return mMaxDamage;
	}

	return dam;
}

function DoOnHitVFX()
{
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithRotationAndScale(m_onHitParticle, m_allyId, m_teamColorIndex, Location, Rotation, 2.0f);

	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer && m_onHitParticle != none && !psc.HiddenGame )
	{
		if(!m_owner.bHidden){
			m_owner.m_TMPC.m_AudioManager.requestPlaySFXWithActor(SoundCue'SFX_Dynamics.Dynamics_SFX_Shrine_Explosion', m_owner);
		}
	}
}

function Cleanup()
{
	if(m_owner.m_TMPC.bCameraFollowNuke)
	{
		TMCamera(m_owner.m_TMPC.PlayerCamera).LerpTo( Location, 3, 0);
	}

	mRevealPawn.Destroy();
	Destroy();
}


////// OVERRIDES //////
//event Tick( float DeltaTime ) {}
//simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal ) {}
simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp) {}
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal) {}
simulated function Explode(vector HitLocation, vector HitNormal) {}

DefaultProperties
{
	bCollideWorld = false       // nuke needs to go through walls
	bCollideActors = true


	Begin Object  Name=CollisionCylinder
	CollisionRadius=50
	CollisionHeight=90
	AlwaysLoadOnClient=True
//	//AlwaysLoadOnServer=True
	//BlockNonZeroExtent=true
	//BlockZeroExtent=true
	//BlockActors=true
	CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CollisionType=COLLIDE_TouchAll
	Components.Add(CollisionCylinder)
}
