class TMStopFE extends Object implements (TMFastEventInterface);

const COMMAND_TYPE_GENERIC = "C_Stop";
const COMMAND_TYPE_ATTACK = "C_Stop_Attack";
var int pawnId;
var string commandType;
var intArray pawnIDs1;
var intArray pawnIDs2;
var intArray pawnIDs3;
var intArray pawnIDs4;
var bool isQueued;

static function TMStopFE create(int f_pawnId,optional array<UDKRTSPawn> similarIssuedPawns, optional string command, optional bool queued )
{
	local TMStopFE stopFE;
	local int i;
	stopFE = new () class'TMStopFE';
	if(command == "")
	{
		stopFE.commandType = COMMAND_TYPE_GENERIC;
	}
	else
	{

		stopFE.commandType = command;
	}
	stopFE.pawnId = f_pawnId;

	
	if(similarIssuedPawns.Length != 0)
	{
		i = 0;
		stopFE.pawnIDs1.A = TMPawn(similarIssuedPawns[i]).pawnId;
		i++;
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs1.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs1.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs1.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs1.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		
		//PAWN IDS TWO STARTS HERE
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs2.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs2.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs2.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs2.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs2.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		//PAWN IDS 3 STARTS HERE
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs3.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs3.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs3.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs3.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs3.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		
		//PAWN IDS 4 STARTS HERE
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs4.A = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs4.B = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs4.C = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs4.D = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
		if(i < similarIssuedPawns.Length){
			stopFE.pawnIDs4.E = TMPawn(similarIssuedPawns[i]).pawnId;
			i++;
		}
	}


	//IS QUEABLE
	stopFE.isQueued = queued;

	
	return stopFE;
}

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;


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



	return fe;
}

static function TMStopFE fromFastEvent(TMFastEvent fe)
{
	local TMStopFE stopFE;

	stopFE = new () class'TMStopFE';
	stopFE.commandType = fe.commandType;
	stopFE.pawnId = fe.pawnId;

	return stopFE;
}

DefaultProperties
{
}
