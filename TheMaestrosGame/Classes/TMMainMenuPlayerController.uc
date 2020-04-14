class TMMainMenuPlayerController extends PlayerController
								dependson(TMPlatformConnection);

enum SteamRequestType {
	SRT_AUTHSESSIONTICKET
};

struct TMSteamRequest {
	var SteamRequestType requestType;
	var int requestNum;
};

var const int INVALID_STEAM_REQUEST_NUMBER;

var config bool bShouldDisableAllScreenMessages;

// Player Info
var string username;
var string email;
var string mSessionToken;
var int ally;
var string commander;
var bool isNewPlayer;

var JSONObject availableGames;
var JSONObject currentGame;
var SFMFrontEnd myMenu;
var SFMAudioPlayer menuAudio;

var TMTcpLink mTcpLink;
var TMChatLink mChatLink;
var TMPlatformConnection platformConnection;
var TMSteamInviteServerCommunicator steamInviteServerCommunicator;

var TMSteamProxy mTmSteamProxy;
var string mSteamId;
var Array<TMSteamFriend> mCachedOnlineFriends;

var string startupMenu;
var TMMainMenuGameInfo menuGameInfo;

var string MotD;
var string MaestrosGameFeedbackURL;
var string MaestrosBugSubmissionURL;

var array<TMPlatformRequest> platformRequests;
var array<TMSteamRequest> steamRequests;

var int requestedGameIndex;
var array<string> expiredGameGUIDs;
var bool isLobbyHost;

var bool gameStarted;
var string mLobbyDisconnectReason;

var const string DISCONNECT_REASON_HOST_CANCELED;
var const string DISCONNECT_REASON_UNKNOWN;
var const string DISCONNECT_REASON_QUIT;
var const string DISCONNECT_REASON_GAME_JOIN_TIMEOUT;
var const string DISCONNECT_REASON_TIMEOUT;
var const string MAPS_JSON_FILE_PATH;

var array<string> gameTypeList;

var Vector mainSpawnLocation;
var Vector leftSpawnLocation;
var Vector rightSpawnLocation;

var Rotator mainRotation;
var Rotator leftRotation;
var Rotator rightRotation;

var float tinkermeisterScale;
var float rosieScale;
var float robomeisterScale;
var float randomScale;
var float salvatorScale;
var float rambamqueenScale;
var float hivelordScale;
var float leftrightScale;

var TMMainMenuPawn mainPawn;
var TMMainMenuPawn leftPawn;
var TMMainMenuPawn rightPawn;

var string currentLevel;

var TMJsonParser m_JsonParser;

var string mapToLoad;
var string gameTypeToLoad;

var class<SFMFrontEnd> LastMenu;

//Save Object
var TMSaveData mSaveData;
var TMPlayerInventory mPlayerInventory;

var bool bAllowMenuLogMessages;

var string mSteamAuthSessionTicket;

var JsonObject mLobbyInvites;
var JsonObject mAcceptedLobbyInvite;

// Dru, what do you think about this? We need some way to store the friend we are accepting from.
var TMSteamFriend mSteamFriendAcceptedInviteFrom; 	// we need to save the steam friend we accept to search all our invites for this friend

struct CommanderSelectTooltip
{
	var string name;
	var string description;
};

var array<CommanderSelectTooltip> commanderSelectTooltipCache;

var int botNum;

var FeatureToggles mFeatureToggles;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();

	// Init Json Parser
	m_JsonParser = new() class'TMJsonParser';
	m_JsonParser.setup();

	mTcpLink = Spawn(class'TMTcpLink');
	mTcpLink.PC = self;

	mChatLink = Spawn(class'TMChatLink');
	mChatLink.PC = self;

	ally = 0;
	commander = "TinkerMeister";

	platformConnection = new () class'TMRealPlatformConnection';
	// => Uncomment this Mark => platformConnection = new () class'TMMockablePlatformConnection';
	platformConnection.Setup();
	steamInviteServerCommunicator = new () class'TMSteamInviteServerCommunicator';

	menuGameInfo = TMMainMenuGameInfo(WorldInfo.Game);
	startupMenu = menuGameInfo.specifiedMenu;

	// lol optimize this shit
	// only poll after making a response
	// this is bad and i should feel bad
	self.SetTimer(0.05, true, NameOf(CheckPlatformResponse));

	self.SetTimer(0.05, true, NameOf(CheckSteamResponse));

	if (bShouldDisableAllScreenMessages)
	{
		self.SetTimer(1.0, false, NameOf(DoDisableAllScreenMessages));
	}

	gameStarted = false;

	gameTypeList = CallListGameTypes();

	currentLevel = "Login";

	// Play (looping Max Loh) Theme
	PlayTheme();
	menuAudio = Spawn(class 'SFMAudioPlayer');

	// Setting commander select values based on what looks good.
	// Main
	mainSpawnLocation.X = -17794.97;
	mainSpawnLocation.Y = -14606.07;
	mainSpawnLocation.Z = -2992;

	mainRotation.Pitch = 0;
	mainRotation.Yaw = 22.5 * DegToUnrRot;
	mainRotation.Roll = 0;

	// Left
	leftSpawnLocation.X = -18994.97;
	leftSpawnLocation.Y = -14222.07;
	leftSpawnLocation.Z = -2992;

	leftRotation.Pitch = 0;
	leftRotation.Yaw = 17.0 * DegToUnrRot;
	leftRotation.Roll = 0;

	// Right
	rightSpawnLocation.X = -17506.97;
	rightSpawnLocation.Y = -15790.07;
	rightSpawnLocation.Z = -2992;

	rightRotation.Pitch = 0;
	rightRotation.Yaw = 25.0 * DegToUnrRot;
	rightRotation.Roll = 0;

	//LR Scale
	tinkermeisterScale = 9.0;
	rosieScale = 9.0;
	robomeisterScale = 8.0;
	randomScale = 45.0;
	salvatorScale = 8.0;
	rambamqueenScale = 9.0;
	hivelordScale = 9.0;
	leftrightScale = 0.8;

	// Load Tooltips
	LoadCommanderSelectTooltips();

	botNum = 1;
	isNewPlayer = false;

	//Load SaveFile
	mSaveData = new class'TMSaveData'();
	mPlayerInventory = new class'TMPlayerInventory'();

	// Set up steam proxy
	if (SteamApiInit()) {
		SteamRequestAuthSessionTicket();
	}
}

function DoDisableAllScreenMessages()
{
	ConsoleCommand("DisableAllScreenMessages", true);
}

exec function SteamRequestAuthSessionTicket()
{
	local TMSteamRequest request;
	request.requestType = SRT_AUTHSESSIONTICKET;
	request.requestNum = mTmSteamProxy.RequestAuthSessionTicket();
	if (request.requestNum == INVALID_STEAM_REQUEST_NUMBER)
	{
		`warn("invalid requestNumber returned from RequestAuthSessionTicket - handle for steam auth session ticket was invalid or steam is in an incorrect state.");
		myMenu.SetError("Unable to talk to running steam instance");
		return;
	}

	steamRequests.AddItem(request);
}

exec function int SendLobbyInvite(string receiverSteamId)
{
	return self.PostSendLobbyInvite(receiverSteamId);
}

exec function int RetrieveLobbyInvites()
{
	return self.PostRetrieveLobbyInvites();
}

exec function int DeclineLobbyInvite(int index)
{
	local JsonObject lobbyInvite;
	local JsonObject steamLobbyInvites;

	steamLobbyInvites = mLobbyInvites.GetObject("steamLobbyInvites");
	if (steamLobbyInvites.ObjectArray.Length == 0)
	{
		`log("LobbyInvites is empty", true, 'dru');
		return -1;
	}
	lobbyInvite = steamLobbyInvites.ObjectArray[index];
	return self.PostDeclineLobbyInvites(lobbyInvite.GetIntValue("senderSteamId")$"", lobbyInvite.GetStringValue("senderPlayerName"), lobbyInvite.GetStringValue("gameGUID"), lobbyInvite.GetStringValue("host"), lobbyInvite.GetIntValue("port")$"", lobbyInvite.GetStringValue("httpEndpoint"));
}

