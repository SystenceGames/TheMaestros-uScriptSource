class TMProjectilePush extends TMProjectile;

var int mCollisionRadius;
var int mExplosionRadius;
var int mSightRadius;
var float mDamagePercentage;
var int mMaxDamage;
var bool mIsTriggered;
var vector m_lastInterval;
var float m_range;

var string mCallBack;
var bool mHitTarget;

simulated function UpdatePush()
{
	local TMAbilityFE fe;
	if ( mIsTriggered )
	{
		return;
	}
	if(VSize(location - m_lastInterval)> 100) {
		
		fe = new () class'TMAbilityFE';
		fe.commandType = mCallBack;
		fe.abilityLocation = location;
		fe.pawnId = m_owner.pawnId;
		m_owner.SendFastEvent(fe);
		m_lastInterval=location;
	}
    if(VSize(location  - mOriginalLocation) > m_range) {
		cleanup();
    }
}

simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local TMPawn tempPawn;
	
	tempPawn = TMPawn(Other);

	if ( !class'UDKRTSPawn'.static.IsValidPawn(m_owner) || !class'UDKRTSPawn'.static.IsValidPawn(tempPawn) )
	{
		return;
	}

	if( !m_owner.IsAuthority() )
	{
		return;
	}

	if ( mHitTarget )
	{
		return;
	}

	if( tempPawn.m_allyId != m_owner.m_allyId )
	{
		tempPawn.m_Unit.SendStatusEffect( SE_GRAPPLER_KNOCKBACK );		
		tempPawn.GetForcePushed(Velocity);
		tempPawn.TakeDamage( 0, m_owner.m_TMPC, tempPawn.Location, tempPawn.Location, class'DamageType',, m_owner.m_TMPC );
	}
}

simulated function FirePush(Vector targetLocation, TMPawn owningpawn, ParticleSystem ps, float projSpeed, int collisionRadius, float range, string callBack)
{
	local Vector direction;
	mCallBack = callBack;
	m_owner = owningpawn;
	mOriginalLocation = m_owner.Location;
	m_speed = projSpeed;
	m_lastInterval = mOriginalLocation;
	direction = Normal( targetLocation - mOriginalLocation );
	m_range = range;
	mHitTarget = false;

	// Make sure direction is non-zero. NOTE: this will probably never ever happen.
	if ( IsZero(direction) )
	{
		direction = Normal( Vector( m_owner.Rotation ) );   // just shoot it in front of you
	}
	Velocity += direction * m_speed;
	SetTimer(1/10,true,'UpdatePush');
	mCollisionRadius = collisionRadius;
	mIsTriggered = false;

	SetTimer( 5.0f, false, 'Cleanup', self );     // destroy after 10 seconds. This is bad :( should be doing a bounds check, but our BB isn't working
	
	ProjectileSetup(owningpawn,ps);
}

function DoOnHitVFX()
{
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithRotationAndScale( m_onHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), Location, Rotation, 2.0f );
	
	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer && m_onHitParticle != none && !psc.HiddenGame )
	{
		m_owner.m_TMPC.m_AudioManager.requestPlaySFXWithActor(SoundCue'SFX_Dynamics.Dynamics_SFX_Shrine_Explosion', m_owner);
	}
}

function Cleanup()
{
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
	bCollideWorld = false       // Push needs to go through walls
	bCollideActors = true

	Begin Object  Name=CollisionCylinder
	CollisionRadius=200
	CollisionHeight=90
	AlwaysLoadOnClient=True
	CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CollisionType=COLLIDE_TouchAll
	Components.Add(CollisionCylinder)
}
