class TMRealPlatformConnection extends Object implements(TMPlatformConnection)
	config(TMPlatform)
	DLLBind(TMServerCommunication);

var string LocalGameServerBaseURL;
var config string PlatformBaseURL;
var config string AccountsBaseURL;
var config string PlayerStatsBaseURL;
var config string GrayLogBaseURL;
var config string PlatformVersionString;
var config string PlatformPort;
var config string PlatformShard;

dllimport final function string ReturnHi();
dllimport final function string HTTPGet(string urlEndQuery);
dllimport final function string HTTPPost(string urlEndQuery, string payload);
dllimport final function int HTTPPostAsync(string urlEndQuery, string payload);
dllimport final function string HTTP10PostNoResponse(string urlEndQuery, string payload);
dllimport final function string GetResponse(int requestNumber);
dllimport final function string UploadCurrentUDKLog(string graylogUrl, string playerName, int maxLogLengthPerBlob, int maxNumberofBlobs);
dllimport final function string CheckForCrashLogs(string graylogUrl, string playerName, int maxLogLengthPerBlob, int maxNumberofBlobs);
dllimport final function bool StartFlashingWindow();
dllimport final function bool StopFlashingWindow();
dllimport final function bool Flash();
dllimport final function bool FlashCount(int count);
dllimport final function bool ForceWindowOpenAndFront();
dllimport final function bool ShowWindowAsync(int nCmdShow);
dllimport final function bool ShowWindow(int nCmdShow);
dllimport final function bool SetForegroundWindow();

function Setup() {}

function SetPlatformBaseURL(string inURL)
{
	PlatformBaseURL = inURL;
}

function int PostToAnyLobbyAsync(string command, string payload)
{
	local string address;

	address = baseUrlWithPort(PlatformBaseURL, PlatformPort) $ PlatformVersionString;
	address $= command;

	`log("Posting a"@command@"command to "$address);
	if ( command != "login" && command != "createPlayer" && payload != "")
	{
		`log(payload);
	}

	return HTTPPostAsync(address, payload);
}

function int PostToSpecificLobbyAsync(string command, string payload, string endpoint)
{
	local string address;

	address = endpoint $ PlatformVersionString $ command;

	`log("Posting a"@command@"command to lobby service at:"@address);
	if ( command != "login" && command != "createPlayer" && payload != "")
	{
		`log(payload);
	}

	return HTTPPostAsync(address, payload);
}

function int PostToAccountsAsync(string command, string payload)
{
	local string address;

	address = AccountsBaseURL;
	address $= command;

	`log("Posting a "$command$" command to "$address);

	return HTTPPostAsync(address, payload);
}

function int PostToPlayerProgressionData(string command, string payload)
{
	local string address;
	address = PlayerStatsBaseURL $ command;

	`log("Posting a "$command$" command to "$address);
	`log("PPD payload: " $ payload);

	return HTTPPostAsync(address, payload);
}

function int PostProcessEndGameStats(string payload)
{
	local string modifiedPayload;

	`log("TMRealPlatformConnection::PostProcessEndGameStats() posting " $ payload);

	modifiedPayload = "playerStats="$payload;

	return self.PostToPlayerProgressionData("processEndGameStats", modifiedPayload);
}

function PostToPlayerStats(string command, string payload)
{
	local string address;
	local string response;

	address = PlayerStatsBaseURL $ command;

	response = HTTPPost(address, payload);
	
	if (response != "no error")
	{
		`WARN("TMPlatformConnection says HTTP10PostNoResponse() returned an error: "$response);
	}
}

function PostToGraylog(string payload)
{
	local string address;
	local string response;

	address = GrayLogBaseURL;
	
	response = HTTP10PostNoResponse(address, payload);
	
	if (response != "no error")
	{
		`WARN("TMPlatformConnection says HTTP10PostNoResponse() returned an error: "$response);
	}
}

function string GetPlatformResponse(int requestNumber)
{
	return GetResponse(requestNumber);
}