exec function int AcceptLobbyInvite(int index)
{
	local JsonObject steamLobbyInvites;

	steamLobbyInvites = mLobbyInvites.GetObject("steamLobbyInvites");
	if (steamLobbyInvites.ObjectArray.Length == 0)
	{
		`log("LobbyInvites is empty", true, 'dru');
		return -1;
	}
	mAcceptedLobbyInvite = steamLobbyInvites.ObjectArray[index];
	mAcceptedLobbyInvite.SetStringValue("port", mAcceptedLobbyInvite.GetIntValue("port")$"");
	return self.PostAcceptLobbyInvite(mAcceptedLobbyInvite.GetIntValue("senderSteamId")$"", mAcceptedLobbyInvite.GetStringValue("senderPlayerName"),  mAcceptedLobbyInvite.GetStringValue("gameGUID"), mAcceptedLobbyInvite.GetStringValue("host"), mAcceptedLobbyInvite.GetStringValue("port"), mAcceptedLobbyInvite.GetStringValue("httpEndpoint"));
}

exec function CreatePlayer3Async(string playerName, string password, string inEmail, string birthday)
{
	PostCreatePlayer3(playerName, password, inEmail, birthday, mSteamAuthSessionTicket);
}

exec function RetrieveAuthSessionTicket(int requestNumber)
{
	local TMSteamAuthSessionTicket steamAuthSessionTicket;
	local array<byte> ticket;

	steamAuthSessionTicket = mTmSteamProxy.RetrieveAuthSessionTicketResponseFor(requestNumber);
	if (steamAuthSessionTicket == None)
	{
		return;
	}

	if (steamAuthSessionTicket.authSessionTicketData.steamResultCode != class'TMSteamProxy'.default.STEAM_RESULT_OK)
	{
		`warn("Bad response code: "$ steamAuthSessionTicket.authSessionTicketData.steamResultCode$" returned from retrieving auth session ticket", true, 'dru');
		return;
	}

	if (steamAuthSessionTicket.authSessionTicketData.ticketLength < 1)
	{
		`warn("Uh Oh. Looks like RetrieveAuthSessionTicketResponseFor() didn't give us a good ticket\n", true, 'dru');
		return;
	}

	ticket = steamAuthSessionTicket.GenerateTicketFromSessionTicketData();
	mSteamAuthSessionTicket = hexStringFrom(ticket);
	AutoLogin();
}

exec function LoadCommanderSelect()
{
	TriggerGlobalEventClass(class'SeqEvent_LoadCommanderSelectLevel', self);
}

exec function LoadLogin()
{
	TriggerGlobalEventClass(class'SeqEvent_LoadLoginLevel', self);
}

function string hexStringFrom(array<byte> inStream)
{
    local int i;
	local string outString;
	for (i = 0; i < inStream.Length; ++i)
	{
		outString $= Locs(Right(ToHex(inStream[i]), 2));
	}
	return outString;
}

/* IsCommanderAvailable
	Returns true if the commander is available or the commander is "Random"
	A commander is considered "available" if it's in the player's inventory and currently supported in the feature toggles.
*/
function bool IsCommanderAvailable( string inCommanderName )
{
	local int retVal;

	if( inCommanderName == "Random" )
	{
		return true;
	}

	// Commanders in the blacklisted list aren't available to play
	if(mFeatureToggles.blacklistedCommanders.Find(inCommanderName) != -1)
	{
		return false;
	}

	retVal = mPlayerInventory.HasCommander( inCommanderName );
	if (retVal < 0) {
		if (retVal == -1) {
			return false;
		} else {
			myMenu.setError("");
			return true;
		}
	} else {
		//commander found
		return true;
	}
}

function bool IsCommanderInInventory( string inCommanderName )
{
	return (mPlayerInventory.HasCommander( inCommanderName ) >= 0);
}

exec function SpawnMenuPawn( out TMMainMenuPawn outPawn, string inPawnType, Vector inLocation, Rotator inRotation )
{
	if( outPawn != none )
	{
		outPawn.Destroy();
	}
	outPawn = Spawn( class'TMMainMenuPawn',,, inLocation, inRotation,, true );
	outPawn.SetupUnitAs( inPawnType );

	// Set the pawn's proper scale
	switch( inPawnType )
	{
		case "TinkerMeister":
			outPawn.Mesh.SetScale( tinkermeisterScale );
			break;
		case "Rosie":
			outPawn.Mesh.SetScale( rosieScale );
			break;
		case "RoboMeister":
			outPawn.Mesh.SetScale( robomeisterScale );
			break;
		case "Random":
			outPawn.Mesh.SetScale( randomScale );
			break;
		case "Salvator":
			outPawn.Mesh.SetScale( salvatorScale );
			break;
		case "RamBamQueen":
			outPawn.Mesh.SetScale( rambamqueenScale );
			break;
		case "HiveLord":
			outPawn.Mesh.SetScale( hivelordScale );
			break;
		default:
			`log("pawn type invalid, setting to default enlarged scale");
			outPawn.Mesh.SetScale( tinkermeisterScale );
			break;
	}

	// Play the commander select sound if it's available
	if( IsCommanderAvailable( inPawnType ) )
	{
		PlaySelectCommanderSound( inPawnType );
	}

	// Make the material black if the commander isn't available (unless you're random)
	if (outPawn == mainPawn) {
		if( !IsCommanderAvailable( inPawnType ) )
		{
			outPawn.Mesh.SetMaterial( 0, Material'jc_material_sandbox.Masters.JC_TFUnit_Master' );
		}
	}

	outPawn.Mesh.SetRotation( inRotation );
}

exec function PlaySelectCommanderSound( string inCommander )
{
	switch( inCommander )
	{
		case "TinkerMeister":
			menuGameInfo.tinkermeisterSound.Play();
			break;
		case "Rosie":
			menuGameInfo.rosieSound.Play();
			break;
		case "RoboMeister":
			menuGameInfo.robomeisterSound.Play();
			break;
		case "Random":
			break;
		case "Salvator":
			menuGameInfo.salvatorSound.Play();
			break;
		case "RamBamQueen":
			break;
		case "HiveLord":
			menuGameInfo.hiveLordSound.Play();
			break;
		default:
			break;
	}
}

exec function SpawnMainPawn(string pawnType)
{
	SpawnMenuPawn( mainPawn, pawnType, mainSpawnLocation, mainRotation );
}

exec function SpawnLeftPawn(string pawnType)
{
	SpawnMenuPawn( leftPawn, pawnType, leftSpawnLocation, leftRotation );
}

exec function SpawnRightPawn(string pawnType)
{
	SpawnMenuPawn( rightPawn, pawnType, rightSpawnLocation, rightRotation );
}

