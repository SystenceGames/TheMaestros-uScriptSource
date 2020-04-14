class SFMFrontEndTeamSelect extends SFMFrontEnd;

var GFxClikWidget mapNameDDM, gameTypeDDM, teamDDM, startBtn, quitBtn, team1SL, team2SL, spectatorSL, chatLog, sendBtn, t1AddBotBtn, t2AddBotBtn;
var GFxClikWidget t1p1RemoveBtn, t1p2RemoveBtn, t1p3RemoveBtn, t2p1RemoveBtn, t2p2RemoveBtn, t2p3RemoveBtn, t3p1RemoveBtn, t3p2RemoveBtn;
var GFxClikWidget t1p1DifficultyDDM, t1p2DifficultyDDM, t1p3DifficultyDDM, t2p1DifficultyDDM, t2p2DifficultyDDM, t2p3DifficultyDDM;
var GFxClikWidget inviteList;
var array<string> team1;
var array<string> team2;
var array<string> spectators;
var array<string> bots;
var array<string> availableBotDifficulties;
var array<TMPlayerprogressionData> playerStatsArray;
var array<TMSteamFriend> friends;
var int cachedNumPlayers;

function bool Start(optional bool startPaused = false) {
	local Array< string > usernames;
	local bool retVal;
	retVal = super.Start(startPaused);
	SetMotD(myPC.MotD);
	CurrentMenu = "TeamSelect";

	usernames.AddItem( myPC.username );
	myPC.PostGetPlayerStats( usernames );

	//this ensures we stop calling post list games on team select initiation
	myPC.ClearTimer('PostListGames');
	return retVal;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;
	bWashandled = false;
	switch(Widgetname) {
		case ('mapNameDDM'):
			mapNameDDM = GFxClikWidget(Widget);
			mapNameDDM.AddEventListener('CLIK_listIndexChange', MapChanged);
			mapNameDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			mapNameDDM.SetInt("menuRowCount", 4);
			bWasHandled = true;
			break;
		case ('gameTypeDDM'):
			gameTypeDDM = GFxClikWidget(Widget);
			gameTypeDDM.AddEventListener('CLIK_listIndexChange', GameTypeChanged);
			gameTypeDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			gameTypeDDM.SetInt("menuRowCount", 2);
			bWasHandled = true;
			break;
		case ('teamDDM'):
			teamDDM = GFxClikWidget(Widget);
			teamDDM.AddEventListener('CLIK_listIndexChange', TeamChanged);
			teamDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('startBtn'):
			startBtn = GFxClikWidget(Widget);
			startBtn.AddEventListener('CLIK_click', StartGame);
			startBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('quitBtn'):
			quitBtn = GFxClikWidget(Widget);
			quitBtn.AddEventListener('CLIK_click', GoBack);
			quitBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			quitBtn.AddEventListener('CLIK_click', PlayCancel);
			bWasHandled = true;
			break;
		case ('team1SL'):
			team1SL = GFxClikWidget(Widget);
			bWasHandled = true;
			break;
		case ('team2SL'):
			team2SL = GFxClikWidget(Widget);
			bWasHandled = true;
			break;
		case ('spectatorSL'):
			spectatorSL = GFxClikWidget(Widget);
			bWasHandled = true;
			break;
		case ('chatLog'):
			chatLog = GFxClikWidget(Widget);
			bWasHandled = true;

			// Quick chat log init, for looks.
			chatLog.SetText(" ");
			break;
		//customGameSL is our Steam Friends scrolling list !!!
		case ('customGameSL'):
			inviteList = GFxClikWidget(Widget);
			bWasHandled = true;
			break;
		case ('sendBtn'):
			sendBtn = GFxClikWidget(Widget);
			sendBtn.AddEventListener('CLIK_click', SendChat);
			sendBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;

		case ('t1AddBotBtn'):
			t1AddBotBtn = GFxClikWidget(Widget);
			t1AddBotBtn.AddEventListener('CLIK_click', AddBot);
			t1AddBotBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			//t1AddBotBtn.AddEventListener('CLIK_click', PlayTeamSwap);
			bWasHandled = true;
			break;
		case ('t2AddBotBtn'):
			t2AddBotBtn = GFxClikWidget(Widget);
			t2AddBotBtn.AddEventListener('CLIK_click', AddBot);
			t2AddBotBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			//t2AddBotBtn.AddEventListener('CLIK_click', PlayTeamSwap);
			bWasHandled = true;
			break;

		case ('t1p1RemoveBtn'):
			t1p1RemoveBtn = GFxClikWidget(Widget);
			t1p1RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t1p1RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t1p1RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t1p2RemoveBtn'):
			t1p2RemoveBtn = GFxClikWidget(Widget);
			t1p2RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t1p2RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t1p2RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t1p3RemoveBtn'):
			t1p3RemoveBtn = GFxClikWidget(Widget);
			t1p3RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t1p3RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t1p3RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t2p1RemoveBtn'):
			t2p1RemoveBtn = GFxClikWidget(Widget);
			t2p1RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t2p1RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t2p1RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t2p2RemoveBtn'):
			t2p2RemoveBtn = GFxClikWidget(Widget);
			t2p2RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t2p2RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t2p2RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t2p3RemoveBtn'):
			t2p3RemoveBtn = GFxClikWidget(Widget);
			t2p3RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t2p3RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t2p3RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t3p1RemoveBtn'):
			t3p1RemoveBtn = GFxClikWidget(Widget);
			t3p1RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t3p1RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t3p1RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;
		case ('t3p2RemoveBtn'):
			t3p2RemoveBtn = GFxClikWidget(Widget);
			t3p2RemoveBtn.AddEventListener('CLIK_click', RemovePlayer);
			t3p2RemoveBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			t3p2RemoveBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			bWasHandled = true;
			break;

		case ('t1p1DifficultyDDM'):
			t1p1DifficultyDDM = GFxClikWidget(Widget);
			t1p1DifficultyDDM.AddEventListener('CLIK_listIndexChange', BotDifficultyChanged);
			t1p1DifficultyDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('t1p2DifficultyDDM'):
			t1p2DifficultyDDM = GFxClikWidget(Widget);
			t1p2DifficultyDDM.AddEventListener('CLIK_listIndexChange', BotDifficultyChanged);
			t1p2DifficultyDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('t1p3DifficultyDDM'):
			t1p3DifficultyDDM = GFxClikWidget(Widget);
			t1p3DifficultyDDM.AddEventListener('CLIK_listIndexChange', BotDifficultyChanged);
			t1p3DifficultyDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('t2p1DifficultyDDM'):
			t2p1DifficultyDDM = GFxClikWidget(Widget);
			t2p1DifficultyDDM.AddEventListener('CLIK_listIndexChange', BotDifficultyChanged);
			t2p1DifficultyDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('t2p2DifficultyDDM'):
			t2p2DifficultyDDM = GFxClikWidget(Widget);
			t2p2DifficultyDDM.AddEventListener('CLIK_listIndexChange', BotDifficultyChanged);
			t2p2DifficultyDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('t2p3DifficultyDDM'):
			t2p3DifficultyDDM = GFxClikWidget(Widget);
			t2p3DifficultyDDM.AddEventListener('CLIK_listIndexChange', BotDifficultyChanged);
			t2p3DifficultyDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
	}
	return bWasHandled;
}

