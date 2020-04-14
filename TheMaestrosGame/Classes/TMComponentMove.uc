class TMComponentMove extends TMComponent;

const MOVE_COMMAND_TYPE = "C_Move";
const AI_MOVE_COMMAND_TYPE = "C_AI_Move";
const STOP_COMMAND_ALL = "C_Stop_All";
const STOP_CMD = "C_Stop";
const REACHED_DESTINATION = "C_ReachedDestination";
const STOP_MOVING = "C_Stop_Move";
const RESUME_ATTACK_MOVE = "C_Resume_Attack_Move";
enum MoveState
{
	MS_IDLE, MS_MOVING, MS_ATTACKMOVE
};

var bool bHasReachedDestination;
var float m_UpdateMoveTimeInterval;
var float m_UpdateMoveTimeElapsed;
var Vector m_PositionBefore;
var Vector m_PositionStart;
var Vector m_TargetLocation;
var MoveState m_State;
var TMPawn m_target;
var bool m_AttackMove;
var bool m_isStopMove;
var bool m_movementPaused;
var bool m_targetIsEngaged;
var Vector m_OriginallyIssuedDestination;
var int moveGroupId;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_owner = parent;
	m_State = MS_IDLE;
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentMove newcomp;
	newcomp= new () class'TMComponentMove' (self);
	newcomp.m_owner=newowner;
	newcomp.m_movementPaused = false;
	return newcomp;
}

//function to update whatever you need
function UpdateComponent(float dt)
{
	if(self.m_target != none)
	{
		m_TargetLocation = m_target.Location;
	}

	switch (m_State)
	{
	case MS_IDLE:
		break;

	case MS_MOVING:
		DoUpdateMoving(dt);
		break;

	case MS_ATTACKMOVE:
//		DoUpdateAttackMove(dt);
		break;
	}
}

function bool CheckAtDestination(float dt )
{
	local bool atDestination;

	// Shit happens man
	if(m_Owner == None)
		return false;

	atDestination = false;
	m_UpdateMoveTimeElapsed += dt;

	if (bHasReachedDestination ) 
	{
		return true;
	}
	
	if( m_UpdateMoveTimeElapsed > m_UpdateMoveTimeInterval )
	{
		m_PositionBefore = m_Owner.Location;
		m_UpdateMoveTimeElapsed = 0;    
	}

	return atDestination;
}


function DoUpdateMoving( float dt )
{
	if (CheckAtDestination( dt ))
	{
		if( m_Target == none )
		{
			CommandFinished();
		}
	}
	else
	{
		if( m_Target != none )
		{
			if( m_owner.m_allyId == m_target.m_allyId )
			{
				m_TargetLocation = m_target.Location;
			}
			else
			{
				if( isInRange( m_owner, m_Target, m_owner.m_Unit.m_attackRange ))
				{
					m_TargetLocation = m_owner.Location;
					m_owner.m_pathDestination = m_owner.Location;
				}
			}
			FinallyActuallyDoTheMoveCode();
		}
	}
}

function bool IsInRange(Pawn pawn1, Pawn Pawn2, int range)
{
	local float dist;
	dist = VSize2D(pawn1.Location - pawn2.Location); // changing this to 2D, but it may have effects on movement code deeper in native, so keep an eye out. - dru
	dist -= pawn1.GetCollisionRadius(); 
	dist -= pawn2.GetCollisionRadius(); 
	return (dist < range);
}

function FinallyActuallyDoTheMoveCode()
{
	local UDKRTSAIController UDKRTSAIController;

	UDKRTSAIController = UDKRTSAIController(m_owner.Controller);
	
	if(m_target == none )
	{
		if(UDKRTSAIController != none)
		{
			if (moveGroupId != 0)
			{
				UDKRTSAIController.GroupedMoveToPoint2(m_TargetLocation, m_OriginallyIssuedDestination, true);
			} else
			{
				UDKRTSAIController.GroupedMoveToPoint(m_TargetLocation, m_OriginallyIssuedDestination, true);
			}
		}
		m_owner.m_pathDestination = m_TargetLocation;
		if (!m_isStopMove)
		{
			m_owner.mPointToDetermineIfWeHaveSameDestination = m_OriginallyIssuedDestination;
		}
	}
	else
	{
		m_owner.m_pathDestination = m_target.Location;
		if (!m_isStopMove)
		{
			m_owner.mPointToDetermineIfWeHaveSameDestination = m_OriginallyIssuedDestination;
		}
		if(UDKRTSAIController != none)
		{
			if( m_target.Health <= 0 && m_attackMove )
			{
				UDKRTSAIController.MoveToPoint(m_target.Location, true);
				m_target = none;
			}
			else if( m_attackMove )
			{
				UDKRTSAIController.MoveToPoint(m_target.Location, true);
			}
			else
			{
				UDKRTSAIController.MoveToPoint(m_TargetLocation, true);
			}
		}
	}
}

