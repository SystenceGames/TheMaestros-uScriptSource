class SFMFrontEndLogin extends SFMFrontEnd;

var GFxClikWidget loginBtn, quitBtn, confirmAccountBtn, resendButton, settingsBtn, newAccountBtn, cancelBtn, resetBtn;
var GFxObject usernameInput, passwordInput, createUNinput, createPWinput, confirmPWinput, emailInput, monthInput, dayInput, yearInput;
var string storedEmail;

var TMCachedAccountData cachedAccountData;
var bool isLoginAllowed;


function bool Start(optional bool startPaused = false) {
	local bool retVal;
	myPC.Log( "SFMFrontEndLogin::Start() starting!" );
	retVal = super.Start(startPaused);
	if(myPC.startupMenu == "GameOver_Victory") {
		LoadMenu(class'SFMFrontEndGameOver');
	} else if(myPC.startupMenu == "GameOver_Defeat") {
		LoadMenu(class'SFMFrontEndGameOver');
	} else if(myPC.startupMenu == "MainMenu" && Len(myPC.mSessionToken) != 0) {
		LoadMenu(class'SFMFrontEndMainMenu');
	} else if(myPC.startupMenu == "TutorialMenu" && Len(myPC.mSessionToken) != 0) {
		LoadMenu(class'SFMFrontEndTutorialMenu');
	}
	SetMotD(myPC.MotD);
	CurrentMenu = "Login";
	
	usernameInput = GetVariableObject("root").GetObject("usernameInput");
	passwordInput = GetVariableObject("root").GetObject("passwordInput");
	createUNinput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("createUNinput");
	createPWinput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("createPWinput");
	confirmPWinput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("confirmPWinput");
	emailInput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("emailInput");
	monthInput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("monthInput");
	dayInput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("dayInput");
	yearInput = GetVariableObject("root").GetObject("accountCreationMenu").GetObject("yearInput");
	
	cachedAccountData = class'TMCachedAccountData'.static.LoadFile();
	usernameInput.SetText(cachedAccountData.accountName);

	return retVal;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;
	bWashandled = false;
	switch(Widgetname) {
		case ('loginBtn'):
			loginBtn = GFxClikWidget(Widget);
			loginBtn.AddEventListener('CLIK_click', AttemptLogin);
			loginBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			loginBtn.AddEventListener('CLIK_doubleClick', AttemptLogin);
			loginBtn.AddEventListener('CLIK_doubleClick', PlayButtonSelect);
			loginBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('quitBtn'):
			quitBtn = GFxClikWidget(Widget);
			quitBtn.AddEventListener('CLIK_click', Quit);
			quitBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			quitBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('confirmAccountBtn'):
			confirmAccountBtn = GFxClikWidget(Widget);
			confirmAccountBtn.AddEventListener('CLIK_click', AttemptAccountCreation);
			confirmAccountBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			confirmAccountBtn.AddEventListener('CLIK_doubleClick', AttemptAccountCreation);
			confirmAccountBtn.AddEventListener('CLIK_doubleClick', PlayButtonSelect);
			confirmAccountBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('resendButton'):
			resendButton = GFxClikWidget(Widget);
			resendButton.AddEventListener('CLIK_click', ResendEmail);
			resendButton.AddEventListener('CLIK_click', PlayButtonSelect);
			resendButton.AddEventListener('CLIK_doubleClick', ResendEmail);
			resendButton.AddEventListener('CLIK_doubleClick', PlayButtonSelect);
			resendButton.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('settingsBtn'):
			settingsBtn = GFxClikWidget(Widget);
			settingsBtn.AddEventListener('CLIK_click', GoToSettings);
			settingsBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			settingsBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('newAccountBtn'):
			newAccountBtn = GFxClikWidget(Widget);
			newAccountBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			newAccountBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			bWasHandled = true;
			break;
		case ('cancelBtn'):
			cancelBtn = GFxClikWidget(Widget);
			cancelBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			cancelBtn.AddEventListener('CLIK_click', PlayCancel);
			bWasHandled = true;
			break;
		case ('resetBtn'):
			resetBtn = GFxClikWidget(Widget);
			resetBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			resetBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			resetBtn.AddEventListener('CLIK_click', SendReset);
			resetBtn.AddEventListener('CLIK_doubleClick', PlayButtonSelect);
			resetBtn.AddEventListener('CLIK_doubleClick', SendReset);
			//resetBtn.SetVisible(false);
			bWasHandled = true;
			break;
	}
	return bWasHandled;
}

function SetFeatureToggles(FeatureToggles inFeatureToggles) 
{
	isLoginAllowed = inFeatureToggles.isOnline;

	if (false == inFeatureToggles.isOnline)
	{
		GetVariableObject("root").GetObject("loginBtn").SetVisible(false);
		GetVariableObject("root").GetObject("newAccountBtn").SetVisible(false);
		GetVariableObject("root").GetObject("resetBtn").SetVisible(false);
		SetError("Our login server is offline.");
	} else
	{
		GetVariableObject("root").GetObject("loginBtn").SetVisible(true);
		GetVariableObject("root").GetObject("newAccountBtn").SetVisible(true);
		GetVariableObject("root").GetObject("resetBtn").SetVisible(true);
	}
}

