class SFMFrontEndCommanderSelect extends SFMFrontEnd;

var GFxClikWidget selectMaestroButton, gregoryIcon, rosieIcon, robomeisterIcon, randomIcon, salvatorIcon, rambamqueenIcon, hivelordIcon, chatLog, sendBtn, backButton;
var bool firstTime;
var string leftAllyName, rightAllyName;
var string currentLeftCommander, currentRightCommander, currentCommander;
var array<bool> lockedInCommanders;
var bool isLockedIn;
var int timeLeft;


function bool Start(optional bool startPaused = false)
{
	local bool retVal;
	retVal = super.Start(startPaused);
	//SetMotD(myPC.MotD);

	firstTime = true;
	leftAllyName = "";
	rightAllyName = "";
	timeLeft = 60;

	currentLeftCommander = "Unselected";
	currentRightCommander = "Unselected";
	currentCommander = "Unselected";

	CurrentMenu = "CommanderSelect";

	isLockedIn = false;

	SetCommanderToolTipText();

	myPC.platformConnection.SetWindowOpenAndFront();

	return retVal;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;
	bWashandled = false;
	switch(Widgetname) {
		case ('selectMaestroButton'):
			selectMaestroButton = GFxClikWidget(Widget);
			selectMaestroButton.AddEventListener('CLIK_click', LockMyCommander);
			selectMaestroButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			selectMaestroButton.AddEventListener('CLIK_click', PlayButtonSelect);
			selectMaestroButton.SetVisible(false);
			bWasHandled = true;
			break;
		case ('gregoryIcon'):
			gregoryIcon = GFxClikWidget(Widget);
			gregoryIcon.AddEventListener('CLIK_click', SelectGregory);
			gregoryIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			gregoryIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('rosieIcon'):
			rosieIcon = GFxClikWidget(Widget);
			rosieIcon.AddEventListener('CLIK_click', SelectRosie);
			rosieIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			rosieIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('robomeisterIcon'):
			robomeisterIcon = GFxClikWidget(Widget);
			robomeisterIcon.AddEventListener('CLIK_click', SelectRoboMeister);
			robomeisterIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			robomeisterIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('randomIcon'):
			randomIcon = GFxClikWidget(Widget);
			randomIcon.AddEventListener('CLIK_click', SelectRandom);
			randomIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			randomIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('salvatorIcon'):
			salvatorIcon = GFxClikWidget(Widget);
			salvatorIcon.AddEventListener('CLIK_click', SelectSalvator);
			salvatorIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			salvatorIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('rambamqueenIcon'):
			rambamqueenIcon = GFxClikWidget(Widget);
			rambamqueenIcon.AddEventListener('CLIK_click', SelectRamBamQueen);
			rambamqueenIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			rambamqueenIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('hivelordIcon'):
			hivelordIcon = GFxClikWidget(Widget);
			hivelordIcon.AddEventListener('CLIK_click', SelectHiveLord);
			hivelordIcon.AddEventListener('CLIK_rollOver', PlayMouseOver);
			hivelordIcon.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('chatLog'):
			chatLog = GFxClikWidget(Widget);
			bWasHandled = true;

			// Quick chat log init, for looks.
			chatLog.SetText(" ");
			break;
		case ('sendBtn'):
			sendBtn = GFxClikWidget(Widget);
			sendBtn.AddEventListener('CLIK_click', SendChat);
			sendBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('backButton'):
			backButton = GFxClikWidget(Widget);
			backButton.AddEventListener('CLIK_click', GoBack);
			backButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			backButton.AddEventListener('CLIK_click', PlayCancel);
			backButton.SetVisible(false);
			bWasHandled = true;
			break;
	}

	return bWasHandled;
}

function SetError(string error) {
	GetVariableObject("root").GetObject("errorText").SetVisible(true);
	menuAudio.PlayError();
}

function LockMyCommander(EventData data) {
	if( myPC.IsCommanderAvailable( myPC.commander ) )
	{
		isLockedIn = true;
		myPC.PostLockCommander();
	}
}

function SetSelectMaestroButtonEnabled(bool enabled) {
	selectMaestroButton.SetBool("enabled", enabled);
}

// Hides the lock commander button if the commander isn't available
function CheckLockCommanderVisibility( string inCommanderName )
{
	if( myPC.IsCommanderAvailable( inCommanderName ) )
	{
		selectMaestroButton.SetVisible( true );
	}
	else
	{
		selectMaestroButton.SetVisible( false );
	}
}

