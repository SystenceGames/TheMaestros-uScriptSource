class SFMFrontEndGameOver extends SFMFrontEnd;

var GFxClikWidget returnToLobbyButton;
var TMEndGameStats stats;
var TMPlayerProgressionData preMatchPlayerStats;
var Array<TMPlayerProgressionData> playerStatsArray;

var int blueCounter;
var int redCounter;

var bool exitToTutorialMenu;


/* NEW SFMFrontEndGameOver.uc goals
	1) Load the data we know first (TMEndGameStats)
	2) When player stats data comes from server load that as well (playerStatsArray)
*/

function bool Start(optional bool startPaused = false) {
	local bool retVal;
	myPC.Log( "SFMFrontEndGameOver::Start() starting!" );
	retVal = super.Start(StartPaused);

	if(myPC.startupMenu == "GameOver_Victory") {
		myPC.Log( "SFMFrontEndGameOver::Start() showing victory" );
		SetResult(true);
	} else if(myPC.startupMenu == "GameOver_Defeat") {
		myPC.Log( "SFMFrontEndGameOver::Start() showing defeat" );
		SetResult(false);
	}

	// Check if this was a battle practice (considered a tutorial)
	myPC.LoadSaveData();
	if(myPC.ShouldOpenTutorialMenu()) {
		if(myPC.mSaveData.DidJustCompleteBattlePractice()) {
			exitToTutorialMenu = true;
		}
		else {
			// Immediately go to the tutorial menu
			LoadMenu(class'SFMFrontEndTutorialMenu');
			return retVal;
		}
	}
	
	// Load stats
	initializeStats();
	loadEndGameStats();

	//set experience unlock invisible
	GetVariableObject("root").GetObject("unlockAdd").SetVisible(false);

	CurrentMenu = "GameOver";
	return retVal;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;
	bWashandled = false;
	switch(Widgetname) {
		case ('returnToLobbyButton'):
			returnToLobbyButton = GFxClikWidget(Widget);
			returnToLobbyButton.AddEventListener('CLIK_click', ReturnToLobby);
			returnToLobbyButton.AddEventListener('CLIK_click', PlayButtonSelect);
			returnToLobbyButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
	}
	return bWasHandled;
}

