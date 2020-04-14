class TMMoveFE extends Object implements (TMFastEventInterface);

var int groupId;
var int leadPawnId;
var int pawnId;
var int targetId;
var Vector destination;
var bool playSound;
var string commandType;
var intArray pawnIDs1;
var intArray pawnIDs2;
var intArray pawnIDs3;
var intArray pawnIDs4;
var vector animParentChild;
var bool isQueued;
var bool m_AttackMove;
var bool m_isStopMove;
var bool m_isAbilityMove;
var bool m_isTransformMove;

var Vector m_AttackMovePosition;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';

	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.targetId = targetId;
	fe.position1 = destination;
	fe.position2.X = animParentChild.X;
	fe.bool1 = playSound;

	/* 
	 * 
	 *  GROUP 1 
	 * 
	 * 
	 * */
	if(pawnIDs1.A != 0)
	{
		fe.PawnIDs1.A = pawnIDs1.A;
	}
	if(pawnIDs1.B != 0)
	{
		fe.PawnIDs1.B = pawnIDs1.B;
	}
	if(pawnIDs1.C != 0)
	{
		fe.PawnIDs1.C = pawnIDs1.C;
	}
	if(pawnIDs1.D != 0)
	{
		fe.PawnIDs1.D = pawnIDs1.D;
	}
	if(pawnIDs1.E != 0)
	{
		fe.PawnIDs1.E = pawnIDs1.E;
	}



	/* 
	 * 
	 *  GROUP 2 
	 * 
	 * 
	 * */
	if(pawnIDs2.A != 0)
	{
		fe.PawnIDs2.A = pawnIDs2.A;
	}
	if(pawnIDs2.B != 0)
	{
		fe.PawnIDs2.B = pawnIDs2.B;
	}
	if(pawnIDs2.C != 0)
	{
		fe.PawnIDs2.C = pawnIDs2.C;
	}
	if(pawnIDs2.D != 0)
	{
		fe.PawnIDs2.D = pawnIDs2.D;
	}
	if(pawnIDs2.E != 0)
	{
		fe.PawnIDs2.E = pawnIDs2.E;
	}


	/* 
	 * 
	 *  GROUP 3 
	 * 
	 * 
	 * */
	if(pawnIDs3.A != 0)
	{
		fe.pawnIDs3.A = pawnIDs3.A;
	}
	if(pawnIDs3.B != 0)
	{
		fe.pawnIDs3.B = pawnIDs3.B;
	}
	if(pawnIDs3.C != 0)
	{
		fe.pawnIDs3.C = pawnIDs3.C;
	}
	if(pawnIDs3.D != 0)
	{
		fe.pawnIDs3.D = pawnIDs3.D;
	}
	if(pawnIDs3.E != 0)
	{
		fe.pawnIDs3.E = pawnIDs3.E;
	}


/* 
	 * 
	 *  GROUP 4 
	 * 
	 * 
	 * */
	if(pawnIDs4.A != 0)
	{
		fe.pawnIDs4.A = pawnIDs4.A;
	}
	if(pawnIDs4.B != 0)
	{
		fe.pawnIDs4.B = pawnIDs4.B;
	}
	if(pawnIDs4.C != 0)
	{
		fe.pawnIDs4.C = pawnIDs4.C;
	}
	if(pawnIDs4.D != 0)
	{
		fe.pawnIDs4.D = pawnIDs4.D;
	}
	if(pawnIDs4.E != 0)
	{
		fe.pawnIDs4.E = pawnIDs4.E;
	}

	//IS QUEABLE
	fe.bools.E = isQueued;
	fe.position2 = m_AttackMovePosition;
	fe.bools.D = m_AttackMove;
	fe.bools.C = m_isStopMove;
	fe.bools.B = m_isAbilityMove;
	fe.bools.A = m_isTransformMove;

	if (leadPawnId != 0)
	{
		fe.int1  = leadPawnId;
	}

	fe.ints.A = groupId;

	return fe;
}

static function TMMoveFE create(Vector f_destination, bool isCommandFromPlayerController, int f_pawnId, optional array<UDKRTSPawn> similarIssuedPawns, optional UDKRTSPawn targetPawn, optional bool queued, optional bool attackMove, optional bool isStopMove, optional bool isAbilityMove, optional bool isTransformMove, optional int inLeadPawnId, optional int inGroupId )
{
	local TMMoveFE moveFE;
	local int i;

	moveFE = new () class'TMMoveFE';
	moveFE.pawnId = f_pawnId;
	if ( targetPawn != none )
	{
		moveFE.targetId = TMPawn(targetPawn).pawnId;
	}
	else
	{
		moveFE.targetId = -1;
	}

	
	

	if (isCommandFromPlayerController)
	{
		moveFE.commandType = "C_Move";
	}
	else
	{
		moveFE.commandType = "C_AI_Move";
	}

	if(similarIssuedPawns.Length != 0)
	{
		i = 0;
		moveFE.pawnIDs1.A = TMPawn(similarIssuedPawns[i]).pawnId;
		i++;
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs1.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs1.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs1.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs1.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		
		//PAWN IDS TWO STARTS HERE
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs2.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs2.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs2.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs2.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs2.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		//PAWN IDS 3 STARTS HERE
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs3.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs3.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs3.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs3.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs3.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		//PAWN IDS 4 STARTS HERE
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs4.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs4.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs4.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs4.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			moveFE.pawnIDs4.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
	}

	moveFE.destination = f_destination;
	moveFE.playSound = true;
	
	moveFE.m_isStopMove = isStopMove;
	moveFE.m_AttackMove = attackMove;
	moveFE.m_isAbilityMove = isAbilityMove;
//IS QUEABLE
	moveFE.isQueued = queued;
	moveFE.m_isTransformMove = isTransformMove;
	

	if (inLeadPawnId != 0)
	{
		moveFE.leadPawnId = inLeadPawnId;
	}

	moveFE.groupId = inGroupId;

	return moveFE;
}


static function TMMoveFE fromFastEvent(TMFastEvent fe)
{
	local TMMoveFe moveFE;

	moveFE = new () class'TMMoveFe';
	moveFE.commandType = fe.commandType;
	moveFE.pawnId = fe.pawnId;
	moveFE.targetId = fe.targetId;
	moveFE.destination = fe.position1;
	moveFE.playSound = fe.bool1;
	moveFE.animParentChild = fe.position2;
	moveFE.m_AttackMove = fe.bools.D;
	moveFE.m_AttackMovePosition = fe.position2;
	moveFE.isQueued = fe.bools.E;
	moveFE.m_isStopMove = fe.bools.C;
	moveFE.m_isAbilityMove = fe.bools.B;
	moveFE.m_isTransformMove = fe.bools.A;
	moveFE.leadPawnId = fe.int1;
	moveFE.groupId = fe.ints.A;
	
	return moveFE;
}

DefaultProperties
{
}
