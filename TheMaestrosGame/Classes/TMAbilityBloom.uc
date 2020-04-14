class TMAbilityBloom extends TMAbility;

var float m_fGrassTick;
var vector m_vPreviousSpawn;
var int m_iSpawnDistance;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	//super.SetUpComponent(json, parent);
	m_owner = parent;
	m_fGrassTick = 0.05f;
	m_iSpawnDistance = 75;
	m_owner.SetTimer(m_fGrassTick, true, NameOf(SpawnGrass), self);
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityBloom newcomp;
	newcomp= new () class'TMAbilityBloom'(self);
	newcomp.m_owner=newowner;
	return newcomp;
}


function ShouldSpawnGrass(bool bSpawnGrass)
{
	if ( !bSpawnGrass )
	{
		m_owner.ClearTimer(NameOf(SpawnGrass),self);
		bSpawnGrass = true;
	}
	else 
	{
		m_owner.SetTimer(m_fGrassTick, true, NameOf(SpawnGrass), self);		
		bSpawnGrass = false;
	}
}



function SpawnGrass()
{
	if (!IsInRange(m_vPreviousSpawn, m_owner.Location, m_iSpawnDistance))
	{
		m_vPreviousSpawn = m_owner.Location;
		m_owner.Spawn(class'TMBloomGrass', none, 'none', m_owner.Location,,,);
	}
}
