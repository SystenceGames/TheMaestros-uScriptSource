class SFMFrontEndSettingsMenu extends SFMFrontEnd;

var GFxClikWidget backBtn, resolutionDDM, screenModeDDM, graphicsQualityDDM, volumeDDM;

var TMSettingsMenuHelper settingsMenuHelper;


function bool Start(optional bool startPaused = false) {
	local bool retVal;
	retVal = super.Start(startPaused);
	SetMotD(myPC.MotD);
	CurrentMenu = "Settings";

	settingsMenuHelper = new class 'TMSettingsMenuHelper'();
	settingsMenuHelper.LoadSettings(myPC, self);

	InitSettings();

	return retVal;
}

event bool WidgetInitialized(name WidgetName, name WidgetPath, GFxObject Widget) {
	local bool bWasHandled;
	bWashandled = false;
	switch(Widgetname) {
		case ('backBtn'):
			backBtn = GFxClikWidget(Widget);
			backBtn.AddEventListener('CLIK_click', GoToLastMenu);
			backBtn.AddEventListener('CLIK_rollOver', PlayMouseOver);
			backBtn.AddEventListener('CLIK_click', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ( 'resolutionDDM' ):
			resolutionDDM = GFxClikWidget( Widget );
			resolutionDDM.AddEventListener( 'CLIK_listIndexChange', ResolutionChanged );
			resolutionDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ( 'screenModeDDM' ):
			screenModeDDM = GFxClikWidget( Widget );
			screenModeDDM.AddEventListener( 'CLIK_listIndexChange', ScreenModeChanged );
			screenModeDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ( 'graphicsQualityDDM' ):
			graphicsQualityDDM = GFxClikWidget( Widget );
			graphicsQualityDDM.AddEventListener( 'CLIK_listIndexChange', GraphicsQualityChanged );
			graphicsQualityDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
		case ( 'volumeDDM' ):
			volumeDDM = GFxClikWidget( Widget );
			volumeDDM.AddEventListener( 'CLIK_listIndexChange', VolumeChanged );
			volumeDDM.AddEventListener('CLIK_listIndexChange', PlayButtonSelect);
			bWasHandled = true;
			break;
	}
	return bWasHandled;
}

function InitSettings()
{
	local int ddmIndex;
	local int levelOfDetail;

	// Set up the resolution option list
	settingsMenuHelper.PopulateResolutionOptionsList();

	// Get the DDM index of the current resolution option
	ddmIndex = settingsMenuHelper.GetResolutionOptionListIndex( settingsMenuHelper.GetCurrentResolutionOption() );

	// NOTE: the DDM index can be -1, but that's alright!
	// By setting the DDM's selectedIndex to -1 we hide this bad resolution, which is fine

	// Set the initial DDM
	resolutionDDM.SetInt( "selectedIndex", ddmIndex );


	// Get DDM index of screen mode
	if( settingsMenuHelper.IsFullscreen() )
	{
		ddmIndex = 1;
	}
	else
	{
		ddmIndex = 0;
	}

	screenModeDDM.SetInt( "selectedIndex", ddmIndex );

	
	// Set the initial graphics quality setting
	levelOfDetail = settingsMenuHelper.GetLevelOfDetail();

	if( levelOfDetail == 0 )
	{
		// Set it to low quality
		graphicsQualityDDM.SetInt( "selectedIndex", 0 );
	}
	else
	{
		// Set it to high quality
		graphicsQualityDDM.SetInt( "selectedIndex", 1 );
	}

	// Set volume to 100%
	volumeDDM.SetInt( "selectedIndex", settingsMenuHelper.GetCurrentVolumeIndex() );
}

///// Required SFMFrontEnd functions /////
function GoToLastMenu(EventData data) {
	LoadMenu(myPC.GetLastMenu());
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
///// End required functions /////


// Called when the user selects a resolution from the DDM
function ResolutionChanged( EventData data )
{
	local int resOptionIndex;
	resOptionIndex = resolutionDDM.GetInt( "selectedIndex" );

	if( resOptionIndex < 0 || resOptionIndex >= settingsMenuHelper.mResolutionOptionsList.Length )
	{
		`log( "ERROR: SFMFrontEndSettingsMenu::ResolutionChanged() got a bad DDM index!" );
		return;
	}

	// Set the resolution to this res option
	settingsMenuHelper.SetResolution( settingsMenuHelper.mResolutionOptionsList[ resOptionIndex ]._resolutionString );
}

// Called when the user selects a screen mode from the DDM
function ScreenModeChanged( EventData data )
{
	local int index;
	index = screenModeDDM.GetInt( "selectedIndex" );

	if( index < 0 || index >= 2 )
	{
		`log( "ERROR: SFMFrontEndSettingsMenu::ScreenModeChanged() got a bad DDM index!" );
		return;
	}

	// Set the screen mode (0 = windowed, 1 = fullscreen)
	settingsMenuHelper.SetIsFullscreen( index == 1 );
}

// Called when the user selects a volume setting from the DDM
function VolumeChanged( EventData data )
{
	local int index;
	local float volume;

	index = volumeDDM.GetInt( "selectedIndex" );

	if( index < 0 || index > 10 )
	{
		`log( "ERROR: SFMFrontEndSettingsMenu::VolumeChanged() got a bad DDM index!" );
		return;
	}

	if( index == 0 )
	{
		volume = 0;
	}
	else
	{
		volume = 11 - index;
		volume /= 10.0f;
	}

	settingsMenuHelper.SetMasterVolume( volume );
}

// Called when the user selects a graphical quality from the DDM
function GraphicsQualityChanged( EventData data )
{
	local int index;
	local bool isFullscreenMode;
	local string resString;
	index = graphicsQualityDDM.GetInt( "selectedIndex" );

	if( index < 0 || index >= 2 )
	{
		`log( "ERROR: SFMFrontEndSettingsMenu::GraphicsQualityChanged() got a bad DDM index!" );
		return;
	}

	// Save the current screen mode and resolution, since "Scale ..." may change it
	resString = settingsMenuHelper.GetScreenResolution();
	isFullscreenMode = settingsMenuHelper.IsFullscreen();

	if( index == 0 )
	{
		myPC.ConsoleCommand( "Scale LowEnd" );
	}
	else
	{
		myPC.ConsoleCommand( "Scale HighEnd" );
	}

	// Set the values that may have changed
	settingsMenuHelper.SetResolution( resString );
	settingsMenuHelper.SetIsFullscreen( isFullscreenMode );
}


///// DDM Loading Functions /////
function array<GFxObject> GetResolutionDDMData()
{
	local int i;
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;

	if (settingsMenuHelper == None)
	{
		return dataProvider;
	}

	for( i = 0; i < settingsMenuHelper.mResolutionOptionsList.Length; i++ )
	{
		tempObj = CreateObject("Object");
		tempObj.SetString("label", settingsMenuHelper.mResolutionOptionsList[ i ]._resolutionString);
		tempObj.SetInt("index", i);
		dataProvider.AddItem(tempObj);
	}

	return dataProvider;
}

function array<GFxObject> GetScreenModeDDMData()
{
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "Windowed");
	tempObj.SetInt("index", 0);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "Fullscreen");
	tempObj.SetInt("index", 1);
	dataProvider.AddItem(tempObj);

	return dataProvider;
}

