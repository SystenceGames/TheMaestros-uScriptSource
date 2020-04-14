Interface TMPlatformConnection;

enum RequestType {
	RT_MOTD,
	RT_LOGIN,
	RT_CREATEPLAYER,
	RT_LISTGAMES,
	RT_HOSTGAME,
	RT_JOINGAME,
	RT_SWITCHTEAM,
	RT_CHANGEMAP,
	RT_CHANGEGAMETYPE,
	RT_STARTGAME,
	RT_LOCKTEAMS,
	RT_CHOOSECOMMANDER,
	RT_LOCKCOMMANDER,
	RT_ADDBOT,
	RT_CHANGEBOTDIFFICULTY,
	RT_KICKPLAYER,
	RT_PLAYERSTATS,
	RT_PLAYERINVENTORY,
	RT_ENDGAMEPLAYERSTATS,
	RT_RESEND,
	RT_RESET,
	RT_LOGIN4,
	RT_SENDLOBBYINVITE,
	RT_RETRIEVELOBBYINVITES,
	RT_DECLINELOBBYINVITE,
	RT_ACCEPTLOBBYINVITE,
	RT_PROCESSENDGAMESTATS
};

struct TMPlatformRequest {
	var RequestType requestType;
	var int requestNum;
};

function Setup();

function string GetPlatformResponse(int requestNumber);

function SetPlatformBaseURL(string inURL);

function int LoginAsync(string playerName, string password);
function int Login4Async(string steamAuthSessionTicket);
function int ResendAsync(string email);
function int ResetAsync(string email);
function int CreatePlayerAsync(string playerName, string password, string email, string birthday);
function int CreatePlayer3Async(string playerName, string password, string email, string birthday, string steamAuthSessionTicket);
function int ListGamesAsync(string playerName, string sessionToken);
function int HostGameAsync(string playerName, string sessionToken, string gameName, string mapName, string gameType);
function int SwitchTeamsAsync(string playerName, string sessionToken, string gameGUID, int team, string endpoint);
function int ChangeMapAsync(string playerName, string sessionToken, string gameGUID, string map, string endpoint);
function int ChangeGameTypeAsync(string playerName, string sessionToken, string gameGUID, string type, string endpoint);
function int LockTeamsAsync(string playerName, string sessionToken, string gameGUID, string endpoint);
function int ChooseCommanderAsync(string playerName, string sessionToken, string gameGUID, string lobbyCommandParams, string endpoint);
function int AddBotAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint);
function int ChangeBotDifficultyAsync(string playerName, string sessionToken, string gameGUID, string botName, int botDifficulty, int teamNumber, string endpoint);
function int KickPlayerAsync(string playerName, string sessionToken, string gameGUID, string targetPlayerName, string endpoint);
function int LockCommanderAsync(string playerName, string sessionToken, string gameGUID, string endpoint);
function int MessageOfTheDayAsync();
function int GetPlayerStats(string sessionToken, Array<string> playerNames);
function int GetPlayerInventory(string sessionToken, string playerName);
function int GetEndGamePlayerStats(string sessionToken, Array<string> playerNames, int newGamesPlayed, string callingPlayerName);

function int SendSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint);
function int RetrieveSteamLobbyInvitesAsync(string sessionToken, string playerName, string receiverSteamId);
function int DeclineSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint);
function int AcceptSteamLobbyInviteAsync(string sessionToken, string playerName, string receiverSteamId, string senderSteamId, string senderPlayerName, string gameGUID, string host, string port, string endpoint);

function PostGameInitialized(string port, string jobId);
function PostToGraylog(string payload);
function int PostProcessEndGameStats(string payload);
function PostToPlayerStats(string method, string payload);
function UpdateActiveHumanPlayerCount(int humanPlayerCount, string port, string jobId);

function string GetShard();

function UploadLog(string playerName);
function CheckForCrashes(string playerName);

function bool FlashWindowStart();
function bool FlashWindowStop();
function bool FlashWindowUntilFocus();
function bool FlashWindow(int times);
function bool SetWindowOpenAndFront();
function bool TMShowWindowAsync(int nCmdShow);
function bool TMSetForegroundWindow();
function bool TMShowWindow(int nCmdShow);

