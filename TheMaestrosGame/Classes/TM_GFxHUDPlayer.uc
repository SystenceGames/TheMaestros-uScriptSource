class TM_GFxHUDPlayer extends TM_GFxMoviePlayer;

var WorldInfo thisWorld;
var TMPlayerController playerController;
var TMHUD parentHUD;
var TMAllyInfo enemyAllyInfo;
var float hudWidth, hudHeight;

var GFxObject rootObject;
var GFxObject hudStatObject;
var GFxObject unitAbilityBarObject;
var GFxObject pausedMenuObject;

var const string CHAT_RATE_LIMITED_MESSAGE;
var const string TEAM_CHAT_TYPE;
var const string ALL_CHAT_TYPE;
var const int CURSOR_COLOR_CODE_DEFAULT;
var const int CURSOR_COLOR_CODE_ATTACK;
var int prevCursorColor;

/** The number of messages you can send right now.  Increments over time to a max */
var int availableMessageCount;

var const int MAX_AVAILABLE_MESSAGE_COUNT;
var const float INCREMENT_MESSAGE_COUNT_TIME_SECONDS;

var bool doOnce;
var bool tickColors;

var bool tutorial;
var bool spectator;
var bool hidden;

var string race, commanderType;
var string unitNames[6];

var int coolDowns[7];
var array<bool> radialDone;
var const int COMMANDER_ABILITY_INDEX;
var const int GHOST_ABILITY_INDEX;

var int cachePopulation, cachePopulationCap, cachePlayerUnitSize;

var int teamSpawnsLeft, opponentSpawnsLeft;

var array<bool> cacheUnitSpawned;
var array<bool> unitSpawned;

var int cacheCommanderHealth, cacheCommanderIndex;

var bool cacheShowTransform, showTransform;

var string lastSelected;

var int cacheNumPlayers;

var GFxObject scoreScreen;

var GFxObject timerScreen;

var bool quitViaMenu;
var bool endGameStatsSaved;

var bool bMouseStayHidden;

var TMJsonParser m_JsonParser;

struct HUDTooltip
{
	var string title;
	var string description;
};

// select tooltips
var HUDTooltip selectAllTooltip;
var HUDTooltip selectCommanderTooltip;
var array<HUDTooltip> teutonianSelectTooltips;
var array<HUDTooltip> alchemistSelectTooltips;

// ability tooltips
var HUDTooltip attackTooltip;
var array<HUDTooltip> teutonianCommanderTooltips;
var array<HUDTooltip> alchemistCommanderTooltips;
var array<HUDTooltip> teutonianAbilityTooltips;
var array<HUDTooltip> alchemistAbilityTooltips;
var HUDTooltip boostTooltip;
var HUDTooltip transformTooltip;

//in-game settings
var TMSettingsMenuHelper settingsMenuHelper;
var int resolutionIndex;

function bool Start(optional bool startPaused = false)
{
	super.Start(startPaused);
	thisWorld = GetPC().WorldInfo;
	hudWidth = 1600;
	hudHeight = 900;

	SetViewScaleMode(SM_ExactFit);

	playerController = TMPlayerController(GetPC());
	playerController.registerHUD(self);

	// Init Json Parser
	m_JsonParser = new() class'TMJsonParser';
	m_JsonParser.setup();

	doOnce = true;
	tickColors = true;

	cachePopulation = 0;
	cachePlayerUnitSize = 0;
	cacheNumPlayers = 0;

	teamSpawnsLeft = 0;
	opponentSpawnsLeft = 0;

	quitViaMenu = false;
	endGameStatsSaved = false;

	bMouseStayHidden = false;

	setSpectatorModeIfNecessary();

	// Load Tooltips
	LoadHUDTooltips();

	availableMessageCount = MAX_AVAILABLE_MESSAGE_COUNT;
	parentHud.SetTimer(INCREMENT_MESSAGE_COUNT_TIME_SECONDS, true, 'incrementAvailableMessageCount', self);

	//connect to settings helper
	settingsMenuHelper = new class 'TMSettingsMenuHelper'();
	settingsMenuHelper.LoadSettings(playerController, self);
	settingsMenuHelper.PopulateResolutionOptionsList();
	InitSettings();

	return true;
}

function incrementAvailableMessageCount()
{
	if (availableMessageCount >= MAX_AVAILABLE_MESSAGE_COUNT)
	{
		return;
	}

	++availableMessageCount;
}

