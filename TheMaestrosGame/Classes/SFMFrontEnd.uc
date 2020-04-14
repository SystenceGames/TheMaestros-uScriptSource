class SFMFrontEnd extends GFxMoviePlayer;

var GFxObject CursorMC;
var SFMFrontEnd NextMenu;
var Vector2D MouseCoords;
var TMMainMenuPlayerController myPC;
var string CurrentMenu;
var bool bIsSpecLoading;
var SFMAudioPlayer menuAudio;

struct FeatureToggles
{
	var bool isOnline;
	var bool multiplayerEnabled;
	var bool allowErrorLogs;
	var array<string> blacklistedCommanders;
	var array<string> availableMaps;
};

function bool Start(optional bool startPaused = false) {
	local bool retVal;
	retVal = super.Start(StartPaused);
	Advance(0);

	if(myPC == none) {
		myPC = TMMainMenuPlayerController(GetPC());
		myPC.SetMenu(self);
		bIsSpecLoading = false;
	} else {
		menuAudio = myPC.GetAudioManager();
	}

	SetViewScaleMode(SM_ExactFit);

	return retVal;
}

function LoadMenu(class<SFMFrontEnd> NextMenuClass, optional JSONObject commandObject = none) {
	local GFxObject rootObject;
	// Get new MotD every load menu.
	myPC.PostMOTD();

	myPC.SetLastMenu(Self.class);
	NextMenu = new NextMenuClass;
	rootObject = GetVariableObject("root");
	if ( rootObject != None )
	{
		NextMenu.SetMouseCoords(rootObject.GetObject("cursor"));
	}
	NextMenu.LocalPlayerOwnerIndex = LocalPlayerOwnerIndex;
	NextMenu.SetPC(myPC);
	NextMenu.Start();
	if(commandObject != none) {
		NextMenu.UpdateGameInfo(commandObject);
	}

	CheckMap(NextMenuClass);

	Close(false);
}

//function CheckSound(class<SFMFrontEnd> NextMenuClass) {
//	switch(NextMenuClass) {
//		// Play main theme (only on first screen shown... ever.)
//		case class'SFMFrontEndLogin':
//		case class'SFMFrontEndGameOver':
//			if(!myPC.menuGameInfo.themeMusic.IsPlaying()) {
//				myPC.PlayTheme();
//				myPC.SetTimer(245, true, 'PlayTheme');
//			}
//			if(myPC.menuGameInfo.ambientMusic.IsPlaying()) {
//				myPC.StopAmbient();
//			}
//			break;
//		// Play ambient (auto-loops).
//		case class'SFMFrontEndMainMenu':
//		case class'SFMFrontEndOptionsMenu':
//		case class'SFMFrontEndLobby':
//		case class'SFMFrontEndTeamSelect':
//		case class'SFMFrontEndCommanderSelect':
//		case class'SFMFrontEndLoading':
//		default:
//			if(myPC.menuGameInfo.themeMusic.IsPlaying()) {
//				myPC.StopTheme();
//				myPC.SetTimer(0.f, false, 'PlayTheme');
//			}
//			if(!myPC.menuGameInfo.ambientMusic.IsPlaying()) {
//				myPC.PlayAmbient();
//			}
//			break;
//	}
//}

function CheckMap(class<SFMFrontEnd> NextMenuClass) {
	switch(NextMenuClass) {
		// Load Commander Select
		case class'SFMFrontEndCommanderSelect':
		case class'SFMFrontEndLoading':
			if(myPC.currentLevel != "CommanderSelect") {
				myPC.currentLevel = "CommanderSelect";
				myPC.LoadCommanderSelect();

				// Clear pawns.
				if(myPC.mainPawn != none) {
					myPC.mainPawn.Destroy();
				}
				if(myPC.leftPawn != none) {
					myPC.leftPawn.Destroy();
				}
				if(myPC.rightPawn != none) {
					myPC.rightPawn.Destroy();
				}
			}
			break;
		// Load Login Level
		case class'SFMFrontEndLogin':
		case class'SFMFrontEndMainMenu':
		case class'SFMFrontEndOptionsMenu':
		case class'SFMFrontEndTeamSelect':
		case class'SFMFrontEndGameOver':    // Move this back up to Commander Select?
		default:
			if(myPC.currentLevel != "Login") {
				myPC.currentLevel = "Login";
				myPC.LoadLogin();

				// Clear pawns.
				if(myPC.mainPawn != none) {
					myPC.mainPawn.Destroy();
				}
				if(myPC.leftPawn != none) {
					myPC.leftPawn.Destroy();
				}
				if(myPC.rightPawn != none) {
					myPC.rightPawn.Destroy();
				}
			}
			break;
	}
}

