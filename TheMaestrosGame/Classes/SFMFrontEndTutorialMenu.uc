class SFMFrontEndTutorialMenu extends SFMFrontEnd;

var GFxClikWidget basicBtn, advancedBtn, quitBtn, practiceBtn, yesBtn, noBtn, alchemistBtn;

function bool Start(optional bool startPaused = false) 
{
	local bool retVal;
	myPC.Log( "SFMFrontEndTutorialMenu::Start() starting!" );

	retVal = super.Start(startPaused);
	//SetMotD(myPC.MotD);
	CurrentMenu = "TutorialMenu";

	//handle tutorial progress
	myPC.LoadSaveData(); 	// fix print ugliness
	myPC.mSaveData.ClearInProgressTutorials(); 	// at start of menu, so no tutorials are in progress

	callPractice();

	if( myPC.ShouldOpenPracticeBattleMenu() ) {
		myPC.Log( "SFMFrontEndTutorialMenu::Start() showing battle practice menu" );
		myPC.mSaveData.ClearJustCompletedTutorial();
		showPractice();
	}

	if( !myPC.IsBasicCompleted() ) {
		GetVariableObject("root").GetObject("advancedBlock").SetVisible(true);
		desaturate("advanced");
	}

	if( !myPC.IsAdvancedCompleted() ) {
		GetVariableObject("root").GetObject("practiceBlock").SetVisible(true);
		desaturate("practice");
	}

	// If we don't have RBQ, hide the alchemist button and ask the server for our current player inventory
	if (!myPC.IsCommanderInInventory("RamBamQueen")) {
		alchemistBtn.SetVisible(false);
		myPC.PostGetPlayerInventory();
	}

	return retVal;
}

/* UpdateAlchemistTutorialButton()
	Desaturates or enables the alchemist tutorial button, depending on if the player has RBQ
*/
function UpdateAlchemistTutorialButton()
{
	myPC.mPlayerInventory.PrintInventory();
	alchemistBtn.SetVisible(true); 	// set the button visible (if we don't have RBQ, the next lines will block the button)

	if (!myPC.IsCommanderInInventory("RamBamQueen")) {
		alchemistBtn.SetVisible(true);
		GetVariableObject("root").GetObject("alchemistBlock").SetVisible(true);
		desaturate("alchemist");
	}
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;
	bWashandled = false;
	switch(Widgetname) {
		case ('basicBtn'):
			basicBtn = GFxClikWidget(Widget);
			basicBtn.AddEventListener('CLIK_click', GoToBasic);
			basicBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			basicBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('advancedBtn'):
			advancedBtn = GFxClikWidget(Widget);
			advancedBtn.AddEventListener('CLIK_click', GoToAdvanced);
			advancedBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			advancedBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('quitBtn'):
			quitBtn = GFxClikWidget(Widget);
			quitBtn.AddEventListener('CLIK_click', GoToMenu);
			quitBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			quitBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('practiceBtn'):
			practiceBtn = GFxCLIKWidget(Widget);
			practiceBtn.AddEventListener('CLIK_click', GoToPractice);
			practiceBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			practiceBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('yesBtn'):
			yesBtn = GFxClikWidget(Widget);
			yesBtn.AddEventListener('CLIK_click', GoToPractice);
			yesBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			yesBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ('noBtn'):
			noBtn = GFxClikWidget(Widget);
			noBtn.AddEventListener('CLIK_click', hidePractice);
			noBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			noBtn.AddEventListener('CLIK_click', PlayCancel);
			bWasHandled = true;
			break;
		case ('alchemistBtn'):
			alchemistBtn = GFxClikWidget(Widget);
			alchemistBtn.AddEventListener('CLIK_click', GoToAlchemist);
			alchemistBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			alchemistBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
	}
	return bWasHandled;
}

function GoToBasic(EventData data) {
	myPC.DisconnectChat();
	myPC.StartBasic();
	GoToTutorial(1);
}

function GoToAdvanced(EventData data) {
	local bool basicTest;
	basicTest = myPC.IsBasicCompleted();
	if (basicTest == true) {
		myPC.DisconnectChat();
		myPC.StartAdvanced();
		GoToTutorial(2);
	}
}

function GoToAlchemist(EventData data) {

	if (myPC.IsCommanderInInventory("RamBamQueen")) {
		myPC.StartAlchemist();
		myPC.DisconnectChat();
		LoadMenu(class'SFMFrontEndLoading');
		myPC.ClientTravel("TM_tutorial3?game=TheMaestrosGame.TMGameInfo?Ally=1?PlayerName=" $ myPC.username $ "?SessionToken=" $ myPC.mSessionToken, myPC.ETravelType.TRAVEL_Absolute, false,);
	}
}

