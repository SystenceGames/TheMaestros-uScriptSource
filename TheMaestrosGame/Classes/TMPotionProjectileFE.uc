class TMPotionProjectileFE extends Object implements(TMFastEventInterface);

var Vector targetLocation;
var int pawnId;
var int targetId;
var string commandType;
var string potionType;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.position1 = targetLocation;
	fe.pawnId = pawnId;
	fe.targetId = targetId;
	fe.commandType = commandType;
	fe.string1 = potionType;

	return fe;
}

static function TMPotionProjectileFE fromFastEvent(TMFastEvent fe)
{
	local TMPotionProjectileFE potionProjectileFE;

	potionProjectileFE = new () class'TMPotionProjectileFE';
	potionProjectileFE.targetLocation = fe.position1;
	potionProjectileFE.pawnId = fe.pawnId;
	potionProjectileFE.targetId = fe.targetId;
	potionProjectileFE.commandType = fe.commandType;
	potionProjectileFE.potionType = fe.string1;

	return potionProjectileFE;
}

static function TMPotionProjectileFE create(Vector inTargetLocation, int inPawnId, int inTargetPawnId, string inCommandType, string inPotionType)
{
	local TMPotionProjectileFE potionProjectileFE;

	potionProjectileFE = new () class'TMPotionProjectileFE';
	potionProjectileFE.targetLocation = inTargetLocation;
	potionProjectileFE.pawnId = inPawnId;
	potionProjectileFE.targetId = inTargetPawnId;
	potionProjectileFE.commandType = inCommandType;
	potionProjectileFE.potionType = inPotionType;

	return potionProjectileFE;
}

DefaultProperties
{
}