simulated function print(string str)
{
	`log(str);
}

simulated function setSpectatorModeIfNecessary()
{
	if ( playerController.m_allyId == -3 )
	{
		spectatorMode( true );
	}
}

// Dru TODO: Remove DeltaTime, we don't actually use it
event Tick(float DeltaTime)
{
	//cannot send anything to actionscript if the connection has not yet been established
	if(rootObject == none)
	{
		rootObject = GetVariableObject("_root");
		if (rootObject == None)
		{
			return;
		}
	}

	if(playerController.PlayerReplicationInfo != none)
	{
		if(doOnce)
		{
			tickTutorial();

			tickRace();

			tickCommanderType();

			findCommanderAndUpdateHealthBar();

			initScoreScreen();

			setGameTypeText(playerController.mObjectiveText);

			doOnce = false;

			setSpectatorModeIfNecessary();

			// Set Tooltip Text
			SetHUDTooltipText();
			InitSettings();
		}

		if(tickColors)
		{
			tickRespawnCounterColors();
		}
	}

	tickTimer();

	tickCursorColor();

	tickPopulation();

	tickUnitIcons();

	tickSpawnCounts();

	tickAbilityRadials();

	tickCommanderHealth();

	tickTransform();

	//tickEndGameOverlay();

	tickScoreScreen();
}

function LoadHUDTooltips()
{
	local array<string> jsons;
	local array<JsonObject> jsonObjs;
	local int i;

	jsons = LoadHUDJsons();

	for(i = 0; i < jsons.Length; ++i)
	{
		jsonObjs.AddItem(m_JsonParser.getJsonFromString(jsons[i]));
	}

	BuildHUDTooltipCache(jsonObjs);
}

function array<string> LoadHUDJsons()
{
	local array<string> jsonStringArray;
	local array<string> filesArray;
	local string manifestPath;
	local string manifestFile;

	manifestPath = "\\" $  "HUD" $ "manifest.json";

	filesArray = GetJsonStringsFromManifest(manifestPath);
	foreach filesArray(manifestFile)
	{
		jsonStringArray.AddItem(manifestFile);
	}

	return jsonStringArray;
}

function array<string> GetJsonStringsFromManifest(string manifestPath)
{
	local JsonObject json;
	local array<string> jsonStringArray;
	local int count;
	local string jsonID;

	json = m_JsonParser.loadJSON(manifestPath ,true);
	count = 0;
	if(json != none)
	{
		while(true)
		{
			jsonID = "j" $ string(count);
			if(json.HasKey(jsonID))
			{
				jsonID = json.GetStringValue(jsonID);
				jsonID = m_JsonParser.LoadJsonString(jsonID);
				if(jsonID != "")
				{
					jsonStringArray.AddItem(jsonID);
				}
				else
				{
					break;
				}
			}
			else
			{
				break;
			}
			count++;
		}
	}

	return jsonStringArray;
}

function BuildHUDTooltipCache(array<JsonObject> jsons)
{
	local int i;
	local HUDTooltip tooltip;
	local array<JSONObject> jsonTooltips;
	local string title;
	local string description;

	title = "Title";
	description = "Description";

	/*
	hudTooltipCache.Remove(0, hudTooltipCache.Length); // reset the array
	for(i = 0; i < jsons.Length; ++i)
	{
		tooltip.title = jsons[i].GetStringValue(title);
		tooltip.description = jsons[i].GetStringValue(description);
		hudTooltipCache.AddItem(tooltip);
	}
	*/

	// This is read in based on the order in HUDmanifest.json.
	// If we change the order, this needs to change.
	// (There's definitely a better way to do this, but while
	// still knowing which JSON holds what.)

	// Select All
	selectAllTooltip.title = jsons[0].GetStringValue(title);
	selectAllTooltip.description = jsons[0].GetStringValue(description);

	// Select Commander
	selectCommanderTooltip.title = jsons[1].GetStringValue(title);
	selectCommanderTooltip.description = jsons[1].GetStringValue(description);

	// Teutonian Select
	jsonTooltips = jsons[2].GetObject("Buttons").ObjectArray;
	for (i = 0; i < 6; ++i)
	{
		tooltip.title = jsonTooltips[i].GetStringValue(title);
		tooltip.description = jsonTooltips[i].GetStringValue(description);
		teutonianSelectTooltips.AddItem(tooltip);
	}
	
	// Alchemist Select
	jsonTooltips = jsons[3].GetObject("Buttons").ObjectArray;
	for (i = 0; i < 6; ++i)
	{
		tooltip.title = jsonTooltips[i].GetStringValue(title);
		tooltip.description = jsonTooltips[i].GetStringValue(description);
		alchemistSelectTooltips.AddItem(tooltip);
	}

	// Attack
	attackTooltip.title = jsons[4].GetStringValue(title);
	attackTooltip.description = jsons[4].GetStringValue(description);

	// Teutonian Abilities
	jsonTooltips = jsons[5].GetObject("Commanders").ObjectArray;
	for (i = 0; i < 3; ++i)
	{
		tooltip.title = jsonTooltips[i].GetStringValue(title);
		tooltip.description = jsonTooltips[i].GetStringValue(description);
		teutonianCommanderTooltips.AddItem(tooltip);
	}
	jsonTooltips = jsons[5].GetObject("Units").ObjectArray;
	for (i = 0; i < 5; ++i)
	{
		tooltip.title = jsonTooltips[i].GetStringValue(title);
		tooltip.description = jsonTooltips[i].GetStringValue(description);
		teutonianAbilityTooltips.AddItem(tooltip);
	}

	// Alchemist Abilities
	jsonTooltips = jsons[6].GetObject("Commanders").ObjectArray;
	for (i = 0; i < 3; ++i)
	{
		tooltip.title = jsonTooltips[i].GetStringValue(title);
		tooltip.description = jsonTooltips[i].GetStringValue(description);
		alchemistCommanderTooltips.AddItem(tooltip);
	}
	jsonTooltips = jsons[6].GetObject("Units").ObjectArray;
	for (i = 0; i < 5; ++i)
	{
		tooltip.title = jsonTooltips[i].GetStringValue(title);
		tooltip.description = jsonTooltips[i].GetStringValue(description);
		alchemistAbilityTooltips.AddItem(tooltip);
	}

	// Boost
	boostTooltip.title = jsons[7].GetStringValue(title);
	boostTooltip.description = jsons[7].GetStringValue(description);

	// Transform
	transformTooltip.title = jsons[8].GetStringValue(title);
	transformTooltip.description = jsons[8].GetStringValue(description);
}

function SetHUDTooltipText()
{
	local int i;

	// Select Bar
	addSelectTooltip(selectAllTooltip.title, selectAllTooltip.description);
	addSelectTooltip(selectCommanderTooltip.title, selectCommanderTooltip.description);
	if (race == "Teutonian")
	{
		for (i = 0; i < teutonianSelectTooltips.Length; ++i)
		{
			addSelectTooltip(teutonianSelectTooltips[i].title, teutonianSelectTooltips[i].description);
		}
	}
	else if (race == "Alchemist")
	{
		for (i = 0; i < alchemistSelectTooltips.Length; ++i)
		{
			addSelectTooltip(alchemistSelectTooltips[i].title, alchemistSelectTooltips[i].description);
		}
	}

	// Abilities Bar
	addAbilityTooltip(attackTooltip.title, attackTooltip.description);
	if (race == "Teutonian")
	{
		switch (commanderType)
		{
			case "TinkerMeister":
				addAbilityTooltip(teutonianCommanderTooltips[0].title, teutonianCommanderTooltips[0].description);
				break;
			case "Rosie":
				addAbilityTooltip(teutonianCommanderTooltips[1].title, teutonianCommanderTooltips[1].description);
				break;
			case "RoboMeister":
				addAbilityTooltip(teutonianCommanderTooltips[2].title, teutonianCommanderTooltips[2].description);
				break;
		}
		for (i = 0; i < teutonianAbilityTooltips.Length; ++i)
		{
			addAbilityTooltip(teutonianAbilityTooltips[i].title, teutonianAbilityTooltips[i].description);
		}
	}
	else if (race == "Alchemist")
	{
		switch (commanderType)
		{
			case "Salvator":
				addAbilityTooltip(alchemistCommanderTooltips[0].title, alchemistCommanderTooltips[0].description);
				break;
			case "RamBamQueen":
				addAbilityTooltip(alchemistCommanderTooltips[1].title, alchemistCommanderTooltips[1].description);
				break;
			case "HiveLord":
				addAbilityTooltip(alchemistCommanderTooltips[2].title, alchemistCommanderTooltips[2].description);
				break;
		}
		for (i = 0; i < alchemistAbilityTooltips.Length; ++i)
		{
			addAbilityTooltip(alchemistAbilityTooltips[i].title, alchemistAbilityTooltips[i].description);
		}
	}
	addAbilityTooltip(boostTooltip.title, boostTooltip.description);
	if (race == "Alchemist")
	{
		addAbilityTooltip(transformTooltip.title, transformTooltip.description);
	}
}

function addSelectTooltip(string title, string description)
{
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = title;
	Param1.Type = AS_String;
	Param1.s = description;

	args.Length = 2;
    args[0] = Param0;
    args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "addSelectTooltip";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function addAbilityTooltip(string title, string description)
{
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = title;
	Param1.Type = AS_String;
	Param1.s = description;

	args.Length = 2;
    args[0] = Param0;
    args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "addAbilityTooltip";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickTimer()
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = playerController.GetGameTime();

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updateTimer";


	if(timerScreen==None)
	{
		timerScreen = GetVariableObject(FunctionPath);
	}

	if(timerScreen != none)
	{
		timerScreen.Invoke(InvokeFunction, args);
	}
}

simulated function tickAbilityRadials()
{
	local int i, j;
	local TMPawn pawn;
	local TMAbility tempAbility;
	local int allcooldown[7];
	local int lowestcooldown[7];
	local TMPlayerReplicationInfo tempTMPRI;
	
	tempTMPRI = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo);

	if (tempTMPRI == None)
	{
		return;
	}

	// all but commander
	for(i = 1; i < 6; i++)
	{
		allcooldown[i] = 0;
		lowestcooldown[i] = 10000;
		if(radialDone[i] == true) {
			for(j = 0; j < tempTMPRI.m_PlayerUnits.Length; j++)
			{
				pawn = tempTMPRI.m_PlayerUnits[j];
				if(pawn != none && pawn.m_UnitType == unitnames[i])
				{
					tempAbility = pawn.GetAbilityComponent();
					if(tempAbility!=none) {
						if(tempAbility.m_AbilityState == AS_COOLDOWN) {
							allcooldown[i]= 1;
							if(lowestcooldown[i] > (tempAbility.mCooldown - tempAbility.m_fTimeInState)) {
								lowestcooldown[i] = (tempAbility.mCooldown - tempAbility.m_fTimeInState);
							}
						}
						else {
							allcooldown[i] = 0;
							break;
						}
					}
				}
			}
		}
	}

	// commander
	allcooldown[COMMANDER_ABILITY_INDEX] = 0;
	allcooldown[GHOST_ABILITY_INDEX] = 0;
	pawn = TMPawn(playerController.Pawn);
	if(pawn != none && pawn.m_UnitType == commanderType)
	{
		// commander ability
		if(radialDone[COMMANDER_ABILITY_INDEX] == true) {
			tempAbility = pawn.GetAbilityComponent();
			if(tempAbility!=none) {
				if(tempAbility.m_AbilityState == AS_COOLDOWN) {
					allcooldown[COMMANDER_ABILITY_INDEX] = 1;
					lowestcooldown[COMMANDER_ABILITY_INDEX] = (tempAbility.mCooldown - tempAbility.m_fTimeInState);
				}
			}
		}

		// ghost ability
		if(radialDone[GHOST_ABILITY_INDEX] == true) {
			tempAbility = pawn.GetGhostAbilityComponent();
			if(tempAbility!=none) {
				if(tempAbility.m_AbilityState == AS_COOLDOWN) {
					allcooldown[GHOST_ABILITY_INDEX] = 1;
					lowestcooldown[GHOST_ABILITY_INDEX] = (tempAbility.mCooldown - tempAbility.m_fTimeInState);
				}
			}
		}
	}

	for(i = 0; i < 7; i++)
	{
		if(allcooldown[i] == 1) {
			updateAbilityRadial(i, lowestcooldown[i]*1000);
			radialDone[i] = false;
		}
	}
}

simulated function markRadialDone(int i)
{
	radialDone[i] = true;
}

simulated function resetAbilityRadials()
{
	local int i;

	// this is actually disgusting.
	for(i = 0; i < 7; ++i)
	{
		updateAbilityRadial(i, 0.000001);
	}
}

simulated function updateAbilityRadial(int i, int cooldowntime)
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = i;
	Param1.Type = AS_Number;
	Param1.n = cooldowntime;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.unitAbilityBar";
	InvokeFunction = "updateAbilityRadial";
	if (unitAbilityBarObject == none)
	{
		unitAbilityBarObject = GetVariableObject(FunctionPath);
	}

	if(unitAbilityBarObject != none)
	{
		unitAbilityBarObject.Invoke(InvokeFunction, args);
	}
}

simulated function tickRace()
{
	local int i;
	if(playerController.PlayerReplicationInfo != none) {
		race = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).race;
		for (i = 0; i < 6; i++)
		{
			unitNames[i] = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).raceUnitNames[i];
		}
		updateUnitNames();
		updateRace();
	}
}

simulated function updateRace()
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = race;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "updateRace";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function disableAll( bool disable )
{
	parentHUD.isDisabled = disable;
	
	hideAllHUD( disable );
}

simulated function hideAllHUD(bool hide )
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Boolean;
	Param0.b = hide;

	args.Length = 1;
    args[0] = Param0;

	parentHUD.bHideMinimap = hide;
	if ( !hide )
	{
		parentHUD.SetMinimapSize( parentHUD.MinimapSize );
	}

	FunctionPath = "_root";
	InvokeFunction = "hideAll";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function hideCursor(bool hide)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	bMouseStayHidden = hide;

	Param0.Type = AS_Boolean;
	Param0.b = hide;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "hideCursor";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function spectatorMode(bool mode)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Boolean;
	Param0.b = mode;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "spectatorMode";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function updateUnitNames()
{
	local ASValue Param0, Param1, Param2, Param3, Param4, Param5;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = unitNames[0];
	Param1.Type = AS_String;
	Param1.s = unitNames[1];
	Param2.Type = AS_String;
	Param2.s = unitNames[2];
	Param3.Type = AS_String;
	Param3.s = unitNames[3];
	Param4.Type = AS_String;
	Param4.s = unitNames[4];
	Param5.Type = AS_String;
	Param5.s = unitNames[5];

	args.Length = 6;
    args[0] = Param0;
	args[1] = Param1;
	args[2] = Param2;
	args[3] = Param3;
	args[4] = Param4;
	args[5] = Param5;

	FunctionPath = "_root";
	InvokeFunction = "updateUnitNames";

	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function catchCommandIssued(String s)
{
	local ECommand command;

	switch (s)
	{
	case "All":
		command = C_SelectUnitType1;
		break;
	case commanderType:
		command = C_SelectUnitType2;
		break;
	case unitNames[0]:
		command = C_SelectUnitType3;
		break;
	case unitNames[1]:
		command = C_SelectUnitType4;
		break;
	case unitNames[2]:
		command = C_SelectUnitType5;
		break;
	case unitNames[3]:
		command = C_SelectUnitType6;
		break;
	case unitNames[4]:
		command = C_SelectUnitType7;
		break;
	case unitNames[5]:
		command = C_SelectUnitType8;
		break;
	default:
		break;
	}
	
	if (playerController != None)
	{
		playerController.CommandIssued(command);
	}
}

simulated function selectUnits(String s)
{
	local int i;

	// Dru TODO: Couldn't we just check the InputHandler that's being used currently?
	if( playerController.InputHandlerInactiveCommand.isInChat ||
		playerController.InputHandlerActiveCommand.isInChat )
	{
		// Don't allow unit selection while doing chat stuffs
		// NOTE: this shouldn't be done here!!! The icons still flicker
			// this should be done in actionscript
		return;
	}

	playerController.InputHandler.notOnHud = false;
	playerController.RemoveActorsSelected();
	lastSelected = "selectUnits " @ s;

	catchCommandIssued(s);

	if(playerController.PlayerReplicationInfo != none && !TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).bIsCommanderDead) {
		switch(s) {
			case "All":
				playerController.SelectAllOwnedActors();
				break;
			default:

				playerController.SetHotSelectionGroup( s );
				for(i = 0; i < TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits.Length; i++)
				{
					if(TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits[i] != none)
					{
						checkUnitAndSelect(s, TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits[i]);
					}
				}
				break;
		}
	}
	playerController.InputHandler.notOnHud = true;
}


function checkUnitAndSelect(String type, TMPawn tempPawn)
{
	
	if(tempPawn.m_UnitType == type && tempPawn.IsValidPawn( tempPawn))
	{
		playerController.AddActorAsSelected(tempPawn);
		tempPawn.CommandMesh.SetHidden(false);
	}
}

simulated function centerUnits()
{
	playerController.CenterCameraOnGroup();
}

simulated function doAbility(String s)
{
	playerController.InputHandler.notOnHud = false;
	lastSelected = "doAbility " @ s;
	switch(s)
	{
		case commanderType:
			playerController.TM_Key_Q_Pressed();
			break;
		case "Conductor":
		case "Disruptor":
			playerController.TM_Key_W_Pressed();
			break;
		case "Sniper":
		case "Grappler":
			playerController.TM_Key_E_Pressed();
			break;
		case "Splitter":
		case "Vinecrawler":
			playerController.TM_Key_R_Pressed();
			break;
		case "Oiler":
		case "Turtle":
			playerController.TM_Key_D_Pressed();
			break;
		case "Skybreaker":
		case "Regenerator":
			playerController.TM_Key_F_Pressed();
			break;
	}
}

simulated function doGhostAbility()
{
	playerController.InputHandler.notOnHud = false;
	playerController.TM_Key_G_Pressed();
}

simulated function doAttackMove()
{ 
	lastSelected = "doAttackMove";
	playerController.TM_Key_A_Pressed();
}

simulated function doBruteAbility()
{ 
	lastSelected = "doBruteAbility";
	playerController.TM_Key_B_Pressed();
}

simulated function tickCommanderType()
{
	if(playerController.PlayerReplicationInfo!=None){
		commanderType = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).commanderType;
		updateCommanderType();
	}
}

simulated function updateCommanderType()
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = commanderType;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "updateCommanderType";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickRespawnCounterColors()
{
	local int teamIndex;

	if(playerController.PlayerReplicationInfo != None && TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyInfo != None){
		teamIndex = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyId;
		updateRespawnCounterColors(teamIndex);
		tickColors = false;
	}
}

simulated function updateRespawnCounterColors(int teamIndex)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;


	if( teamIndex == -3 ) //if spectator
	{
		teamIndex = 0;
	}

	Param0.Type = AS_Number;
	Param0.n = teamIndex;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updateRespawnCounterColors";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickSpawnCounts()
{
	if(playerController.PlayerReplicationInfo != None && TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyInfo != None)
	{
		tickTeamSpawnCounts();
		tickOpponentSpawnCounts();
	}
}

simulated function tickTeamSpawnCounts()
{
	local TMAllyInfo allyInfo, tmAllyInfo;

	if( !playerController.PlayerReplicationInfo.bOnlySpectator )
	{
		if(playerController.PlayerReplicationInfo != none) {

			allyInfo = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyInfo;

			//if(teamSpawnsLeft != (allyInfo.maxSpawns - allyInfo.numSpawns))
			if(teamSpawnsLeft != allyInfo.score)
			{
				//teamSpawnsLeft = allyInfo.maxSpawns - allyInfo.numSpawns;
				teamSpawnsLeft = allyInfo.score;
				if(teamSpawnsLeft < 0)
				{
					teamSpawnsLeft = 0;
				}
				updateTeamsSpawnsLeft(teamSpawnsLeft);
			}
		}
	}
	else
	{
		foreach playerController.AllActors(class'TMAllyInfo', tmAllyInfo)
		{
			if(tmAllyInfo.allyIndex == 0)
			{
				allyInfo = tmAllyInfo;
				if(allyInfo != none) 
				{
					if(teamSpawnsLeft != allyInfo.score)
					{
						teamSpawnsLeft = allyInfo.score;
						if(teamSpawnsLeft < 0)
						{
							teamSpawnsLeft = 0;
						}
						updateTeamsSpawnsLeft(teamSpawnsLeft);
					}
				}
				break;
			}
		}
	}
}

simulated function tickOpponentSpawnCounts()
{
	local TMAllyInfo tmAllyInfo;
	local int opponentIndex;
	
	if(playerController.PlayerReplicationInfo == none) 
	{
		return;
	}

	if( !playerController.PlayerReplicationInfo.bOnlySpectator )
	{
		opponentIndex = Abs(TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyInfo.allyIndex - 1);
	}
	else
	{
		opponentIndex = 1;
	}

	if ( enemyAllyInfo == None && playerController.mAllyInfos.Length > 1 )
	{
		foreach playerController.mAllyInfos(tmAllyInfo)
		{
			if(tmAllyInfo.allyIndex == opponentIndex)
			{
				enemyAllyInfo = tmAllyInfo;
				break;
			}
		}
	}
	
	if(enemyAllyInfo != none) 
	{
		if(opponentSpawnsLeft != enemyAllyInfo.score)
		{
			opponentSpawnsLeft = enemyAllyInfo.score;
			if(opponentSpawnsLeft < 0)
			{
				opponentSpawnsLeft = 0;
			}
			updateOpponentsSpawnsLeft(opponentSpawnsLeft);
		}
	}
}

simulated function updateTeamsSpawnsLeft(int spawnsLeft)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = spawnsLeft;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updateTeamsSpawnsLeft";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function updateOpponentsSpawnsLeft(int spawnsLeft)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = spawnsLeft;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updateOpponentsSpawnsLeft";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickTransform()
{
	if(race == "Alchemist") {
		showTransform = true;
	}
	else {
		showTransform = false;
	}
	if(cacheshowTransform != showTransform)
	{
		cacheshowTransform = showTransform;
		updateTransform();
	}
}

simulated function updateTransform()
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Boolean;
	Param0.b = showTransform;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root.unitAbilityBar";
	InvokeFunction = "updateTransform";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickTutorial()
{
	if(playerController.WorldInfo.GetMapName() == "tm_tutorial1_kismet")
	{
		tutorial = true;
	}
	else
	{
		tutorial = false;
	}
	updateTutorial();
}

simulated function updateTutorial()
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Boolean;
	Param0.b = tutorial;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updateTutorial";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickPopulation()
{
	checkAllUnits();
	if(playerController.PlayerReplicationInfo != None && cachePopulation != TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).Population)
	{
		cachePopulation = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).Population;
		cachePopulationCap = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).PopulationCap;
		if(cachePopulation < 0)
		{
			cachePopulation = 0;
		}
		updatePopulation();
	}
}

simulated function checkAllUnits()
{
	local int i, j;
	local TMPlayerReplicationInfo tmpri;

	tmpri = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo);

	if(tmpri == none) 
	{
		return;
	}
	
	for(j = 0; j < 6; j++)
	{
		unitSpawned[j] = false;
	}

	for(i = 0; i < tmpri.m_PlayerUnits.Length; i++) 
	{
		for(j = 0; j < 6; j++)
		{
			if( !unitSpawned[j] && 
				tmpri.m_PlayerUnits[i] != none && 
				tmpri.m_PlayerUnits[i].m_UnitType == unitNames[j])
			{
				unitSpawned[j] = true;
				break;
			}
		}
	}
}

simulated function updatePopulation()
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = cachePopulation;
	Param1.Type = AS_Number;
	Param1.n = cachePopulationCap;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updatePopulation";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function shrineDestroyed(int teamid, int killerid)
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = teamid;
	Param1.Type = AS_Number;
	Param1.n = killerid;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "shrineDestroyed";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickUnitIcons()
{
	local int i;
	for(i = 0; i < unitSpawned.Length; i++)
	{
		if(unitSpawned[i] != cacheUnitSpawned[i])
		{
			cacheUnitSpawned[i] = unitSpawned[i];
			updateUnitIcons(i+1, unitSpawned[i]);
		}
	}
}

simulated function updateUnitIcons(int unit, bool spawned)
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = unit;

	Param1.Type = AS_Boolean;
	Param1.b = spawned;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "updateUnitIcons";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

/* RemovePawn
	I'm 90% sure this is supposed to be called whenever a pawn dies

	It updates the player units stuff?

	This is Taylor making this comment, please let me know if you know more about the function.
*/
simulated function removePawn(TMPawn temp) 
{
	local bool found;
	local int i, j;
	found = false;
	if(playerController.PlayerReplicationInfo != none) {
		for(i = 0; i < TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits.Length; i++)
		{
			if(TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits[i] != none)
			{
				if(TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits[i].m_UnitType == temp.m_UnitType && TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).m_PlayerUnits[i].pawnId != temp.pawnId)
				{
					found = true;
					break;
				}
			}
		}
		if(!found) 
		{
			for (i = 0; i < 6; i++)
			{
				if(unitNames[i] == temp.m_UnitType) 
				{
					j = i;
					break;
				}
			}
			unitSpawned[j] = false;
		}

		//this function only gets called WHEN PAWNS DIE - GAGAN
		TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).RemovePawn(temp);
	}
}

simulated function findCommanderAndUpdateHealthBar()
{
	local int i;
	local TMPlayerReplicationInfo tempTMPRI;

	tempTMPRI = playerController.GetTMPRI();

	if(tempTMPRI == none) 
	{
		return;
	}

	for(i = 0; i < tempTMPRI.m_PlayerUnits.Length; i++) 
	{
		if(tempTMPRI.m_PlayerUnits[i].m_UnitType == commanderType)
		{
			cacheCommanderHealth = tempTMPRI.m_PlayerUnits[i].Health;
			cacheCommanderIndex = i;

			// Update the health bar when you find the commander.
			updateHUDCommanderHealthBar(tempTMPRI.m_PlayerUnits[cacheCommanderIndex].Health, tempTMPRI.m_PlayerUnits[cacheCommanderIndex].HealthMax);
			return;
		}
	}
}

simulated function tickCommanderHealth()
{
	local TMPlayerReplicationInfo tempTMPRI;
	local TMPawn commander;

	commander = TMPawn(playerController.pawn);
	tempTMPRI = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo);

	if(tempTMPRI == none) {
		findCommanderAndUpdateHealthBar();
		potionSelected("None", "0");
		return;
	}

	if ( class'UDKRTSPawn'.static.IsValidPawn( commander ) )
	{

		if (cacheCommanderHealth / float(commander.HealthMax) >= 0.25 &&
			commander.Health / float(commander.HealthMax) <= 0.25 )
		{
			playerController.m_AudioManager.requestPlayVO(SoundCue'VO_Main.Male_CommanderWounded_Cue', true, false);
		}

		cacheCommanderHealth = playerController.Pawn.Health; // I'm fucking baffled as to why this couldn't be commander.Health, but my compiler wouldn't budge - dru
		updateHUDCommanderHealthBar(commander.Health, commander.HealthMax);
	}
	else
	{
		updateHUDCommanderHealthBar(0, 1);
	}
}

simulated function updateHUDCommanderHealthBar(float health, float maxHealth)
{
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	if(health < 1)
	{
		health = 0;
	}

	Param0.Type = AS_Number;
	Param0.n = health;
	Param1.Type = AS_Number;
	Param1.n = maxHealth;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "updateCommanderHealth";

	if(hudStatObject == None)
	{
		hudStatObject = GetVariableObject(FunctionPath);
	}

	if(hudStatObject != None)
	{
		hudStatObject.Invoke(InvokeFunction, args);
	}
}

simulated function initScoreScreen()
{
	local int myAllyID;
	local TMPlayerReplicationInfo tmPRI;
	local int index;

	if(scoreScreen == none) {
		scoreScreen = GetVariableObject("root").GetObject("ScoreScreenMC");
	}

	if(playerController.PlayerReplicationInfo != none) {
		myAllyID = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyId;

		cacheNumPlayers = 0;

		// Clear all players. If a player disconnects we will wipe his slot
		clearScoreScreen();

		// NOTE: Uses color index to determine spot on Score Screen.
		foreach playerController.AllActors(class'TMPlayerReplicationInfo', tmPRI)
		{
			cacheNumPlayers++;

			index = tmPRI.mTeamColorIndex + (tmPRI.allyId * 3) + 1;

			if(tmPRI.allyId == 0 || tmPRI.allyId == 1)
			{
				scoreScreen.GetObject("backbar"$index).SetVisible(true);
				scoreScreen.GetObject("p"$index$"Stats").SetVisible(true);
				scoreScreen.GetObject("p"$index$"Stats").GetObject("commanderName"$index).SetText(tmPRI.GetCommanderName());
				scoreScreen.GetObject("p"$index$"Stats").GetObject("username"$index).SetText(tmPRI.PlayerName);
				if(tmPRI.allyId == myAllyID || playerController.IsSpectator() == 1)
					scoreScreen.GetObject("p"$index$"Units").SetVisible(true);
				updateScoreScreenCommander(index, tmPRI.commanderType);
			}
		}
	}
}

simulated function clearScoreScreen()
{
	local int index;
	local int numPlayerSlots;
	local GFxObject backbar;
	local GFxObject stats;
	local GFxObject units;

	numPlayerSlots = 6; 	// we have 6 potential players on the score screen to clear

	for(index=0; index < numPlayerSlots; index++)
	{
		backbar = scoreScreen.GetObject("backbar"$index);
		stats = scoreScreen.GetObject("p"$index$"Stats");
		units = scoreScreen.GetObject("p"$index$"Units");

		if( backbar != none && stats != none && units != none )
		{
			backbar.SetVisible(false);
			stats.SetVisible(false);
			units.SetVisible(false);
		}
	}
}

simulated function updateScoreScreenCommander(int player, string commander)
{
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = player;

	Param1.Type = AS_String;
	Param1.s = commander;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "updateScoreScreenCommander";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function tickScoreScreen()
{
	local int myAllyID;
	local TMPlayerReplicationInfo tmPRI;
	local int numPlayers;
	local int unitCount[6];
	local int i;
	local TMPawn myPawn;
	local int index;

	numPlayers = 0;

	if( scoreScreen == none )
	{
		scoreScreen = GetVariableObject("root").GetObject("ScoreScreenMC");
	}

	if(scoreScreen.GetBool("visible") && playerController.PlayerReplicationInfo != none) {
		myAllyID = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyId;

		// Note: -1 = Server, 0 = Team 1, 1 = Team 2 (allyId)
		foreach playerController.AllActors(class'TMPlayerReplicationInfo', tmPRI)
		{
			numPlayers++;

			if(tmPRI.allyId == 0 || tmPRI.allyId == 1)
			{
				for(i = 0; i < 6; i++)
				{
					unitCount[i] = 0;
				}
				foreach tmPRI.m_PlayerUnits(myPawn)
				{
					if(!myPawn.bDeleteMe)
					{
						switch(myPawn.m_UnitType)
						{
							case tmPRI.raceUnitNames[0]:
								unitCount[0]++;
								break;
							case tmPRI.raceUnitNames[1]:
								unitCount[1]++;
								break;
							case tmPRI.raceUnitNames[2]:
								unitCount[2]++;
								break;
							case tmPRI.raceUnitNames[3]:
								unitCount[3]++;
								break;
							case tmPRI.raceUnitNames[4]:
								unitCount[4]++;
								break;
							case tmPRI.raceUnitNames[5]:
								unitCount[5]++;
								break;
						}
					}
				}

				index = tmPRI.mTeamColorIndex + (tmPRI.allyId * 3) + 1;

				scoreScreen.GetObject("p"$index$"Stats").GetObject("deadX").SetVisible(tmPRI.bIsCommanderDead);

				scoreScreen.GetObject("p"$index$"Stats").GetObject("kda"$index).SetText(
					tmPRI.mStats[PS_KILLS] $ "/" $
					tmPRI.mStats[PS_DEATHS] $ "/" $
					tmPRI.mStats[PS_ASSISTS]);

				if(tmPRI.allyId == myAllyID || playerController.IsSpectator() == 1)
				{
					// DoughBoy, Conductor, Sniper, Splitter, Oiler, SkyBreaker
					// VERSUS
					// DoughBoy, Sniper, SkyBreaker, Oiler, Conductor, Splitter
					// 0 2 5 4 1 3

					// RamBam, Disruptor, Grappler, VineCrawler, Turtle, Regenerator
					// VERSUS
					// RamBam, Disruptor, Grappler, VineCrawler, Turtle, Regenerator

					if(tmPRI.race == "Teutonian")
					{
						scoreScreen.GetObject("p"$index$"Units").GetObject("numDoughBoy"$index).SetText(unitCount[0]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numSniper"$index).SetText(unitCount[2]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numSkyBreaker"$index).SetText(unitCount[5]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numOiler"$index).SetText(unitCount[4]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numConductor"$index).SetText(unitCount[1]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numSplitter"$index).SetText(unitCount[3]);
					}
					else if(tmPRI.race == "Alchemist")
					{
						scoreScreen.GetObject("p"$index$"Units").GetObject("numDoughBoy"$index).SetText(unitCount[0]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numSniper"$index).SetText(unitCount[1]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numSkyBreaker"$index).SetText(unitCount[2]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numOiler"$index).SetText(unitCount[3]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numConductor"$index).SetText(unitCount[4]);
						scoreScreen.GetObject("p"$index$"Units").GetObject("numSplitter"$index).SetText(unitCount[5]);
					}
				}
			}
		}

		if(numPlayers != cacheNumPlayers) {
			initScoreScreen();
		}
	}
}

simulated function tickCursorColor()
{
	//change cursor on hover
	if ((playerController.InputHandler == playerController.InputHandlerActiveCommand && 
		(playerController.InputHandlerInactiveCommand.m_CursorState == playerController.InputHandler.CursorState.CURSOR_ATTACK ||
		playerController.InputHandlerActiveCommand.m_CursorState == playerController.InputHandler.CursorState.CURSOR_ATTACK)) ||
		UDKRTSPCHUD(playerController.myHUD).CursorColor == playerController.InputHandler.CURSOR_COLOR_ATTACK)
	{
		if (prevCursorColor != CURSOR_COLOR_CODE_ATTACK)
		{
			updateCursorColorOnHover(CURSOR_COLOR_CODE_ATTACK);
			prevCursorColor = CURSOR_COLOR_CODE_ATTACK;
		}
	}
	else
	{
		if (prevCursorColor != CURSOR_COLOR_CODE_DEFAULT)
		{
			updateCursorColorOnHover(CURSOR_COLOR_CODE_DEFAULT);
			prevCursorColor = CURSOR_COLOR_CODE_DEFAULT;
		}
	}
}

simulated function updateCursorColorOnHover(int c)
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;

	if (bMouseStayHidden)
	{
		return;
	}  

	args.Length = 0;

	FunctionPath = "_root.mouse";

	if (c == CURSOR_COLOR_CODE_DEFAULT)
	{
		InvokeFunction = "setCursorNormal";
	}
	else if (c == CURSOR_COLOR_CODE_ATTACK)
	{
		InvokeFunction = "setCursorSelect";
	}
	
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function mouseMoved(float x, float y)
{
	local Vector2d screenSize;
	local float xScaled, yScaled;
	GetGameViewportClient().GetViewportSize(screenSize);

	xScaled = x / hudWidth * screenSize.X;
	yScaled = y / hudHeight * screenSize.Y;
	
	if (x != 0 && y != 0)
	{
		parentHUD.moveMouse(xScaled, yScaled);
	}
}

function mouseClicked(float x, float y)
{
	mouseMoved(x, y);
	playerController.InputHandler.notOnHud = true;
}

function addNotification(string text, int time)
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	Param0.Type = AS_String;
	Param0.s = text;

	Param1.Type = AS_Number;
	Param1.n = time;

	args.Length = 2;
	args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.notifications";
	InvokeFunction = "AddNotify";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function forceNotification(string text, int time)
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	Param0.Type = AS_String;
	Param0.s = text;

	Param1.Type = AS_Number;
	Param1.n = time;

	args.Length = 2;
	args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.notifications";
	InvokeFunction = "ForceNotify";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function clearNotifications()
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	
	args.Length = 0;

	FunctionPath = "_root.notifications";
	InvokeFunction = "ClearNotifications";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function potionSelected(string unit, string count)
{
	local ASValue Param0, Param1;
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	Param0.Type = AS_String;
	Param0.s = unit;

	Param1.Type = AS_String;
	Param1.s = count;

	args.Length = 2;
	args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root.alchemist";
	InvokeFunction = "changePotion";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function setCountdown(int time)
{
	local ASValue Param0;
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = time;

	args.Length = 1;
	args[0] = Param0;

	FunctionPath = "_root.notifications";
	InvokeFunction = "StartCountdown";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function setGameTypeText(string type)
{
	local ASValue Param0;
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	Param0.Type = AS_String;
	Param0.s = type;

	args.Length = 1;
	args[0] = Param0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "setGameType";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function showTooltip(string tt_title, string tt_description, bool showIcon, string unit1, string unit2)
{
	local ASValue Param0, Param1, Param2, Param3, Param4;
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = tt_title;
	Param1.Type = AS_String;
	Param1.s = tt_description;
	Param2.Type = AS_Boolean;
	Param2.b = showIcon;
	Param3.Type = AS_String;
	Param3.s = unit1;
	Param4.Type = AS_String;
	Param4.s = unit2;
	
	args.Length = 5;
	args[0] = Param0;
	args[1] = Param1;
	args[2] = Param2;
	args[3] = Param3;
	args[4] = Param4;

	FunctionPath = "_root";
	InvokeFunction = "showTooltip";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function hideTooltip()
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;

	args.Length = 0;

	FunctionPath = "_root";
	InvokeFunction = "hideTooltip";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function moveHintArrow(int x, int y)
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	local ASValue Param0, Param1;
	
	Param0.Type = AS_Number;
	Param0.n = x;
	Param1.Type = AS_Number;
	Param1.n = y;

	args.Length = 2;
	args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "moveHintArrow";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function rotateHintArrow(int rot)
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	local ASValue Param0;
	
	Param0.Type = AS_Number;
	Param0.n = rot;

	args.Length = 1;
	args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "rotateHintArrow";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function showHintArrow(bool v)
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	local ASValue Param0;
	
	Param0.Type = AS_Boolean;
	Param0.b = v;

	args.Length = 1;
	args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "setHintArrowVisible";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function showScores(bool v)
{
	local array<ASValue> args;
	local string FunctionPath, InvokeFunction;
	local ASValue Param0;
	
	Param0.Type = AS_Boolean;
	Param0.b = v;

	args.Length = 1;
	args[0] = Param0;

	FunctionPath = "_root.scoreScreen";
	InvokeFunction = "setVisible";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function sendTeamChatText(string text)
{
	self.sendChatText(text, TEAM_CHAT_TYPE);
}

function sendChatText(string text, string type)
{
	playerController.checkForCheatCode(text);

	--availableMessageCount;

	if (availableMessageCount < 0) 
	{
		if (availableMessageCount == -1)
		{
			parentHUD.AddConsoleMessage(CHAT_RATE_LIMITED_MESSAGE, class'TMLocalMessage', none);		
		}

		return;
	}

	if (type == TEAM_CHAT_TYPE)
	{
		playerController.TMTeamSay(text);
	}
	else if (type == ALL_CHAT_TYPE)
	{
		playerController.Say(text);
	}
}

function sendAllChatText(string text)
{
	self.sendChatText(text, ALL_CHAT_TYPE);
}

function updateInChat(bool inChat)
{
	playerController.InputHandlerInactiveCommand.isInChat = inChat;
	playerController.InputHandlerActiveCommand.isInChat = inChat;
}

function goToSettings() 
{
	//TODO
}

function quitToMenu() 
{
	local TMPlayerReplicationInfo tmPRI;
	if(playerController.PlayerReplicationInfo != none) {
		tmPRI = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo);
		quitViaMenu = true;

		if( playerController.IsAuthority() && 	// we can't be in a tutorial if we're not authority
			playerController.m_tmGameInfo.IsTutorial() )
		{
			// Travel back to tutorial menu
			playerController.ClientTravel("TM_MainMenu?game=TheMaestrosGame.TMMainMenuGameInfo?Menu=TutorialMenu?PlayerName=" $ tmPRI.PlayerName $ "?SessionToken=" $ tmPRI.SessionToken,playerController.ETravelType.TRAVEL_Absolute, false,);
		}
		else
		{
			// Go to main menu
			playerController.ClientTravel("TM_MainMenu?game=TheMaestrosGame.TMMainMenuGameInfo?Menu=MainMenu?PlayerName=" $ tmPRI.PlayerName $ "?SessionToken=" $ tmPRI.SessionToken,playerController.ETravelType.TRAVEL_Absolute, false,);
		}
	}
}

function exitToDesktop() 
{
	ConsoleCommand("exit");
}

simulated function goToEndOfGameStats()
{
	local TMPlayerReplicationInfo tmPRI;
	
	if(playerController.PlayerReplicationInfo != none) {
		tmPRI = TMPlayerReplicationInfo(playerController.PlayerReplicationInfo);

		if(!quitViaMenu)
		{
			if(playerController.m_victory)
			{
				playerController.ClientTravel("TM_MainMenu?game=TheMaestrosGame.TMMainMenuGameInfo?Menu=GameOver_Victory?PlayerName=" $ tmPRI.PlayerName $ "?SessionToken=" $ tmPRI.SessionToken,playerController.ETravelType.TRAVEL_Absolute, false,);
			}
			else
			{
				playerController.ClientTravel("TM_MainMenu?game=TheMaestrosGame.TMMainMenuGameInfo?Menu=GameOver_Defeat?PlayerName=" $ tmPRI.PlayerName $ "?SessionToken=" $ tmPRI.SessionToken,playerController.ETravelType.TRAVEL_Absolute, false,);
			}
		}
	}
}

simulated function saveEndGameStats()
{
	local TMPlayerReplicationInfo tmPRI;
	local TMEndGameStats stats;
	local int tempTime;

	if(!endGameStatsSaved)
	{
		`log("TM_GFxHUDPlayer::saveEndGameStats() saving end game stats!" );
		stats = new () class'TMEndGameStats';

		stats.numPlayers = 0;

		stats.mapName = playerController.WorldInfo.GetMapName(false);
		switch(stats.mapName)
		{
			case "sacredarena":
				stats.mapName = "Sacred Arena";
				break;
			case "fissure":
				stats.mapName = "Fissure";
				break;
			case "terra":
				stats.mapName = "Terra";
				break;
			case "crater":
				stats.mapName = "Crater";
				break;
			case "sunsetisle":
				stats.mapName = "Sunset Isle";
				break;
			case "tm_tutorial1_kismet":
			case "tm_tutorial2_kismet":
			case "tm_tutorial3":
				stats.mapName = "Tutorial";
				break;
		}

		tempTime = playerController.GetGameTime();
		//stats.gameTime = "Time: ";
		stats.gameTime $= tempTime / 60;
		stats.gameTime $= ":";
		tempTime = tempTime % 60;
		if(tempTime < 10) {
			stats.gameTime $= "0";
		}
		stats.gameTime $= tempTime;

		// Note: -1 = Server, 0 = Team 1, 1 = Team 2 (allyId)
		foreach playerController.AllActors(class'TMPlayerReplicationInfo', tmPRI)
		{
			if(tmPRI.allyId == 0 || tmPRI.allyId == 1)
			{
				stats.playerNames[stats.numPlayers] = tmPRI.PlayerName;
				stats.commanderTypes[stats.numPlayers] = tmPRI.commanderType;
				stats.race[stats.numPlayers] = tmPRI.race;
				stats.allyid[stats.numPlayers] = tmPRI.allyId;
				if (tmPRI.mIsBot)
				{
					stats.isBot[stats.numPlayers] = 1;
				}
				else
				{
					stats.isBot[stats.numPlayers] = 0;
				}

				stats.kills[stats.numPlayers] = tmPRI.mStats[PS_KILLS];
				stats.deaths[stats.numPlayers] = tmPRI.mStats[PS_DEATHS];
				stats.assists[stats.numPlayers] = tmPRI.mStats[PS_ASSISTS];

				stats.doughboy[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_DOUGHBOY];
				stats.oiler[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_OILER];
				stats.splitter[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_SPLITTER];
				stats.conductor[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_CONDUCTOR];
				stats.sniper[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_SNIPER];
				stats.skybreaker[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_SKYBREAKER];

				stats.disruptor[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_DISRUPTOR];
				stats.grappler[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_GRAPPLER];
				stats.rambam[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_RAMBAM];
				stats.vinecrawler[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_VINECRAWLER];
				stats.turtle[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_TURTLE];
				stats.regenerator[stats.numPlayers] = tmPRI.mStats[PS_SPAWNED_REGENERATOR];
				
				if(tmPRI.race == "Teutonian")
				{
					stats.unitsCreated[stats.numPlayers] = stats.oiler[stats.numPlayers] + stats.splitter[stats.numPlayers]
						+ stats.conductor[stats.numPlayers] + stats.sniper[stats.numPlayers] + stats.skybreaker[stats.numPlayers];
				}
				else if(tmPRI.race == "Alchemist")
				{
					stats.unitsCreated[stats.numPlayers] = stats.disruptor[stats.numPlayers] + stats.grappler[stats.numPlayers]
						+ stats.vinecrawler[stats.numPlayers] + stats.turtle[stats.numPlayers] + stats.regenerator[stats.numPlayers];
				}
				stats.unitsKilled[stats.numPlayers] = tmPRI.mStats[PS_UNITSKILLED];

				stats.numPlayers++;
			}
		}

		if ( self.playerController != None && self.playerController.PlayerReplicationInfo != None )
		{
			stats.save(self.playerController.PlayerReplicationInfo.PlayerName);
		}
		else
		{
			`warn("Couldn't retrieve PlayerName to write stats file off to disk");
		}


		endGameStatsSaved = true;
	}
}

simulated function showVictoryOrDefeatOverlay()
{
	if(playerController.IsSpectator() != 1)
	{
		if(playerController.m_victory)
		{
			GetVariableObject("root").GetObject("VictoryOverlay").SetBool("visible", true);
		}
		else
		{
			GetVariableObject("root").GetObject("DefeatOverlay").SetBool("visible", true);
		}
	}
}

simulated function hideVictoryOrDefeatOverlay()
{
	GetVariableObject("root").GetObject("VictoryOverlay").SetBool("visible", false);
	GetVariableObject("root").GetObject("DefeatOverlay").SetBool("visible", false);
}

simulated function flashPopulationBar()
{
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	args.Length = 0;

	FunctionPath = "_root.hudStat";
	InvokeFunction = "blinkBar";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function blinkSelect(int input) {
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = input;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "blinkSelection";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function blinkAbility(int input) {
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = input;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "blinkAbility";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

exec function blinkAbilityExec(int input) {
	blinkAbility(input);
}

exec function blinkSelectionExec(int input) {
	blinkSelect(input);
}











///// SETTINGS FUNCTIONS /////
function InitSettings()
{
	//TODO: Get all game settings and pass them via one actionscript function to the menu
	//TODO: pull actual master volume from saved settings
	local int LOD;
	local ASValue Param0;
	local ASValue Param1;
	local ASValue Param2;
	local ASValue Param3;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

    //volume from player
	Param0.Type = AS_Number;
	Param0.n = settingsMenuHelper.GetCurrentVolumeLinear() * 10;
	`log("HUD Init Master Volume with value "$ Param0.n);

	//isFullscreen
	Param1.Type = AS_Boolean;
	Param1.b = settingsMenuHelper.IsFullscreen();

	//isHigh
	LOD = settingsMenuHelper.GetLevelOfDetail();
	if (LOD == 0) {
		//low graphics quality
		Param2.Type = AS_Boolean;
		Param2.b = false;
	} else {
		//high graphics quality
		Param2.Type = AS_Boolean;
		Param2.b = true;
	}

	//push resolution to actionscript
	Param3.Type = AS_String;
	Param3.s = settingsMenuHelper.GetCurrentResolutionOption()._resolutionString;

	//set local index variable
	resolutionIndex = settingsMenuHelper.GetResolutionOptionListIndex(settingsMenuHelper.GetCurrentResolutionOption());

	args.Length = 4;
    args[0] = Param0;
    args[1] = Param1;
    args[2] = Param2;
    args[3] = Param3;

	FunctionPath = "_root.pausedMenu";
	InvokeFunction = "initSettings";
	if(pausedMenuObject == None)
	{	
		pausedMenuObject = GetVariableObject(FunctionPath);
	}

	if(pausedMenuObject != None)
	{
		pausedMenuObject.Invoke(InvokeFunction, args);
	}
}

function setLowGraphics() {
	local bool isFullscreenMode;
	local string resString;

	//save resolution and fullscreen
	resString = settingsMenuHelper.GetScreenResolution();
	isFullscreenMode = settingsMenuHelper.IsFullscreen();

	playerController.ConsoleCommand( "Scale LowEnd" );


	// Set the values that may have changed
	settingsMenuHelper.SetResolution( resString );
	settingsMenuHelper.SetIsFullscreen( isFullscreenMode );
}

function setHighGraphics() {
	local bool isFullscreenMode;
	local string resString;

	//save resolution and fullscreen
	resString = settingsMenuHelper.GetScreenResolution();
	isFullscreenMode = settingsMenuHelper.IsFullscreen();

	playerController.ConsoleCommand( "Scale HighEnd" );


	// Set the values that may have changed
	settingsMenuHelper.SetResolution( resString );
	settingsMenuHelper.SetIsFullscreen( isFullscreenMode );
}


function setFullscreen() {
	// Set the screen mode (0 = windowed, 1 = fullscreen)
	settingsMenuHelper.SetIsFullscreen(true);
}

function setWindowed() {
	// Set the screen mode (0 = windowed, 1 = fullscreen)
	settingsMenuHelper.SetIsFullscreen(false);
}

function raiseVolume() {
	if (settingsMenuHelper.GetCurrentVolumeLinear() < 10) {
		settingsMenuHelper.SetMasterVolume( (settingsMenuHelper.GetCurrentVolumeLinear() +1.0f)/10.0f );
	}
}

function lowerVolume() {
	if (settingsMenuHelper.GetCurrentVolumeLinear()  > 0) {
		settingsMenuHelper.SetMasterVolume( (settingsMenuHelper.GetCurrentVolumeLinear() -1.0f)/10.0f );
	}
}

function upResolution() {
	if (resolutionIndex == 0) {
		//at max value, do nothing
	} else {
		resolutionIndex--;
		GetVariableObject("root").GetObject("settingsMenu").GetObject("ResolutionText").SetText(settingsMenuHelper.GetResolutionFromIndex(resolutionIndex));
	}
}

function downResolution() {
	if (resolutionIndex == settingsMenuHelper.GetNumResolutionOptions()-1) {
		//at min value, do nothing
	} else {
		resolutionIndex++;
		GetVariableObject("root").GetObject("settingsMenu").GetObject("ResolutionText").SetText(settingsMenuHelper.GetResolutionFromIndex(resolutionIndex));
	}
}

function applyResolution() {
	settingsMenuHelper.SetResolution( settingsMenuHelper.GetResolutionFromIndex(resolutionIndex) );
}






defaultproperties
{
	bAllowInput = true

	MovieInfo=SwfMovie'HUDGFx.HUD'

	unitSpawned = (false, false, false, false, false, false);
	cacheUnitSpawned = (true, true, true, true, true, true);

	radialDone = (1, 1, 1, 1, 1, 1, 1);

	cacheShowTransform = true;

	CURSOR_COLOR_CODE_DEFAULT = 0x00ff00;
	CURSOR_COLOR_CODE_ATTACK = 0xff0000;

	MAX_AVAILABLE_MESSAGE_COUNT=7
	INCREMENT_MESSAGE_COUNT_TIME_SECONDS=5.0f
	CHAT_RATE_LIMITED_MESSAGE="Your message was not sent.  Please don't spam chat messages."
	TEAM_CHAT_TYPE="TEAM"
	ALL_CHAT_TYPE="ALL"

	COMMANDER_ABILITY_INDEX = 0;
	GHOST_ABILITY_INDEX = 6;
}