function bool UpdateGameInfo(JSONObject commandObject) {
	local array<ASValue> args;
	local array<string> t1;
	local array<string> t2;
	local array<string> spec;
	local array<string> b;
	local int i;
	local int j;
	local bool userFound;
	//local JSONObject jobj;
	local string playerName;
	local int teamNumber;
	local bool isBot;
	local int botDifficulty;
	local int index;
	local string host;
	//progression stuffs
	local Array<string> baseUsernames;
	local Array<string> newUsernames;

	//compare new users against base list for missing players
	/*for(i = 0; i<baseUsernames.length; i++) {
		userFound = false;
		for(j = 0; j<commandObject.GetObject("players").ObjectArray.Length; j++) {
			if (commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName") == baseUsernames[j]) {
				userFound = true;
				break;
			}
		}

		if (!userFound) {
			leftUsernames.AddItem(baseUsernames[i]);
		}
	}*/

	if(super.UpdateGameInfo(commandObject)) { return true; }

	args.Length = 0; // Making it explicit for the compiler that we want this guy empty - avoids warnings.

	HideAllPerSlotWidgets();

	GetVariableObject("root").GetObject("gameName").SetText(commandObject.GetStringValue("gameName"));
	for(i = 0; i < commandObject.GetObject("players").ObjectArray.Length; i++) {
		if(commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName") == myPC.username) {
			if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 1)
				myPC.ally = 0;
			else if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 2)
				myPC.ally = 1;
			else if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 3)
				myPC.ally = 2;
			//break;
		}

		///call myPC.PostPlayerStats at some point
	}

	teamDDM.SetInt("selectedIndex", myPC.ally);

	myPC.gameTypeToLoad = commandObject.GetStringValue("gameType");

	if(myPC.gameTypeToLoad == "TheMaestrosGame.TMRoundBasedGameInfo") {
		gameTypeDDM.SetInt("selectedIndex", 0);
	} else if(myPC.gameTypeToLoad == "TheMaestrosGame.TMDMGameInfo") {
		gameTypeDDM.SetInt("selectedIndex", 1);
	}

	// Other game modes. Add these back in when we want them
	// } else if(myPC.gameTypeToLoad == "TheMaestrosGame.TMNexusCommandersGameInfo") {
	// 	gameTypeDDM.SetInt("selectedIndex", 1);
	// }
	// } else if(myPC.gameTypeToLoad == "TheMaestrosGame.TMDMGameInfo") {
	// 	gameTypeDDM.SetInt("selectedIndex", 1);
	// } else if(myPC.gameTypeToLoad == "TheMaestrosGame.TMGameInfo") {
	// 	gameTypeDDM.SetInt("selectedIndex", 2);
	// }
	
	myPC.mapToLoad = commandObject.GetStringValue("mapName");

	for(i = 0; i < myPC.GetMapsList().Length; ++i)
	{
		if(myPC.mapToLoad == ParseMapName(myPC.GetMapsList()[i]))
		{
			mapNameDDM.SetInt("selectedIndex", i);
			break;
		}
	}

	host =  commandObject.GetStringValue("host");
	myPC.isLobbyHost = host == myPC.username;

	startBtn.SetBool("enabled", myPC.isLobbyHost);
	mapNameDDM.SetBool("enabled", myPC.isLobbyHost);
	gameTypeDDM.SetBool("enabled", myPC.isLobbyHost);
	t1AddBotBtn.SetBool("enabled", myPC.isLobbyHost);
	t2AddBotBtn.SetBool("enabled", myPC.isLobbyHost);

	for(i = 0; i < commandObject.GetObject("players").ObjectArray.Length; i++)
	{
		teamNumber = commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber");
		playerName = commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName");
		isBot = commandObject.GetObject("players").ObjectArray[i].GetBoolValue("isBot");
		botDifficulty = commandObject.GetObject("players").ObjectArray[i].GetIntValue("botDifficulty");

		if(teamNumber == 1)
		{
			t1.AddItem(playerName);
			index = t1.Length;
		}
		else if(teamNumber == 2)
		{
			t2.AddItem(playerName);
			index = t2.Length;
		}
		else if(teamNumber == 3)
		{
			spec.AddItem(playerName);
			index = spec.Length;
		}

		if (playerName == host)
		{
			GetVariableObject("root").GetObject("t" $ teamNumber $ "p" $ index $ "Crown").SetVisible(true);
		}
		if (( teamNumber == 1 || teamNumber == 2))
		{
			if (isBot) {
				GetVariableObject("root").GetObject("t" $ teamNumber $ "p" $ index $ "DifficultyDDM").SetBool("enabled", myPC.isLobbyHost);
				GetVariableObject("root").GetObject("t" $ teamNumber $ "p" $ index $ "DifficultyDDM").SetVisible(true);
				GetVariableObject("root").GetObject("t" $ teamNumber $ "p" $ index $ "DifficultyDDM").SetInt("selectedIndex", botDifficulty-1);
			} else {
				GetVariableObject("root").GetObject("t" $ teamNumber $ "p" $ index $ "DifficultyDDM").SetVisible(false);
			}
			GetVariableObject("root").GetObject("t" $ teamNumber $ "p" $ index $ "RemoveBtn").SetVisible(myPC.isLobbyHost && myPC.username != playerName);
		} else {
			//not a player
		}
		if (isBot) {
			b.AddItem(playerName);
		}

	}

	//hide prog data if teams are empty
	if (t1.length == 0) {
			for (i = 0; i<3; i++) {
				GetVariableObject("root").GetObject("team1rend" $ i+1).SetVisible(false);
			}
	}
	if (t2.length == 0) {
			for (i = 0; i<3; i++) {
				GetVariableObject("root").GetObject("team2rend" $ i+1).SetVisible(false);
			}
	}
	
	updateMinimap(commandObject.GetStringValue("mapName"));

	//create combined base player list
	for(i = 0; i<team1.length; i++) {
		baseUsernames.AddItem(team1[i]);
	}
	for(i = 0; i<team2.length; i++) {
		baseUsernames.AddItem(team2[i]);
	}
	for(i = 0; i<spec.length; i++) {
		baseUsernames.AddItem(spec[i]);
	}
	for(i = 0; i<bots.length; i++) {
		baseUsernames.AddItem(bots[i]);
	}

	//compare new users list against base list for new players
	for(i = 0; i<commandObject.GetObject("players").ObjectArray.Length; i++) {
		userFound = false;
		for(j = 0; j<baseUsernames.length; j++) {
			if (commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName") == baseUsernames[j]) {
				userFound = true;
				break;
			}
		}

		if (!userFound && !commandObject.GetObject("players").ObjectArray[i].GetBoolValue("isBot")) {
			newUsernames.AddItem(commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName"));
		}
	}

	if (cachedNumPlayers < commandObject.GetObject("players").ObjectArray.Length && cachedNumPlayers != 0) {
		menuAudio.PlayTeamSwap();
		myPC.platformConnection.FlashWindowUntilFocus();
	}

	cachedNumPlayers = commandObject.GetObject("players").ObjectArray.Length;

	//reload saved player stats just to get rid of leaving players

	 myPC.PostGetPlayerStats( newUsernames );


	team1 = t1;
	team2 = t2;
	spectators = spec;
	bots = b;
	team1SL.GetObject("dataProvider").Invoke("invalidate", args);
	team2SL.GetObject("dataProvider").Invoke("invalidate", args);
	spectatorSL.GetObject("dataProvider").Invoke("invalidate", args);

	loadPlayerStats( playerStatsArray );

	return false;
}

