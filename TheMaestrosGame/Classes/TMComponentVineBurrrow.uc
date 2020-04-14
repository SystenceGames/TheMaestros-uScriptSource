class TMComponentVineBurrrow extends TMComponent;

var float m_duration;
var float m_currentTime;
var bool m_fired;
var TMDecal m_decal;
var bool m_hidePawn;
function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_duration = json.GetFloatValue("duration");
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentVineBurrrow newcomp;
	newcomp= new () class'TMComponentVineBurrrow' (self);
	newcomp.m_owner = newowner;
	newcomp.m_duration = m_duration;
	newcomp.m_fired = false;
	newcomp.m_hidePawn = false;
	return newcomp;
}

//function to update whatever you need
function UpdateComponent(float dt)
{
	local TMFastEvent fe;
	local Vector vec;
	local Rotator rot;
	local TMAttackFE attackFe;

	if(m_hidePawn)
	{
		m_owner.m_Controller.GetFoWManager().HideAPawn(m_owner);
	}

	if(m_owner != none)
	{
		if(m_owner.m_currentState == TMPS_IDLE)
		{
			m_currentTime += dt;
		}
		else
		{
			m_currentTime = 0;
			if(m_decal != none)
			{
				m_decal.Destroy();
				m_decal = none;
			}
			
		
			if(m_fired)
			{
				m_owner.SetCollision(true,true,);
				attackFe = new () class'TMAttackFE';
				attackFe.pawnId = m_owner.pawnId;
				attackFe.commandType = "VineBurrow";
				attackFe.m_AttackMove = false;
				m_owner.SendFastEvent(attackFe);
			}
			m_fired = false;
		}
	}
	

	if(m_currentTime >= m_duration && !m_fired)
	{
		m_fired = true;
		fe = new () class'TMFastEvent';
		fe.commandType = "Animation";
		fe.int1 = 4;
		m_owner.ReceiveFastEvent(fe);
		

		attackFe = new () class'TMAttackFE';
		attackFe.pawnId = m_owner.pawnId;
		attackFe.commandType = "VineBurrow";
		attackFe.m_AttackMove = true;
		m_owner.SetCollision(false,false,);
		m_owner.SendFastEvent(attackFe);


		vec = m_owner.Location;
		vec.Z += 70;
		rot.Pitch = -90 * DegToUnrRot;
		if(m_decal == none && m_owner.m_owningPlayerId == m_owner.m_TMPC.PlayerId)
		{
			m_decal = m_owner.Spawn(class'TMDecal ',m_owner,,vec,rot,,);
			m_decal.SetPositionAndRotation(vec,rot);
		}  
		
	}
}


function ReceiveFastEvent(TMFastEvent event)
{   
	if(event.commandType == "VineBurrow" && m_owner.m_owningPlayerId != m_owner.m_TMPC.PlayerId)
	{
		if(event.bools.D)
		{
			m_hidePawn = true;
		}
		else 
		{
			m_hidePawn = false;
		}
	}
}

function HandleStopFE()
{

}



DefaultProperties
{
}
