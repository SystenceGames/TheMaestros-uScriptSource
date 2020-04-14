class TMAttackFE extends Object implements(TMFastEventInterface);


const ATTACK_COMMAND_TYPE = "C_Attack";
var int pawnId;
var int targetId;
var string commandType;
var bool isQueued;
var bool m_AttackMove;
var Vector m_AttackMovePosition;
//wasnt finding the int array type for some reason so i included it here
struct intArray
{
	var int A,B,C,D,E;
};
var intArray pawnIDs1;
var intArray pawnIDs2;
var intArray pawnIDs3;
var intArray pawnIDs4;

static function TMAttackFE create(TMPawn target, int f_pawnId, optional array<UDKRTSPawn> similarIssuedPawns, optional bool queued, optional bool attackMove, optional Vector attackMoveTarget )
{
	local TMAttackFE result;
	local int i;
	result = new () class'TMAttackFE';
	result.commandType = ATTACK_COMMAND_TYPE;
	result.pawnId = f_pawnId;
	if( target != none )
	{
		result.targetId = target.pawnId;
		
	}
	else
	{
		result.targetId = -1;
	}

	if(similarIssuedPawns.Length != 0)
	{
		i = 0;
		result.pawnIDs1.A = TMPawn(similarIssuedPawns[i]).pawnId;
		i++;
		if(i < similarIssuedPawns.Length){
			result.pawnIDs1.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs1.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs1.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs1.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		
		//PAWN IDS TWO STARTS HERE
		if(i < similarIssuedPawns.Length){
			result.pawnIDs2.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs2.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs2.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs2.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs2.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		//PAWN IDS 3 STARTS HERE
		if(i < similarIssuedPawns.Length){
			result.pawnIDs3.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs3.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs3.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs3.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs3.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		//PAWN IDS 4 STARTS HERE
		if(i < similarIssuedPawns.Length){
			result.pawnIDs4.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs4.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs4.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs4.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			result.pawnIDs4.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
	}


	result.isQueued = queued;
	result.m_AttackMove = attackMove;
	result.m_AttackMovePosition = attackMoveTarget;
	return result;
}

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.targetId = targetId;

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

	fe.position2 = m_AttackMovePosition;
	fe.bools.E = isQueued;
	fe.bools.D = m_AttackMove;
	return fe;
}

static function TMAttackFE fromFastEvent(TMFastEvent fe)
{
	local TMAttackFE atkFE;

	atkFE = new () class'TMAttackFE';
	atkFE.commandType = fe.commandType;
	atkFe.pawnId = fe.pawnId;
	atkFe.targetId = fe.targetId;
	atkFe.m_AttackMove = fe.bools.D;
	atkFe.m_AttackMovePosition = fe.position2;
	atkFe.isQueued = fe.bools.E;

	return atkFE;
}

DefaultProperties
{
}
