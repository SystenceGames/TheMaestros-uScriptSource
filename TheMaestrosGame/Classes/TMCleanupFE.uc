class TMCleanupFE extends Object implements(TMFastEventInterface);

const CLEANUP_COMMAND_TYPE = "C_Cleanup";
var int pawnId;
var string commandType;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = CLEANUP_COMMAND_TYPE;
	fe.pawnId = pawnId;

	return fe;
}

static function TMCleanupFE create(int f_pawnId)
{
	local TMCleanupFE result;

	result = new () class 'TMCleanupFE';
	result.pawnId = f_pawnId;
	result.commandType = CLEANUP_COMMAND_TYPE;

	return result;
}

static function TMCleanupFE fromFastEvent(TMFastEvent fe)
{
	local TMCleanupFE cleanupFE;

	cleanupFE = new () class 'TMCleanupFE';
	cleanupFE.pawnId = fe.pawnId;
	cleanupFE.commandType = CLEANUP_COMMAND_TYPE;

	return cleanupFE;
}

DefaultProperties
{
}