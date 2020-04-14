class TMProjectile extends Projectile;

var ParticleSystemComponent psc;
var ParticleSystem m_onHitParticle;
var TMPawn m_target, m_owner;
var Vector m_LastKnownLocation;
var Vector m_lobbedProjectileLocation;
var Vector mOriginalLocation;
var string m_callBackString;
var float m_speed;
var float m_damage;
var float delta;
var bool m_shootAndForget;
var float m_distanceOfFireAndForget;
var bool mIsAoE;
var int mAoERadius;
var float mAoEPercentDamage;
var int mParticleOnHitScale;
var bool bApplyFow;
var int m_allyId;
var int m_teamColorIndex;

function UpdateDirection()
{
	local Vector direction;
	
	if( m_shootAndForget )
	{
		if(VSize(m_LastKnownLocation - Location) >= m_distanceOfFireAndForget)
		{
			Destroy();
		}
		return;
	}

	if(m_owner == none || !class'UDKRTSPawn'.static.IsValidPawn( m_target ) )
	{
		Destroy();
	}

	self.Velocity = direction;
	m_LastKnownLocation = m_target.Location;
	direction = Normal(m_target.Location - Location);
	Velocity = direction * m_speed;
		
	if(VSize2D(m_target.Location - Location) < VSize2D(direction * m_speed * delta))
	{
		Touch(m_target,none,direction,direction);
	}
	
	self.SetRotation( Rotator(m_target.Location - Location) );
}

event Tick( float DeltaTime )
{
	delta = DeltaTime;
	if( m_owner != none)
	{
		if( bApplyFow && psc != none )
		{
			psc.SetHidden(!m_owner.m_Controller.GetFoWManager().IsLocationVisible(Location));
		}
	}
}

simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	local TMPawn tm_pawn;

	tm_pawn = TMPawn(Other);

	if(false == class'UDKRTSPawn'.static.IsValidPawn(tm_pawn))
	{
		return;
	}

	if( m_shootAndForget && tm_pawn.m_allyId != m_allyId )
	{
		if( IsAuthority() )
		{
			HitTarget( tm_pawn );
		}

		Destroy();
		return;
	}
			
	if( !m_shootAndForget && m_target != none) 
	{
		if(tm_pawn.pawnId == m_target.pawnId)
		{
			//this is used by the potion stuff, will provide a callback to the owner of this thing  of the callback
			if(m_callBackString != "")
			{
				if(m_owner != none && m_callBackString != "dontSend")
				{
					BuildAndSendFE();
				}
				Destroy();
				return;
			}

			m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale(m_onHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), Location, mParticleOnHitScale);

			if( IsAuthority() )
			{
				HitTarget( m_target );
			}
			
			Destroy();
		}
	}
}

// Dru TODO: Why BuildAndSend? Just Send?
simulated function BuildAndSendFE()
{
	local TMAttackFE fe;
	fe = new () class'TMAttackFe';
	fe.commandType = m_callBackString;
	fe.pawnId = m_owner.pawnId;
	fe.targetId = m_target.pawnId;
	m_owner.SendFastEvent( fe );
}

simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{   
	if( m_shootAndForget )
	{
		Destroy();
	}
}

simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{

}

simulated function Explode(vector HitLocation, vector HitNormal)
{

}


function CheckIfHitTarget()
{
	local float difference;

	difference = VSize(m_lobbedProjectileLocation - self.Location);
	if( difference < 50)
	{
		if(m_owner != none)
		{
			m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnId,m_callBackString) );
		}
		Destroy();
	}

}


function SetOnHitParticle(ParticleSystem ps, optional int scale)
{  
	m_onHitParticle = ps;

	if( scale != 0 )
	{
		mParticleOnHitScale = scale;
	}
	else
	{
		mParticleOnHitScale = 1;
	}
}

function bool IsAuthority()
{
	return ((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone));
}

