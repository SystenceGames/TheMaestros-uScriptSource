class SFMAudioPlayer extends Actor;

var SoundCue mouseOver, buttonSelect, cancel, chatSend, enterLobby, gameStart, hostSuccess, teamSwap, logOutSuccess, logInSuccess, error;

event PostBeginPlay()
{
     
}

function PlayMouseOver()
{
   PlaySound( mouseOver );
}

function PlayButtonSelect() {
	PlaySound( buttonSelect );
}

function PlayCancel() {
	PlaySound( cancel );
}

function PlayChatSend() {
	PlaySound( chatSend );
}

function PlayEnterLobby() {
	PlaySound( enterLobby );
}

function PlayGameStart() {
	PlaySound( gameStart );
}

function PlayHostSuccess() {
	PlaySound( hostSuccess );
}

function PlayTeamSwap() {
	PlaySound( teamSwap );
}

function PlayLogInSuccess() {
	PlaySound( logInSuccess );
}

function PlayLogOutSuccess() {
	PlaySound( logOutSuccess );
}

function PlayError() {
	PlaySound( error );
}

defaultproperties
{
	mouseOver = SoundCue'Audio_MainMenu.MouseOver_Cue'
	buttonSelect = SoundCue'Audio_MainMenu.ButtonSelect_Cue'
	cancel = SoundCue'Audio_MainMenu.Cancel_Cue'
	chatSend = SoundCue'Audio_MainMenu.ChatSend_Cue'
	enterLobby = SoundCue'Audio_MainMenu.EnterLobby_Cue'
	gameStart = SoundCue'Audio_MainMenu.GameStart_Cue'
	hostSuccess = SoundCue'Audio_MainMenu.HostSuccess_Cue'
	teamSwap = SoundCue'Audio_MainMenu.TeamSwap_Cue'
	logInSuccess = SoundCue'Audio_MainMenu.LogInSuccess_Cue'
	logOutSuccess = SoundCue'Audio_MainMenu.LogOutSuccess_Cue'
	error = SoundCue'Audio_MainMenu.Error_Cue'
}