function ReturnToLobby(EventData data) {
	// if there is no session token (i.e. you're not logged in) go to login screen
	if (Len(myPC.mSessionToken) == 0)
	{
		`warn( "SFMFrontEndGameOver::ReturnToLobby() myPC's session token is null! Returning to login screen" );
		myPC.startupMenu = "";
		LoadMenu(class'SFMFrontEndLogin');
	}
	else if (exitToTutorialMenu)
	{
		LoadMenu(class'SFMFrontEndTutorialMenu');
	}
	else
	{
		LoadMenu(class'SFMFrontEndMainMenu');
	}
}

function SetResult(bool victory) {
	if(victory) {
		GetVariableObject("root").GetObject("scoreScreenVictory").SetVisible(true);
		GetVariableObject("root").GetObject("scoreScreenDefeat").SetVisible(false);
	} else {
		GetVariableObject("root").GetObject("scoreScreenVictory").SetVisible(false);
		GetVariableObject("root").GetObject("scoreScreenDefeat").SetVisible(true);
	}
}

function initializeStats()
{
	local int i;
	local Array<string> playerNames;
	local TMEndGameStats emptyStats;

	local TM_TEMP_PlayerNamesList playerNamesList;
	local string tempPlayerName;
	local bool haveRealStats;

	// Prematch player stats
	preMatchPlayerStats = new () class'TMPlayerProgressionData';
	if(	!class'Engine'.static.BasicLoadObject(preMatchPlayerStats, "PreMatchPlayerStats"$myPC.username$".bin", false, 0) )
	{
		`warn( "SFMFrontEndGameOver::loadPreMatchPlayerStats() don't have pre match player stats saved!" );
		preMatchPlayerStats.playerName = myPC.username;
	}

	myPC.Log( "SFMFrontEndGameOver::initializeStats() have preMatchPlayerStats for " $ preMatchPlayerStats.playerName $ " with " $ preMatchPlayerStats.gamesPlayed $ " games played." );

	// End game stats
	stats = new () class'TMEndGameStats';
	class'Engine'.static.BasicLoadObject(stats, "GameStats"$myPC.username$".bin", false, 0);

	// Ask the platform for all players' new end game stats
	myPC.Log( "SFMFrontEndGameOver::initializeStats() loading players..." );
	haveRealStats = false;
	for( i = 0; i < 6; i++ )
	{
		myPC.Log( "SFMFrontEndGameOver::initializeStats() got player name " $ stats.playerNames[i] );
		if( stats.playerNames[i] != "")
		{
			if (stats.isBot[i] > 0)
			{
				`log("Not adding playername: "$stats.playerNames[i]$" because they are a bot", true, 'dru'); 
			}
			else
			{
				playerNames.AddItem( stats.playerNames[i] );
			}

			haveRealStats = true;
		}
	}

	if( !haveRealStats )
	{
		// Taylor TODO: fix our break and remove this shitty system. Need saveEndGameStats() to be called at end of EVERY game
		myPC.Log( "SFMFrontEndGameOver::initializeStats() using cheating player names system for tutorial" );
		// Somehow broke for tutorial. Use our cheating player names system
		playerNamesList = new class'TM_TEMP_PlayerNamesList'();
		class'Engine'.static.BasicLoadObject(playerNamesList, "TEMP_BattlePracticePlayersList.bin", false, 0);
		foreach playerNamesList.playerNames( tempPlayerName )
		{
			myPC.Log( "SFMFrontEndGameOver::initializeStats() adding fake player " $ tempPlayerName );
			playerNames.AddItem( tempPlayerName );
		}
	}

	// Erase the GameStats bin
	emptyStats = new () class'TMEndGameStats';
	emptyStats.save(myPC.username);

	myPC.PostGetEndGamePlayerStats( playerNames, preMatchPlayerStats.gamesPlayed+1 );
}


function loadPlayerProgressionStats( TMGetEndGamePlayerStatsResponse getEndGamePlayerStatsResponse)
{
	local int i;
	local int j;
	local ASValue Param0;
	local ASValue Param1;
	local ASValue Param2;
	local ASValue Param3;
	local ASValue Param4;
	local ASValue Param5;
	local ASValue Param6;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;
    local TMEndGamePlayerStats progData;

	progData = getEndGamePlayerStatsResponse.endGamePlayerStats;

   	if( progData != none)
   	{
	   	Param0.Type = AS_Number;
		Param1.Type = AS_Number;
		Param2.Type = AS_Number;
		Param3.Type = AS_Number;
		Param4.Type = AS_Number;
		Param5.Type = AS_Number;
		Param6.Type = AS_Number;

		Param0.n = progData.currentExperience;
		Param1.n = progData.experienceForNextLevel;
		Param2.n = progData.currentLevel;
		Param3.n = preMatchPlayerStats.currentExperience;
		Param4.n = preMatchPlayerStats.experienceForNextLevel;
		Param5.n = preMatchPlayerStats.currentLevel;
		Param6.n = progData.experienceGained;

		//`log(progData.currentExperience $ "+" $ progData.experienceForNextLevel $ "+" $ progData.currentLevel, true, 'Mark');
		//`log(preMatchPlayerStats.currentExperience $ "+" $ preMatchPlayerStats.experienceForNextLevel $ "+" $ preMatchPlayerStats.currentLevel, true, 'Mark');

		args.Length = 7;
	    args[0] = Param0;
		args[1] = Param1;
		args[2] = Param2;
		args[3] = Param3;
		args[4] = Param4;
		args[5] = Param5;
		args[6] = Param6;

		FunctionPath = "_root";
		InvokeFunction = "testScale";
		if(GetVariableObject(FunctionPath) != none)
		{
			GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
		}
   	}

    playerStatsArray = getEndGamePlayerStatsResponse.playerStatsList;

	//set level for each player
	blueCounter = 0;
	redCounter = 3;
	for(i = 0; i < stats.numPlayers; i++) {
		
		for(j = 0; j < playerStatsArray.Length; j++) {
			if (stats.playerNames[i] == playerStatsArray[j].playerName) {
				//found a j index to match the name in the i index
				break;
			}
		}

		if (j == playerStatsArray.Length)
		{
			`log("TMPlayerProgressionData for " $ stats.playerNames[i] $ " doesn't exist (probably bot), and TMEndGameStats exist at index " $ i, true, 'Mark');
		}
		else
		{
			`log("TMPlayerProgressionData for " $ stats.playerNames[i] $ " exist at index " $ j $ " and TMEndGameStats exist at index " $ i, true, 'Mark');
		}


		if(stats.allyid[i] == 0) {
			blueCounter++;

			//bot check
			if (stats.isBot[i] > 0) {
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("playerLevel"$blueCounter).SetVisible(false);
			} 
			else
			{
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("playerLevel"$blueCounter).SetText(playerStatsArray[j].currentLevel);
			}
		} else if (stats.allyid[i] == 1) {
			redCounter++;

			//bot check
			if (stats.isBot[i] > 0) {
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("playerLevel"$redCounter).SetVisible(false);
			}
			else
			{
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("playerLevel"$redCounter).SetText(playerStatsArray[j].currentLevel);
			}
		} else {
			`log("ERROR: PLAYER'S ALLYID WAS NOT 0 OR 1 FOR SCORE SCREEN");
		}
	}

	// Trigger unlockables
	if (progData.unlockedItems.length != 0) {
		GetVariableObject("root").GetObject("unlockAdd").SetVisible(true);
		loadUnlockables(progData.unlockedItems[0]);
		menuAudio.PlayLogOutSuccess();

		// If we unlocked the RamBamQueen, we should now have the alchemist tutorial unlocked. Exit to the tutorial when we leave
		if (progData.unlockedItems[0] == "RamBamQueen") {
			exitToTutorialMenu = true;
		}
	} else {
		menuAudio.PlayGameStart();
	}

	//show next unlock
	showNextUnlock(progData.nextUnlockAt);
}

function showNextUnlock(int nextLevel) {
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;
	//`log("desaturating " $ playerNum $ " player " $ unitNum $ " and unit", true, 'Mark');

	Param0.Type = AS_Number;
	Param0.n = nextLevel;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "nextUnlockAt";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function loadUnlockables(String commander) {
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;
	//`log("desaturating " $ playerNum $ " player " $ unitNum $ " and unit", true, 'Mark');

	Param0.Type = AS_String;
	Param0.s = commander;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "showUnlock";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

// Mark TODO: make this only load the stuff we know without needing playerstats
function loadEndGameStats()
{
	local int i;
	//local int maxUnitsCreated;
	local int maxUnitsKilled;
	//local float unitsCreatedScale;
	local float unitsKilledScale;
	//local playerStats object

	blueCounter = 1;
	redCounter = 4;
	//maxUnitsCreated = 0;
	maxUnitsKilled = 0;


	for(i = 0; i < stats.numPlayers; i++)
	{
		/*if(stats.unitsCreated[i] > maxUnitsCreated) {
			maxUnitsCreated = stats.unitsCreated[i];
		}*/
		if(stats.unitsKilled[i] > maxUnitsKilled) {
			maxUnitsKilled = stats.unitsKilled[i];
		}
	}
	//`log("Players Num " $ stats.numPlayers, true, 'Mark');
	for(i = 0; i < stats.numPlayers; i++)
	{   
		if(stats.allyid[i] == 0)
		{

			//`log("Attempting to desaturate " $ blueCounter, true, 'Mark');
			desaturatePlayerUnits(blueCounter, i);

			GetVariableObject("root").GetObject("p"$blueCounter$"Info").SetVisible(true);
			if (stats.commanderTypes[i] == "Rosie") {
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("commanderName"$blueCounter).SetText("BlastMeister");
			} else {
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("commanderName"$blueCounter).SetText(stats.commanderTypes[i]);
			}
			GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("username"$blueCounter).SetText(stats.playerNames[i]);

			GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("kda"$blueCounter).SetText(stats.kills[i] $ "/" $ stats.deaths[i] $ "/" $ stats.assists[i]);

			//GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("mCreated"$blueCounter).SetText(stats.unitsCreated[i]);
			GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("mKilled"$blueCounter).SetText(stats.unitsKilled[i]);

			/*if(maxUnitsCreated != 0) {
				unitsCreatedScale = float(stats.unitsCreated[i]) / maxUnitsCreated;
			} else {
				unitsCreatedScale = 0;
			}*/
			if(maxUnitsKilled != 0) {
				unitsKilledScale = float(stats.unitsKilled[i]) / maxUnitsKilled;
			} else {
				unitsKilledScale = 0;
			}
			//GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("mCreatedBar"$blueCounter).SetFloat("scaleX", unitsCreatedScale);
			GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("mKilledBar"$blueCounter).SetFloat("scaleX", unitsKilledScale);

			if(stats.race[i] == "Teutonian")
			{
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u1Created"$blueCounter).SetText(stats.doughboy[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u2Created"$blueCounter).SetText(stats.sniper[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u3Created"$blueCounter).SetText(stats.skybreaker[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u4Created"$blueCounter).SetText(stats.oiler[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u5Created"$blueCounter).SetText(stats.conductor[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u6Created"$blueCounter).SetText(stats.splitter[i]);
			}
			else if(stats.race[i] == "Alchemist")
			{
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u1Created"$blueCounter).SetText(stats.rambam[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u2Created"$blueCounter).SetText(stats.disruptor[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u3Created"$blueCounter).SetText(stats.grappler[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u4Created"$blueCounter).SetText(stats.vinecrawler[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u5Created"$blueCounter).SetText(stats.turtle[i]);
				GetVariableObject("root").GetObject("p"$blueCounter$"Info").GetObject("u6Created"$blueCounter).SetText(stats.regenerator[i]);
			}

			updateScoreScreenCommander(blueCounter, stats.commanderTypes[i]);

			blueCounter++;
		}
		else if(stats.allyid[i] == 1)
		{

			desaturatePlayerUnits(redCounter, i);

			GetVariableObject("root").GetObject("p"$redCounter$"Info").SetVisible(true);
			if (stats.commanderTypes[i] == "Rosie") {
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("commanderName"$redCounter).SetText("BlastMeister");
			} else {
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("commanderName"$redCounter).SetText(stats.commanderTypes[i]);
			}
			GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("username"$redCounter).SetText(stats.playerNames[i]);

			GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("kda"$redCounter).SetText(stats.kills[i] $ "/" $ stats.deaths[i] $ "/" $ stats.assists[i]);

			//GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("mCreated"$redCounter).SetText(stats.unitsCreated[i]);
			GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("mKilled"$redCounter).SetText(stats.unitsKilled[i]);

			/*if(maxUnitsCreated != 0) {
				unitsCreatedScale = float(stats.unitsCreated[i]) / maxUnitsCreated;
			} else {
				unitsCreatedScale = 0;
			}*/
			if(maxUnitsKilled != 0) {
				unitsKilledScale = float(stats.unitsKilled[i]) / maxUnitsKilled;
			} else {
				unitsKilledScale = 0;
			}
			//GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("mCreatedBar"$redCounter).SetFloat("scaleX", unitsCreatedScale);
			GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("mKilledBar"$redCounter).SetFloat("scaleX", unitsKilledScale);

			if(stats.race[i] == "Teutonian")
			{
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u1Created"$redCounter).SetText(stats.doughboy[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u2Created"$redCounter).SetText(stats.sniper[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u3Created"$redCounter).SetText(stats.skybreaker[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u4Created"$redCounter).SetText(stats.oiler[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u5Created"$redCounter).SetText(stats.conductor[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u6Created"$redCounter).SetText(stats.splitter[i]);
			}
			else if(stats.race[i] == "Alchemist")
			{
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u1Created"$redCounter).SetText(stats.rambam[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u2Created"$redCounter).SetText(stats.disruptor[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u3Created"$redCounter).SetText(stats.grappler[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u4Created"$redCounter).SetText(stats.vinecrawler[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u5Created"$redCounter).SetText(stats.turtle[i]);
				GetVariableObject("root").GetObject("p"$redCounter$"Info").GetObject("u6Created"$redCounter).SetText(stats.regenerator[i]);
			}

			updateScoreScreenCommander(redCounter, stats.commanderTypes[i]);

			redCounter++;
		}
		else
		{
			`log("ERROR: PLAYER'S ALLYID WAS NOT 0 OR 1 FOR SCORE SCREEN");
		}
	}

	GetVariableObject("root").GetObject("mapName").SetText(stats.mapName);
	GetVariableObject("root").GetObject("gameTime").SetText(stats.gameTime);
}


function desaturatePlayerUnits(int displayNum, int playerNum) {

	if(stats.race[playerNum] == "Teutonian") {
		if (stats.doughboy[playerNum] == 0) {
			desaturate(displayNum, 1);
		}

		if (stats.oiler[playerNum] == 0) {
			desaturate(displayNum, 4);
		}

		if (stats.splitter[playerNum] == 0) {
			desaturate(displayNum, 6);
		}

		if (stats.conductor[playerNum] == 0) {
			desaturate(displayNum, 5);
		}

		if (stats.sniper[playerNum] == 0) {
			desaturate(displayNum, 2);
		}

		if (stats.skybreaker[playerNum] == 0) {
			desaturate(displayNum, 3);
		}

	} else if(stats.race[playerNum] == "Alchemist") {
		if (stats.disruptor[playerNum] == 0) {
			desaturate(displayNum, 2);
		}

		if (stats.grappler[playerNum] == 0) {
			desaturate(displayNum, 3);
		}

		if (stats.rambam[playerNum] == 0) {
			desaturate(displayNum, 1);
		}

		if (stats.vinecrawler[playerNum] == 0) {
			desaturate(displayNum, 4);
		}

		if (stats.turtle[playerNum] == 0) {
			desaturate(displayNum, 5);
		}

		if (stats.regenerator[playerNum] == 0) {
			desaturate(displayNum, 6);
		}
	}
}

simulated function desaturate(int displayNum, int unitNum) {
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;
	//`log("desaturating " $ playerNum $ " player " $ unitNum $ " and unit", true, 'Mark');

	Param0.Type = AS_Number;
	Param0.n = displayNum;

	Param1.Type = AS_Number;
	Param1.n = unitNum;

	args.Length = 2;
    args[0] = Param0;
	args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "desaturate";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

simulated function updateScoreScreenCommander(int playerNum, string commander)
{
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = playerNum;

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



/* Needs Kismet. Copy/Paste Kismet into map from testingMap3:
 * 
 * Syntax:
 * var SFMFrontEndGameOver EndGameOverlay;
 * EndGameOverlay = new () class'SFMFrontEndGameOver';
 * EndGameOverlay.DisplayEndGameOverlay();
 * EndGameOverlay.SetWinnerLoser("Red Team", "Blue Team");
 * 
 * Can change params for SetWinnerLoser later.
 * Also, can't figure out how to turn off HUD from this class alone. May need to turn off manually?
 */
/*
function DisplayEndGameOverlay() {
	local int i;
    local Sequence GameSeq;
    local array<SequenceObject> AllSeqEvents;

	GameSeq = class'WorldInfo'.static.GetWorldInfo().GetGameSequence();
	if(GameSeq != None) {
		GameSeq.FindSeqObjectsByClass(class'TMSeqEvent_GameEnded', true, AllSeqEvents); //iterate over all events of some type
		for(i=0; i<AllSeqEvents.Length; i++)
			TMSeqEvent_GameEnded(AllSeqEvents[i]).CheckActivate(class'WorldInfo'.static.GetWorldInfo(), None); //trigger it!
	}

	//self.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
	self.SetTimingMode( TM_Real );  // need this so everything doesn't get paused in menu
	self.Start(); // call our movies init	
}

function SetWinnerLoser(string Winner, string Loser) {
	//winnerText.SetText("Winner: " $ Winner);
	//loserText.SetText("Loser: " $ Loser);
}
*/

DefaultProperties
{
	MovieInfo=SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_GameOver'
	WidgetBindings.Add((WidgetName="returnToLobbyButton",WidgetClass=class'GFxCLIKWidget'))
	//WidgetBindings.Add((WidgetName="victoryBtn",WidgetClass=class'GFxCLIKWidget'))
	//WidgetBindings.Add((WidgetName="defeatBtn",WidgetClass=class'GFxCLIKWidget'))

	// the HUD is turned off in this menu so let's make sure it will still show up
	bDisplayWithHudOff = true

	// we need this to capture user input
	bAllowInput = true
	bCaptureInput = true

	bHideLesserMovies = true
	bPauseGameWhileActive = false
}