exec function CallListFilesInDir(string path)
{
	local array<string> filesInDir;
	local string temp;

	//path = "..\\..\\..\\UDKGame\\Content\\TM\\Maps";

	filesInDir = m_JsonParser.GetFilesInDirectory(path);
	
	foreach filesInDir(temp)
	{
		`log(temp);
	}
}

function array<string> GetMapsList()
{
	return mFeatureToggles.availableMaps;
}

function array<string> CallListGameTypes()
{
	local array<string> types;

	types.AddItem("Round Based");
	// types.AddItem("Nexus Commanders");
	types.AddItem("Team Deathmatch");
	// types.AddItem("Team Stock");

	return types;
}

function OpenFeedbackPage()
{
	class'Engine'.static.LaunchURL(MaestrosGameFeedbackURL);
}

function PlayTheme() {
	menuGameInfo.themeMusic.Play();
}

function StopTheme() {
	menuGameInfo.themeMusic.Stop();
}

function PlayAmbient() {
	menuGameInfo.ambientMusic.Play();
}

function StopAmbient() {
	menuGameInfo.ambientMusic.Stop();
}

function LoadCommanderSelectTooltips()
{
	local array<string> jsons;
	local array<JsonObject> jsonObjs;
	local int i;

	if (commanderSelectTooltipCache.Length == 0)
	{
		jsons = LoadCommanderSelectJsons();

		for(i = 0; i < jsons.Length; ++i)
		{
			jsonObjs.AddItem(m_JsonParser.getJsonFromString(jsons[i]));
		}

		BuildCommanderSelectTooltipCache(jsonObjs);
	}
}

function array<string> LoadCommanderSelectJsons()
{
	local array<string> jsonStringArray;
	local array<string> filesArray;
	local string manifestPath;
	local string manifestFile;

	manifestPath = "\\" $  "CommanderSelect" $ "manifest.json";

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

function BuildCommanderSelectTooltipCache(array<JsonObject> jsons)
{
	local int i;
	local CommanderSelectTooltip tooltip;

	commanderSelectTooltipCache.Remove(0, commanderSelectTooltipCache.Length); // reset the array
	for(i = 0; i < jsons.Length; ++i)
	{
		tooltip.name = jsons[i].GetStringValue("Name");
		tooltip.description = jsons[i].GetStringValue("Description");

		if (tooltip.name == "Tinkermeister") {
			tooltip.name = "TinkerMeister";
		} else if (tooltip.name == "Robomeister") {
			tooltip.name = "RoboMeister";
		} else if (tooltip.name == "Blastmeister") {
			tooltip.name = "BlastMeister";
		}

		commanderSelectTooltipCache.AddItem(tooltip);
	}
}

function TimedOutConnectingToGameServer()
{
	// Undo client-travel B.S.?
	LeaveLobby(DISCONNECT_REASON_GAME_JOIN_TIMEOUT);
	`WARN("Timed out trying to connect to the game server.  Could be a version mismatch.");
}

// We use ReceivedPlayer to notify when the level is loaded. If we have a real OnLevelLoaded in the future we should use that
simulated event ReceivedPlayer()
{
	// Set volume
	ConsoleCommand(class'TMSoundSettings'.static.LoadVolumeCommand());
}

function HandleGameStarted(JsonObject commandObject)
{
	local string command;

	`log("Received A GameStarted Command");
	`log(class'JSONObject'.static.EncodeJson(commandObject));

	// Fail safe.
	if(!IsCommanderAvailable(commander) && commander != "Random")
	{
		`warn("Somehow chose a commander that's unavailable, switching to random.");
		commander = "Random";
	}

	// Randomize commander.
	if(commander == "Random" || commander == "Unselected") 
	{
		commander = GetRandomAvailableCommander();
	}

	CancelHeartbeatTimeout();

	SetTimer(12.5f, false, 'TimedOutConnectingToGameServer');

	if(ally == 2) {
		command = commandObject.GetObject("endpoint").GetStringValue("serverHostName") $ ":" $ commandObject.GetObject("endpoint").GetStringValue("publicPort")
			$ "?PlayerName=" $ username $ "?SessionToken=" $ mSessionToken $ "?SpectatorOnly=1";
	} else {
		command = commandObject.GetObject("endpoint").GetStringValue("serverHostName") $ ":" $ commandObject.GetObject("endpoint").GetStringValue("publicPort")
			$ "?Ally=" $ ally $ "?PlayerName=" $ username $ "?Commander=" $ commander $ "?SessionToken=" $ mSessionToken $ "?SpectatorOnly=0";
	}

	`log("ClientTravel(" $ command);
	ClientTravel(command, ETravelType.TRAVEL_Absolute, false, );
}

function string GetRandomAvailableCommander()
{
	local int i;
	local string iterCommander;
	local array<string> availableCommandersList;
	local array<string> playerInventoryCommanders;

	// Compile availableCommandersList. A commander is available if the player has the commander and the commander isn't blacklisted.
	playerInventoryCommanders = mPlayerInventory.GetCommanderList();
	foreach playerInventoryCommanders(iterCommander)
	{
		if(mFeatureToggles.blacklistedCommanders.Find(iterCommander) == -1) 	// commander not in blacklist
		{
			availableCommandersList.AddItem(iterCommander);
		}
	}

	// Get a random commander index
	i = int(RandRange( 0, availableCommandersList.Length ));

	// Make sure we didn't go out of array range (very small chance)
	if( i == availableCommandersList.Length ) 	// Taylor update 1/26/17: above comment seems sketch
	{
		i = availableCommandersList.Length - 1;
	}

	return availableCommandersList[i];
}

function HandleUpdateGameInfo(JsonObject commandObject)
{
	`log("Received A UpdateGameInfo Command");
	`log(class'JSONObject'.static.EncodeJson(commandObject));
	ScheduleHeartbeatTimeout();
	myMenu.UpdateGameInfo(commandObject.GetObject("body"));
	if(commandObject.HasKey("error"))
	{
		myMenu.SetError(commandObject.GetStringValue("error"));
	}
}

function ScheduleHeartbeatTimeout()
{
	SetTimer(12.5, false, 'HeartbeatTimedOut');
	`log("Scheduling heartbeat timeout", true, 'dru');
}
	
function CancelHeartbeatTimeout()
{
	SetTimer(0.f, false, 'HeartbeatTimedOut');
	`log("Canceling heartbeat timeout", true, 'dru');
}

function DisconnectFromLobby(string disconnectReason)
{
	mLobbyDisconnectReason = disconnectReason;
	mTcpLink.Close();
	CancelHeartbeatTimeout();
}

/***
 * @param disconnectReason a string describing why you disconnected, e.g. DISCONNECT_REASON_UNKNOWN
 */
function LeaveLobby(string disconnectReason)
{
	// TODO: Steam close invites

	DisconnectFromLobby(disconnectReason);
	mChatLink.Close();
}

function HeartbeatTimedOut() {
	LeaveLobby(DISCONNECT_REASON_TIMEOUT);
	`WARN("Connection timed out. Disconnected from lobby.");
}

function ConnectToLobby(string gameGUID, string playerName, string connectionKey, coerce int port, string host)
{
	mTcpLink.targetPort = port;
	mTcpLink.targetHost = host;
	
	mTcpLink.SetConnectionInfo(gameGUID, playerName, connectionKey);

	mTcpLink.ResolveAndOpen(); // opens lobby screen when HandleSocketOpened() fires

	ScheduleHeartbeatTimeout();
}

function HandleSocketClosed()
{
	if (mLobbyDisconnectReason == DISCONNECT_REASON_HOST_CANCELED || (mLobbyDisconnectReason == DISCONNECT_REASON_QUIT && isLobbyHost))
	{
		expiredGameGUIDs.AddItem(currentGame.GetStringValue("gameGUID"));	
	}
	currentGame = none;
	ally = 0;
	commander = "TinkerMeister";
	
	myMenu.LoadMenu(class'SFMFrontEndMainMenu');
	if (mLobbyDisconnectReason != DISCONNECT_REASON_QUIT)
	{
		myMenu.SetError(mLobbyDisconnectReason);
	}

	`log("Lobby socket closed", true, 'dru');
}

function ConnectChat(string roomName, string playerName)
{
	mChatLink.SetConnectionInfo(roomName, playerName);

	mChatLink.ResolveAndOpen();
}

function DisconnectChat() {
	mChatLink.Close();
}

function SendChatMessage(string message)
{
	// Escaping strings.
	message = Repl(message, "\\", "\\\\");
	message = Repl(message, "\"", "\\\"");

	mChatLink.SendMessage(message);
}

function HandleReceivedGetUsersMessage(array<string> usersInRoom)
{
	local int i;
	local string message;

	`log("Received a getUsers response.", true, 'dru');

	for(i = 0; i< usersInRoom.Length; i++) {
		if (usersInRoom[i] != username) {
			message = message $ usersInRoom[i] $ "\n";
		}
	}

	myMenu.ReceiveUsers(message);
}

function HandleReceivedChatMessage(string message)
{
	myMenu.ReceiveChatMessage(message);
}

function HandleChatSocketOpened()
{
	`log("Chat socket opened.");
}

function HandleChatSocketClosed()
{
	`log("Chat socket closed.");
}

exec function AutoLogin()
{
	local SFMFrontEndLogin loginMenu;

	if(mFeatureToggles.isOnline == false)
	{
		return;
	}

	loginMenu = SFMFrontEndLogin(myMenu);
	if (loginMenu != None)
	{
		loginMenu.ToggleLoadingAnimation(true);
	}
	isNewPlayer = false;
	PostLogin4(mSteamAuthSessionTicket);
}

function HandleSocketOpened()
{
	mLobbyDisconnectReason = DISCONNECT_REASON_UNKNOWN;
	myMenu.LoadMenu(class'SFMFrontEndTeamSelect');
}

function CheckSteamResponse()
{
	local int i;

	if(steamRequests.Length == 0) 
	{ 
		return; 
	}

	for(i = 0; i < steamRequests.Length; i++) {
		if (steamRequests[i].requestType == SRT_AUTHSESSIONTICKET) {
			RetrieveAuthSessionTicket(steamRequests[i].requestNum);
		}
		steamRequests.RemoveItem(steamRequests[i--]);
	}
}

function CheckPlatformResponse()
{
	local int i;
	local string response;

	if(platformRequests.Length == 0) { return; }

	for(i = 0; i < platformRequests.Length; i++) {
		response = platformConnection.GetPlatformResponse(platformRequests[i].requestNum);
		if(response != "") {
			`log("Response JSON: " $ response, true, 'Andre');
			switch(platformRequests[i].requestType) {
				case RT_MOTD:
					ParseMOTDResponse(response);
					break;
				case RT_LOGIN:
					ParseLoginResponse(response);
					break;
				case RT_LOGIN4:
					ParseLogin4Response(response);
					break;
				case RT_CREATEPLAYER:
					ParseCreatePlayerResponse(response);
					break;
				case RT_LISTGAMES:
					ParseListGamesResponse(response);
					break;
				case RT_HOSTGAME:
					ParseHostGameResponse(response);
					break;
				case RT_SWITCHTEAM:
					ParseSwitchTeamResponse(response);
					break;
				case RT_CHANGEMAP:
					ParseChangeMapResponse(response);
					break;
				case RT_CHANGEGAMETYPE:
					ParseChangeGameTypeResponse(response);
					break;
				case RT_STARTGAME:
					ParseStartGameResponse(response);
					break;
				case RT_LOCKTEAMS:
					ParseLockTeamsResponse(response);
					break;
				case RT_CHOOSECOMMANDER:
					ParseChooseCommanderResponse(response);
					break;
				case RT_LOCKCOMMANDER:
					ParseLockCommanderResponse(response);
					break;
				case RT_PLAYERSTATS:
					ParsePlayerStatsResponse(response);
					break;
				case RT_PLAYERINVENTORY:
					ParsePlayerInventoryResponse(response);
					break;
				case RT_ENDGAMEPLAYERSTATS:
					ParseEndGamePlayerStatsResponse(response);
					break;
				case RT_RESEND:
					ParseResendResponse(response);
					break;
				case RT_RESET:
					ParseResetResponse(response);
					break;
				case RT_SENDLOBBYINVITE:
					ParseSendLobbyInviteResponse(response);
					break;
				case RT_RETRIEVELOBBYINVITES:
					ParseRetrieveLobbyInvitesResponse(response);
					break;
				case RT_DECLINELOBBYINVITE:
					ParseDeclineLobbyInvitesResponse(response);
					break;
				case RT_ACCEPTLOBBYINVITE:
					ParseAcceptLobbyInvitesResponse(response);
					break;
			}
			platformRequests.RemoveItem(platformRequests[i--]);
		}
	}
}

