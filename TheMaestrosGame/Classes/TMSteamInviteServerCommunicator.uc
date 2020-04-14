class TMSteamInviteServerCommunicator extends Object
	DLLBind(TMServerCommunication);

var string EndpointURL;
var int CheckForInviteAsyncRequestNumber;

dllimport final function int HTTPPostAsync(string urlEndQuery, string payload);
dllimport final function string GetResponse(int requestNumber);

function PostInvite(int inSteamIdToInvite, string inConnectString)
{
	local string payload;
	payload = "steam_id=" $ inSteamIdToInvite $ "&" $ inConnectString;
	`log("TMSteamInviteServerCommunicator::CheckForInviteAsync() sending invite to " $ inSteamIdToInvite $ "\n  " $ inConnectString);
	HTTPPostAsync(EndpointURL, payload);
}

function PostCheckForInviteAsync(string inSteamId)
{
	local string payload;
	payload = "steam_id_to_check=" $ inSteamId;
	CheckForInviteAsyncRequestNumber = HTTPPostAsync(EndpointURL, payload);
}

function string CheckForInviteResponse()
{
	`log("Checking response for number " $ CheckForInviteAsyncRequestNumber);
	return GetResponse(CheckForInviteAsyncRequestNumber);
}

DefaultProperties
{
	EndpointURL = "https://tm-steam-invite.appspot.com/"
}
