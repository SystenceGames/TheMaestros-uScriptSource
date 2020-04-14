class TMTookDamageFastEvent extends Object implements(TMFastEventInterface);


const TOOK_DAMAGE_COMMAND_TYPE = "C_Took_Damage"; 	// I'd love to make this "Event" instead of Command
var string commandType;
var int pawnId;
var int attackerPawnId;
var int attackerAllyId;


static function TMTookDamageFastEvent create(int inPawnId, int inAttackerPawnId, int inAttackerAllyId)
{
	local TMTookDamageFastEvent result;
	result = new () class'TMTookDamageFastEvent';
	result.commandType = TOOK_DAMAGE_COMMAND_TYPE;
	result.pawnId = inPawnId;
	result.attackerPawnId = inAttackerPawnId;
	result.attackerAllyId = inAttackerAllyId;

	return result;
}

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;
	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.targetId = attackerPawnId;
	fe.int1 = attackerAllyId;

	return fe;
}

static function TMTookDamageFastEvent fromFastEvent(TMFastEvent fe)
{
	local TMTookDamageFastEvent tdFE;

	tdFE = new () class'TMTookDamageFastEvent';
	tdFE.commandType = fe.commandType;
	tdFE.pawnId = fe.pawnId;
	tdFE.attackerPawnId = fe.targetId;
	tdFE.attackerAllyId = fe.int1;

	return tdFE;
}