function PostLogin4(string steamAuthSessionTicket) {
	local TMPlatformRequest request;
	request.requestType = RT_LOGIN4;
	request.requestNum = platformConnection.Login4Async(steamAuthSessionTicket);
	platformRequests.AddItem(request);
}

function PostLogin(string un, string password) {
	local TMPlatformRequest request;
	request.requestType = RT_LOGIN;
	request.requestNum = platformConnection.LoginAsync(un, password);
	platformRequests.AddItem(request);

	//TODO: Assign username upon login
	username = un;
	email = un;
}

function ParseLogin4Response(string response) {
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			username = json.GetStringValue("playerName");
			email = json.GetStringValue("email");
			mSessionToken = json.GetStringValue("sessionToken");
			if (SFMFrontEndLogin(myMenu) != None)
			{
				SFMFrontEndLogin(myMenu).cacheLoggedIn(email);
			}
			menuAudio.PlayLogInSuccess();
			myMenu.LoadMenu(class'SFMFrontEndMainMenu');
			CheckForInvitesOnLogin(); 	// Dru, could we have existing invites be part of the login response?
		} else {
			SFMFrontEndLogin(myMenu).ToggleLoadingAnimation(false);
			myMenu.ShowReset();
		}
	}
}

function ParseLoginResponse(string response) {
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			username = json.GetStringValue("playerName");
			email = json.GetStringValue("email");
			mSessionToken = json.GetStringValue("sessionToken");
			if (SFMFrontEndLogin(myMenu) != None)
			{
				SFMFrontEndLogin(myMenu).cacheLoggedIn(email);
			}
			menuAudio.PlayLogInSuccess();
			myMenu.LoadMenu(class'SFMFrontEndMainMenu');
		} else {
			myMenu.SetError(json.GetStringValue("error"));
			SFMFrontEndLogin(myMenu).ToggleLoadingAnimation(false);
			myMenu.ShowReset();
		}
	}
}

function PostResend(string emailIn) {
	local TMPlatformRequest request;
	request.requestType = RT_RESEND;
	request.requestNum = platformConnection.ResendAsync(emailIn);
	platformRequests.AddItem(request);

	myMenu.SetVerification();
}

function PostReset(string emailIn) {
	local TMPlatformRequest request;
	request.requestType = RT_RESET;
	request.requestNum = platformConnection.ResetAsync(emailIn);
	platformRequests.AddItem(request);

	myMenu.SetReset();
}

function JoinGameHelper(JsonObject currentGameJson)
{
	currentGame = currentGameJson;
	EnterLobby(currentGame.GetStringValue("gameGUID"), "dummyConnectionKey", currentGame.GetStringValue("port"), currentGame.GetStringValue("host"));
	ClearTimer('PostListGames');
}

function AcceptLobbyInviteIfExitedCompletely()
{
	if (currentGame != None)
	{
		return;
	}

	ClearTimer(NameOf(AcceptLobbyInviteIfExitedCompletely));
	JoinGameHelper(mAcceptedLobbyInvite);
}

