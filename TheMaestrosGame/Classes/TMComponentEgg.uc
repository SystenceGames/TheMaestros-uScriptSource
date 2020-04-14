class TMComponentEgg extends TMComponent;

var float m_SpawnTimer;
var string m_ResultUnitType;
var bool m_UnitSpawned;

var ParticleSystem m_TransformParticleEffect;
var ParticleSystemComponent m_CurrentEffect;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_Owner = parent;
	m_SpawnTimer = json.GetFloatValue("SpawnTimer");
	m_UnitSpawned = false;
}

function TMComponent makeCopy(TMPawn newowner) 
{
	local TMComponentEgg newComp;
	
	newComp = new() class'TMComponentEgg' (self);
	newComp.m_owner = newowner;
	newComp.m_SpawnTimer = self.m_SpawnTimer;
	newComp.m_ResultUnitType = self.m_ResultUnitType;
	m_UnitSpawned = false;

	return newComp;
}

function ReceiveFastEvent(TMFastEvent event)
{
	if(m_Owner.m_TMPC != none)
	{
		if(event.commandType == "C_EggEvent")
		{
			m_ResultUnitType = event.string1;
		}
	}
}

function UpdateComponent(float dt)
{
	local TMPawn newUnit;
	local Vector vCachedPosition;
	local GameInfo cachedGameInfo;
	local UDKRTSPlayerReplicationInfo cachedRepInfo;

	if(m_Owner == None)
		return;

	m_SpawnTimer -= dt;

	if(m_SpawnTimer <= 0 && !m_UnitSpawned)
	{
		m_UnitSpawned = true;

		if( m_Owner.m_TMPC != None )
		{
			m_Owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale(m_TransformParticleEffect, m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_Owner.Location, 1.5f);
		}

		// Only do actual spawning on the server
		if(m_Owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer && m_Owner.m_TMPC.WorldInfo.NetMode != NM_ListenServer && m_Owner.m_TMPC.WorldInfo.NetMode != NM_Standalone)
			return;

		vCachedPosition = m_Owner.Location;
		cachedGameInfo = m_Owner.WorldInfo.Game;
		cachedRepInfo = m_Owner.OwnerReplicationInfo;

		m_Owner.OwnerReplicationInfo.Population -= m_Owner.PopulationCost;
		m_Owner.removeActiveSelection();
		m_Owner.Destroy();

		newUnit = TMGameInfo(cachedGameInfo).RequestUnit(m_ResultUnitType, TMPlayerReplicationInfo(cachedRepInfo), vCachedPosition, false, vCachedPosition, None, true);
		newUnit.SendFastEvent(class'TMFastEventSpawn'.static.create(newUnit.pawnId, newUnit.Location, true));
		
		/*
		newUnit = TMGameInfo(m_Owner.WorldInfo.Game).RequestUnit(m_ResultUnitType, TMPlayerReplicationInfo(m_Owner.OwnerReplicationInfo), vCachedPosition, false, vCachedPosition, None, true);
		newUnit.SendFastEvent(class'TMFastEventSpawn'.static.create(newUnit.pawnId, newUnit.Location, true));
		*/
	}
}

DefaultProperties
{
	m_TransformParticleEffect = ParticleSystem'VFX_Adam.Particles.P_NeutralOrb_SpawnAlchemist';
}
