class TMComponentTugOfWar extends TMComponent;

var bool m_recentBlueDamage;
var bool m_recentRedDamage;
var float m_lastHealthTugOfWar;
var array<float> m_recentDamage;

var float m_maxTotalHealth;
var float m_currentHealth;

var int m_active;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_maxTotalHealth = json.GetFloatValue("MaxHealth");
	m_currentHealth = m_maxTotalHealth/2;
	m_active = json.GetIntValue("active");

}

function TMComponent makeCopy(TMPawn newowner) 
{
	local TMComponentTugOfWar newcomp;
	newcomp = new() class'TMComponentTugOfWar' (self);
	newcomp.m_owner = newowner;
	newcomp.m_maxTotalHealth = m_maxTotalHealth;
	newcomp.m_currentHealth = m_currentHealth;
	newcomp.m_active = m_active;
//	newowner.Health = newcomp.m_currentHealth;
//	newowner.HealthMax = newcomp.m_maxTotalHealth;
	m_recentBlueDamage = false;
	m_recentRedDamage = false;
	m_lastHealthTugOfWar = newowner.Health;
	return newcomp;
}


function bool IsAuthority()
{
	return (m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone);
}

function TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local TMPlayerReplicationInfo tmPRI;
	local TMPawn pw;

	pw = TMPawn(DamageCauser);
	tmPRI = TMPlayerReplicationInfo(pw.OwnerReplicationInfo);
	

	
	if(pw != none && IsAuthority() && m_owner.bCanBeDamaged)
	{   
		if(tmPRI.allyId == 0)
		{
			m_owner.SuperTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
		}
		else 
		{
			m_owner.Health += DamageAmount;
			if(m_owner.Health >= m_owner.HealthMax)
			{
				m_owner.SuperTakeDamage(m_owner.Health + 5, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
			}
		}
	}

}

function UpdateComponent(float dt)
{
	local int recentDamageSum;
	local int index;
	
	super.UpdateComponent(dt);

	recentDamageSum = 0;

	// Add last tick's damage
	m_recentDamage.AddItem(m_lastHealthTugOfWar - m_owner.Health);
		
	// Total recent damage taken
	for (index = 0; index < m_recentDamage.Length; index++)
	{
		recentDamageSum += m_recentDamage[index];
	}

	// Keep 60 ticks of history
	if (m_recentDamage.Length > 60)
	{
		m_recentDamage.Remove(0, 1); // Dru TODO: Is this pop_front()'ing a 60-item array every tick and rescaling? >.<
	}

	if (recentDamageSum > 0)
	{
		m_recentBlueDamage = true;
		m_recentRedDamage = false;
	}
	else if (recentDamageSum < 0)
	{
		m_recentRedDamage = true;
		m_recentBlueDamage = false;
	}
	else
	{
		m_recentBlueDamage = false;
		m_recentRedDamage = false;
	}

	//update last health
	m_lastHealthTugOfWar = m_owner.Health;
}


DefaultProperties
{
}