function ResendEmail(EventData data) {
	storedEmail = Trim(usernameInput.GetText());
	if (storedEmail == "" || storedEmail == " ") {
		SetError("Type in an Email to Reset Password");
	} else {
		myPC.PostResend(storedEmail);
		DisableResendBtn();
	}
}

function AttemptLogin(EventData data) {
	if(isLoginAllowed == false) {
		return;
	}

	SetError("");
	if(usernameInput.GetText() != "" && passwordInput.GetText() != "") {
		ToggleLoadingAnimation(true);
		myPC.isNewPlayer = false;
		myPC.PostLogin(Trim(usernameInput.GetText()), Trim(passwordInput.GetText()));
		cacheLoggedIn(usernameInput.GetText());
		DisableLoginBtn();
	} else {
		SetError("Invalid Email or Password.");
	}
}

function cacheLoggedIn(string email)
{
	cachedAccountData.accountName = email;
	cachedAccountData.SaveFile();
}

function SendReset(EventData data) {
	`log("Reset function called");
	storedEmail = usernameInput.GetText();
	if (storedEmail == "" || storedEmail == " ") {
		SetError("Invalid Email for Verification Resend");
	} else {
		myPC.PostReset(storedEmail);
		DisableResetBtn();
	}
}

function GoToSettings(EventData data) {
	LoadMenu(class'SFMFrontEndSettingsMenu');
}

function ToggleLoadingAnimation(bool visible) {
	GetVariableObject("root").GetObject("loadingAnim").SetBool("visible", visible);
}

function AttemptAccountCreation(EventData data) {
	local string month;
	local string day;
	local string year;
	local string birthday;

	month = monthInput.GetText();
	day = dayInput.GetText();
	year = yearInput.GetText();
	birthday =  month $ "/" $ day $ "/" $ year;

	`log("birthday is " $ birthday);

	SetError("");

	if(createUNinput.GetText() == "") {
		SetError("Must enter a username.");
		return;
	}
	if(createPWinput.GetText() == "") {
		SetError("Must enter a password.");
		return;
	}
	if(confirmPWinput.GetText() == "") {
		SetError("Must confirm password.");
		return;
	}
	if(createPWinput.GetText() != confirmPWinput.GetText()) {
		SetError("Passwords do not match.");
		return;
	}

	//if(myPC.CreatePlayer(createUNinput.GetText(), createPWinput.GetText())) {
	//	LoadMenu(class'SFMFrontEndMainMenu');
	//}
	ToggleLoadingAnimation(true);
	myPC.isNewPlayer = true;
	myPC.PostCreatePlayer(createUNinput.GetText(), createPWinput.GetText(), emailInput.GetText(), birthday);
	DisableCreateAccountBtn();
}

function Quit(EventData data) {
	ConsoleCommand("exit");
}

function SetMotD(string motd) {
	GetVariableObject("root").GetObject("motdText").SetText(motd);
}

function SetReset() {
	GetVariableObject("root").GetObject("errorText").SetText("Reset Email Sending...");
}

function SetResetConfirmed() {
	GetVariableObject("root").GetObject("errorText").SetText("Reset Email Sent");
}

function ShowReset() {
	resetBtn.SetVisible(true);
}

function SetError(string error) {
	local string preText;

	if (error == "Name taken") {
		GetVariableObject("root").GetObject("accountCreationMenu").GetObject("nameText").SetBool("visible", true);
		error = "";
		menuAudio.PlayError();
	} else if (error == "You must verify your email address before logging in.") {
		GetVariableObject("root").GetObject("verifyPopup").SetBool("visible", true);
		error = "";
		menuAudio.PlayError();
	}
	 else if(error != "") {
	 	GetVariableObject("root").GetObject("accountCreationMenu").GetObject("nameText").SetBool("visible", false);
		preText = "ERROR: ";
		menuAudio.PlayError();
	}
	GetVariableObject("root").GetObject("errorText").SetText(preText $ error);
}

function DisableLoginBtn() {
	loginBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableLoginBtn', self);
}

function EnableLoginBtn() {
	loginBtn.SetVisible(true);
}

function DisableCreateAccountBtn() {
	confirmAccountBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableCreateAccountBtn', self);
}

function EnableCreateAccountBtn() {
	confirmAccountBtn.SetVisible(true);
}

function DisableResendBtn() {
	resendButton.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableResendBtn', self);
}

function EnableResendBtn() {
	resendButton.SetVisible(true);
}

function DisableResetBtn() {
	resetBtn.SetVisible(false);
	myPC.SetTimer(2, false, 'EnableResetBtn', self);
}

function EnableResetBtn() {
	resetBtn.SetVisible(true);
}

DefaultProperties
{
	MovieInfo = SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_Login'
	WidgetBindings.Add((Widgetname="loginBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="quitBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="confirmAccountBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="settingsBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="resendButton", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="newAccountBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="cancelBtn", WidgetClass=class'GFxCLIkWidget'))
	WidgetBindings.Add((Widgetname="resetBtn", WidgetClass=class'GFxCLIkWidget'))
}
