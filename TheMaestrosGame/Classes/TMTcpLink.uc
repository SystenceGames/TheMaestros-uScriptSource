class TMTcpLink extends TcpLink
	config(TMPlatform);

var TMMainMenuPlayerController PC; //reference to our player controller

var string targetHost; //URL or P address of web server
var int targetPort; //port you want to use for the link

var string requesttext; //data we will send
var JsonObject mConnectionJson;
var string lastMessage;
var int localPort;

event PostBeginPlay()
{
    super.PostBeginPlay();
	lastMessage = "";
}

function SetConnectionInfo(string gameGUID, string playerName, string connectionKey)
{
	mConnectionJson = new () class'JsonObject';

	mConnectionJson.SetStringValue("gameGUID", gameGUID);
	mConnectionJson.SetStringValue("playerName", playerName);
	mConnectionJson.SetStringValue("connectionKey", connectionKey);
}

function ResolveAndOpen() //removes having to send a host
{
    Resolve(TargetHost);
}
 
event Resolved( IpAddr Addr )
{
    // The hostname was resolved succefully
    `Log("[TcpLinkClient] "$TargetHost$" resolved to "$ IpAddrToString(Addr));
     
    // Make sure the correct remote port is set, resolving doesn't set
    // the port value of the IpAddr structure
    Addr.Port = TargetPort;
     

	localPort = BindPort();
    `Log("[TcpLinkClient] Bound to port: "$ localPort);
    if (!Open(Addr))
    {
        `Log("[TcpLinkClient] Open failed");
    }
}
 
event ResolveFailed()
{
    `Log("[TcpLinkClient] Unable to resolve "$TargetHost);
    // You could retry resolving here if you have an alternative
    // remote host.
}
 
event Opened()
{
    `Log("[TcpLinkClient] event opened from local port:"$localPort $ "to " $ targetHost $ ":" $ TargetPort );
	
	SendConnectionString(mConnectionJson);

	PC.HandleSocketOpened();
}

function SendConnectionString(JsonObject connectionObject)
{
	local int returnBytes;
	local string connectionJsonString;

	connectionJsonString = class'JsonObject'.static.EncodeJson(connectionObject);
    returnBytes = SendText(connectionJsonString);

	if (Len(connectionJsonString) != 0 && returnBytes == 0)
	{
		`log("TMTcpLink::SendConnectionString() ERROR: IT BROKE, NO BYTES SENT");
	}
}

event Closed()
{
    // In this case the remote client should have automatically closed
    // the connection, because we requested it in the HTTP request.
    `Log("[TMTcpLinkClient] event closed");
	PC.HandleSocketClosed();
    // After the connection was closed we could establish a new
    // connection using the same TcpLink instance.
}
 
event ReceivedText( string Text )
{   
	local array<string> multicommands;
	local string commandObjectString;

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
	local string command;

	commandObject = class'JsonObject'.static.DecodeJson(commandText);

	if (commandObject == None)
	{
		`Log("ERROR: the response from the server was not a parseable Json");
		return;
	}
	
	command = commandObject.GetStringValue("command");

	if (command == "")
	{
		`Log("ERROR: there was no command in the response from platform");
		return;
	}

	switch(command)
	{
		case "updateGameInfo":
			PC.HandleUpdateGameInfo(commandObject);
			return;
	}

	`Log("Error: Couldn't recognize command from platform");
}

defaultproperties
{
}