function ParseAcceptLobbyInvitesResponse(string response)
{
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			if ( currentGame != None)
			{
				LeaveLobby(self.DISCONNECT_REASON_QUIT);
				self.SetTimer(0.05, true, NameOf(AcceptLobbyInviteIfExitedCompletely));
			} else
			{
				JoinGameHelper(mAcceptedLobbyInvite);
			}
			// Remove from your list? Or just check for invites again?
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function ParseDeclineLobbyInvitesResponse(string response) 
{
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			`log("response: "$response, true, 'dru');
			// Remove from your list? Or just check for invites again? 
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function ParseRetrieveLobbyInvitesResponse(string response) 
{
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			`log("response: "$response, true, 'dru');
			mLobbyInvites = json;
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function ParseSendLobbyInviteResponse(string response) {
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			if (false == json.GetBoolValue("success"))
			{
				myMenu.SetError("Error trying to send your steam lobby invite");
				`warn("Error trying to send steam lobby invite");
			}
			else 
			{
				`log("lobby invite sent successfully", true, 'dru');
			}
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function ParseResetResponse(string response) {
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			myMenu.SetResetConfirmed();
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function ParseResendResponse(string response) {
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			//myMenu.SetError("Verification Email Resent");
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function PostCreatePlayer(string un, string password, string emailIn, string birthday) {
	local TMPlatformRequest request;
	request.requestType = RT_CREATEPLAYER;
	if (mTmSteamProxy.IsInitialized() && mSteamAuthSessionTicket != "") {
		request.requestNum = platformConnection.CreatePlayer3Async(un, password, emailIn, birthday, mSteamAuthSessionTicket);
	} else {
		request.requestNum = platformConnection.CreatePlayerAsync(un, password, emailIn, birthday);
	}

	platformRequests.AddItem(request);

	username = un;
	email = emailIn;
}

function int PostDeclineLobbyInvites(string senderSteamId, string senderPlayerName, string gameGuid, string host, string port, string httpEndpoint)
{
	local TMPlatformRequest request;
	if (self.mSteamId == "")
	{
		`warn("attempted to decline invites when steamId hadn't been set");
		return -1;
	}

	request.requestType = RT_DECLINELOBBYINVITE;
	request.requestNum = platformConnection.DeclineSteamLobbyInviteAsync(mSessionToken, username, mSteamId, senderSteamId, senderPlayerName, gameGuid, host, port, httpEndpoint);

	platformRequests.AddItem(request);
	return request.requestNum;
}

function int PostAcceptLobbyInvite(string senderSteamId, string senderPlayerName, string gameGuid, string host, string port, string httpEndpoint)
{
	local TMPlatformRequest request;
	if (self.mSteamId == "")
	{
		`warn("attempted to accept invites when steamId hadn't been set");
		return -1;
	}

	request.requestType = RT_ACCEPTLOBBYINVITE;
	request.requestNum = platformConnection.AcceptSteamLobbyInviteAsync(mSessionToken, username, mSteamId, senderSteamId, senderPlayerName, gameGuid, host, port, httpEndpoint);

	platformRequests.AddItem(request);
	return request.requestNum;
}

function int PostRetrieveLobbyInvites()
{
	local TMPlatformRequest request;
	if (self.mSteamId == "")
	{
		`warn("attempted to retrieve invites when steamId hadn't been set");
		return -1;
	}

	request.requestType = RT_RETRIEVELOBBYINVITES;
	request.requestNum = platformConnection.RetrieveSteamLobbyInvitesAsync(mSessionToken, username, mSteamId);
	platformRequests.AddItem(request);
	return request.requestNum;
}

function int PostSendLobbyInvite(string receiverSteamId) {
	local TMPlatformRequest request;
	if (self.mSteamId == "")
	{
		`warn("attempted to send an invite when steamId hadn't been set");
		return -1;
	}

	request.requestType = RT_SENDLOBBYINVITE;
	request.requestNum = platformConnection.SendSteamLobbyInviteAsync(mSessionToken, username, receiverSteamId, mSteamId, username, currentGame.GetStringValue("gameGUID"), currentGame.GetStringValue("host"), currentGame.GetStringValue("port"), currentGame.GetStringValue("httpEndpoint"));
	platformRequests.AddItem(request);
	return request.requestNum;
}

function PostCreatePlayer3(string un, string password, string emailIn, string birthday, string steamAuthSessionTicket) {
	local TMPlatformRequest request;
	request.requestType = RT_CREATEPLAYER;
	request.requestNum = platformConnection.CreatePlayer3Async(un, password, emailIn, birthday, steamAuthSessionTicket);
	platformRequests.AddItem(request);

	username = un;
	email = emailIn;
}

function ParseCreatePlayerResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			mSessionToken = json.GetStringValue("sessionToken");
			menuAudio.PlayLogInSuccess();
			myMenu.LoadMenu(class'SFMFrontEndMainMenu');
		} else {
			myMenu.SetError(json.GetStringValue("error"));
			SFMFrontEndLogin(myMenu).ToggleLoadingAnimation(false);
		}
	}
}

function PostListGames() {
	local TMPlatformRequest request;
	request.requestType = RT_LISTGAMES;
	request.requestNum = platformConnection.ListGamesAsync(username, mSessionToken);
	platformRequests.AddItem(request);
}

function ParseListGamesResponse(string response) {
	availableGames = class'JsonObject'.static.DecodeJson(response);
	if(myMenu.IsA('SFMFrontEndMainMenu') && availableGames.GetStringValue("error") == "") {
		SFMFrontEndMainMenu(myMenu).RefreshGameBrowserList();
	} else {
		myMenu.SetError(availableGames.GetStringValue("error"));
	}
}

function PostHostGame(string gameName, string mapName, string type) {
	local TMPlatformRequest request;
	request.requestType = RT_HOSTGAME;
	request.requestNum = platformConnection.HostGameAsync(username, mSessionToken, gameName, mapName, type);
	platformRequests.AddItem(request);
}

// Dru TODO: All these parse functions, why??
function ParseHostGameResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json != none) {
		if(json.GetStringValue("error") == "") {
			currentGame = json;
			EnterLobby(currentGame.GetStringValue("gameGUID"), json.GetStringValue("connectionKey"), json.GetStringValue("port"), json.GetStringValue("host"));  // Dru TODO: Should this be json...("gameGUID") too?
			menuAudio.PlayHostSuccess();
		} else {
			myMenu.SetError(json.GetStringValue("error"));
		}
	}
}

function EnterLobby(string gameGUID, string connectionKey, string port, string host)
{
	if(mFeatureToggles.multiplayerEnabled == false)
	{
		return;
	}

	ConnectToLobby(gameGUID, username, connectionKey, port, host);
	CallSwitchRoom(gameGUID);
}

exec function CallGetUsers(string room)
{
	mChatLink.SendGetUsers(room);
}

exec function CallSwitchRoom(string room)
{
	mChatLink.SendSwitchRooms(room);
}

exec function CallSendMessage(string message)
{
	mChatLink.SendMessage(message);
}

function PostSwitchTeam(int team) {
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_SWITCHTEAM;
		request.requestNum = platformConnection.SwitchTeamsAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), team, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function ParseSwitchTeamResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") == "") {
		SFMFrontEndTeamSelect(myMenu).UpdateTeamDDM();
	} else {
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function PostChangeMap(string map) {
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_CHANGEMAP;
		request.requestNum = platformConnection.ChangeMapAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), map, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function ParseChangeMapResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") != "") {
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function PostChangeGameType(string type) {
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_CHANGEGAMETYPE;
		request.requestNum = platformConnection.ChangeGameTypeAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), type, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function ParseChangeGameTypeResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") != "") {
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function ParseStartGameResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") != "")
		myMenu.SetError(json.GetStringValue("error"));
}

function PostLockTeams() {
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_LOCKTEAMS;
		request.requestNum = platformConnection.LockTeamsAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function ParseLockTeamsResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") == "") {
		myMenu.UpdateGameInfo(json);
	} else {
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function PostChooseCommander(string choice) {
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_CHOOSECOMMANDER;
		request.requestNum = platformConnection.ChooseCommanderAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), choice, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

exec function CallPostAddBot(string botName, int botDifficulty, int teamNumber)
{
	PostAddBot(botName, botDifficulty, teamNumber);
}

function PostAddBot(string botName, int botDifficulty, int teamNumber)
{
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_ADDBOT;
		request.requestNum = platformConnection.AddBotAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), botName, botDifficulty, teamNumber, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function PostChangeBotDifficulty(string botName, int botDifficulty, int teamNumber)
{
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_CHANGEBOTDIFFICULTY;
		request.requestNum = platformConnection.ChangeBotDifficultyAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), botName, botDifficulty, teamNumber, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function PostKickPlayer(string playerName)
{
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_KICKPLAYER;
		request.requestNum = platformConnection.KickPlayerAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), playerName, currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function ParseChooseCommanderResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") != "")
		myMenu.SetError(json.GetStringValue("error"));
}

function PostLockCommander() {
	local TMPlatformRequest request;
	if(currentGame != none) {
		request.requestType = RT_LOCKCOMMANDER;
		request.requestNum = platformConnection.LockCommanderAsync(username, mSessionToken, currentGame.GetStringValue("gameGUID"), currentGame.GetStringValue("httpEndpoint"));
		platformRequests.AddItem(request);
	}
}