function HideAllPerSlotWidgets() 
{
	HideAllCrowns();
	HideAllRemoveButtons();
	HideAllDifficultyDDM();
}

function HideAllDifficultyDDM()
{
	local int team;
	local int i; 

	for (team = 1; team < 3; ++team)
	{
		for (i = 1; i < 4; ++i)
		{
			GetVariableObject("root").GetObject("t" $ team $ "p" $ i $ "DifficultyDDM").SetVisible(false);
		}
	}
}

function HideAllRemoveButtons()
{
	local int team;
	local int i;

	for (team = 1; team < 3; ++team)
	{
		for (i = 1; i < 4; ++i)
		{
			GetVariableObject("root").GetObject("t" $ team $ "p" $ i $ "RemoveBtn").SetVisible(false);
		}
	}
}

function HideAllCrowns()
{
	local int i;
	local int team;

	for (team = 1; team <= 3; ++team)
	{
		for (i = 1; i <= 3; ++i)
		{
			if (i != 3 || team != 3)
			{
				GetVariableObject("root").GetObject("t" $ team $ "p" $ i $ "Crown").SetVisible(false);
			}
		}
	}
}

function array<string> GetTeam1PlayerNames() {
	return team1;
}

function array<string> GetTeam2PlayerNames() {
	return team2;
}

