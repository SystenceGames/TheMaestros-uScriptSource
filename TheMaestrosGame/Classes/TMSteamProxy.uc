class TMSteamProxy extends Object
	DLLBind(TMSteamProxy);

var private bool mIsSteamInitialized;

var const int STEAM_RESULT_TM_FAIL;
var const int STEAM_RESULT_OK;
var const int STEAM_RESULT_FAIL;
var const int STEAM_RESULT_NO_CONNECTION; // many more of these exist in steamclientpublic.h if needed

dllimport final function bool SteamApiInit();
dllimport final function GetMySteamId(out TMSteamID outTMSteamId);
dllimport final function int GetRegularFriendCount();
dllimport final function bool IsRegularFriendOnline(int inFriendIndex);
dllimport final function int GetRegularFriendSteamId(out TMSteamID outTMSteamId, int inFriendIndex);
dllimport final function string GetFriendName(TMSteamID inTMSteamId);
dllimport final function bool InviteFriendToGame(TMSteamID inTMSteamId, string inConnectString);
dllimport final function UpdateSteamCallbacks();
dllimport final function bool HaveAcceptedGameInvite();
dllimport final function bool GetGameInviterSteamIdAndClearInvite(out TMSteamID outTMSteamId);

dllimport final function int RequestAuthSessionTicket(); // returns a requestNumber for you to then retrieve with RetrieveAuthSessionTicketResponseFor(). When calling, set a timer for 10-20s and if it doesn't happen by then, consider it failed (likely no connection to Steam)
dllimport final function bool GetAuthSessionTicketResponseFor(int requestNumber, out TMAuthSessionTicketData outTMAuthSessionTicketData);
dllimport final function bool AuthSessionTicketResponseExistsFor(int requestNumber);

dllimport final function tempBadTaylorCodeOpenBugSubmissionPage();
dllimport final function tempBadTaylorCodeOpenFeedbackSubmissionPage();

// These 2 functions currently aren't implemented. Check taylor shelved files to mess with these
dllimport final function reportSteamError();
dllimport final function string GetLogMessage();

function bool SteamAPI_Init()
{
	mIsSteamInitialized = SteamApiInit();
	return mIsSteamInitialized;
}

function bool IsInitialized()
{
	return mIsSteamInitialized;
}

function TMSteamFriend GetPlayerSteamId()
{
	local TMSteamFriend tempSteamFriend;
	tempSteamFriend = new class'TMSteamFriend'();
	GetMySteamId(tempSteamFriend.steamId);
	return tempSteamFriend;
}

function Array<TMSteamFriend> GetOnlineSteamFriends()
{
	local int friendCount;
	local Array<TMSteamFriend> onlineFriendList;
	local int i;
	local TMSteamFriend tempSteamFriend;

	if(!mIsSteamInitialized)
	{
		`warn("Tried to get online friends but steam is not initialized.");
		return onlineFriendList;
	}

	friendCount = GetRegularFriendCount();

	for(i=0; i < friendCount; i++)
	{
		if( IsRegularFriendOnline(i) )
		{
			tempSteamFriend = new class'TMSteamFriend'();
			GetRegularFriendSteamId(tempSteamFriend.steamId, i);
			tempSteamFriend.steamName = GetFriendName(tempSteamFriend.steamId);
			onlineFriendList.AddItem( tempSteamFriend );
		}
	}

	return onlineFriendList;
}

// Remove this function when we add "get steam name from steam ID"
function TMSteamFriend GetSteamFriendWithSteamId(int inSteamId)
{
	// NOTE: this function will return 'none' if it can't find the friend
	local Array<TMSteamFriend> onlineFriends;
	local TMSteamFriend friend;
	onlineFriends = GetOnlineSteamFriends();
	foreach onlineFriends(friend)
	{
		if(friend.steamId.steamId == inSteamId)
		{
			return friend;
		}
	}

	return none;
}

function bool TryInviteFriendToLobby(TMSteamFriend inTMSteamFriend, string inLobby)
{
	if(!mIsSteamInitialized)
	{
		`warn("Tried to invite friend but steam is not initialized.");
		return false;
	}

	`log("TMSteamProxy::TryInviteFriendToLobby() inviting " $ inTMSteamFriend.steamName $ " to " $ inLobby);
	return InviteFriendToGame(inTMSteamFriend.steamId, inLobby);
}

function bool HaveAcceptedInvite()
{
	UpdateSteamCallbacks();
	return HaveAcceptedGameInvite();
}

function TMSteamFriend GetSteamFriendToJoin()
{
	local TMSteamFriend tempSteamFriend;
	tempSteamFriend = new class'TMSteamFriend'();

	// TODO: add bool check to get inviter steam ID. Should be safe for now tho
	GetGameInviterSteamIdAndClearInvite(tempSteamFriend.steamId);
	tempSteamFriend.steamName = GetFriendName(tempSteamFriend.steamId);

	return tempSteamFriend;
}

function TMSteamAuthSessionTicket RetrieveAuthSessionTicketResponseFor(int requestNumber)
{
	local TMSteamAuthSessionTicket steamAuthSessionTicket;
	if (!AuthSessionTicketResponseExistsFor(requestNumber))
	{
		return None;
	}

	steamAuthSessionTicket = new class'TMSteamAuthSessionTicket'(); // this allocates a reasonably large buffer (~1kb) and thus shouldn't be called unnecessarily
	if (!GetAuthSessionTicketResponseFor(requestNumber, steamAuthSessionTicket.authSessionTicketData)) {
		`log("No auth session found via GetAuthSessionTicketResponseFor requestNumber:"$requestNumber, true, 'dru');
		return None;
	}

	return steamAuthSessionTicket;
}

function OpenBugForm()
{
	tempBadTaylorCodeOpenBugSubmissionPage();
}

function OpenFeedbackForm()
{
	tempBadTaylorCodeOpenFeedbackSubmissionPage();
}

DefaultProperties
{
	STEAM_RESULT_TM_FAIL = -1
	STEAM_RESULT_OK = 1
	STEAM_RESULT_FAIL = 2
	STEAM_RESULT_NO_CONNECTION = 3
}