function int Login4Async(string steamAuthSessionTicket)
{
	local string payload;

	payload = "steamAuthSessionTicket="$steamAuthSessionTicket;

	return PostToAccountsAsync("login4", payload);
}

function int LoginAsync(string playerName, string password)
{
	local string payload;

	payload = "email="$playerName$"&password="$password;

	return PostToAccountsAsync("login3", payload);
}

function int ResendAsync(string email) {
	local string payload;
	payload = "email="$email;
	return PostToAccountsAsync("resendVerificationEmail", payload);
}

function int ResetAsync(string email) {
	local string payload;
	payload = "email="$email;
	return PostToAccountsAsync("sendPasswordResetEmail", payload);
}

function int CreatePlayer3Async(string playerName, string password, string email, string birthday, string steamAuthSessionTicket)
{
	local string payload;
	`log ("Posting creation3 payload with " $ playerName $ " " $ email $ " " $ birthday $ " " $ steamAuthSessionTicket);
	payload = "playerName=" $ playerName $ "&password=" $ password $ "&email=" $ email $ "&birthDate=" $ birthday $ "&steamAuthSessionTicket=" $ steamAuthSessionTicket;

	return PostToAccountsAsync("createPlayer3", payload);
}

function int CreatePlayerAsync(string playerName, string password, string email, string birthday)
{
	local string payload;
	`log ("Posting creation payload with " $ playerName $ " " $ email $ " " $ birthday);
	payload = "playerName=" $ playerName $ "&password=" $ password $ "&email=" $ email $ "&birthDate=" $ birthday;

	return PostToAccountsAsync("createPlayer2", payload);
}

function int ListGamesAsync(string playerName, string sessionToken)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken;

	return PostToAnyLobbyAsync("listGames", payload);
}

function int HostGameAsync(string playerName, string sessionToken, string gameName, string mapName, string gameType)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameName="$gameName$"&mapName="$mapName$"&gameType="$gameType;

	return PostToAnyLobbyAsync("hostGame", payload);
}

function int SwitchTeamsAsync(string playerName, string sessionToken, string gameGUID, int team, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$team;

	return PostToSpecificLobbyAsync("updateLobbyInfo/switchTeams", payload, endpoint);
}

function int ChangeMapAsync(string playerName, string sessionToken, string gameGUID, string map, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$map;

	return PostToSpecificLobbyAsync("updateLobbyInfo/changeMap", payload, endpoint);
}

function int ChangeGameTypeAsync(string playerName, string sessionToken, string gameGUID, string type, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$type;

	return PostToSpecificLobbyAsync("updateLobbyInfo/changeGameType", payload, endpoint);
}

function int LockTeamsAsync(string playerName, string sessionToken, string gameGUID, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID;

	return PostToSpecificLobbyAsync("updateLobbyInfo/lockTeams", payload, endpoint);
}

function int SendSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint)
{
	local string payload;

	payload = "sessionToken="$sessionToken$"&playerName="$playerName$"&receiverSteamId="$receiverSteamId$"&senderSteamId="$senderSteamId$"&senderPlayerName="$senderPlayerName$"&gameGUID="$gameGUID$"&host="$host$"&port="$port$"&httpEndpoint="$endpoint;

	return PostToSpecificLobbyAsync("sendSteamLobbyInvite", payload, endpoint);
}

function int RetrieveSteamLobbyInvitesAsync(string sessionToken, string playerName, string receiverSteamId)
{
	local string payload;

	payload = "sessionToken="$sessionToken$"&playerName="$playerName$"&receiverSteamId="$receiverSteamId;

	return PostToAnyLobbyAsync("retrieveSteamLobbyInvites", payload);
}