function ReceiveFastEvent(TMFastEvent fe)
{
	m_PositionStart = m_owner.Location;
	if( IsAuthority() )
	{
		if(fe.commandType == MOVE_COMMAND_TYPE || fe.commandType == AI_MOVE_COMMAND_TYPE)
		{
			m_OriginallyIssuedDestination = fe.position2; // this is for grouped movement behavior - dru
			HandleMoveFE(class'TMMoveFE'.static.fromFastEvent(fe));
		}
		else if(fe.commandType == STOP_COMMAND_ALL || fe.commandType == STOP_CMD )
		{
			HandleStopFE();
		}
		else if(fe.commandType == RESUME_ATTACK_MOVE )
		{
			ResumeAttackMove();
		}
		else if (fe.commandType == REACHED_DESTINATION)
		{
			HandleReachedDestinationFE();
		}
		else if (fe.commandType == "Target_Engaged")
		{
			TargetEngaged();
		}
		else if(fe.commandType == "Target_DisEngaged")
		{
			TargetDisEngaged();
		}   
		else if( fe.commandType == STOP_MOVING )
		{
			HandleStopMove();
		}
		super.ReceiveFastEvent(fe);
	}
}

function TargetDisEngaged()
{
//	m_targetIsEngaged = false;
}

function TargetEngaged()
{
//	m_targetIsEngaged = true;
}

function bool IsAuthority()
{
	return ((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone));
}

function ResumeAttackMove()
{
	local TMMoveFE moveFE;

	m_target = none;
	if(m_owner.NotInteruptingCommand())
	{
		m_movementPaused = false;
		//basically re-doing a move command
		moveFE = class'TMMoveFE'.static.create(m_TargetLocation, false, m_owner.pawnId,, , false, true );
		m_owner.ReceiveFastEvent ( moveFE.toFastEvent() );
	}
}

//this is specific to the attack move or someone just wanting to pause movement if we are a attack move
function HandleStopMove()
{
	local UDKRTSAIController UDKRTSAIController;
	//means we just want to pause the movement
	if( m_AttackMove )
	{
		m_movementPaused = true;
		m_owner.m_pathDestination = m_owner.Location;
		m_State = MS_IDLE;

		UDKRTSAIController = UDKRTSAIController(m_owner.Controller);
		UDKRTSAIController.MoveToPoint(m_owner.Location, true);
	}
	//but if we are not attack moving, just chillll
	else
	{
		HandleStopFE();
	}
}

function RemoveMoveGroup()
{
	if (IsAuthority())
	{
		m_owner.MoveGroup = None;
		moveGroupId = 0;
	}
}

function HandleStopFE()
{
	local UDKRTSAIController UDKRTSAIController;

	if(m_owner != none && m_owner.Controller != none )
	{
		m_owner.UpdateUnitState( TMPS_IDLE );
		m_target = none;
		m_State = MS_IDLE;
		RemoveMoveGroup();
		UDKRTSAIController = UDKRTSAIController(m_owner.Controller);
		UDKRTSAIController.MoveToPoint(m_owner.Location, true);
	}
}

function MoveAnimation()
{
	local TMAnimationFe animation;
	animation = new () class'TMAnimationFe';
	animation.m_commandType = "Move_Anim";
	animation.m_pawnID = m_owner.pawnId;
	m_owner.SendFastEvent( animation );
}

