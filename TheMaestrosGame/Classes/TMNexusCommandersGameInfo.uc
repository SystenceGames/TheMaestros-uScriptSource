/* TMNexusCommandersGameInfo
	Your commander is a nexus that can't move.

	Units spawn periodically.


	Spawn towers on transform points. When you spawn the tower it switches your new spawning unit to that unit?

	Towers shoot bullets and grant vision around the map.

	If your nexus is destroyed you lose.
*/

class TMNexusCommandersGameInfo extends TMRoundBasedGameInfo;


var string STARTING_UNIT;

var float SPAWN_UNIT_FREQUENCY;

var float CAMERA_ZOOM;


function RestartPlayer(Controller NewPlayer)
{
	if(TMController(NewPlayer) != None)
	{
		TMController(NewPlayer).GetTMPRI().commanderType = STARTING_UNIT;
		TMController(NewPlayer).GetTMPRI().nexuscommander_current_towers.Remove(0, TMController(NewPlayer).GetTMPRI().nexuscommander_current_towers.length);
		TMController(NewPlayer).SetCommanderType(STARTING_UNIT);
	}

	super.RestartPlayer(NewPlayer);

	SetTimer( 1.0f, false, NameOf( StartUnitsSpawn ) );

	TMPlayerController(NewPlayer).ClientSetCameraZoom(CAMERA_ZOOM);
}


function StartUnitsSpawn()
{
	SpawnUnits();
	SpawnUnits();

	SetTimer( SPAWN_UNIT_FREQUENCY, true, NameOf( SpawnUnits ) );
}


function array<string> GetMyTowerUnitsToSpawn(TMPlayerReplicationInfo tmpri)
{
	local array<string> unitsToSpawn;
	local TMPawn iterPawn;

	foreach tmpri.nexuscommander_current_towers(iterPawn)
	{
		if( class'UDKRTSPawn'.static.IsValidPawn(iterPawn) )
		{
			unitsToSpawn.AddItem(iterPawn.nexuscommander_current_unit);
		}
	}

	return unitsToSpawn;
}


function SpawnUnits()
{
	local TMController iterTmController;
	local TMPlayerController tmpc;
	local array<string> unitsToSpawn;
	local string iterUnit;

	foreach mAllTMControllers(iterTmController)
	{
		if (TMPlayerController(iterTmController) != None)
		{
			tmpc = TMPlayerController(iterTmController);

			// Only spawn units if the commander is alive
			if(tmpc.GetTMPRI().bIsCommanderDead)
			{
				continue;
			}

			unitsToSpawn = GetMyTowerUnitsToSpawn(tmpc.GetTMPRI());

			if( unitsToSpawn.length == 0 )
			{
				RequestUnit("DoughBoy", tmpc.GetTMPRI(), tmpc.Pawn.Location, false, tmpc.Pawn.Location, None);
				RequestUnit("DoughBoy", tmpc.GetTMPRI(), tmpc.Pawn.Location, false, tmpc.Pawn.Location, None);
			}
			else
			{
				foreach unitsToSpawn(iterUnit)
				{
					RequestUnit(iterUnit, tmpc.GetTMPRI(), tmpc.Pawn.Location, true, tmpc.Pawn.Location, None, true);
				}
			}
		}
	}	
}


/* override RequestUnit
	Make some unit swaps

	Stealing IsRallyPointValid and dontUseRadialSpawn for some bullshit. If both are true I know that I spawned it myself
*/
function TMPawn RequestUnit(string unitType, TMPlayerReplicationInfo ownerReplicationInfo, Vector SpawnLocation, bool IsRallyPointValid, Vector locationRallyPoint, Actor actorRallyPoint, optional bool dontUseRadialSpawn)
{
	local TMPawn spawnedTower;

	// Make droplets and nexuses not spawn
	// This is shitty but yolo
	if( unitType == "Droplet" ||
		unitType == "Nexus" )
	{
		return None;
	}

	// Don't do anything special for these unit types, we only care about transformed units.
	if( (IsRallyPointValid && dontUseRadialSpawn) || 	// this is true when we spawn the unit ourselves
		unitType == STARTING_UNIT ||
		mTMGameInfoHelper.IsBaseUnit(unitType) ||
		mTMGameInfoHelper.IsNeutralUnit(unitType) ||
		mTMGameInfoHelper.IsGameObjectiveUnit(unitType) ||
		unitType == "MiniSplitter" || 	// minisplitter needs to spawn when splitter dies
		unitType == "ConvertedBrute" ) 	// allow brute to spawn when taken over
	{
		return super.RequestUnit(unitType, ownerReplicationInfo, SpawnLocation, IsRallyPointValid, locationRallyPoint, actorRallyPoint, dontUseRadialSpawn);
	}

	// Spawn a tower
	spawnedTower = super.RequestUnit("Tower", ownerReplicationInfo, SpawnLocation, IsRallyPointValid, locationRallyPoint, actorRallyPoint, dontUseRadialSpawn);
	SetupTower(spawnedTower, unitType, ownerReplicationInfo);

	return spawnedTower;
}

function SetupTower(TMPawn inTower, string unitType, TMPlayerReplicationInfo ownerReplicationInfo)
{
	local TMTransformer iterTransformer;

	// Assign this as my new spawning unit
	inTower.nexuscommander_current_unit = unitType;
	ownerReplicationInfo.nexuscommander_current_towers.AddItem(inTower);

	// Assign the transform point as mine
	ForEach AllActors(class'TMTransformer', iterTransformer)
	{
		if(inTower.IsInRange2D( iterTransformer.Location, inTower.Location, 50 ))
		{
			iterTransformer.mCurrentTower = inTower;
		}
	}
}

/* StartFinishingRound override
	Cancel our timer between rounds
*/
function StartFinishingRound(TMPlayerReplicationInfo diedPlayerTMPRI)
{
	ClearTimer( NameOf(SpawnUnits) );

	super.StartFinishingRound(diedPlayerTMPRI);
}

/* GetJsonStringsFromManifest override
	Make any transformed units count as 1 population
*/
function array<string> GetJsonStringsFromManifest(string manifestPath)
{
	local array<string> jsonStringArray;
	local array<string> newJsonStringArray;
	local string jsonString;
	local JsonObject json;

	jsonStringArray = super.GetJsonStringsFromManifest(manifestPath);

	if(manifestPath == ("\\" $  "Tenshii" $ "manifest.json"))
	{
		return jsonStringArray;
	}

	foreach jsonStringArray(jsonString)
	{
		json = m_JsonParser.getJsonFromString(jsonString);

		if( json.HasKey("UN") &&
			json.HasKey("PC") &&
			json.GetIntValue("PC") > 0 )
		{
			json.SetIntValue("PC", 1);
		}

		newJsonStringArray.AddItem(class'JsonObject'.static.EncodeJson(json));
	}

	return newJsonStringArray;
}

/* GetRaceNameForCommander override
	Always be Teutonian in this game mode
*/
function string GetRaceNameForCommander(string commanderName)
{
	return "Teutonian";
}


DefaultProperties
{
	STARTING_UNIT = "NexusCommander";

	SPAWN_UNIT_FREQUENCY = 8f;

	CAMERA_ZOOM = 500;
}
