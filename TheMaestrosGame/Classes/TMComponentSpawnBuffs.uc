class TMComponentSpawnBuffs extends TMComponent;


var float m_fDuration;
var float m_fSpeedIncreasePercent;
var float m_fDamageIncreasePercent;
var int m_bActive;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_bActive = json.GetIntValue("active");
	if(m_bActive == 1)
	{
		m_fDuration = json.GetFloatValue("duration");
		m_fSpeedIncreasePercent = json.GetFloatValue("speedPercent");
		m_fDamageIncreasePercent = json.GetFloatValue("damagePercent");
	}
}


function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentSpawnBuffs newcomp;

	newcomp= new () class'TMComponentSpawnBuffs' (self);
	newcomp.m_fDamageIncreasePercent = m_fDamageIncreasePercent;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fSpeedIncreasePercent = m_fSpeedIncreasePercent;
	newcomp.m_owner = newowner;
	newcomp.m_bActive = m_bActive;
	return newcomp;
}

function RemoveBuffs()
{
	local int i;
	local array<TMPawn> pawnList;
	if(m_owner == none)
	{
		return;
	}
	pawnList =  TMPlayerReplicationInfo(m_owner.m_TMPC.PlayerReplicationInfo).m_PlayerUnits;
	 for(i=0;i < pawnList.Length; i++)
	 {
			if(pawnList[i].m_owningPlayerId == m_owner.m_TMPC.PlayerId)
			{
				pawnList[i].m_Unit.m_fDamagePercentIncrease = 1;
				pawnList[i].GroundSpeed = pawnList[i].m_Unit.m_Data.moveSpeed;
			}
	 }

}

function ApplyBuffs()
{
	local int i;
	local array<TMPawn> pawnList;

	if(m_owner == none)
	{
		return;
	}
	pawnList = TMPlayerReplicationInfo(m_owner.m_TMPC.PlayerReplicationInfo).m_PlayerUnits;
	 for(i=0;i < pawnList.Length; i++)
	 {
			if(pawnList[i].m_owningPlayerId == m_owner.m_TMPC.PlayerId)
			{
				pawnList[i].m_Unit.m_fDamagePercentIncrease = self.m_fDamageIncreasePercent;
				pawnList[i].GroundSpeed *= self.m_fSpeedIncreasePercent;
			}
	 }
}


function WaitForUnitsToSpawn()
{
	if(TMPlayerReplicationInfo(m_owner.m_TMPC.PlayerReplicationInfo).m_startingUnits <=  TMPlayerReplicationInfo(m_owner.m_TMPC.PlayerReplicationInfo).m_PlayerUnits.Length)
	{
		ApplyBuffs();
		m_owner.SetTimer(m_fDuration,false,'RemoveBuffs',self);
		m_owner.ClearTimer('WaitForUnitsToSpawn',self);
	}
	
}

function ReceiveFastEvent(TMFastEvent event)
{
	if(event.commandType == "C_SpawnFinished")
	{
		//did this, cuz we we will only call it wont, dont need to evaluate twice in an if statement
		if(m_owner.IsAuthority() && self.m_bActive == 1)
		{
			m_owner.SetTimer(1/10,true,'WaitForUnitsToSpawn',self);
		//	ApplyBuffs();
			//
		}
	}
}

function HandleStopFE()
{
}


DefaultProperties
{
}
