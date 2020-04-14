class SFMFrontEndMainMenu extends SFMFrontEnd;

// Main menu widgets
var GFxClikWidget 	menu_BrowseGamesBtn,
					menu_TutorialBtn,
					menu_SettingsBtn,
					menu_QuitBtn,
					menu_CreditsBtn,
					menu_FeedbackBtn,
					menu_BugBtn,
					menu_DiscordBtn;

// Game browser widgets
var GFxClikWidget 	gameBrowser_RefreshBtn,
					gameBrowser_ScrollingList,
					gameBrowser_OpenCreateGameBtn;

// AllChat Widgets
var GFxCLIKWidget	allChat_SendBtn,
					allChat_TextArea,
					allChat_userTextArea;

//Game Creation Widgets
var GFxCLIKWidget   create_hostCreateBtn,
					create_cancelBtn;

// Account Verification Widgets
var GFxClikWidget 	account_ResendButton,
					account_OkayButton;

var GFxClikWidget	invite_AcceptButton,
					invite_OkayButton;

var TMSteamFriend cachedFriend;


function bool Start(optional bool startPaused = false) {
	local bool retVal;
	myPC.Log( "SFMFrontEndMainMenu::Start() starting!" );
	retVal = super.Start(startPaused);
	SetMotD(myPC.MotD);
	CurrentMenu = "MainMenu";
	GetVariableObject("root").GetObject("progressBarMain").GetObject("usernameText").SetText(myPC.username);
	initializeStats();

	//handle verification popup for new players
	if (myPC.isNewPlayer == true) {
		GetVariableObject("root").GetObject("verifyPopup").SetBool("visible", true);
		myPC.isNewPlayer = false;
	}

	// Get my player inventory from the server
	myPC.PostGetPlayerInventory();

	// If I'm at the main menu no tutorials will be in progress.
	myPC.mSaveData.ClearInProgressTutorials();	// NOTE: need to figure out our UI flow. Too many of these BS checks all over the place

	//connect to allchat
	myPC.ConnectChat("allChat", myPC.username);

	// Join the lobby if we got a steam invite. NOTE: need to clean this up later. Just testing
	if( Len(myPC.menuGameInfo.mInvitedLobbyGUID) > 0 &&
		Len(myPC.menuGameInfo.mInvitedLobbyPort) > 0 &&
		Len(myPC.menuGameInfo.mInvitedLobbyHost) > 0 )
	{
		`log("Trying to connect to " $ myPC.menuGameInfo.mInvitedLobbyGUID $ " " $ myPC.menuGameInfo.mInvitedLobbyPort $ " " $ myPC.menuGameInfo.mInvitedLobbyHost);
		myPC.EnterLobby(myPC.menuGameInfo.mInvitedLobbyGUID, "dummyConnectionKey", myPC.menuGameInfo.mInvitedLobbyPort, myPC.menuGameInfo.mInvitedLobbyHost);

		// Erase values after connecting (TODO: move this later)
		myPC.menuGameInfo.mInvitedLobbyGUID = "";
		myPC.menuGameInfo.mInvitedLobbyPort = "";
		myPC.menuGameInfo.mInvitedLobbyHost = "";
	}

	// Check if we have a crash log we should submit
	myPC.CheckForCrashes();

	return retVal;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;

	bWashandled = false;
	switch(Widgetname) {
		///// Main Menu Widgets /////
		case ('joinGameBtn'):
			menu_BrowseGamesBtn = GFxClikWidget(Widget);
			menu_BrowseGamesBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_BrowseGamesBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('tutorialBtn'):
			menu_TutorialBtn = GFxClikWidget(Widget);
			menu_TutorialBtn.AddEventListener('CLIK_click', OpenTutorialMenu);
			menu_TutorialBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_TutorialBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('settingsBtn'):
			menu_SettingsBtn = GFxClikWidget(Widget);
			menu_SettingsBtn.AddEventListener('CLIK_click', OpenSettingsMenu);
			menu_SettingsBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_SettingsBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('quitBtn'):
			menu_QuitBtn = GFxClikWidget(Widget);
			menu_QuitBtn.AddEventListener('CLIK_click', QuitGame);
			menu_QuitBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_QuitBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('creditsBtn'):
			menu_CreditsBtn = GFxClikWidget(Widget);
			menu_CreditsBtn.AddEventListener('CLIK_click', RunCredits);
			menu_CreditsBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_CreditsBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('feedbackBtn'):
			menu_FeedbackBtn = GFxClikWidget(Widget);
			menu_FeedbackBtn.AddEventListener('CLIK_click', OpenFeedbackForm);
			menu_FeedbackBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_FeedbackBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('bugBtn'):
			menu_BugBtn = GFxClikWidget(Widget);
			menu_BugBtn.AddEventListener('CLIK_click', SubmitBug);
			menu_BugBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_BugBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('discordBtn'):
			menu_DiscordBtn = GFxClikWidget(Widget);
			menu_DiscordBtn.AddEventListener('CLIK_click', OpenDiscordLink);
			menu_DiscordBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			menu_DiscordBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;

		///// Account verification widgets /////
		case ('resendButton'):
			account_ResendButton = GFxClikWidget(Widget);
			account_ResendButton.AddEventListener('CLIK_click', ResendEmail);
			account_ResendButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			account_ResendButton.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('okayButton'):
			account_OkayButton = GFxClikWidget(Widget);
			account_OkayButton.AddEventListener('CLIK_click', OpenTutorialMenu);
			account_OkayButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			account_OkayButton.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;

		///// Game Creation /////

		case ('hostOkayBtn'):
			create_hostCreateBtn = GFxClikWidget(Widget);
			create_hostCreateBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			create_hostCreateBtn.AddEventListener('CLIK_click', DisableCreateGameBtn);
			bWasHandled = true;
			break;
		case ('hostBackBtn'):
			create_cancelBtn = GFxClikWidget(Widget);
			create_cancelBtn.AddEventListener('CLIK_click', ResetListGames);
			create_cancelBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			create_cancelBtn.AddEventListener('CLIK_click', PlayCancel);
			bWasHandled = true;
			break;

		///// INVITE /////
		case ('acceptInviteBtn'):
			invite_AcceptButton = GFxClikWidget(Widget);
			invite_AcceptButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			invite_AcceptButton.AddEventListener('CLIK_click', PlayCancel);
			invite_AcceptButton.AddEventListener('CLIK_click', DisableAcceptInviteBtn);
			bWasHandled = true;
			break;
		case ('okayInviteBtn'):
			invite_OkayButton = GFxClikWidget(Widget);
			invite_OkayButton.AddEventListener('CLIK_click', DeclineInvite);
			invite_OkayButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			invite_OkayButton.AddEventListener('CLIK_click', PlayCancel);
			bWasHandled = true;
			break;

		///// All Chat widgets /////
		case ('sendBtn'):
			allChat_SendBtn = GFxClikWidget(Widget);
			allChat_SendBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('chatArea'):
			allChat_TextArea = GFxClikWidget(Widget);
			bWasHandled = true;
			allChat_TextArea.SetText("Hi, Welcome to The Maestros!\n\nWe're officially in BETA MODE!!!\nFeel free to send us feedback and bug reports. They'll help us make the game even better.\n\nMake sure to check out our discord! Click the discord button on the bottom left.\n\n"); 	// Quick chat log init, for looks.
			break;
		case ('userTextfield'):
			allChat_userTextArea = GFxClikWidget(Widget);
			bWasHandled = true;
			break;

		///// user browser widgets /////
		case ('createBtn'):
			gameBrowser_OpenCreateGameBtn = GFxClikWidget(Widget);
			gameBrowser_OpenCreateGameBtn.AddEventListener('CLIK_click', OpenCreateGameMenu);
			gameBrowser_OpenCreateGameBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			gameBrowser_OpenCreateGameBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('refreshBtn'):
			gameBrowser_RefreshBtn = GFxClikWidget(Widget);
			gameBrowser_RefreshBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			gameBrowser_RefreshBtn.AddEventListener('CLIK_click', PlayEnterLobby);
			gameBrowser_RefreshBtn.AddEventListener('CLIK_click', DisableRefreshBtn);
			bWasHandled = true;
			break;
		case ('customGameSL'):
			gameBrowser_ScrollingList = GFxClikWidget(Widget);
			bWasHandled = true;
			break;
	}

	return bWasHandled;
}


///// Main Menu Functions /////

function OpenTutorialMenu(EventData data) {
	LoadMenu(class'SFMFrontEndTutorialMenu');
}

function OpenSettingsMenu(EventData data) {
	LoadMenu(class'SFMFrontEndSettingsMenu');
}

function QuitGame(EventData data) {
	myPC.DisconnectChat();
	ConsoleCommand("exit");
}

function RunCredits(EventData data) {

	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	args.Length = 0;

	FunctionPath = "_root";
	InvokeFunction = "startCredits";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function SetFeatureToggles(FeatureToggles inFeatureToggles) 
{
	if (false == inFeatureToggles.multiplayerEnabled)
	{
		GetVariableObject("root").GetObject("joinGameBtn").SetVisible(false);
		SetError("Our beta is offline. In the mean time, learn to play in one of our tutorials.");
	} else
	{
		GetVariableObject("root").GetObject("joinGameBtn").SetVisible(true);
	}
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

function SetVerification() {
	GetVariableObject("root").GetObject("errorText").SetText("Verification Email Resent");
}

function initializeStats(){
	local Array<string> playerNames;
	playerNames.AddItem(myPC.username);
	myPC.PostGetPlayerStats(playerNames);
}

function loadPlayerProgressionStats(Array<TMPlayerProgressionData> playerData)
{
	local ASValue Param0;
	local ASValue Param1;
	local ASValue Param2;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;
    local TMPlayerProgressionData progData, tempData;

   	foreach playerData( tempData )
   	{
   		if( tempData.playerName == myPC.username )
   		{
   			progData = tempData;
   		}
   	}

   	if( progData == none )
   	{
   		`warn( "SFMFrontEndGameOver::loadEndGamePlayerStats() couldn't find my player in the player progression data list!" );
   		return;
   	}


	Param0.Type = AS_Number;
	Param1.Type = AS_Number;
	Param2.Type = AS_Number;

	Param0.n = progData.currentExperience;
	Param1.n = progData.experienceForNextLevel;
	Param2.n = progData.currentLevel;

	`log(progData.currentExperience $ "+" $ progData.experienceForNextLevel $ "+" $ progData.currentLevel, true, 'Mark');
	//`log(preMatchPlayerStats.currentExperience $ "+" $ preMatchPlayerStats.experienceForNextLevel $ "+" $ preMatchPlayerStats.currentLevel, true, 'Mark');

	args.Length = 3;
    args[0] = Param0;
	args[1] = Param1;
	args[2] = Param2;

	FunctionPath = "_root";
	InvokeFunction = "scaleProgress";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}

	//set games played
	GetVariableObject("root").GetObject("progressBarMain").GetObject("gamesPlayed").SetText(progData.gamesPlayed);
}


