class TMPlayerInventory extends Object;

var array<string> commanders;


static function TMPlayerInventory DeserializeFromJson( JsonObject inJson )
{
	local TMPlayerInventory inv;
	local string commander;
	local JsonObject commandersJson;

	inv = new class'TMPlayerInventory'();
	commandersJson = inJson.GetObject( "inventoryIds" ); 	// TODO: expand this to other items when our inventory includes more than just commanders

	foreach commandersJson.ValueArray( commander )
	{
		inv.commanders.AddItem( commander );
	}

	inv.PrintInventory();
	return inv;
}


function int HasCommander( string inCommander )
{
	//-2 if no commanders
	//-1 if commander not found
	//0-? if commander exists
	if (commanders.length == 0) {
		return -2;
	}
	return commanders.Find( inCommander );
}

function array<string> GetCommanderList()
{
	return commanders;
}


function PrintInventory()
{
	local string commander;
	local string msg;
	msg = "TMPlayerInventory::PrintInventory() commanders:";

	foreach commanders( commander ) {
		msg $= "\n" $ commander;
	}

	`log( msg );
}