function HandleMoveCommand(TMMoveFE moveFE)
{   
	if( moveFE.targetId == m_owner.pawnId)
	{
		return;
	}

	m_AttackMove = moveFE.m_AttackMove;
	m_isStopMove = moveFE.m_isStopMove;
	m_movementPaused = false;
	m_targetIsEngaged = false;
	bHasReachedDestination = false;
	m_owner.mHasBumpedGuyAtDestinationTransitively = false;
	m_TargetLocation = moveFE.destination;
	m_UpdateMoveTimeElapsed = 0;
	if (IsAuthority())
	{
		moveGroupId = moveFE.groupId;
		if (moveGroupId == 0)
		{
			m_owner.MoveGroup = None;
		} else if (moveGroupId != 0 && m_owner.MoveGroup == None)
		{
			`WARN("MoveGroup was None but groupId was nonzero");
		}
	}

	if( m_AttackMove )
	{
		m_owner.m_followTarget = None;
	}
		
	if( moveFE.targetId != -1 )
	{
		m_State = MS_MOVING;
		m_owner.UpdateUnitState( TMPS_MOVING_FOLLOW );
		m_target = m_owner.m_TMPC.GetPawnByID(moveFE.targetId);
		m_owner.m_followTarget = m_target;
	}
	else
	{
		m_State = MS_MOVING;
		m_owner.UpdateUnitState( TMPS_MOVING );
		FinallyActuallyDoTheMoveCode();
		m_owner.m_followTarget = None;
	}

	if (moveFE.leadPawnId != 0)
	{
		m_owner.leadPawn = m_owner.m_TMPC.GetPawnByID(moveFE.leadPawnId);
	} else
	{
		m_owner.leadPawn = None;
		UDKRTSAIController(m_owner.Controller).leadPawnMovePoints.Length = 0;
	}

	// Kindof a hack to make sure you fake a move to your own location if you get told to move to your own location
	if (moveFE.targetId == -1 && ( Vsize2D( moveFE.destination - m_owner.Location ) < m_owner.GetCollisionRadius() ) )
	{
		m_owner.UnitIsIdle();
		return;
	}

	MoveAnimation();
	//	m_owner.RecieveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, "C_Stop_Attack" ) );
}


function HandleMoveFE(TMMoveFE moveFE)
{
	m_target = none;
	if(m_owner.NotInteruptingCommand() || moveFE.m_isAbilityMove)
	{
		m_PositionBefore.X = 0;
		m_PositionBefore.Y = 0;
		m_PositionBefore.Z = 0;

		if( m_target != none)
		{
			if(m_target.pawnId == moveFE.targetId )
			{   
				return;
			}
		}

		//means we have engaged an enemy or was attacking them
		if( m_movementPaused )
		{
			if(!moveFE.m_AttackMove )
			{
				HandleMoveCommand( moveFE );
			}
			else if( moveFE.targetId != -1)
			{
				m_movementPaused = false;
				m_targetIsEngaged = false;
				bHasReachedDestination = false;
				m_owner.mHasBumpedGuyAtDestinationTransitively = false;
				m_TargetLocation = moveFE.destination;
				m_UpdateMoveTimeElapsed = 0;
				RemoveMoveGroup();
				if( moveFE.targetId != -1 )
				{
					m_State = MS_MOVING;
					m_owner.UpdateUnitState( TMPS_MOVING_FOLLOW );
					m_target = m_owner.m_TMPC.GetPawnByID(moveFE.targetId);
					m_owner.m_followTarget = m_target;
				}
			}
			else
			{
				m_TargetLocation = moveFE.destination;
			}
		}
		//if we do an attack move while we are attacking a target that wasn't already
		//attacked moved to. ie we clicked to attack then did an attack move
		else if( moveFE.m_AttackMove && m_owner.GetAttackComponent().m_Target != none)
		{
			m_TargetLocation = moveFE.destination;
			m_target = m_owner.m_TMPC.GetPawnByID( moveFE.targetId);
		}
		else
		{
			HandleMoveCommand( moveFE );
		}	
	}
}


function CommandFinished()
{
	m_State = MS_IDLE;
	m_owner.UpdateUnitState( TMPS_IDLE );
	m_Owner.CommandQueueDo();
}

function bool IsAtAttackMoveDestination()
{
	if(VSize( m_TargetLocation - m_owner.Location ) < 50)
	{
		return true;
	}

	return false;
}

function HandleReachedDestinationFE()
{
	local UDKRTSAIController UDKRTSAIController;
	bHasReachedDestination = true;
	UDKRTSAIController = UDKRTSAIController(m_owner.Controller);
	UDKRTSAIController.StopMoving();
	m_owner.mHasBumpedGuyAtDestinationTransitively = true;


	if( m_AttackMove)
	{
		if( IsAtAttackMoveDestination() )
		{
			CommandFinished();
		}
	}
}

DefaultProperties
{
	m_UpdateMoveTimeInterval = .01;
}