function GoToTutorial(int num) {
	LoadMenu(class'SFMFrontEndLoading');
	myPC.ClientTravel("TM_tutorial" $ num $ "_Kismet?game=TheMaestrosGame.TMGameInfo?PlayerName=" $ myPC.username $ "?SessionToken=" $ myPC.mSessionToken, myPC.ETravelType.TRAVEL_Absolute, false,);
}

function GoToMenu(EventData data) {
	LoadMenu(class'SFMFrontEndMainMenu');
}

function GoToPractice(EventData data) {
	local bool advancedTest;
	local Array<string> myUsernameAsList;

	advancedTest = myPC.IsAdvancedCompleted();
	if (advancedTest == true) {
		myPC.DisconnectChat();
		myUsernameAsList.AddItem(myPC.username);
		myPC.PostGetPlayerStats(myUsernameAsList);
	}
}

function handleStatsLoaded(Array<TMPlayerProgressionData> inPlayerStatsList) 
{
	myPC.SavePreMatchPlayerStats(inPlayerStatsList);
	GoToPracticeBattle();
}

function GoToPracticeBattle()
{
	myPC.gameTypeToLoad = "TheMaestrosGame.TMDMGameInfo";
	myPC.mapToLoad = "SacredArena";
	myPC.StartBattle();
	LoadMenu(class'SFMFrontEndLoading');
	myPC.ClientTravel(myPC.mapToLoad$"?game="$myPC.gameTypeToLoad$"?PlayerName=" $ myPC.username $ "?SessionToken=" $ myPC.mSessionToken $ "?Commander=RoboMeister?Ally=0?NumAIPlayers=3?IsPracticeBattle=1?bot0Difficulty=2?bot0PlayerName=AllyBlastMeisterBot?bot0Ally=0?bot0CommanderName=Rosie?bot1Difficulty=1?bot1PlayerName=EnemyRoboMeisterBot?bot1Ally=1?bot1CommanderName=RoboMeister?bot2Difficulty=1?bot2PlayerName=EnemyTinkerMeisterBot?bot2Ally=1?bot2CommanderName=TinkerMeister", myPC.ETravelType.TRAVEL_Absolute, false,);
}

function desaturate(string block) {
	local ASValue param0;
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

    Param0.Type = AS_Number;
    if (block == "advanced") {
    	Param0.n = 0;
    } else if (block == "practice") {
    	Param0.n = 1;
    } else if (block == "alchemist") {
    	Param0.n = 2;
    } else {
    	return;
    }

    `log("desturate gets this far");

    args.Length = 1;
    args[0] = Param0;

    FunctionPath = "_root";
	InvokeFunction = "desaturate";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function showPractice() {	
	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;
    args.Length = 0;
    FunctionPath = "_root";
	InvokeFunction = "showPractice";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function hidePractice(EventData data) {
	callPractice();
}

function callPractice() {

	local array<ASValue> args;
    local string FunctionPath, InvokeFunction;

    args.Length = 0;
    FunctionPath = "_root";
	InvokeFunction = "hidePractice";
	if(GetVariableObject(FunctionPath) != none)
	{
		GetVariableObject(FunctionPath).Invoke(InvokeFunction, args);
	}
}

function SetMotD(string motd) {
	GetVariableObject("root").GetObject("motdText").SetText(motd);
}

function OnPlayerInventoryUpdated() {
	// When we get a new player inventory, update the alchemist tutorial button
	// 	NOTE: this fixes the race condition where a player loads the tutorial menu before getting a player inventory.
	// 		It'd probably be better to fix this race condition another way, but we have a systematic UI race condition
	// 		problem which should be solved. This is a little bandaid fix in the meantime.
	UpdateAlchemistTutorialButton();
}

function SetError(string error) {
	local string preText;
	if(error != "") {
		preText = "ERROR: ";
		menuAudio.PlayError();
	}
	GetVariableObject("root").GetObject("errorText").SetText(preText $ error);
}

DefaultProperties
{
	MovieInfo = SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_TutorialMenu'
	WidgetBindings.Add((Widgetname="basicBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="advancedBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="quitBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="practiceBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="yesBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="noBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="alchemistBtn", WidgetClass=class'GFxCLIKWidget'))
}