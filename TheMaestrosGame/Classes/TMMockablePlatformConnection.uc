/* TMMockablePlatformConnection
	A PlatformConnection which has some Mock calls and some real ones.
	Uses a TMRealPlatfromConnection and a TMMockPlatformConnection for calls
*/
class TMMockablePlatformConnection extends Object implements(TMPlatformConnection);

var TMRealPlatformConnection mRealPlatformConnection;
var TMMockPlatformConnection mMockPlatformConnection;

function Setup()
{
	mRealPlatformConnection = new class'TMRealPlatformConnection'();
	mMockPlatformConnection = new class'TMMockPlatformConnection'();
}

function string GetPlatformResponse(int requestNumber)
{
	if( mMockPlatformConnection.HaveResponse(requestNumber) )
	{
		return mMockPlatformConnection.GetPlatformResponse(requestNumber);
	}
	else
	{
		return mRealPlatformConnection.GetPlatformResponse(requestNumber);
	}
}

function SetPlatformBaseURL(string inURL)
{
	mRealPlatformConnection.SetPlatformBaseURL(inURL);
}

function int Login4Async(string steamAuthSessionTicket)
{
	return mRealPlatformConnection.Login4Async(steamAuthSessionTicket);
}

function int LoginAsync(string playerName, string password)
{
	return mRealPlatformConnection.LoginAsync(playerName, password);
}

function int ResendAsync(string email) {
	return mRealPlatformConnection.ResendAsync(email);
}

function int ResetAsync(string email) {
	return mRealPlatformConnection.ResetAsync(email);
}

function int CreatePlayer3Async(string playerName, string password, string email, string birthday, string steamAuthSessionTicket)
{
	return mRealPlatformConnection.CreatePlayer3Async(playerName, password, email, birthday, steamAuthSessionTicket);
}

function int CreatePlayerAsync(string playerName, string password, string email, string birthday)
{
	return mRealPlatformConnection.CreatePlayerAsync(playerName, password, email, birthday);
}

function int ListGamesAsync(string playerName, string sessionToken)
{
	return mRealPlatformConnection.ListGamesAsync(playerName, sessionToken);
}

function int HostGameAsync(string playerName, string sessionToken, string gameName, string mapName, string gameType)
{
	return mRealPlatformConnection.HostGameAsync(playerName, sessionToken, gameName, mapName, gameType);
}

function int SwitchTeamsAsync(string playerName, string sessionToken, string gameGUID, int team, string endpoint)
{
	return mRealPlatformConnection.SwitchTeamsAsync(playerName, sessionToken, gameGUID, team, endpoint);
}

function int ChangeMapAsync(string playerName, string sessionToken, string gameGUID, string map, string endpoint)
{
	return mRealPlatformConnection.ChangeMapAsync(playerName, sessionToken, gameGUID, map, endpoint);
}

function int ChangeGameTypeAsync(string playerName, string sessionToken, string gameGUID, string type, string endpoint)
{
	return mRealPlatformConnection.ChangeGameTypeAsync(playerName, sessionToken, gameGUID, type, endpoint);
}

function int LockTeamsAsync(string playerName, string sessionToken, string gameGUID, string endpoint)
{
	return mRealPlatformConnection.LockTeamsAsync(playerName, sessionToken, gameGUID, endpoint);
}

function int ChooseCommanderAsync(string playerName, string sessionToken, string gameGUID, string lobbyCommandParams, string endpoint)
{
	return mRealPlatformConnection.ChooseCommanderAsync(playerName, sessionToken, gameGUID, lobbyCommandParams, endpoint);
}

function int AddBotAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint)
{
	return mRealPlatformConnection.AddBotAsync(playerName, sessionToken, gameGUID, botName, botDifficulty, teamNumber, endpoint);
}

function int ChangeBotDifficultyAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint)
{
	return mRealPlatformConnection.ChangeBotDifficultyAsync(playerName, sessionToken, gameGUID, botName, botDifficulty, teamNumber, endpoint);
}

