class TMChatLink extends TcpLink
	config(TMPlatform);

var TMMainMenuPlayerController PC; //reference to our player controller

var config string targetHost; //URL or P address of web server
var config int targetPort; //port you want to use for the link

var string path; //path to file you want to request
var string requesttext; //data we will send
var JsonObject mConnectionJson;
var string lastMessage;

var const string SEND_MESSAGE_COMMAND_TYPE;
var const string GET_USERS_COMMAND_TYPE;
var const string SWITCH_ROOM_COMMAND_TYPE;

event PostBeginPlay()
{
    super.PostBeginPlay();
	lastMessage = "";
}

function SetConnectionInfo(string roomName, string playerName)
{
	mConnectionJson = new () class'JsonObject';

	mConnectionJson.SetStringValue("room", roomName);
	mConnectionJson.SetStringValue("name", playerName);

	`log("chat target host: " $ targetHost);
	`log("chat target port: " $ targetPort);
}

function ResolveAndOpen() //removes having to send a host
{
    Resolve(TargetHost);
}
 
event Resolved( IpAddr Addr )
{
    // The hostname was resolved succefully
    `Log("[ChatLinkClient] "$TargetHost$" resolved to "$ IpAddrToString(Addr));
     
    // Make sure the correct remote port is set, resolving doesn't set
    // the port value of the IpAddr structure
    Addr.Port = TargetPort;
     
    //dont comment out this log because it rungs the function bindport
    `Log("[ChatLinkClient] Bound to port: "$ BindPort() );
    if (!Open(Addr))
    {
        `Log("[ChatLinkClient] Open failed");
    }
}
 
event ResolveFailed()
{
    `Log("[ChatLinkClient] Unable to resolve "$TargetHost);
    // You could retry resolving here if you have an alternative
    // remote host.
}
 
event Opened()
{
    `Log("[ChatLinkClient] event opened");
	
	SendConnectionString(mConnectionJson);

	PC.HandleChatSocketOpened();
}

function SendConnectionString(JsonObject connectionObject)
{
	local int returnBytes;
	local string connectionJsonString;

	connectionJsonString = class'JsonObject'.static.EncodeJson(connectionObject);
	connectionJsonString $= "\n";
    returnBytes = SendText(connectionJsonString);

	if (Len(connectionJsonString) != 0 && returnBytes == 0)
	{
		`log("TMChatLink::SendConnectionString() ERROR: IT BROKE, NO BYTES SENT");
	}
}

event Closed()
{
    // In this case the remote client should have automatically closed
    // the connection, because we requested it in the HTTP request.
    `Log("[ChatLinkClient] event closed");
	PC.HandleChatSocketClosed();
    // After the connection was closed we could establish a new
    // connection using the same TcpLink instance.
}

function SendObject(JsonObject objectToSend)
{
	local int returnBytes;
	local string jsonString;

	jsonString = class'JsonObject'.static.EncodeJson(objectToSend);
	jsonString $= "\n";
    returnBytes = SendText(jsonString);

	if (Len(jsonString) != 0 && returnBytes == 0)
	{
		`log("TMChatLink::SendObject() ERROR: IT BROKE, NO BYTES SENT");
	}
}

function SendMessage(string message)
{
	local JSONObject messageJSON;

	messageJSON = new () class'JSONObject';
	messageJSON.SetStringValue("commandType", SEND_MESSAGE_COMMAND_TYPE);
	messageJSON.SetStringValue("message", message);
	SendObject(messageJSON);
}

function SendGetUsers(string room)
{
	local JSONObject messageJSON;

	messageJSON = new () class'JSONObject';
	messageJSON.SetStringValue("commandType", GET_USERS_COMMAND_TYPE);
	messageJSON.SetStringValue("room", room);
	SendObject(messageJSON);
}

function SendSwitchRooms(string newRoom)
{
	local JSONObject messageJSON;

	messageJSON = new () class'JSONObject';
	messageJSON.SetStringValue("commandType", SWITCH_ROOM_COMMAND_TYPE);
	messageJSON.SetStringValue("room", newRoom);
	SendObject(messageJSON);
}

event ReceivedText( string Text )
{   
	local array<string> multicommands;
	local string commandObjectString;

	// receiving some text, note that the text includes line breaks
    `Log("[ChatLinkClient] ReceivedText:: "$Text);

	// parse out the newline
	multicommands = SplitString(Text, "\n", true);

	// check error cases (this is the buffer)
	if(lastMessage != "")
	{
		multicommands[0] = lastMessage $ multiCommands[0];
		lastMessage = "";
	}
	if(Right(Text, 1) != "\n")
	{
		lastMessage = multicommands[multicommands.Length - 1];
		multicommands.Remove(multicommands.Length - 1, 1);
	}
	
	foreach multicommands(commandObjectString)
	{
		HandleCommand(commandObjectString);
	}
}
 
function HandleCommand(string commandText)
{
    local JsonObject commandObject;
	local string commandType;
	
	commandObject = class'JsonObject'.static.DecodeJson(commandText);
	if (commandObject == None)
	{
		`Log("ERROR: the response from the server was not a parseable Json");
		return;
	}

	commandType = commandObject.GetStringValue("commandType");
	if (commandType == SEND_MESSAGE_COMMAND_TYPE)
	{
		HandleSendMessageResponse(commandObject);
	}
	else if (commandType == GET_USERS_COMMAND_TYPE)
	{
		HandleGetUsersResponse(commandObject);
	}
	else
	{
		`warn("recieved a commandType we do not recognize "$commandType);
	}
}

function HandleGetUsersResponse(JsonObject commandObject)
{
	local array<string> users;
	local JsonObject usersJson;
	local string iterName;

	usersJson = commandObject.GetObject("users");
	if( usersJson == none ) {
		`warn("Received null when expecting users in GetUsers Response");
		return;
	}

	foreach usersJson.ValueArray( iterName ) {
		users.AddItem( iterName );
	}

	PC.HandleReceivedGetUsersMessage(users);
}

function HandleSendMessageResponse(JsonObject commandObject)
{
	local string message;
	message = commandObject.GetStringValue("message");
	if (message == "")
	{
		`warn("there was no message in SendMessage response from ChatServer");
		return;
	}
	PC.HandleReceivedChatMessage(message);
}

defaultproperties
{
	SEND_MESSAGE_COMMAND_TYPE = "SendMessage"
	GET_USERS_COMMAND_TYPE = "GetUsers"
	SWITCH_ROOM_COMMAND_TYPE = "SwitchRoom"
}