function array<string> GetSpectatorPlayerNames() {
	return spectators;
}

function StartGame(EventData data) {
	myPC.PostLockTeams();
	DisableStartBtn();
}

function GoBack(EventData data) {
	myPC.CallSwitchRoom("allChat");
	myPC.LeaveLobby(myPC.DISCONNECT_REASON_QUIT);
	DisableBackBtn();
}

function string ParseMapName(string mapName)
{
	mapName = Split(mapName, ")", true);

	mapName = Trim(mapName);
	
	mapName = Repl(mapname, " ", "", false);

	return mapName;
}

function MapChanged(EventData data) {
	local string mapName;

	// This is hacky, but make it so you can't change the map if you're in NexusCommanders mode. Need better solution with UI/art support later
	if(myPC.gameTypeToLoad == "TheMaestrosGame.TMNexusCommandersGameInfo") {
		return;
	}

	mapName = ParseMapName(myPC.GetMapsList()[mapNameDDM.GetInt("selectedIndex")]);
	myPC.PostChangeMap(mapName);
}

function GameTypeChanged(EventData data) {
	local string gameType;
	local string fullGameType;
	gameType = myPC.gameTypeList[gameTypeDDM.GetInt("selectedIndex")];
	if(gameType == "Round Based") {
		fullGameType = "TheMaestrosGame.TMRoundBasedGameInfo";
	} else if(gameType == "Team Deathmatch") {
		fullGameType = "TheMaestrosGame.TMDMGameInfo";
	} else if(gameType == "Team Stock") {
		fullGameType = "TheMaestrosGame.TMGameInfo";
	} else if(gameType == "Nexus Commanders") {
		fullGameType = "TheMaestrosGame.TMNexusCommandersGameInfo";
		myPC.PostChangeMap("SacredArena2"); 	// switch to SacredArena2 if we're playin NexusCommanders mode
	}

	myPC.PostChangeGameType(fullGameType);
}