///// Account Creation Functions /////
function ResendEmail(EventData data) {
	myPC.PostResend(myPC.email);
	DisableResendBtn();
}


///// All Chat Functions /////
//TODO: Disconnect from allChat on Game Selection
function SendChatMessage() {
	local GFxObject chatInput;

	chatInput = GetVariableObject("root").GetObject("chatbox").GetObject("chatInput");

	if(chatInput.GetText() != "") {
		myPC.SendChatMessage(chatInput.GetText());
		chatInput.SetText("");
		menuAudio.PlayChatSend();
	} else {
		menuAudio.PlayError();
	}
}

function ReceiveChatMessage(string message) {
	allChat_TextArea.SetText(allChat_TextArea.GetText() $ message $ "\n");
	allChat_TextArea.GetObject("textField").SetInt("scrollV", allChat_TextArea.GetObject("textField").GetInt("maxScrollV"));
}

function GetUsers() {
	myPC.CallGetUsers("allChat");
	menuAudio.PlayButtonSelect();
}

function ReceiveUsers(string message) {
	if (message != "") {
		allChat_userTextArea.SetText(message);
	}
}

function ShowInvite(TMSteamFriend inFriend) {
	cachedFriend = inFriend;
	//show things to player here
	GetVariableObject("root").GetObject("invitePopup").SetVisible(true);
	GetVariableObject("root").GetObject("invitePopup").GetObject("friendName").SetText(cachedFriend.steamName);
}

