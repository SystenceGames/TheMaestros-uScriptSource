class TMSpawnProjectile extends Projectile;

var ParticleSystemComponent psc;
var ParticleSystem m_onHitParticle;
var TMPawn m_owner;
var string m_callBackString;
var float m_speed;
var Vector m_lobbedProjectileLocation;


simulated singular event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{

}

simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{

}

event Tick( float DeltaTime )
{
	if( m_owner != none)
	{
		if( psc != none )
		{
			psc.SetHidden(!m_owner.m_Controller.GetFoWManager().IsLocationVisible(Location));
		}
	}
}



function SendMessageBack()
{
	local TMAttackFe fe;
	fe = new () class'TMAttackFE';
		fe.commandType = m_callBackString;
		fe.pawnId = m_owner.pawnId;
		m_owner.SendFastEvent( fe );
}

function CheckIfHitTarget()
{
	local float difference;
	local Vector loc;
	difference = VSize(m_lobbedProjectileLocation - self.Location);
	if( difference < 50)
	{
		loc = Location;
		loc.Z -= 40;
		m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithRotation(m_onHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), loc, Rotation);

		SendMessageBack();
		Destroy();
	}
}


function SetOnHitParticle(ParticleSystem ps)
{  
	m_onHitParticle = ps;
}

function bool IsAuthority()
{
	return ((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone));
}


simulated function FireLobbedProjectileAtPosition(Vector target, TMPawn owningPawn, ParticleSystem ps, float lobbSpeed, optional string callBackEvent, optional float angle)
{
	local Vector lobbVelocity;


	if(angle == 0)
	{
		angle = 0.5f;
	}

	m_owner = owningPawn;
	m_lobbedProjectileLocation= target;

	if(callBackEvent != "")
	{
		m_callBackString = callBackEvent;
	}
	

	if(SuggestTossVelocity(lobbVelocity, target, Location, lobbSpeed, 0, angle,,, self.GetGravityZ() ,))
	{
	
		Velocity += lobbVelocity;
	}
	else
	{
		SendMessageBack();
		`log("Couldnt lob the projectile");
		Destroy();
		return;
	}

	

	SetPhysics( PHYS_Falling );
	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc = WorldInfo.MyEmitterPool.SpawnEmitter( ps, Location, Rotation,self, );
		AttachComponent(psc);
	}

	SetTimer(1/15,true,'CheckIfHitTarget');
}

DefaultProperties
{
	
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
	End Object
	psc=MyParticleSystemComponent
	CollisionComponent=MyParticleSystemComponent
	Components.Add(MyParticleSystemComponent)
	
	
	Begin Object  Name=CollisionCylinder
		CollisionRadius=10
		CollisionHeight=10
		AlwaysLoadOnClient=True
		AlwaysLoadOnServer=True
		BlockNonZeroExtent=true
		BlockZeroExtent=true
		BlockActors=true
		CollideActors=true
	End Object

	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)


}
