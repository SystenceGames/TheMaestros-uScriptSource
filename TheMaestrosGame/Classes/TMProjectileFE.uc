class TMProjectileFE extends Object implements(TMFastEventInterface);

const PROJECTILE_COMMAND_TYPE = "C_Projectile";
var int pawnId;
var string commandType;

var vector position1;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;

	return fe;
}

static function TMProjectileFE create(int f_pawnId)
{
	local TMProjectileFE result;

	result = new () class 'TMProjectileFE';
	result.pawnId = f_pawnId;
	result.commandType = PROJECTILE_COMMAND_TYPE;

	return result;
}

static function TMProjectileFE fromFastEvent(TMFastEvent fe)
{
	local TMProjectileFE projFE;

	projFE = new () class 'TMProjectileFE';
	projFE.pawnId = fe.pawnId;
	projFE.commandType = PROJECTILE_COMMAND_TYPE;

	return projFE;
}

DefaultProperties
{
}