function int KickPlayerAsync(string playerName, string sessionToken, string gameGUID, string targetPlayerName, string endpoint)
{
	return mRealPlatformConnection.KickPlayerAsync(playerName, sessionToken, gameGUID, targetPlayerName, endpoint);
}

function int LockCommanderAsync(string playerName, string sessionToken, string gameGUID, string endpoint)
{
	return mRealPlatformConnection.LockCommanderAsync(playerName, sessionToken, gameGUID, endpoint);
}

function int MessageOfTheDayAsync()
{
	return mRealPlatformConnection.MessageOfTheDayAsync();
}

function int GetPlayerStats(string sessionToken, Array<string> playerNames)
{
	return mMockPlatformConnection.GetPlayerStats(sessionToken, playerNames);
}

function int GetPlayerInventory(string sessionToken, string playerName)
{
	return mMockPlatformConnection.GetPlayerInventory(sessionToken, playerName);
}

function int GetEndGamePlayerStats(string sessionToken, Array<string> playerNames, int newGamesPlayed, string callingPlayerName)
{
	return mMockPlatformConnection.GetEndGamePlayerStats(sessionToken, playerNames, newGamesPlayed, callingPlayerName);
}

function PostGameInitialized(string port, string jobId)
{
	mRealPlatformConnection.PostGameInitialized(port, jobId);
}

function PostToGraylog(string payload)
{
	mRealPlatformConnection.PostToGraylog(payload);
}

function int PostProcessEndGameStats(string payload)
{
	return mRealPlatformConnection.PostProcessEndGameStats(payload);
}

function PostToPlayerStats(string method, string payload)
{
	mRealPlatformConnection.PostToPlayerStats(method, payload);
}

function UpdateActiveHumanPlayerCount(int humanPlayerCount, string port, string jobId)
{
	mRealPlatformConnection.UpdateActiveHumanPlayerCount(humanPlayerCount, port, jobId);
}

function int SendSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint)
{
	return mRealPlatformConnection.SendSteamLobbyInviteAsync(sessionToken, playerName, receiverSteamId, senderSteamId, senderPlayerName, gameGUID, host, port, endpoint);
}

function int RetrieveSteamLobbyInvitesAsync(string sessionToken, string playerName, string receiverSteamId)
{
	return mRealPlatformConnection.RetrieveSteamLobbyInvitesAsync( sessionToken,  playerName,  receiverSteamId);
}

function int DeclineSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint)
{
	return mRealPlatformConnection.DeclineSteamLobbyInviteAsync(sessionToken, playerName, receiverSteamId, senderSteamId, senderPlayerName, gameGUID, host, port, endpoint);
}

function int AcceptSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint)
{
	return mRealPlatformConnection.AcceptSteamLobbyInviteAsync(sessionToken, playerName, receiverSteamId, senderSteamId, senderPlayerName, gameGUID, host, port, endpoint);
}

function bool FlashWindowStart()
{
	return mRealPlatformConnection.FlashWindowStart();
}

function bool FlashWindowStop()
{
	return mRealPlatformConnection.FlashWindowStop();
}

function bool FlashWindowUntilFocus()
{
	return mRealPlatformConnection.FlashWindowUntilFocus();
}

function bool FlashWindow(int times)
{
	return mRealPlatformConnection.FlashWindow(times);
}

function bool SetWindowOpenAndFront()
{
	return mRealPlatformConnection.SetWindowOpenAndFront();
}

function bool TMShowWindowAsync(int nCmdShow)
{
	return mRealPlatformConnection.TMShowWindowAsync(nCmdShow);
}

function bool TMSetForegroundWindow()
{
	return mRealPlatformConnection.TMSetForegroundWindow();
}

function bool TMShowWindow(int nCmdShow)
{
	return mRealPlatformConnection.TMShowWindow(nCmdShow);
}


function string GetShard()
{
	return "mock";
}

function UploadLog(string playerName)
{
	mRealPlatformConnection.UploadLog(playerName);
}

function CheckForCrashes(string playerName)
{
	mRealPlatformConnection.CheckForCrashes(playerName);
}