function AcceptInvite() {
	myPC.AcceptLobbyInviteFromFriend(cachedFriend);
}

function DeclineInvite(EventData data) {
	myPC.DeclineLobbyInviteFromFriend(cachedFriend);
}


///// Game Browser functions /////
// Mark TODO: make this call externally from flash. Then delete this comment
function JoinGame() {
	local int requestedGameIndex;
	
	requestedGameIndex = gameBrowser_ScrollingList.GetInt("selectedIndex");
	if (requestedGameIndex >= 0) 
	{
		myPC.JoinGameHelper(myPC.availableGames.ObjectArray[requestedGameIndex]);
		menuAudio.PlayHostSuccess();
	} else {
		SetError("Must select a game in order to join one.");
	}
}

function PlayExternalMouseOver() {
	menuAudio.PlayMouseOver();
}

function OpenCreateGameMenu(EventData data) {
	myPC.SetTimer(0.f, false, 'PostListGames');
	GetVariableObject("root").GetObject("createGame").GetObject("gameNameInput").SetText(myPC.username $ "'s Game");
}

// Mark TODO: listen for this button press in action script. You can either call this function externally or do the inside of the function from flash
function RefreshGameBrowserList() {
	local array<ASValue> args;
	args.Length = 0; // Making it explicit for the compiler that we want this guy empty - avoids warnings.
	gameBrowser_ScrollingList.GetObject("dataProvider").Invoke("invalidate", args);
	//ActionScriptVoid("InvalidateCustomGameScrollingList");
	//GetScrollingListData();	// Mark TODO: add a this function to action script. It should have the same name
}

