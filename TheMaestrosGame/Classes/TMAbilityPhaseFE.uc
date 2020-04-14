class TMAbilityPhaseFE extends Object  implements(TMFastEventInterface);;

const SPAWN_COMMAND  = "C_AbilityPhase";
var int pawnId;
var string commandType;
var int abilityPhase;

static function TMAbilityPhaseFE create( int inPawnId, int phaseNumber)
{
	local TMAbilityPhaseFE fe;

	fe = new () class'TMAbilityPhaseFE';
	fe.pawnId = inPawnId;
	fe.commandType = SPAWN_COMMAND;
	fe.abilityPhase = phaseNumber;
	return fe;
}

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.int1 = abilityPhase;
	return fe;
}


static function TMAbilityPhaseFE fromFastEvent(TMFastEvent fe)
{
	local TMAbilityPhaseFE sfe;
	
	sfe = new () class'TMAbilityPhaseFE';
	sfe.commandType = fe.commandType;
	sfe.pawnId = fe.pawnId;
	sfe.abilityPhase = fe.int1;
	return sfe;
}
