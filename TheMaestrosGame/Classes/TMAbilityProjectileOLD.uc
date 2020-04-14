/* TMAbiltyProjectileOLD					This old one will soon be eaten by the new one.
 * A projectile fired for an ability.
 */

class TMAbilityProjectileOLD extends TMProjectile;

var Vector m_targetLocation;
function CheckForDestination()
{
	local Vector direction;
	direction = Normal(m_targetLocation - Location);
	Velocity = direction * m_speed;

	if(Vsize(m_targetLocation - Location) < Vsize(direction * m_speed * delta))
	{
		SendMessageBack();
		
		Destroy();
		return;
	}

	if(Location.Z < m_targetLocation.Z)
	{
		SendMessageBack();
		
		Destroy();
		return;
	}

	if(Vsize(Location - m_targetLocation) < 50 )
	{
		SendMessageBack();
		
		Destroy();
		return;
	}

}

function SendMessageBack()
{
	local TMProjectileFE fe;
	
	if(self.IsAuthority() )
	{
		fe = new () class'TMProjectileFE';
		fe.commandType = m_callBackString;
		fe.pawnId = m_owner.pawnId;
		fe.position1 = m_targetLocation;
		m_owner.SendFastEvent( fe );
	}
}

function FireAbilityProjectile(Vector targetLocation, TMPawn owningpawn, ParticleSystem ps, float projSpeed, string callBackString)
{
	local Vector direction;


	m_callBackString = callBackString;
	m_owner = owningpawn;
	//targetLocation.Z -= 50;
	m_speed = projSpeed;
	direction = Normal( targetLocation - Location );
	Velocity = direction * projSpeed;

	m_targetLocation = targetLocation;

	SetTimer( 1/10,true,'CheckForDestination');
	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc = WorldInfo.MyEmitterPool.SpawnEmitter( ps, Location, Rotation,self, );	
		AttachComponent(psc);
	}
}


DefaultProperties
{
	bCollideWorld = false
}