function CreatePost() {
	CreateGame(GetVariableObject("root").GetObject("createGame").GetObject("gameNameInput").GetText());
}

// Mark TODO: make this call externally from flash. Then delete this comment
function CreateGame(string inGameName) {
//	myPC.DisconnectChat();
	myPC.PostHostGame(inGameName, "SacredArena", "TheMaestrosGame.TMRoundBasedGameInfo");
}

// Mark TODO: use this as the function name in AS for customGameSL.dataProvider = new ExternalDataProvider("ListGames");
function array<GFxObject> GetScrollingListData() {
	local int i;
	local GFxObject tempObj;
	local JsonObject availableGame;
	local array<GFxObject> dataProvider;

	GetVariableObject("root").GetObject("lobbyMenu").GetObject("noGamesTB").SetVisible(false);

	if(myPC.availableGames != none) {
		for(i = 0; i < myPC.availableGames.ObjectArray.Length; i++) {
			availableGame = myPC.availableGames.ObjectArray[i];
			if (myPC.expiredGameGUIDs.Find(availableGame.GetStringValue("gameGUID")) != INDEX_NONE)
			{
				continue;
			}

			tempObj = CreateObject("Object");
			tempObj.SetString("gameName", availableGame.GetStringValue("gameName"));
			if(availableGame.GetStringValue("mapName") == "SacredArena") {
				tempObj.SetString("gameMap", "Sacred Arena");
			} else {
				tempObj.SetString("gameMap", availableGame.GetStringValue("mapName"));
			}
			tempObj.SetString("gameType", availableGame.GetStringValue("hostName")); // what the actual fuck?
			tempObj.SetInt("numPlayers", availableGame.GetIntValue("numOfPlayers"));
			dataProvider.AddItem(tempObj);
		}

		if(dataProvider.Length == 0) {
			GetVariableObject("root").GetObject("lobbyMenu").GetObject("noGamesTB").SetVisible(true);
			myPC.SetTimer(5.0f, false, 'PostListGames');
		}
	}

	return dataProvider;
}

function PostGame() {
	myPC.PostListGames();
}

function ResetListGames(EventData data) {
	myPC.PostListGames();
}

function OpenFeedbackForm(EventData data) {
	myPC.OpenFeedbackForm();
}

function SubmitBug(EventData data) {
	menu_BugBtn.SetVisible(false);
	myPC.SubmitBug();
}

function OpenDiscordLink(EventData data) {
	class'Engine'.static.LaunchURL("https://discord.gg/P9QyNzU");
}

function DisableCreateGameBtn(EventData data) {
	create_hostCreateBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableCreateGameBtn', self);
}

function EnableCreateGameBtn() {
	create_hostCreateBtn.SetVisible(true);
}

function DisableResendBtn() {
	account_ResendButton.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableResendBtn', self);
}

function EnableResendBtn() {
	account_ResendButton.SetVisible(true);
}

function DisableAcceptInviteBtn(EventData data) {
	invite_AcceptButton.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableAcceptInviteBtn', self);
}

function EnableAcceptInviteBtn() {
	invite_AcceptButton.SetVisible(true);
}

function DisableRefreshBtn(EventData data) {
	gameBrowser_RefreshBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableRefreshBtn', self);
}

function EnableRefreshBtn() {
	gameBrowser_RefreshBtn.SetVisible(true);
}

DefaultProperties
{
	MovieInfo = SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_MainMenu'

	// Main menu widgets
	WidgetBindings.Add((Widgetname="joinGameBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="tutorialBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="settingsBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="quitBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="creditsBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="feedbackBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="bugBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="discordBtn", WidgetClass=class'GFxCLIKWidget'))

	// Account verification widgets
	WidgetBindings.Add((Widgetname="resendButton", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="okayButton", WidgetClass=class'GFxCLIKWidget'))

	// All chat widgets
	WidgetBindings.Add((Widgetname="sendBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="chatArea",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="userTextfield", WidgetClass=class'GFxCLIKWidget'))

	// Game browser widgets
	WidgetBindings.Add((WidgetName="createBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="createGameButton",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="refreshBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="backBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="customGameSL",WidgetClass=class'GFxCLIKWidget'))

	//Game Creation widgets
	WidgetBindings.Add((WidgetName="hostOkayBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="hostBackBtn",WidgetClass=class'GFxCLIKWidget'))

	//Invite Panel widgets
	WidgetBindings.Add((WidgetName="okayInviteBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="acceptInviteBtn",WidgetClass=class'GFxCLIKWidget'))
}
