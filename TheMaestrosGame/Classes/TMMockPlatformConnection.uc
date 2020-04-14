/* TMMockPlatformConnection
	This is used for giving the dummy data. In the future it could be used if the platform is down.
*/
class TMMockPlatformConnection extends Object implements(TMPlatformConnection);

var Array<string> mMockResponses;

// We need to make sure that mock platform responses don't collide with any future real platform responses
var const int RESPONSE_NUMBER_SHIFT_AMOUNT;


function Setup() {}

function bool HaveResponse(int inRequestNumber)
{
	// All Mock Platform responses will be a number larger than or equal to the shift amount
	if(inRequestNumber >= RESPONSE_NUMBER_SHIFT_AMOUNT)
	{
		return true;
	}

	return false;
}

function int GetMostRecentRequestNumber()
{
	return RESPONSE_NUMBER_SHIFT_AMOUNT + mMockResponses.Length-1;
}

function string GetPlatformResponse(int requestNumber)
{
	requestNumber -= RESPONSE_NUMBER_SHIFT_AMOUNT;
	return mMockResponses[requestNumber];
}

function int MessageOfTheDayAsync()
{
	local JsonObject json;
	json = new class'JsonObject'();
	json.SetStringValue( "MOTD", "Mock Platform MOTD" );
	json.SetStringValue( "error", "" );
	mMockResponses.AddItem( class'JsonObject'.static.EncodeJson(json) );
	return GetMostRecentRequestNumber();
}

function int GetPlayerStats(string sessionToken, Array<string> playerNames)
{
    return CreateFakePlayerProgressionData(sessionToken, playerNames);
}

function int GetEndGamePlayerStats(string sessionToken, Array<string> playerNames, int newGamesPlayed, string callingPlayerName)
{
	return CreateFakePlayerProgressionData(sessionToken, playerNames, newGamesPlayed, 1);
}

private function int CreateFakePlayerProgressionData(string inSessionToken, Array<string> inPlayerNames, int inNewGamesPlayed = 0, int inLevelGainedScalar = 0)
{
	local JsonObject responseJson;
	local JsonObject playerStatsJsonList;
	local int i;

	playerStatsJsonList = new class'JsonObject'();
	for( i = 0; i < inPlayerNames.Length; i++ )
	{
		playerStatsJsonList.ObjectArray[i] = CreatePlayerStatsJson( inPlayerNames[i], 25, 100, i + 1 + inLevelGainedScalar, inNewGamesPlayed*i, 100 );
	}

	responseJson = new class'JsonObject'();
	responseJson.SetObject("playerStatsList", playerStatsJsonList);

	mMockResponses.AddItem( class'JsonObject'.static.EncodeJson(responseJson) );
	return GetMostRecentRequestNumber();
}

private function JsonObject CreatePlayerStatsJson(string inPlayerName, int inCurrentXP, int inXPGained, int inCurrentLevel, int inGamesPlayed, int inXpForNextLevel )
{
	local JsonObject json;
	local JsonObject unlocksJson;
	json = new class'JsonObject'();
	json.SetStringValue( "playerName", inPlayerName );
	json.SetIntValue( "currentXP", inCurrentXP );
	json.SetIntValue( "xpDelta", inXPGained );
	json.SetIntValue( "currentLevel", inCurrentLevel );
	json.SetIntValue( "gamesPlayed", inGamesPlayed );
	json.SetIntValue( "xpForNextLevel", inXpForNextLevel );
	json.SetIntValue( "nextUnlockableLevel", 7);
	unlocksJson = new class'JsonObject'();
	unlocksJson.ValueArray[0] = "Rosie";
	json.SetObject( "lastUnlockedItemIds", unlocksJson );
	json.SetStringValue( "error", "" );
	return json;
}

function int GetPlayerInventory(string sessionToken, string playerName)
{
	local JsonObject json;
	local JsonObject inventoryIds;

	inventoryIds = new class'JsonObject'();
	inventoryIds.ValueArray[0] = "RoboMeister";
	inventoryIds.ValueArray[1] = "TinkerMeister";
	inventoryIds.ValueArray[2] = "RamBamQueen";

	json = new class'JsonObject'();
	json.SetObject("inventoryIds", inventoryIds);

	mMockResponses.AddItem( class'JsonObject'.static.EncodeJson(json) );
	return GetMostRecentRequestNumber();
}

function SetPlatformBaseURL(string inURL) {}



function int Login4Async(string steamAuthSessionTicket) {}
function int LoginAsync(string playerName, string password) {}
function int ResendAsync(string email) {}
function int ResetAsync(string email) {}
function int CreatePlayerAsync(string playerName, string password, string email, string brithday) {}
function int CreatePlayer3Async(string playerName, string password, string email, string brithday, string steamAuthSessionTicket) {}
function int ListGamesAsync(string playerName, string sessionToken) {}
function int HostGameAsync(string playerName, string sessionToken, string gameName, string mapName, string gameType) {}
function int SwitchTeamsAsync(string playerName, string sessionToken, string gameGUID, int team, string endpoint) {}
function int ChangeMapAsync(string playerName, string sessionToken, string gameGUID, string map, string endpoint) {}
function int ChangeGameTypeAsync(string playerName, string sessionToken, string gameGUID, string type, string endpoint) {}
function int LockTeamsAsync(string playerName, string sessionToken, string gameGUID, string endpoint) {}
function int ChooseCommanderAsync(string playerName, string sessionToken, string gameGUID, string lobbyCommandParams, string endpoint) {}
function int AddBotAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint) {}
function int ChangeBotDifficultyAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint) {}
function int KickPlayerAsync(string playerName, string sessionToken, string gameGUID, string targetPlayerName, string endpoint) {}
function int LockCommanderAsync(string playerName, string sessionToken, string gameGUID, string endpoint) {}

function int SendSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint) {}
function int RetrieveSteamLobbyInvitesAsync(string sessionToken, string playerName, string receiverSteamId) {}
function int DeclineSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint) {}
function int AcceptSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint) {}

function PostGameInitialized(string port, string jobId) {}
function PostToGraylog(string payload) {}
function int PostProcessEndGameStats(string payload) {}
function PostToPlayerStats(string method, string payload) {}
function UpdateActiveHumanPlayerCount(int humanPlayerCount, string port, string jobId) {}
function bool FlashWindowStart() {}
function bool FlashWindowStop() {}
function bool FlashWindowUntilFocus() {}
function bool FlashWindow(int times) {}
function bool SetWindowOpenAndFront() {}
function bool TMShowWindowAsync(int nCmdShow) {}
function bool TMSetForegroundWindow() {}
function bool TMShowWindow(int nCmdShow) {}

function string GetShard()
{
	return "mock";
}

function UploadLog(string playerName) {}
function CheckForCrashes(string playerName) {}

DefaultProperties
{
	RESPONSE_NUMBER_SHIFT_AMOUNT = 10000;
}
