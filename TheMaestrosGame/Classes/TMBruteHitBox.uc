class TMBruteHitBox extends StaticMeshActor;

var TMPawn m_owner;
var float m_timeSinceLastTouch;
var array<TMPawn> m_hitPawns;
var int m_damage;


function InitHitBox(int damage, TMPawn pw)
{
	m_owner = pw;
	m_timeSinceLastTouch = 0;
	m_damage = damage;
}

event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{

	if( TMPawn(Other) != none)
	{
		m_timeSinceLastTouch = 0;
		m_hitPawns.AddItem( TMPawn(Other) );
	
	}
}

function ApplyDamage()
{
	local int i;
	for(i = 0;i < m_hitPawns.Length ;i++)
	{
		if(TMPlayerReplicationInfo(m_hitPawns[i].OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId)
		{
			m_hitPawns[i].TakeDamage(m_damage, m_owner.Controller, m_hitPawns[i].Location, m_hitPawns[i].Location, class'DamageType',,m_owner);
		}	
	}

}


simulated event tick(float deltaTime)
{
	if( m_timeSinceLastTouch > 0.2f)
	{
		ApplyDamage();
		Destroy();
	}
	else
	{
		m_timeSinceLastTouch +=deltaTime;
	}

}




DefaultProperties
{
	m_damage = 200;
	Begin Object Class=StaticMeshComponent Name=UnitStaticMesh
		StaticMesh=StaticMesh'TM_Brute_AbilityBox.MyMesh'
	End Object
	CollisionComponent=UnitStaticMesh
	Components.Add(UnitStaticMesh)
	CollisionType=COLLIDE_TouchAll
	bNoDelete=false
	bStatic=false
	bBlockActors=false;

}