// Dru TODO: Really guys? Really?
// Taylor: I tried to somehow combine these functions but I had trouble. I decided to quit and try again after alpha
function SelectGregory(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "TinkerMeister" );
	myPC.PostChooseCommander("TinkerMeister");
}

function SelectRosie(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "Rosie" );
	myPC.PostChooseCommander("Rosie");
}

function SelectRoboMeister(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "RoboMeister" );
	myPC.PostChooseCommander("RoboMeister");
}

function SelectRandom(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "Random" );
	myPC.PostChooseCommander("Random");
}

function SelectSalvator(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "Salvator" );
	myPC.PostChooseCommander("Salvator");
}

function SelectRamBamQueen(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "RamBamQueen" );
	myPC.PostChooseCommander("RamBamQueen");
}

function SelectHiveLord(EventData data) {
	if( isLockedIn )
	{
		return;
	}
	CheckLockCommanderVisibility( "HiveLord" );
	myPC.PostChooseCommander("HiveLord");
}

// Up Next @ 5pm:
// Is this the most inefficient function Andre's ever written?!
// Tune in to find out.
function bool UpdateGameInfo(JSONObject commandObject) {
	local int i, j;

	if(super.UpdateGameInfo(commandObject)) {
		myPC.ClearTimer('SetTimer');
		return true;
	}

	if(firstTime) {
		firstTime = false;
		myPC.SetTimer(1.0, true, 'SetTimerText');
		InitializeCommanderSelect(commandObject);
		return false;
	}

	for(i = 0; i < commandObject.GetObject("players").ObjectArray.Length; i++) {
		// Update Locks
		// This is really, really, really bad. Use a map or some shit, idiot. wtf
		if(commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelectState") == "Locked") {
			if(!lockedInCommanders[i]) {
				for(j = 1; j <= 6; j++) { // wtf r u doin'
					if(GetVariableObject("root").GetObject("p"$j$"Name").GetObject("textField").GetText() == commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName")) {
						lockCommander(j);
						lockedInCommanders[i] = true;
						break;
					}
				}
			}
		}

		// If they're selected, update commander.
		if(commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelectState") != "Unselected") {
			// Update Center Commander
			if(commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName") == myPC.username) {
				if(currentCommander != commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelected")) {
					currentCommander = commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelected");
					myPC.SpawnMainPawn(currentCommander);
					myPC.commander = currentCommander;
				}
			}

			// Update Left/Right Commander
			if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == (myPC.ally + 1)) {
				if(leftAllyName == commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName")) {
					if(currentLeftCommander != commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelected")) {
						currentLeftCommander = commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelected");
						myPC.SpawnLeftPawn(currentLeftCommander);
					}
				} else if(rightAllyName == commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName")) {
					if(currentRightCommander != commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelected")) {
						currentRightCommander = commandObject.GetObject("players").ObjectArray[i].GetStringValue("commanderSelected");
						myPC.SpawnRightPawn(currentRightCommander);
					}
				}
			}
		}

		//set timer in select
		timeLeft = commandObject.GetIntValue("commanderSelectTimeRemaining");
		timeLeft = timeLeft / 1000;
		timeLeft = timeLeft -1;
	}

	return false;
}

function SetTimerText() {
	GetVariableObject("root").GetObject("timerText").SetText(timeLeft);
	if (timeLeft > 0) {
		timeLeft = timeLeft -1;
	}
}