function int DeclineSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint)
{
	local string payload;

	payload = "sessionToken="$sessionToken$"&playerName="$playerName$"&receiverSteamId="$receiverSteamId$"&senderSteamId="$senderSteamId$"&senderPlayerName="$senderPlayerName$"&gameGUID="$gameGUID$"&host="$host$"&port="$port$"&httpEndpoint="$endpoint;

	return PostToSpecificLobbyAsync("declineSteamLobbyInvite", payload, endpoint);
}

function int AcceptSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint)
{
	local string payload;

	payload = "sessionToken="$sessionToken$"&playerName="$playerName$"&receiverSteamId="$receiverSteamId$"&senderSteamId="$senderSteamId$"&senderPlayerName="$senderPlayerName$"&gameGUID="$gameGUID$"&host="$host$"&port="$port$"&httpEndpoint="$endpoint;

	return PostToSpecificLobbyAsync("acceptSteamLobbyInvite", payload, endpoint);
}

function int ChooseCommanderAsync(string playerName, string sessionToken, string gameGUID, string lobbyCommandParams, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$lobbyCommandParams;

	return PostToSpecificLobbyAsync("updateLobbyInfo/chooseCommander", payload, endpoint);
}

function int AddBotAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint)
{
	local string payload;
	local JsonObject addBotCommandParameters;
	local string addBotCommandParametersString;
	addBotCommandParameters = new () class'JsonObject';

	addBotCommandParameters.SetIntValue("teamNumber", teamNumber);
	addBotCommandParameters.SetStringValue("playerName", botName);
	addBotCommandParameters.SetIntValue("botDifficulty", botDifficulty);
	addBotCommandParametersString = class'JsonObject'.static.EncodeJson(addBotCommandParameters);
	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$addBotCommandParametersString;

	return PostToSpecificLobbyAsync("updateLobbyInfo/addBot", payload, endpoint);
}

function int ChangeBotDifficultyAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint)
{
	local string payload;
	local JsonObject changeBotCommandParameters;
	local string changeBotCommandParametersString;
	changeBotCommandParameters = new () class'JsonObject';

	changeBotCommandParameters.SetIntValue("teamNumber", teamNumber);
	changeBotCommandParameters.SetStringValue("playerName", botName);
	changeBotCommandParameters.SetIntValue("botDifficulty", botDifficulty);
	changeBotCommandParametersString = class'JsonObject'.static.EncodeJson(changeBotCommandParameters);
	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$changeBotCommandParametersString;

	return PostToSpecificLobbyAsync("updateLobbyInfo/changeBotDifficulty", payload, endpoint);
}

function int KickPlayerAsync(string playerName, string sessionToken, string gameGUID, string targetPlayerName, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID$"&lobbyCommandParameters="$targetPlayerName;

	return PostToSpecificLobbyAsync("updateLobbyInfo/kickPlayer", payload, endpoint);
}

function int LockCommanderAsync(string playerName, string sessionToken, string gameGUID, string endpoint)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameGUID="$gameGUID;

	return PostToSpecificLobbyAsync("updateLobbyInfo/lockCommander", payload, endpoint);
}

function int MessageOfTheDayAsync()
{
	local string payload;

	payload = "";

	return PostToAnyLobbyAsync("platformMOTD", payload);
}

function int GetPlayerStats(string sessionToken, Array<string> playerNames)
{
	local JsonObject json;
	local JsonObject playerNamesJson;
	local string payload;
	local int i;

	json = new class'JsonObject'();
	json.SetStringValue("sessionToken", sessionToken);
	playerNamesJson = new class'JsonObject'();
	for( i = 0; i < playerNames.Length; i++ )
	{
		playerNamesJson.ValueArray[i] = playerNames[i];
	}
	json.SetObject("playerNames", playerNamesJson);

	payload = "playerStats="$class'JsonObject'.static.EncodeJson(json);
	return PostToPlayerProgressionData("getPlayerStats", payload);
}