function array<GFxObject> GetGraphicsQualityDDMData()
{
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "Low");
	tempObj.SetInt("index", 0);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "High");
	tempObj.SetInt("index", 1);
	dataProvider.AddItem(tempObj);

	return dataProvider;
}

function array<GFxObject> GetVolumeDDMData()
{
	local GFxObject tempObj;
	local array<GFxObject> dataProvider;

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "OFF");
	tempObj.SetInt("index", 0);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "100%");
	tempObj.SetInt("index", 1);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "90%");
	tempObj.SetInt("index", 2);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "80%");
	tempObj.SetInt("index", 3);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "70%");
	tempObj.SetInt("index", 4);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "60%");
	tempObj.SetInt("index", 5);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "50%");
	tempObj.SetInt("index", 6);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "40%");
	tempObj.SetInt("index", 7);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "30%");
	tempObj.SetInt("index", 8);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "20%");
	tempObj.SetInt("index", 9);
	dataProvider.AddItem(tempObj);

	tempObj = CreateObject("Object");
	tempObj.SetString("label", "10%");
	tempObj.SetInt("index", 10);
	dataProvider.AddItem(tempObj);

	return dataProvider;
}
///// End DDM Loading Functions

DefaultProperties
{
	MovieInfo = SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_Settings'
	WidgetBindings.Add((Widgetname="backBtn", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="resolutionDDM", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="screenModeDDM", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="graphicsQualityDDM", WidgetClass=class'GFxCLIKWidget'))
	WidgetBindings.Add((Widgetname="volumeDDM", WidgetClass=class'GFxCLIKWidget'))
}