function SetMouseCoords(GFxObject LastCursorMC) {
	if(LastCursorMC != none) {
		MouseCoords.X = LastCursorMC.GetFloat("x");
		MouseCoords.Y = LastCursorMC.GetFloat("y");
	}
}

function SetPC(TMMainMenuPlayerController PC) {
	myPC = PC;
	myPC.SetMenu(self);
}

function bool UpdateGameInfo(JSONObject commandObject) {
	if(commandObject.GetStringValue("status") == "GameStarting") {
		if(CurrentMenu != "Loading" && !bIsSpecLoading) {
			menuAudio.PlayGameStart();
			LoadMenu(class'SFMFrontEndLoading');
			return true;
		}
	}
	else if(commandObject.GetStringValue("status") == "InGame") {
		if(CurrentMenu != "HandledGameStarted") {
			myPC.HandleGameStarted(commandObject);
			CurrentMenu = "HandledGameStarted";
			return true;
		}
	}
	else if(commandObject.GetStringValue("status") == "TeamSelect") {
		if(CurrentMenu != "TeamSelect") {
			LoadMenu(class'SFMFrontEndTeamSelect', commandObject);
			return true;
		}
	}
	else if(commandObject.GetStringValue("status") == "CommanderSelect") {
		if(CurrentMenu != "CommanderSelect" && !bIsSpecLoading) {
			menuAudio.PlayLogOutSuccess();
			LoadMenu(class'SFMFrontEndCommanderSelect', commandObject);
			return true;
		}
	}
	else if(commandObject.GetStringValue("status") == "GameCanceled") {
		myPC.LeaveLobby(myPC.DISCONNECT_REASON_HOST_CANCELED);
		return true;
	}
	return false;
}

function SetFeatureToggles(FeatureToggles inFeatureToggles) { }
function SetMotD(string motd) { }
function SetTimerText() { }
function SetError(string error) { }
function SetVerification();
function SetReset();
function SetResetConfirmed();
function ShowReset();
function ReceiveChatMessage(string message) { }
function ReceiveUsers(string message) { }
function OnPlayerInventoryUpdated() { }

// Called from ActionScript (SF_FrontEnd) when cursor is initialized.
function SetCursorPosition() {
	if(GetVariableObject("root").GetObject("cursor") != none) {
		GetVariableObject("root").GetObject("cursor").SetFloat("x", MouseCoords.X);
		GetVariableObject("root").GetObject("cursor").SetFloat("y", MouseCoords.Y);
	}
}

//AUDIO FUNCTIONS

function PlayMouseOver(EventData data) {
	menuAudio.PlayMouseOver();
}

function PlayButtonSelect(EventData data) {
	menuAudio.PlayButtonSelect();
}

function PlayCancel(EventData data) {
	menuAudio.PlayCancel();
}

function PlayChatSend(EventData data) {
	menuAudio.PlayChatSend();
}

function PlayEnterLobby(EventData data) {
	menuAudio.PlayEnterLobby();
}

function PlayGameStart(EventData data) {
	menuAudio.PlayGameStart();
}

function PlayHostSuccess(EventData data) {
	menuAudio.PlayHostSuccess();
}

function PlayTeamSwap(EventData data) {
	menuAudio.PlayTeamSwap();
}

function PlayLogInSuccess(EventData data) {
	menuAudio.PlayLogInSuccess();
}

function PlayLogOutSuccess(EventData data) {
	menuAudio.PlayLogOutSuccess();
}

function PlayError(EventData data) {
	menuAudio.PlayError();
}

DefaultProperties
{
	TimingMode = TM_Real
	bPauseGameWhileActive = false
	bCaptureInput = true
	bAllowInput = true
	bDisplayWithHudOff = true
}
