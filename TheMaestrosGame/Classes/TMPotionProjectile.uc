class TMPotionProjectile extends TMAbilityProjectileOLD;

var string m_potionType;

simulated function BuildAndSendFE()
{
	local TMPotionProjectileFE ppfe;
	
	ppfe = class'TMPotionProjectileFE'.static.create(m_targetLocation, m_owner.pawnId, m_target.pawnId, m_callBackString, m_potionType);

	m_owner.SendFastEvent( ppfe );
}

// Dru TODO: is this actually used? Why?
function SendMessageBack()
{
	local TMFastEvent fe;
	
	if(self.IsAuthority() )
	{
		fe = new () class'TMFastEvent';
		fe.commandType = m_callBackString;
		fe.pawnId = m_owner.pawnId;
		fe.position1 = m_targetLocation;
		fe.string1 = m_potionType;
		m_owner.SendFastEvent( fe );
	}
}

simulated function FirePotionProjectile(TMPawn target, TMPawn owningpawn, ParticleSystem ps, float projSpeed, string callBack, string potionType)
{
	local Vector direction;
	if(target.Health <= 0 || target == none)
	{
		Destroy();
		return;
	}

	m_target = target;
	m_potionType = potionType;
	m_owner = owningpawn;
	m_speed = projSpeed;
	m_shootAndForget = false;
	m_callBackString = callBack;

	direction = Normal( target.Location - Location );
	Velocity += direction * m_speed;

	if( m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc = WorldInfo.MyEmitterPool.SpawnEmitter( ps, Location, Rotation,self, );
		AttachComponent(psc);
	}

	SetTimer(1/10,true,'UpdateDirection');
}