function TeamChanged(EventData data) {
	myPC.PostSwitchTeam(teamDDM.GetInt("selectedIndex") + 1);
}

function UpdateTeamDDM() {
	teamDDM.SetInt("selectedIndex", myPC.ally);
}

function SetMotD(string motd) {
	GetVariableObject("root").GetObject("motdText").SetText(motd);
}

function SetError(string error) {
	local string preText;
	if(error != "") {
		preText = "ERROR: ";
		menuAudio.PlayError();
	}
	GetVariableObject("root").GetObject("errorText").SetText(preText $ error);
}

function SendChat(EventData data) {
	SendChatMessage();
}

function SendChatMessage() {
	local GFxObject chatInput;

	chatInput = GetVariableObject("root").GetObject("chatInput");

	if(chatInput.GetText() != "") {
		myPC.SendChatMessage(chatInput.GetText());
		chatInput.SetText("");
		menuAudio.PlayChatSend();
	}
}

function ReceiveChatMessage(string message) {
	chatLog.SetText(chatLog.GetText() $ message $ "\n ");
	chatLog.GetObject("textField").SetInt("scrollV", chatLog.GetObject("textField").GetInt("maxScrollV"));
	myPC.platformConnection.FlashWindowUntilFocus();
}

function updateMinimap(string map)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = map;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "updateMinimap";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function array<GFxObject> ListMaps() {
	local int i;
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;

	for(i = 0; i < myPC.GetMapsList().Length; i++) {
		tempObj = CreateObject("Object");
		tempObj.SetString("label", myPC.GetMapsList()[i]);
		tempObj.SetInt("index", i);
		dataProvider.AddItem(tempObj);
	}

	return dataProvider;
}

