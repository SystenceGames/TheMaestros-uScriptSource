class TMFastEvent extends Object;

	struct floatArray
	{
		var float A,B,C,D,E;
	};

	struct stringArray
	{
		var string A,B,C,D,E;
	};

	struct intArray
	{
		var int A,B,C,D,E;
	};

	struct boolArray
	{
		var bool A,B,C,D,E;
	};

	var string commandType; 
	var int pawnId;
	var intArray PawnIDs1;
	var intArray PawnIDs2;
	var intArray PawnIDs3;
	var intArray PawnIDs4;
	var int targetId; 
	var Vector position1; 
	var Vector position2; 
	var float float1;
	var floatArray floats;
	var int int1;
	var intArray ints;
	var string string1;
	var stringArray strings;
	var bool bool1;
	var boolArray bools;

function array<int> GetPawnIDs()
{
	local array<int> pawnIds;
	pawnIds.AddItem(pawnId);
	//ONE PARSING
	if(PawnIDs1.A != 0)
	{
		pawnIds.AddItem(PawnIDs1.A);
	}
	if(PawnIDs1.B != 0)
	{
		pawnIds.AddItem(PawnIDs1.B);
	}
	if(PawnIDs1.C != 0)
	{
		pawnIds.AddItem(PawnIDs1.C);
	}
	if(PawnIDs1.D != 0)
	{
		pawnIds.AddItem(PawnIDs1.D);
	}
	if(PawnIDs1.E != 0)
	{
		pawnIds.AddItem(PawnIDs1.E);
	}


	// TWO PARSING
	if(PawnIDs2.A != 0)
	{
		pawnIds.AddItem(PawnIDs2.A);
	}
	if(PawnIDs2.B != 0)
	{
		pawnIds.AddItem(PawnIDs2.B);
	}
	if(PawnIDs2.C != 0)
	{
		pawnIds.AddItem(PawnIDs2.C);
	}
	if(PawnIDs2.D != 0)
	{
		pawnIds.AddItem(PawnIDs2.D);
	}
	if(PawnIDs2.E != 0)
	{
		pawnIds.AddItem(PawnIDs2.E);
	}


	// THREE PARSING
	if(PawnIDs3.A != 0)
	{
		pawnIds.AddItem(PawnIDs3.A);
	}
	if(PawnIDs3.B != 0)
	{
		pawnIds.AddItem(PawnIDs3.B);
	}
	if(PawnIDs3.C != 0)
	{
		pawnIds.AddItem(PawnIDs3.C);
	}
	if(PawnIDs3.D != 0)
	{
		pawnIds.AddItem(PawnIDs3.D);
	}
	if(PawnIDs3.E != 0)
	{
		pawnIds.AddItem(PawnIDs3.E);
	}


	// FOUR PARSING
	if(PawnIDs4.A != 0)
	{
		pawnIds.AddItem(PawnIDs4.A);
	}
	if(PawnIDs4.B != 0)
	{
		pawnIds.AddItem(PawnIDs4.B);
	}
	if(PawnIDs4.C != 0)
	{
		pawnIds.AddItem(PawnIDs4.C);
	}
	if(PawnIDs4.D != 0)
	{
		pawnIds.AddItem(PawnIDs4.D);
	}
	if(PawnIDs4.E != 0)
	{
		pawnIds.AddItem(PawnIDs4.E);
	}
	return pawnIds;


}

/**
 * Creates an FE with the specified commandType.  Please use this if you want to 
 * generate "1-off" FE's that are simply named commands.  
 * NOTE: This is for ReceiveFastEvent() commands only, should NOT SendFastEvent()
 * with these.
 */
static function TMFastEvent createGenericFE(int InPawnId, string InCommandType)
{
	local TMFastEvent fe;
	fe = new () class'TMFastEvent';
	fe.commandType = InCommandType;
	fe.pawnId = InPawnId;
	return fe;
}

function TMFastEvent toFastEvent()
{
	return self;
}

DefaultProperties
{
}