function ParseLockCommanderResponse(string response) {
	local JSONObject json;
	json = class'JsonObject'.static.DecodeJson(response);
	if(json.HasKey("error")) {
		myMenu.SetError(json.GetStringValue("error"));
	} 
	else if (myMenu.Class == class'SFMFrontEndCommanderSelect')
	{
		SFMFrontEndCommanderSelect(myMenu).SetSelectMaestroButtonEnabled(false);
	}
}

exec function FlashWindowStart()
{
	local bool success;
	success = platformConnection.FlashWindowStart();
	`log("Success: "$success, true, 'dru');
}

exec function FlashWindowStop()
{
	local bool success;
	success = platformConnection.FlashWindowStop();
	`log("Success: "$success, true, 'dru');
}

exec function FlashWindowUntilFocus()
{
	local bool success;
	success = platformConnection.FlashWindowUntilFocus();
	`log("Success: "$success, true, 'dru');
}

exec function FlashWindowCount(int count)
{
	local bool success;
	success = platformConnection.FlashWindow(count);
	`log("Success: "$success, true, 'dru');
}

function PostMOTD() {
	local TMPlatformRequest request;
	request.requestType = RT_MOTD;
	request.requestNum = platformConnection.MessageOfTheDayAsync();
	platformRequests.AddItem(request);
}

/* TestFeatureToggles
	Does some simple feature toggle tests to make sure it's functioning properly.

	Tests the blacklistedCommanders properly limit's a player's commander choice.
*/
exec function TestFeatureToggles()
{
	local TMTests tests;
	tests = new class'TMTests'();

	tests.TestBlacklistedCommanders(self);
}

function FeatureToggles featureTogglesFrom(JsonObject json)
{
	local FeatureToggles lFeatureToggles;

	if (json.HasKey("isOnline"))
	{
		lFeatureToggles.isOnline = json.GetBoolValue("isOnline");
	}
	if (json.HasKey("multiplayerEnabled"))
	{
		lFeatureToggles.multiplayerEnabled = json.GetBoolValue("multiplayerEnabled");
	}
	if (json.HasKey("allowErrorLogs"))
	{
		lFeatureToggles.allowErrorLogs = json.GetBoolValue("allowErrorLogs");
	}

	// We can't check for these JSON keys (JsonObject array bug). We have to just grab the object and pray
	lFeatureToggles.blacklistedCommanders = json.GetObject("blacklistedCommanders").ValueArray;
	lFeatureToggles.availableMaps = json.GetObject("availableMaps").ValueArray;

	return lFeatureToggles;
}