function array<GFxObject> ListGameTypes() {
	local int i;
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;

	for(i = 0; i < myPC.gameTypeList.Length; i++) {
		tempObj = CreateObject("Object");
		tempObj.SetString("label", myPC.gameTypeList[i]);
		tempObj.SetInt("index", i);
		dataProvider.AddItem(tempObj);
	}

	return dataProvider;
}

function array<GFxObject> LoadBotDifficultyDDM() {
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;
	local int i;

	for(i=0; i<availableBotDifficulties.length; i++) {
		tempObj = CreateObject("Object");
		tempObj.SetString("label", availableBotDifficulties[i]);
		tempObj.SetInt("index", i);
		dataProvider.AddItem(tempObj);
	}

	return dataProvider;
}


function AddBot(EventData data)
{
	local string buttonName;
	local int teamNum;

	buttonName = data._this.GetObject("target").GetString("name");

	switch(buttonName)
	{
		case "t1AddBotBtn":
			teamNum = 1;
			break;
		case "t2AddBotBtn":
			teamNum = 2;
			break;
	}

	myPC.PostAddBot("TM_BOT_" $ myPC.botNum++, 1, teamNum);
}

function RemovePlayer(EventData data)
{
	local string buttonName;
	buttonName = data._this.GetObject("target").GetString("name");
	
	switch(buttonName)
	{
		case "t1p1RemoveBtn":
			myPC.PostKickPlayer(team1[0]);
			GetVariableObject("root").GetObject("t1p1DifficultyDDM").SetVisible(false);
			GetVariableObject("root").GetObject("t1p1RemoveBtn").SetVisible(false);
			break;
		case "t1p2RemoveBtn":
			myPC.PostKickPlayer(team1[1]);
			GetVariableObject("root").GetObject("t1p2DifficultyDDM").SetVisible(false);
			GetVariableObject("root").GetObject("t1p2RemoveBtn").SetVisible(false);
			break;
		case "t1p3RemoveBtn":
			myPC.PostKickPlayer(team1[2]);
			GetVariableObject("root").GetObject("t1p3DifficultyDDM").SetVisible(false);
			GetVariableObject("root").GetObject("t1p3RemoveBtn").SetVisible(false);
			break;
		case "t2p1RemoveBtn":
			myPC.PostKickPlayer(team2[0]);
			GetVariableObject("root").GetObject("t2p1DifficultyDDM").SetVisible(false);
			GetVariableObject("root").GetObject("t2p1RemoveBtn").SetVisible(false);
			break;
		case "t2p2RemoveBtn":
			myPC.PostKickPlayer(team2[1]);
			GetVariableObject("root").GetObject("t2p2DifficultyDDM").SetVisible(false);
			GetVariableObject("root").GetObject("t2p2RemoveBtn").SetVisible(false);
			break;
		case "t2p3RemoveBtn":
			myPC.PostKickPlayer(team2[2]);
			GetVariableObject("root").GetObject("t2p3DifficultyDDM").SetVisible(false);
			GetVariableObject("root").GetObject("t2p3RemoveBtn").SetVisible(false);
			break;
		case "t3p1RemoveBtn":
			myPC.PostKickPlayer(spectators[0]);
			break;
		case "t3p2RemoveBtn":
			myPC.PostKickPlayer(spectators[1]);
			break;
	}
}

