class TMAlchTransFE extends Object implements(TMFastEventInterface);

var string TransEventType; // FARMORDER, POTIONFARMED, POTIONCAST, CANCEL
var string PotionType;
var int ReceiverID;
var int TransformerID;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;
	fe = new() class'TMFastEvent';
	fe.commandType = "C_AlchTrans";
	fe.int1 = TransformerID;
	fe.pawnId = ReceiverID;
	fe.string1 = TransEventType;
	fe.strings.A = PotionType;

	return fe;
}

static function TMAlchTransFE fromFastEvent(TMFastEvent fe)
{
	local TMAlchTransFE event;
	event = new() class'TMAlchTransFE';
	event.TransformerID = fe.int1;
	event.TransEventType = fe.string1;
	event.ReceiverID = fe.pawnId;
	event.PotionType = fe.strings.A;
	return event;
}

static function TMAlchTransFE create(int transID, string eventType, string type, int pawnID)
{
	local TMAlchTransFE event;

	event = new() class'TMAlchTransFE';
	event.TransformerID = transID;
	event.TransEventType = eventType;
	event.ReceiverID = pawnID;
	event.PotionType = type;

	return event;
}

DefaultProperties
{
	
}