function int GetPlayerInventory(string sessionToken, string playerName)
{
	local JsonObject json;
	local string payload;

	json = new class'JsonObject'();
	json.SetStringValue("sessionToken", sessionToken);
	json.SetStringValue("playerName", playerName);
	payload = "playerStats="$class'JsonObject'.static.EncodeJson(json);
	return PostToPlayerProgressionData("getPlayerInventory", payload);
}

function int GetEndGamePlayerStats(string sessionToken, Array<string> playerNames, int newGamesPlayed, string callingPlayerName)
{
	local JsonObject json;
	local JsonObject playerNamesJson;
	local string payload;
	local int i;

	json = new class'JsonObject'();
	json.SetStringValue("sessionToken", sessionToken);
	json.SetIntValue("newGamesPlayed", newGamesPlayed);
	json.SetStringValue("callingPlayerName", callingPlayerName);
	playerNamesJson = new class'JsonObject'();
	for( i = 0; i < playerNames.Length; i++ )
	{
		playerNamesJson.ValueArray[i] = playerNames[i];
	}
	json.SetObject("playerNames", playerNamesJson);

	payload = "playerStats="$class'JsonObject'.static.EncodeJson(json);
	return PostToPlayerProgressionData("getEndGamePlayerStats", payload);
}

function PostGameInitialized(string port, string jobId)
{
	`log("Posting a GameInitialized to local GameServer with jobId:"$jobId);
	HTTPPostAsync(baseUrlWithPort(LocalGameServerBaseURL, port)$"GameInitialized", "jobID="$jobId);
}

function UpdateActiveHumanPlayerCount(int humanPlayerCount, string port, string jobId)
{
	HTTPPostAsync(baseUrlWithPort(LocalGameServerBaseURL, port)$"UpdateActiveHumanPlayerCount", "jobID="$jobId$"&activeHumanPlayerCount="$humanPlayerCount);
}
// UNUSED EXCEPT FOR EXEC TEST

/** Uses a sync http post */
function string PostToPlatform(string command, string payload)
{
	local string url;

	url = PlatformBaseURL;
	url $= command;

	return HTTPPost(url, payload);
}

function string UpdateGameInfo(string playerName, string sessionToken, string gameInfoJson)
{
	local string payload;

	payload = "playerName="$playerName$"&sessionToken="$sessionToken$"&gameInfo="$gameInfoJson;

	return PostToPlatform("updateGameInfo", payload);
}

function string baseUrlWithPort(string baseUrl, string port)
{
	return baseUrl$":"$port$"/";
}

function string GetShard()
{
	return PlatformShard;
}

function UploadLog(string playerName)
{
	local string message;
	local int numBytesPerBlob, numBlobs;

	`log("Uploading UDK log...");
	numBytesPerBlob = 50000;
	numBlobs = 2;
	message = UploadCurrentUDKLog(GrayLogBaseURL, playerName, numBytesPerBlob, numBlobs);
	`log(message);
}

function CheckForCrashes(string playerName)
{
	local string message;
	local int numBytesPerBlob, numBlobs;

	`log("Checking for previous crashes...");
	numBytesPerBlob = 50000;
	numBlobs = 2;
	message = CheckForCrashLogs(GrayLogBaseURL, playerName, numBytesPerBlob, numBlobs);
	`log(message);
}

function bool FlashWindowStart()
{
	return self.StartFlashingWindow();
}

function bool FlashWindowStop()
{
	return self.StopFlashingWindow();
}

function bool FlashWindowUntilFocus()
{
	return self.Flash();
}

function bool FlashWindow(int times)
{
	return self.FlashCount(times);
}

function bool SetWindowOpenAndFront()
{
	return self.ForceWindowOpenAndFront();
}

function bool TMShowWindowAsync(int nCmdShow)
{
	return self.ShowWindowAsync(nCmdShow);
}

function bool TMShowWindow(int nCmdShow)
{
	return self.ShowWindow(nCmdShow);
}

function bool TMSetForegroundWindow()
{
	return self.SetForegroundWindow();
}



defaultproperties
{
	LocalGameServerBaseURL="http://127.0.0.1"
}
