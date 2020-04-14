class TMFastEventSpawn extends Object  implements(TMFastEventInterface);;

const SPAWN_COMMAND  = "C_Spawn";
var int pawnId;
var string commandType;
var vector startLocation;
var bool isStartingSpawn;
var int owningPlayerId;
var bool shouldMove;
var Vector moveLocation;

static function TMFastEventSpawn create( int id, vector location, optional bool isStarting,optional int owningPlayer, optional bool inShouldMove, optional Vector inMoveLocation)
{
	local TMFastEventSpawn fe;

	fe = new () class'TMFastEventSpawn';
	fe.pawnId = id;
	fe.commandType = SPAWN_COMMAND;
	fe.startLocation = location;
	fe.isStartingSpawn = isStarting;
	fe.owningPlayerId = owningPlayer;
	fe.shouldMove = inShouldMove;
	fe.moveLocation = inMoveLocation;
	return fe;

}

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.position1 = startLocation;
	fe.bool1 = isStartingSpawn;
	fe.int1 = owningPlayerId;
	fe.bools.A = shouldMove;
	fe.position2 = moveLocation;
	return fe;
}


static function TMFastEventSpawn fromFastEvent(TMFastEvent fe)
{
	local TMFastEventSpawn sfe;
	
	sfe = new () class'TMFastEventSpawn';
	sfe.commandType = fe.commandType;
	sfe.pawnId = fe.pawnId;
	sfe.startLocation = fe.position1;
	sfe.isStartingSpawn = fe.bool1;
	sfe.owningPlayerId = fe.int1;
	sfe.shouldMove = fe.bools.A;
	sfe.moveLocation = fe.position2;
	return sfe;

}

DefaultProperties
{
}
