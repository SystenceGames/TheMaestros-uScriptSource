class TMComponentTransformer extends TMComponent;

enum ETransformState {
	NOSTATE, TRANSIT, QUEUED, TRANSFORMING
};

var ETransformState TransformState;
var TMTransformer ActiveTransformer;
var vector QueuePoint;
var vector CachedLocation;
var vector TargetLocation;
var float WarpTime;
var bool reachedTransformPoint;
var int MoveCommands;
var const float radiusSqConsideredInQueue;

var bool m_IsTransforming;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_Owner = parent;
	TransformState = NOSTATE;
	MoveCommands = 0;
	WarpTime = 0.f;
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentTransformer newcomp;
	newcomp= new () class'TMComponentTransformer' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function UpdateComponent(float dt)
{
	local float distanceSq;
	local float LerpDuration;

	LerpDuration = 1.2f;

	if(TransformState == TRANSIT)
	{
		if (m_owner.m_TMPC.PlayerId == m_owner.GetOwningPlayerId() && m_owner.WorldInfo.NetMode != NM_DedicatedServer)
		{
			TMHUD(m_owner.m_TMPC.myHUD).DrawGoingToTranformLine(m_owner, ActiveTransformer.Location);
		}
		
		distanceSq = VSizeSq2D(m_Owner.Location - QueuePoint);

		if(distanceSq <= radiusSqConsideredInQueue)
		{
			TransformState = QUEUED;
			ActiveTransformer.AddPawnToQueue(m_Owner);
		}
	}
	else if(TransformState == TRANSFORMING)
	{
		if(WarpTime > LerpDuration)
		{
			if(!reachedTransformPoint)
			{
				reachedTransformPoint = true;

				// Hide the unit
				m_owner.bApplyFogOfWar = false;
				m_owner.Mesh.SetHidden( true );
			}
		}
		else
		{
			m_Owner.SetLocation(vlerp(CachedLocation, TargetLocation, WarpTime / LerpDuration ));
			WarpTime += dt;
		}
	}
}

function ReceiveFastEvent(TMFastEvent event)
{
	local TMTransformationFE fe;

	if(m_Owner.m_TMPC != none) {

		if(event.commandType == "C_Trans")
		{
			fe = class'TMTransformationFE'.static.fromFastEvent(event);

			if(fe.TransEventType == "ORDER")
			{
				HandleOrder(fe);
			}
			else if(fe.TransEventType == "TRANSFORM")
			{
				HandleTransform(fe);
			}
			else if(fe.TransEventType == "CANCEL")
			{
				Cancel();
			}
		}
	
		// if any commands are issued (other than one
		// move command), cancel the unit in the queue
		// else if(!event.IsA('TMAnimationFE') && TransformState == QUEUED)
		else if( ( event.commandType == "C_Move" || event.commandType == "C_AI_Move" ) && !event.bools.A && (self.TransformState == QUEUED || self.TransformState == TRANSIT))
		{
			// this looks retarded- its because of an old feature that i tweaked and could need to revert. trust me.
			MoveCommands++;
			// if(MoveCommands > 1)
			if(MoveCommands > 0) 
			{
				Cancel();
			}
		}
	}
}

function HandleOrder(TMTransformationFE fe)
{
	local TMTransformer transformer;
	local vector unit;
	local array<UDKRTSPawn> unitsForCommand;
	
	if(TransformState == QUEUED || TransformState == TRANSFORMING)
	{
		return;
	}

	foreach m_Owner.AllActors(class'TMTransformer', transformer)
	{
		/*
		if( Vsize(fe.TransformerPosition - transformer.Location) < 1.0f)
		{
			ActiveTransformer = transformer;
		}
		*/
		if(fe.TransformerId == transformer.TransformerId)
		{
			ActiveTransformer = transformer;
			break;
		}
	}

	if( !CheckUnitTypes(m_Owner.m_UnitType) )
	{
		return;
	}

	TransformState = TRANSIT;
	m_IsTransforming = true;

	unit = Normal(m_Owner.Location - ActiveTransformer.Location);
	unit.Z = 0;
	QueuePoint = (unit * 275) + ActiveTransformer.Location;

	unitsForCommand.AddItem(m_owner);
	if (m_owner.WorldInfo.NetMode != NM_Client)
	{
		m_Owner.DoMoveCommand(QueuePoint, true, unitsForCommand, none, false, false, true);
	}
}

function bool CheckUnitTypes(string unitType)
{
	if(m_Owner.m_UnitType == "DoughBoy")
	{
		return true; // DoughBoys are always down to party
	}
	
	if( m_Owner.m_UnitType == ActiveTransformer.UnitOneType
		|| m_Owner.m_UnitType == ActiveTransformer.UnitTwoType )
	{
		return true;
	}
	
	return false;
}


function HandleTransform(TMTransformationFE fe)
{
	local array<UDKRTSPawn> unitsForCommand;

	unitsForCommand.AddItem(m_owner);
	CachedLocation = m_Owner.Location;
	TargetLocation = ActiveTransformer.Location;
	TargetLocation.Z += 125;
	if (m_owner.WorldInfo.NetMode != NM_Client)
	{
		m_Owner.DoMoveCommand(TargetLocation, false, unitsForCommand);
	}
	MoveCommands = 0;
	reachedTransformPoint = false;
	TransformState = TRANSFORMING;
	m_Owner.bIsTransforming = true;
	m_Owner.bBlockActors = false;
}

function Cancel()
{
	MoveCommands = 0;
	m_IsTransforming = false;
	reachedTransformPoint = false;
	WarpTime = 0.f;

	if(TransformState == TRANSIT)
	{
		TransformState = NOSTATE;
		// m_Owner.UpdateUnitState(TMPS_IDLE);
	}
	else if(TransformState == QUEUED)
	{
		ActiveTransformer.RemovePawnFromQueue(m_Owner);
		TransformState = NOSTATE;
		// m_Owner.UpdateUnitState(TMPS_IDLE);
	}
	else if(TransformState == TRANSFORMING)
	{
		TransformState = NOSTATE;
		m_Owner.SetPhysics(PHYS_Walking); // TODO Dru: Could this be related to our perf issues?
		m_Owner.bBlockActors = true;
		m_Owner.bIsTransforming = false;
		m_owner.bApplyFogOfWar = true;
	}
}


DefaultProperties
{
	m_IsTransforming = false;
	radiusSqConsideredInQueue = 22500; // 150.0f * 150.0f
}
