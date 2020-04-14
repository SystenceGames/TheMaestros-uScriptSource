class TMEggSetupFE extends Object implements(TMFastEventInterface);

var string m_ResultUnitType;
var int m_PawnID;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;
	fe = new() class'TMFastEvent';
	fe.commandType = "C_EggEvent";
	fe.pawnId = m_PawnID;
	fe.string1 = m_ResultUnitType;

	return fe;
}

static function TMEggSetupFE fromFastEvent(TMFastEvent fe)
{
	local TMEggSetupFE event;
	event = new() class'TMEggSetupFE';
	event.m_ResultUnitType = fe.string1;
	event.m_PawnID = fe.pawnId;
	return event;
}

static function TMEggSetupFE create(int pawnID, string resultUnitType)
{
	local TMEggSetupFE event;

	event = new() class'TMEggSetupFE';
	event.m_PawnID = pawnID;
	event.m_ResultUnitType = resultUnitType;

	return event;
}

DefaultProperties
{
}
