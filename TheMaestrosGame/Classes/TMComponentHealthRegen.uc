class TMComponentHealthRegen extends TMComponent;

var float m_healthRegenPerSecond;
var float m_time;
var float m_timeNeededToStartHealthRegen;
function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_healthRegenPerSecond = 	json.GetFloatValue("HealthR")/100;
	m_timeNeededToStartHealthRegen = json.GetFloatValue("HealthT");
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentHealthRegen hr;

	hr = new () class'TMComponentHealthRegen';
	hr.m_owner = newowner;
	hr.m_healthRegenPerSecond = m_healthRegenPerSecond;
	hr.m_timeNeededToStartHealthRegen = m_timeNeededToStartHealthRegen;
	return hr;
}
function bool IsAuthority()
{
	return ((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone));
}

function UpdateComponent(float dt)
{
	if(m_owner.m_TMPC == none) {
		return;
	}
	if((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone))
	{

		if( TMAIController(m_owner.Controller) == none)
		{
			return;
		}

		if(TMAIController(m_owner.Controller).m_timeSinceLastAttack >= m_timeNeededToStartHealthRegen)
		{

			if( m_healthRegenPerSecond < 0)
			{
				m_time += dt;
				if(m_time >= 1)
				{
					m_time -= 1;
					if( IsAuthority() )
					{
						m_owner.TakeDamage(m_healthRegenPerSecond * -1, m_owner.Controller, m_owner.Location, m_owner.Location, class'DamageType',,m_owner);
					}
	
				}
			
			}
			else if(m_owner.Health < m_owner.m_Unit.m_Data.health)
			{
				m_time += dt;
				if(m_time >= 1)
				{
					m_time -= 1;
					m_owner.Health += m_healthRegenPerSecond;
				
					if(m_owner.Health > m_owner.m_Unit.m_Data.health)
					{
						m_owner.Health = m_owner.m_Unit.m_Data.health;
					}
				}
			}
			else 
			{
				m_time = 0;
			}
		}
	}
}


DefaultProperties
{
}