function BotDifficultyChanged(EventData data)
{
	local string ddmName;
	ddmName = data._this.GetObject("target").GetString("name");

	`log(ddmName $ " switched value.");

	switch(ddmName)
	{
		case "t1p1DifficultyDDM":
			myPC.PostChangeBotDifficulty(team1[0], t1p1DifficultyDDM.GetInt("selectedIndex")+1, 1);
			break;
		case "t1p2DifficultyDDM":
			myPC.PostChangeBotDifficulty(team1[1], t1p2DifficultyDDM.GetInt("selectedIndex")+1, 1);
			break;
		case "t1p3DifficultyDDM":
			myPC.PostChangeBotDifficulty(team1[2], t1p3DifficultyDDM.GetInt("selectedIndex")+1, 1);
			break;
		case "t2p1DifficultyDDM":
			myPC.PostChangeBotDifficulty(team2[0], t2p1DifficultyDDM.GetInt("selectedIndex")+1, 2);
			break;
		case "t2p2DifficultyDDM":
			myPC.PostChangeBotDifficulty(team2[1], t2p2DifficultyDDM.GetInt("selectedIndex")+1, 2);
			break;
		case "t2p3DifficultyDDM":
			myPC.PostChangeBotDifficulty(team2[2], t2p3DifficultyDDM.GetInt("selectedIndex")+1, 2);
			break;
	}
}

function handleStatsLoading( Array<TMPlayerProgressionData> inPlayerStatsList ) {
	local int i;
	local int j;
	local bool playerFound;

	if (playerStatsArray.length == 0) {
		//if saved array doesn't exist, create it
		playerStatsArray = inPlayerStatsList;
	} else {
		//add new prog data to saved stats list
		//check if player already exists in  so there aren't duplicates + update their data
		for(i = 0; i<inPlayerStatsList.length; i++) {
			playerFound = false;
			for(j = 0; j<playerStatsArray.length; j++) {
				if (playerStatsArray[j].playerName == inPlayerStatsList[i].playerName) {
					playerFound = true;
					break;
				}
			}

			//if player already exists (ie left and rejoined the server), update their data
			if (playerFound) {
				playerStatsArray[j].currentLevel = inPlayerStatsList[i].currentLevel;
				playerStatsArray[j].currentExperience = inPlayerStatsList[i].currentExperience;
				playerStatsArray[j].experienceGained = inPlayerStatsList[i].experienceGained;
				playerStatsArray[j].experienceForNextLevel = inPlayerStatsList[i].experienceForNextLevel;
				playerStatsArray[j].gamesPlayed = inPlayerStatsList[i].gamesPlayed;
			} else {
				playerStatsArray.AddItem(inPlayerStatsList[i]);
			}
		}
	}

	myPC.SavePreMatchPlayerStats(playerStatsArray);
	loadPlayerStats(playerStatsArray);
}

function loadPlayerStats( Array<TMPlayerProgressionData> inPlayerStatsList )
{

	local TMPlayerProgressionData tempStats;
	local int i;

	resetBotHiding();

	foreach inPlayerStatsList( tempStats )
	{
		//show stuff for individual users
		for(i = 0; i<team1.length; i++) {
			if (team1[i] == tempStats.playerName) {
				GetVariableObject("root").GetObject("team1rend" $ i+1).GetObject("playerLevel").SetText(tempStats.currentLevel);
			}
			GetVariableObject("root").GetObject("team1rend" $ i+1).SetVisible(true);
			hideBotLevel(team1[i], 1, i);
		}
		for (i = 3; i>team1.length; i--) {
			GetVariableObject("root").GetObject("team1rend" $ i).SetVisible(false);
		}

		for (i = 0; i<team2.length; i++) {
			if (team2[i] == tempStats.playerName) {
				GetVariableObject("root").GetObject("team2rend" $ i+1).GetObject("playerLevel").SetText(tempStats.currentLevel);
			}
			GetVariableObject("root").GetObject("team2rend" $ i+1).SetVisible(true);
			hideBotLevel(team2[i], 2, i);
		}
		for (i = 3; i>team2.length; i--) {
			GetVariableObject("root").GetObject("team2rend" $ i).SetVisible(false);
		}
	}
}

function hideBotLevel(string player, int team, int index) {
	local int j;
	for (j = 0; j<bots.length; j++) {
		if (player == bots[j]) {
			GetVariableObject("root").GetObject("team" $ team $ "rend" $ index+1).GetObject("playerLevel").SetVisible(false);
		}
	}
}

function resetBotHiding() {
	local int i;
	for (i = 0; i<team1.length; i++) {
		GetVariableObject("root").GetObject("team1rend" $ i+1).GetObject("playerLevel").SetVisible(true);
	}
	for (i = 0; i<team2.length; i++) {
		GetVariableObject("root").GetObject("team2rend" $ i+1).GetObject("playerLevel").SetVisible(true);
	}
}

function GetFriends() {
	local array<ASValue> args;
	args.Length = 0; // Making it explicit for the compiler that we want this guy empty - avoids warnings.
	`log("Friends Retrieved");
	if( inviteList == none )
	{
		`log("None invite list");
		return;
	}
	if( inviteList.GetObject("dataProvider") == none )
	{
		`log("None dataprovider");
		return;
	}

	inviteList.GetObject("dataProvider").Invoke("invalidate", args);
}

