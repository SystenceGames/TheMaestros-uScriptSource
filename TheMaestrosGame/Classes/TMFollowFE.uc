class TMFollowFE extends Object implements (TMFastEventInterface);

var int pawnId;
var int targetId;
var Vector destination;
var bool playSound;
var bool isQueued;
var string commandType;

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';

	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.targetId = targetId;
	fe.position1 = destination;
	fe.bool1 = playSound;

	//IS QUEABLE
	fe.bools.E = isQueued;
	return fe;
}

static function TMFollowFE create(TMPawn target, bool isCommandFromPlayerController, int pID, optional bool queued )
{
	local TMFollowFE followFE;

	followFE = new () class'TMFollowFE';
	followFE.pawnId = pID;
	if (isCommandFromPlayerController)
	{
		followFE.commandType = "C_Follow";
	}
	else
	{
		followFE.commandType = "C_AI_Follow";
	}

	followFE.targetId = target.pawnId;
	followFE.playSound = true;
	
	//IS QUEABLE
	followFE.isQueued = queued;
	return followFE;
}

static function TMFollowFE fromFastEvent(TMFastEvent fe)
{
	local TMFollowFE followFE;

	followFE = new () class'TMFollowFE';
	followFE.commandType = fe.commandType;
	followFE.pawnId = fe.pawnId;
	followFE.targetId = fe.targetId;
	followFE.destination = fe.position1;
	followFE.playSound = fe.bool1;
	
	return followFE;
}

DefaultProperties
{
}