function ParseMOTDResponse(string response) {
	local JSONObject json;
	json = class'JSONObject'.static.DecodeJson(response);
	if(json.GetStringValue("error") == "") {
		MotD = "Message of the Day: " $ json.GetStringValue("MOTD");
		if (json.GetObject("featureToggles") != none)
		{
			mFeatureToggles = featureTogglesFrom(json.GetObject("featureToggles"));
			myMenu.SetFeatureToggles(mFeatureToggles);
		} else
		{
			`warn("MOTD response didn't contain featureToggles key");		
		}
	} else {
		MotD = "Couldn't retrieve Message of the Day";
	}

	myMenu.SetMOTD(MotD);
}

function PostGetPlayerStats(Array<string> inUsernameList) {
	local TMPlatformRequest request;
	request.requestType = RT_PLAYERSTATS;
	request.requestNum = platformConnection.GetPlayerStats(mSessionToken, inUsernameList);
	platformRequests.AddItem(request);
}

/*TODO: print statements for data in this*/
function ParsePlayerStatsResponse(string response) {
	local Array<TMPlayerProgressionData> playerStatsList;
	local JSONObject json;
	local TMPlayerProgressionData data;

	json = class'JSONObject'.static.DecodeJson(response);
	`log("Parse Player Stats Response payload: " $ response);

	playerStatsList = ParsePlayerStatsList(json);
	foreach playerStatsList(data) {
		if( data.playerName == username ) {
			Log( "TMMainMenuPlayerController::ParsePlayerStatsResponse() caching player prog data for " $ username );
		}
	}

	if(myMenu.IsA('SFMFrontEndTeamSelect') && json.GetStringValue("error" ) == "") {
		SFMFrontEndTeamSelect(myMenu).handleStatsLoading(playerStatsList);
	} else if (myMenu.IsA('SFMFrontEndMainMenu') && json.GetStringValue("error") == "") {
		SFMFrontEndMainMenu(myMenu).loadPlayerProgressionStats(playerStatsList);
	} else if (myMenu.IsA('SFMFrontEndTutorialMenu') && json.GetStringValue("error") == "") {
		SFMFrontEndTutorialMenu(myMenu).handleStatsLoaded(playerStatsList);
	} else {
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function SavePreMatchPlayerStats(Array<TMPlayerProgressionData> inPlayerStatsList)
{
	local TMPlayerProgressionData tempStats;
	local string saveFile;

	foreach inPlayerStatsList( tempStats )
	{
		if( tempStats.playerName == self.username )
		{
			saveFile = "PreMatchPlayerStats"$username$".bin";
			if (!class'Engine'.static.BasicSaveObject(tempStats, saveFile, false, 0))
			{
				`warn("failed to save PreMatchPlayerStats to "$saveFile);
			}
		}
	}
}

function PostGetPlayerInventory() {
	local TMPlatformRequest request;
	request.requestType = RT_PLAYERINVENTORY;
	request.requestNum = platformConnection.GetPlayerInventory(mSessionToken, username);
	platformRequests.AddItem(request);
}

function ParsePlayerInventoryResponse(string response) {
	local JSONObject json;

	json = class'JSONObject'.static.DecodeJson(response);
	`log("Parse Player Inventory Response payload: " $ response);

	if(json.GetStringValue("error" ) == "")
	{
		mPlayerInventory = class'TMPlayerInventory'.static.DeserializeFromJson( json );
		myMenu.OnPlayerInventoryUpdated();
	}
	else
	{
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function PostGetEndGamePlayerStats(Array<string> inUsernameList, int inGamesPlayed) {
	local TMPlatformRequest request;
	request.requestType = RT_ENDGAMEPLAYERSTATS;
	request.requestNum = platformConnection.GetEndGamePlayerStats(mSessionToken, inUsernameList, inGamesPlayed, username);
	platformRequests.AddItem(request);
}

function ParseEndGamePlayerStatsResponse(string response) {
	local JSONObject json;
	local TMGetEndGamePlayerStatsResponse getEndGamePlayerStatsResponse;

	json = class'JSONObject'.static.DecodeJson(response);
	`log("Parse End Game Player Stats Response payload: " $ response);

	if(myMenu.IsA('SFMFrontEndGameOver') && json.GetStringValue("error" ) == "") {
		getEndGamePlayerStatsResponse = ParseGetEndGamePlayerStatsResponse(json);
		SFMFrontEndGameOver(myMenu).loadPlayerProgressionStats(getEndGamePlayerStatsResponse);
	} else {
		myMenu.SetError(json.GetStringValue("error"));
	}
}

function TMGetEndGamePlayerStatsResponse ParseGetEndGamePlayerStatsResponse(JsonObject inJsonObject)
{
	local TMGetEndGamePlayerStatsResponse getEndGamePlayerStatsResponse;
	
	getEndGamePlayerStatsResponse = new class'TMGetEndGamePlayerStatsResponse'();
	getEndGamePlayerStatsResponse.playerStatsList = ParsePlayerStatsList(inJsonObject);
	getEndGamePlayerStatsResponse.endGamePlayerStats = new class'TMEndGamePlayerStats'();
	getEndGamePlayerStatsResponse.endGamePlayerStats.DeserializeFromJson(inJsonObject.GetObject("endGamePlayerStats"));

	return getEndGamePlayerStatsResponse;
}


function Array<TMPlayerProgressionData> ParsePlayerStatsList(JsonObject inJsonObject)
{
	local JsonObject playerJsonList;
	local JsonObject playerJsonObject;
	local TMPlayerProgressionData playerStats;
	local Array<TMPlayerProgressionData> playerStatsList;

	playerJsonList = inJsonObject.GetObject( "playerStatsList" );
	if (playerJsonList == none) {
		return playerStatsList;
	}

	foreach playerJsonList.ObjectArray( playerJsonObject )
	{
		playerStats = new class'TMPlayerProgressionData'();
		playerStats.DeserializeFromJson(playerJsonObject);
		playerStatsList.AddItem(playerStats);
	}

	return playerStatsList;
}

function SetTimerText() {
	myMenu.SetTimerText();
}

function SetMenu(SFMFrontEnd menu) { myMenu = menu; }

function SetLastMenu(class<SFMFrontEnd> menu) {
	LastMenu = menu;
}

function class<SFMFrontEnd> GetLastMenu() {
	return LastMenu;
}

function LoadSaveData() {
	mSaveData = class'TMSaveData'.static.LoadFile();
}

function SaveSaveData() {
	mSaveData.SaveFile();
}

function StartBasic() {
	mSaveData.SetBasicTutorialStarted();
}

function StartAdvanced() {
	mSaveData.SetAdvancedTutorialStarted();
}

function StartBattle() {
	mSaveData.SetBattleStarted();
}

function StartAlchemist() {
	mSaveData.SetAlchemistStarted();
}

function OnShowedTutorial() {
	mSaveData.ClearJustCompletedTutorial();
}

function bool ShouldOpenTutorialMenu() {
	return mSaveData.justCompletedTutorial;
}

function bool ShouldOpenPracticeBattleMenu() { 	// true when just finished tutorial and we're on battle now
	return ( mSaveData.justCompletedTutorial && mSaveData.advancedTutComplete && mSaveData.battleCompleted == false );
}

function CompletedTutorialSegment() {
	mSaveData.CompletedTutorial();
}

function bool IsBasicInProgress() {
	return mSaveData.basicTutStarted;
}

function bool IsBasicCompleted() {
	return mSaveData.basicTutComplete;
}

function bool IsAdvancedInProgress() {
	return mSaveData.advancedTutStarted;
}

function bool IsAdvancedCompleted() {
	return mSaveData.advancedTutComplete;
}

function bool IsBattleInProgress() {
	return mSaveData.battleStarted;
}

function bool IsBattleCompleted() {
	return mSaveData.battleCompleted;
}

function bool IsAlchemistInProgress() {
	return mSaveData.alchemistStarted;
}

function bool IsAlchemistCompleted() {
	return mSaveData.alchemistCompleted;
}

exec function testPractice() {
	mSaveData.basicTutStarted = false;
	mSaveData.basicTutComplete = true;
	mSaveData.advancedTutStarted = true;
	mSaveData.advancedTutComplete = false;
	mSaveData.battleStarted = false;
	mSaveData.battleCompleted = false;
	mSaveData.alchemistStarted = false;
	mSaveData.alchemistCompleted = false;
	SaveSaveData();
}

exec function testAlchemist() {
	mSaveData.basicTutStarted = false;
	mSaveData.basicTutComplete = true;
	mSaveData.advancedTutStarted = false;
	mSaveData.advancedTutComplete = true;
	mSaveData.battleStarted = false;
	mSaveData.battleCompleted = true;
	mSaveData.alchemistStarted = false;
	mSaveData.alchemistCompleted = false;
	SaveSaveData();
}

// reset the save state to when you are exiting a successful tutorial 2
// TEST: you should enter this command in the main menu. Enter the tutorial menu. You should see a battle practice popup
exec function tutorialTestCompleteTutorial2() {
	mSaveData.ResetSave();
	mSaveData.basicTutComplete = true;
	mSaveData.advancedTutComplete = true;
	mSaveData.justCompletedTutorial = true;
	mSaveData.SaveFile();
}

// reset the save state to when you are exiting a successful battle practice
// TEST: you should enter this command in the main menu. Enter the tutorial menu. You should NOT see a battle practice popup
exec function tutorialTestCompleteBattlePractice() {
	mSaveData.ResetSave();
	mSaveData.basicTutComplete = true;
	mSaveData.advancedTutComplete = true;
	mSaveData.battleCompleted = true;
	mSaveData.justCompletedTutorial = true;
	mSaveData.SaveFile();
}

exec function resetSave() {
	mSaveData.ResetSave();
}

exec function OpenFeedbackForm() {
	mTmSteamProxy.OpenFeedbackForm();
}

exec function SubmitBug() {
	class'Engine'.static.LaunchURL(MaestrosBugSubmissionURL);

	if (mFeatureToggles.allowErrorLogs)
	{
		// Send out UDK log
		platformConnection.UploadLog(username);
	}
}

exec function CheckForCrashes() {
	if (mFeatureToggles.allowErrorLogs)
	{
		platformConnection.CheckForCrashes(username);
	}
}

// Prints a number of bytes into the log. Useful for testing our error logging system where logs are uploaded to a server.
exec function FillLogs(int numBytes)
{
	local int i;
	local string junk;

	junk = "";

	for( i = 0; i < numBytes; i++)
	{
		junk = junk $ "x";
	}

	`log(junk);
}

function SFMAudioPlayer GetAudioManager() {
	return menuAudio;
}

function Log( string inMessage )
{
	if( bAllowMenuLogMessages )
	{
		`log( inMessage );
	}
}


// ------------------- EXEC FUNCTIONS FOR TESTING -------------------

exec function ChangePlatform(string platformURL)
{
	if(platformConnection!=None)
		platformConnection.SetPlatformBaseURL( platformURL );

	mTcpLink.ResolveAndOpen();
}

exec function ChangeTCP(string host, int port)
{
	if(mTcpLink!=None)
	{
		mTcpLink.targetHost = host;
		mTcpLink.targetPort = port;
	}
}

exec function SwitchToRealPlatformConnection()
{
	platformConnection = new class'TMRealPlatformConnection'();
	platformConnection.Setup();
}

exec function SwitchToMockablePlatformConnection()
{
	platformConnection = new class'TMMockablePlatformConnection'();
	platformConnection.Setup();
}

exec function SwitchToFakePlatformConnection()
{
	platformConnection = new class'TMMockPlatformConnection'();
	platformConnection.Setup();
}

exec function bool SteamApiInit()
{
	mTmSteamProxy = new class'TMSteamProxy';
	mTmSteamProxy.SteamAPI_Init();

	if(mTmSteamProxy.IsInitialized())
	{
		`log("TMMainMenuPlayerController::SteamApiInit() TMSteamProxy was initialized");
		mSteamId = mTmSteamProxy.GetPlayerSteamId().steamId.steamId$"";
		self.SetTimer(0.05, true, 'CheckForAcceptedInvitesLoop');
		return true;
	}
	else
	{
		`log("TMMainMenuPlayerController::SteamApiInit() could not initialize TMSteamProxy");
		return false;
	}
}

exec function PrintSteam()
{
	`log(mTmSteamProxy.GetLogMessage());
}

exec function TestSteamErrorLog()
{
	mTmSteamProxy.reportSteamError();
}

exec function Crash()
{
	while(true)
	{
		SwitchToRealPlatformConnection();
	}
}

function CheckForInviteResponse()
{
	if( mLobbyInvites != none )
	{
		StopCheckingForInviteResponse();

		if(mSteamFriendAcceptedInviteFrom == none)
		{
			// We don't have any accepted friend data, so surface it to the user to accept
			DisplayAcceptInvite();
		}
		else
		{
			// This is the friend we accepted through steam UI. Join him
			AcceptLobbyInviteFromFriend(mSteamFriendAcceptedInviteFrom);
			mSteamFriendAcceptedInviteFrom = none;
		}
	}
}

function DisplayAcceptInvite()
{
	local JsonObject steamLobbyInvites;
	local TMSteamFriend steamFriend;

	//USE FOR TESTING
	/*if (myMenu.IsA('SFMFrontEndMainMenu')) {
		//show main menu popup
		steamFriend = new class'TMSteamFriend'();
		steamFriend.steamName = "Whoopsie";
		SFMFrontEndMainMenu(myMenu).ShowInvite(steamFriend);
	}*/

	steamLobbyInvites = mLobbyInvites.GetObject("steamLobbyInvites");
	if (steamLobbyInvites.ObjectArray.Length == 0)
	{
		`log("DisplayAcceptInvite() no steam lobby invites!");
		return;
	}

	// Taylor TODO: replace "GetSteamFriendWithSteamId" with GetSteamNameFromSteamId. Prevents rare case where the inviter isn't active for the player
	steamFriend = mTmSteamProxy.GetSteamFriendWithSteamId(steamLobbyInvites.ObjectArray[0].GetIntValue("senderSteamId"));
	if(steamFriend == none)
	{
		`log("DisplayAcceptInvite() Can't find steam friend with ID " $ steamLobbyInvites.ObjectArray[0].GetIntValue("senderSteamId"));
		return;
	}

	`log("Do you want to accept an invite from " $ steamFriend.steamName);

	if (myMenu.IsA('SFMFrontEndMainMenu')) {
		//show main menu popup
		SFMFrontEndMainMenu(myMenu).ShowInvite(steamFriend);
	}

}

function int AcceptLobbyInviteFromFriend(TMSteamFriend inSteamFriend)
{
	local int i;
	local JsonObject steamLobbyInvites;
	local JsonObject invite;

	steamLobbyInvites = mLobbyInvites.GetObject("steamLobbyInvites");
	if (steamLobbyInvites.ObjectArray.Length == 0)
	{
		`log("LobbyInvites is empty", true, 'dru');
		return -1;
	}

	for(i=0; i < steamLobbyInvites.ObjectArray.Length; i++)
	{
		invite = steamLobbyInvites.ObjectArray[i];
		
		if(invite.GetIntValue("senderSteamId") == inSteamFriend.steamId.steamId)
		{
			mAcceptedLobbyInvite = steamLobbyInvites.ObjectArray[i];
			mAcceptedLobbyInvite.SetStringValue("port", mAcceptedLobbyInvite.GetIntValue("port")$"");
			return self.PostAcceptLobbyInvite(mAcceptedLobbyInvite.GetIntValue("senderSteamId")$"", mAcceptedLobbyInvite.GetStringValue("senderPlayerName"),  mAcceptedLobbyInvite.GetStringValue("gameGUID"), mAcceptedLobbyInvite.GetStringValue("host"), mAcceptedLobbyInvite.GetStringValue("port"), mAcceptedLobbyInvite.GetStringValue("httpEndpoint"));
		}
	}

	`log("Couldn't find lobby invite from friend " $ inSteamFriend.steamName $ " with ID " $ inSteamFriend.steamId.steamId );
	return -1;
}

function int DeclineLobbyInviteFromFriend(TMSteamFriend inSteamFriend)
{
	local int i;
	local JsonObject steamLobbyInvites;
	local JsonObject invite;

	steamLobbyInvites = mLobbyInvites.GetObject("steamLobbyInvites");
	if (steamLobbyInvites.ObjectArray.Length == 0)
	{
		`log("LobbyInvites is empty", true, 'dru');
		return -1;
	}

	for(i=0; i < steamLobbyInvites.ObjectArray.Length; i++)
	{
		invite = steamLobbyInvites.ObjectArray[i];
		
		if(invite.GetIntValue("senderSteamId") == inSteamFriend.steamId.steamId)
		{
			invite.SetStringValue("port", invite.GetIntValue("port")$"");
			return self.PostDeclineLobbyInvites(invite.GetIntValue("senderSteamId")$"", invite.GetStringValue("senderPlayerName"),  invite.GetStringValue("gameGUID"), invite.GetStringValue("host"), invite.GetStringValue("port"), invite.GetStringValue("httpEndpoint"));
		}
	}

	`log("Couldn't find lobby invite from friend " $ inSteamFriend.steamName $ " with ID " $ inSteamFriend.steamId.steamId );
	return -1;
}

function StopCheckingForInviteResponse()
{
	`log("StopCheckingForInviteResponse() done checking for responses.");
	self.ClearTimer('CheckForInviteResponse');
}

function Array<TMSteamFriend> GetSteamFriends() {
	mCachedOnlineFriends = mTmSteamProxy.GetOnlineSteamFriends();
	return mCachedOnlineFriends;
}

exec function SteamFriends()
{
	local int index;
	local TMSteamFriend iterFriend;
	mCachedOnlineFriends = mTmSteamProxy.GetOnlineSteamFriends();

	index = 0;

	`log("Use command 'invitefriend [index]' to invite one of the friends below:");
	foreach mCachedOnlineFriends(iterFriend)
	{
		Say(" (" $ index $ ") " $ iterFriend.steamName);
		`log(" (" $ index++ $ ") " $ iterFriend.steamName);
	}
}

exec function InviteFriend(int index)
{
	if( index >= mCachedOnlineFriends.Length || index < 0 )
	{
		`log("TMMainMenuPlayerController::InviteFriend() invalid index");
		return;
	}

	if( currentGame == none )
	{
		`log("TMMainMenuPlayerController::InviteFriend() no currentGame");
		return;
	}

	SendGameInvite(mCachedOnlineFriends[index]);
}

function SendGameInvite(TMSteamFriend inSteamFriend)
{
	local bool result;

	if( currentGame == none )
	{
		`log("TMMainMenuPlayerController::InviteFriend() no currentGame");
		return;
	}

	// Send invite to steam friend through steam
	result = mTmSteamProxy.TryInviteFriendToLobby(inSteamFriend, "");

	if(result)
	{
		`log("TMMainMenuPlayerController::InviteFriend() invite sent through steam!");

		// POST invite to our server
		SendLobbyInvite(string(inSteamFriend.steamId.steamId));
	}
	else
	{
		`log("TMMainMenuPlayerController::InviteFriend() couldn't send invite to player " $ inSteamFriend.steamName);
	}
}

exec function TestInvite()
{
	steamInviteServerCommunicator.PostInvite(123123, "123_connect");
}

function CheckForInvitesOnLogin()
{
	`log("Checking for invites on login!");
	PostRetrieveLobbyInvites();
	self.SetTimer(0.05, true, 'CheckForInviteResponse');
	self.SetTimer(2, false, 'StopCheckingForInviteResponse');
}

/* CheckForAcceptedInvitesLoop()
	We need to listen for when a user accepts a game invite through the steam UI.
	This loop will keeps checking if a user accepts a game request, and will try
	to join the game after accepting.
*/
function CheckForAcceptedInvitesLoop()
{
	if(mTmSteamProxy.HaveAcceptedInvite())
	{
		// Grab SteamID and check for an invite
		mSteamFriendAcceptedInviteFrom = mTmSteamProxy.GetSteamFriendToJoin();
		mLobbyInvites = none;
		PostRetrieveLobbyInvites();
		self.SetTimer(0.05, true, 'CheckForInviteResponse');
		self.SetTimer(5, false, 'StopCheckingForInviteResponse');
	}
}

exec function RunTests()
{
	TestWeightedSelection();
}

/* TestWeightedSelection
	Does some testing of our weighted selection system. Not true unit tests, requires you to read the log output and interpret results.
*/
exec function TestWeightedSelection()
{
	local TMTests tests;
	tests = new class'TMTests'();

	tests.TestWeightedSelection();
}

DefaultProperties
{
	DISCONNECT_REASON_HOST_CANCELED = "The host canceled the lobby"
	DISCONNECT_REASON_UNKNOWN = "You disconnected from the lobby"
	DISCONNECT_REASON_TIMEOUT = "You timed out from the lobby"
	DISCONNECT_REASON_QUIT = "You quit the lobby"
	DISCONNECT_REASON_GAME_JOIN_TIMEOUT = "Timed out attempting to join game server, game versions might not match"
	MAPS_JSON_FILE_PATH = "GlobalVariables\\Maps.json"

	mLobbyDisconnectReason = "You disconnected from the lobby"

	MaestrosGameFeedbackURL="http://maestrosgame.com/feedback/"
	MaestrosBugSubmissionURL="https://goo.gl/forms/zL9AIdPU3LdU2fQt1"

	bAllowMenuLogMessages = true;

	INVALID_STEAM_REQUEST_NUMBER = -1
}