function InitializeCommanderSelect(JSONObject commandObject) {
	local int i;
	local int team1Counter;
	local int team2Counter;

	team1Counter = 1;
	team2Counter = 4;

	// Ensure players are on correct team.
	for(i = 0; i < commandObject.GetObject("players").ObjectArray.Length; i++) {
		if(commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName") == myPC.username) {
			if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 1) {
				myPC.ally = 0;
			} else if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 2) {
				myPC.ally = 1;
			} else if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 3) {
				myPC.ally = 2;
				LoadMenu(class'SFMFrontEndLoading');
			}
			break;
		}
	}

	// Set visibles.
	for(i = 0; i < commandObject.GetObject("players").ObjectArray.Length; i++) {
		if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 1) {
			GetVariableObject("root").GetObject("p"$team1Counter$"Name").GetObject("textField").SetText(commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName"));
			GetVariableObject("root").GetObject("p"$team1Counter$"Name").SetVisible(true);
			GetVariableObject("root").GetObject("p"$team1Counter$"Locked").SetVisible(true);
			team1Counter++;
		} else if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == 2) {
			GetVariableObject("root").GetObject("p"$team2Counter$"Name").GetObject("textField").SetText(commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName"));
			GetVariableObject("root").GetObject("p"$team2Counter$"Name").SetVisible(true);
			GetVariableObject("root").GetObject("p"$team2Counter$"Locked").SetVisible(true);
			team2Counter++;
		}

		if(commandObject.GetObject("players").ObjectArray[i].GetIntValue("teamNumber") == (myPC.ally + 1) && commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName") != myPC.username) {
			if(leftAllyName == "") {
				leftAllyName = commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName");
				GetVariableObject("root").GetObject("leftAllyName").SetVisible(true);
				GetVariableObject("root").GetObject("leftAllyName").GetObject("textField").SetText(leftAllyName);
			} else if(rightAllyName == "") {
				rightAllyName = commandObject.GetObject("players").ObjectArray[i].GetStringValue("playerName");
				GetVariableObject("root").GetObject("rightAllyName").SetVisible(true);
				GetVariableObject("root").GetObject("rightAllyName").GetObject("textField").SetText(rightAllyName);
			}
		}
	}

	// Add the lock to every unavailable commander
	InitCommanderLocks();
}

// Locks all commanders that aren't available
function InitCommanderLocks()
{
	LockCommanderIfUnavailable( "TinkerMeister",    "unavailableLock0" );
	LockCommanderIfUnavailable( "Rosie",            "unavailableLock1" );
	LockCommanderIfUnavailable( "RoboMeister",      "unavailableLock2" );
	LockCommanderIfUnavailable( "Salvator",         "unavailableLock3" );
	LockCommanderIfUnavailable( "RamBamQueen",      "unavailableLock4" );
	LockCommanderIfUnavailable( "HiveLord",         "unavailableLock5" );
}

function LockCommanderIfUnavailable( string inCommanderName, string inAssetMemberName )
{
	if( !myPC.IsCommanderAvailable(inCommanderName) )
	{
		// Enable the lock for this commander
		GetVariableObject("root").GetObject( inAssetMemberName ).SetVisible( true );
	}
}

function lockCommander(int player)
{
	local ASValue Param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_Number;
	Param0.n = player;

	args.Length = 1;
    args[0] = Param0;

	FunctionPath = "_root";
	InvokeFunction = "lockCommander";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function SetCommanderToolTipText()
{
	local int i;
	for(i = 0; i < myPC.commanderSelectTooltipCache.Length; ++i)
	{
		setCommanderToolTip(myPC.commanderSelectTooltipCache[i].name, myPC.commanderSelectTooltipCache[i].description);
	}
}

function setCommanderToolTip(string title, string description)
{
	local ASValue Param0;
	local ASValue Param1;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

	Param0.Type = AS_String;
	Param0.s = title;
	Param1.Type = AS_String;
	Param1.s = description;

	args.Length = 2;
    args[0] = Param0;
    args[1] = Param1;

	FunctionPath = "_root";
	InvokeFunction = "setCommanderToolTip";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function SendChat(EventData data) {
	SendChatMessage();
}

function SendChatMessage() {
	local GFxObject chatInput;

	chatInput = GetVariableObject("root").GetObject("chatInput");

	if(chatInput.GetText() != "") {
		myPC.SendChatMessage(chatInput.GetText());
		chatInput.SetText("");
		menuAudio.PlayChatSend();
	}
}

function ReceiveChatMessage(string message) {
	chatLog.SetText(chatLog.GetText() $ message $ "\n ");
	chatLog.GetObject("textField").SetInt("scrollV", chatLog.GetObject("textField").GetInt("maxScrollV"));
}

function GoBack(EventData data)
{
	myPC.LeaveLobby(myPC.DISCONNECT_REASON_QUIT);
}

DefaultProperties
{
	MovieInfo=SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_CommanderSelect'
	
	WidgetBindings.Add((WidgetName="selectMaestroButton",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="gregoryIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="rosieIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="robomeisterIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="randomIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="salvatorIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="rambamqueenIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="hivelordIcon",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="chatLog",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="sendBtn",WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((WidgetName="backButton",WidgetClass=class'GFxCLIKWidget'))
}