function HitTarget( TMPawn target )
{
	local array<TMPawn> pawnArray;
	local int i;

	if( !mIsAoE )   // single target damage
	{
		target.TakeDamage(m_damage,m_owner.Controller, target.Location, target.Location, class'DamageType',,m_owner);
	}
	else            // AoE Damage
	{
		target.TakeDamage(m_damage,m_owner.Controller, target.Location, target.Location, class'DamageType',,m_owner);

	
		pawnArray = m_owner.m_TMPC.GetTMPawnList();
		for(i=0;i< pawnArray.Length; i++)
		{
			if( pawnArray[i] != none &&
				pawnArray[i].pawnId != target.pawnId &&
				TMPlayerReplicationInfo(pawnArray[i].OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId &&
				pawnArray[i].Health > 0 )
			{
				if ( IsInRange( Location, pawnArray[i].Location, mAoERadius ) )
				{
					pawnArray[i].TakeDamage( m_damage*mAoEPercentDamage, m_owner.Controller, pawnArray[i].Location, pawnArray[i].Location, class'DamageType',,m_owner );
				}
			}
		}
	}
}

simulated function ProjectileSetup(TMPawn owningPawn, ParticleSystem ps)
{
	m_owner = owningPawn;
	m_allyId = m_owner.GetAllyId();
	m_teamColorIndex = m_owner.GetTeamColorIndex();

	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc = WorldInfo.MyEmitterPool.SpawnEmitter( ps, Location, Rotation,self, );
		AttachComponent(psc);
	}
}

simulated function bool FireLobbedProjectileAtPosition(Vector target, TMPawn owningPawn, ParticleSystem ps, float lobbSpeed, optional string callBackEvent, optional float angle)
{
	local Vector lobbVelocity;

	ProjectileSetup(owningPawn, ps);

	if(angle == 0)
	{
		angle = 0.5f;
	}

	m_lobbedProjectileLocation= target;

	if(SuggestTossVelocity(lobbVelocity, target, Location, lobbSpeed, 0, angle,,, self.GetGravityZ() ,))
	{
		Velocity += lobbVelocity;
	}
	else
	{
		`log("Couldnt lob the projectile");
		Destroy();
		return false;
	}

	if(callBackEvent != "")
	{
		m_callBackString = callBackEvent;
	}

	SetPhysics( PHYS_Falling );

	SetTimer(1/10,true,'CheckIfHitTarget');
	return true;
}

simulated function FireProjectile(TMPawn target, TMPawn owningpawn, ParticleSystem ps, float projSpeed, float damageOnHit, optional bool dontFollowTarget,optional float distanceOfFireAndForget, optional bool isAoE, optional int aoeRadius, optional float aoePercentDamage )
{
	local Vector direction;
	
	ProjectileSetup(owningPawn, ps);

	m_target = target;

	mIsAoE = isAoE;
	if( mIsAoE )
	{
		mAoERadius = aoeRadius;
		mAoEPercentDamage = aoePercentDamage;
	}

	if(m_target.Health <= 0 || m_target == none)
	{
		Destroy();
		return;
	}
	
	m_damage = damageOnHit;
	m_speed = projSpeed;
	if(dontFollowTarget )
	{
		m_LastKnownLocation = Location;
	}
	else
	{
		m_LastKnownLocation = target.Location;
	}
	direction = Normal( target.Location - Location );
	Velocity += direction * m_speed;
		
	//this will only be used if you supplied it
	m_distanceOfFireAndForget = distanceOfFireAndForget;
	m_shootAndForget = dontFollowTarget;

	m_distanceOfFireAndForget = distanceOfFireAndForget;
	m_shootAndForget = dontFollowTarget;
	SetTimer(1/10,true,'UpdateDirection');
}

// We need a global place for this function :(
function bool IsInRange(Vector location1, Vector location2, int range)
{
	local int rangeSq;
	rangeSq = range*range;
	return (VSizeSq(location1 - location2) < rangeSq);
}

DefaultProperties
{
	delta = 0.2f;
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
	End Object
	psc=MyParticleSystemComponent
	//CollisionComponent=MyParticleSystemComponent
	Components.Add(MyParticleSystemComponent)
	
	
	Begin Object  Name=CollisionCylinder
		CollisionRadius=10
		CollisionHeight=10
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

	bCollideWorld = false
	bApplyFow = true;
}