function SendInvite() {
	local int requestedIndex;
	requestedIndex = inviteList.GetInt("selectedIndex");

	myPC.SendGameInvite(friends[requestedIndex]);

	`log("Invite Sent");
}

function array<GFxObject> GetFriendsListData() {
	local int i;
	local GFxObject tempObj;
	local TMSteamFriend availableFriend;
	local array<GFxObject> dataProvider;

	friends = myPC.GetSteamFriends();

	if (friends.length != 0) {
		for(i = 0; i < friends.Length; i++) {
			availableFriend = friends[i];
			tempObj = CreateObject("Object");
			tempObj.SetString("playerName", availableFriend.steamName);
			dataProvider.AddItem(tempObj);
		}
	}

	return dataProvider;
}

function DisableStartBtn() {
	startBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableStartBtn', self);
}

function EnableStartBtn() {
	startBtn.SetVisible(true);
}

function DisableBackBtn() {
	quitBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableBackBtn', self);
}

function EnableBackBtn() {
	quitBtn.SetVisible(true);
}

function SetFeatureToggles(FeatureToggles inFeatureToggles)
{
	// Reload the scene when we get our feature toggles so the map DDM will load
	self.Start();
}

DefaultProperties
{
	MovieInfo=SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_TeamSelect'
	WidgetBindings.Add((WidgetName="mapNameDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="gameTypeDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="commanderDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="teamDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="startBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="quitBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="team1SL",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="team2SL",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="spectatorSL",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="chatLog",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="sendBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t1AddBotBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2AddBotBtn",WidgetClass=class'GFxCLIKWidget'))

	WidgetBindings.Add((WidgetName="t1p1RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t1p2RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t1p3RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2p1RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2p2RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2p3RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t3p1RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t3p2RemoveBtn",WidgetClass=class'GFxCLIKWidget'))
	
	WidgetBindings.Add((WidgetName="t1p1DifficultyDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t1p2DifficultyDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t1p3DifficultyDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2p1DifficultyDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2p2DifficultyDDM",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="t2p3DifficultyDDM",WidgetClass=class'GFxCLIKWidget'))

	//customGameSL is our Steam Friends scrolling list !!!
	WidgetBindings.Add((WidgetName="customGameSL",WidgetClass=class'GFxCLIKWidget'))

	availableBotDifficulties = ("Beginner", "Intermediate");
}
