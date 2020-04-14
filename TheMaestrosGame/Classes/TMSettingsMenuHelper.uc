class TMSettingsMenuHelper extends Object;


struct ResolutionOption
{
	var int _resX;
	var int _resY;
	var string _resolutionString;   // in 1920x1080 format
};
var array< ResolutionOption > mResolutionOptionsList;
var TMSoundSettings mSoundSettings;


var PlayerController mPlayerController; 	// used to do console commands
var GFxMoviePlayer mMoviePlayer; 		// needed for viewport stuff

var float WAIT_BETWEEN_RESOLUTION_CHANGES; 	// need a minimum time between resolution switched to prevent a game lock
var float mLastResolutionChangeTimestamp;


function LoadSettings(PlayerController inPlayerController, GFxMoviePlayer inMoviePlayer)
{
	mPlayerController = inPlayerController;
	mMoviePlayer = inMoviePlayer;
	mSoundSettings = class'TMSoundSettings'.static.LoadSettings();
}

function ResolutionOption GetCurrentResolutionOption()
{
	return CreateResolutionOptionFromString( GetScreenResolution() );
}

function int GetNumResolutionOptions() {
	return mResolutionOptionsList.Length;
}

// Returns the index of this resolution option in the DDM. (NOTE: this is neccessary since array.Find() won't work for structs)
function int GetResolutionOptionListIndex( ResolutionOption inResolutionOption )
{
	local int i;

	for( i = 0; i < mResolutionOptionsList.Length; i++ )
	{
		if( mResolutionOptionsList[ i ]._resolutionString == inResolutionOption._resolutionString )
		{
			return i;
		}
	}

	return -1;
}

function string GetResolutionFromIndex(int index) {
	if (index >= 0 && index < mResolutionOptionsList.Length) {
		return mResolutionOptionsList[index]._resolutionString;
	} else {
		return "Invalid Resolution";
	}
}

// Fills our resolution option list using the resolutions supported by the PC's graphics card.
// Sometimes we allow the user to choose odd resolutions, but these are what their graphics card
// 	is telling us they can support.
function PopulateResolutionOptionsList()
{
	local array< string > resolutionStringList;
	local string resolutionString;
	local int i, j;
	local ResolutionOption resOption1, resOption2;
	local array< ResolutionOption > tempResOptionList;
	local bool addedResolution;

	mResolutionOptionsList.Remove( 0, mResolutionOptionsList.Length );
	resolutionStringList = GetAvailableResolutions();

	foreach resolutionStringList( resolutionString )
	{
		tempResOptionList.AddItem( CreateResolutionOptionFromString( resolutionString ) );
	}

	// Sort the list so the highest resolution is at the top
	for( i = 0; i < tempResOptionList.length; i++ )
	{
		resOption1 = tempResOptionList[i];
		addedResolution = false;

		// Compare the resolution against our currently sorted resolutions
		for( j = 0; j < mResolutionOptionsList.length; j++ )
		{
			resOption2 = mResolutionOptionsList[j];

			// Insert the new resolution if it's higher value
			if( (resOption1._resX > resOption2._resX) ||
				(resOption1._resX == resOption2._resX && resOption1._resY > resOption2._resY) )
			{
				mResolutionOptionsList.InsertItem(j, resOption1);
				addedResolution = true;
				break;
			}
		}

		// If this resolution isn't higher than our existing resolutions, append it to the end of the list
		if( addedResolution == false )
		{
			mResolutionOptionsList.AddItem(resOption1);
		}
	}
}

// Prints each resolution option in the list for debug purposes
function PrintResolutionOptionsList()
{
	local ResolutionOption resOption;

	`log( "SFMFrontEndSettingsMenu::PrintResolutionOptionsList() Printing available resolutions..." );

	foreach mResolutionOptionsList( resOption )
	{
		`log( "ResolutionString:"@resOption._resolutionString$".    ResX:"@resOption._resX@"    ResY:"@resOption._resY );
	}

	`log( "SFMFrontEndSettingsMenu::PrintResolutionOptionsList() DONE!" );
}

// This function REQUIRES the resolution to be in "RESXxRESY" format, such as "1920x1080" or "800x600"
function ResolutionOption CreateResolutionOptionFromString( string inResString )
{
	local ResolutionOption resOption;
	local int xIndex;
	local string tempString;

	resOption._resolutionString = inResString;

	// Give a warning if the resolution is smaller than RESxRES (800x600 is probably the smallest)
	if( Len( inResString ) < 7 )
	{
		`log( "WARNING: Got an unusually small resolution passed to SFMFrontEndSettingsMenu::CreateResolutionOptionFromString(). Function may not perform correctly." );
	}
	// Give a warning if the resolution is larger than RESXxRESY (4k resolution is 3840x2160. This function will support larger than that but give a warning anyway)
	if( Len( inResString ) > 9 )
	{
		`log( "WARNING: Got an unusually small resolution passed to SFMFrontEndSettingsMenu::CreateResolutionOptionFromString(). Function may not perform correctly." );
	}

	// Find the index of 'x' in the resolution string, which separates the x and y resolution
	xIndex = InStr( inResString, "x" );
	if( xIndex == -1 )  // make sure 'x' was in the resolution string
	{
		`log( "ERROR: SFMFrontEndSettingsMenu::CreateResolutionOptionFromString() got a bad resolution string!" );
		return resOption;
	}

	// Get X resolution
	tempString = Left( inResString, xIndex );   // the resolution string before 'x'
	resOption._resX = int( tempString );

	// Get Y resolution
	tempString = Mid( inResString, xIndex + 1 );    // the resolution string after 'x'
	resOption._resY = int( tempString );

	return resOption;
}

function SetIsFullscreen( bool inIsFullscreen )
{
	local ResolutionOption resOption;

	resOption = GetCurrentResolutionOption();

	// Append 'f' to the resolution if it's fullscreen, 'w' if it's widescreen
	if( inIsFullscreen )
	{
		resOption._resolutionString $= "f";
	}
	else
	{
		resOption._resolutionString $= "w";
	}

	SetResolution( resOption._resolutionString );
}

// This function expects a resolution such as "1920x1080". It needs the 'x' in the middle to function properly
function SetResolution( string inRes )
{
	local int currentMilliseconds;
	local string setResCommand;

	// Only allow resolution changes if we've waited the wait time. This prevents a potential game lock
	currentMilliseconds = mPlayerController.WorldInfo.TimeSeconds * 1000;
	if( Abs(currentMilliseconds - mLastResolutionChangeTimestamp) < WAIT_BETWEEN_RESOLUTION_CHANGES )
	{
		return;
	}
	mLastResolutionChangeTimestamp = currentMilliseconds;

	UDKRTSHUDBase(self.mPlayerController.myHUD).disableAllTerrain();
	UDKRTSHUDBase(self.mPlayerController.myHUD).mReenableTerrainInFrames = 1; // will reenable terrain in 1 frame to prevent invisible floor bug

	setResCommand = "setres " $ inRes;
	mPlayerController.ConsoleCommand( setResCommand );
}

function string GetScreenResolution()
{
	local Vector2D viewportSize;
	local string resolution;
	mMoviePlayer.GetGameViewportClient().GetViewportSize( viewportSize );
	resolution = string( int(viewportSize.X) ) $ "x" $ string( int(viewportSize.Y) );

	return resolution;
}

function bool IsFullscreen()
{
	return mMoviePlayer.GetGameViewportClient().IsFullScreenViewport();
}

// Takes in a percentage between 0 and 1.0f
function SetMasterVolume( float inVolume )
{
	local string setVolumeCommand;

	if( inVolume > 1 )
	{
		inVolume = 1;
	}
	if( inVolume < 0 )
	{
		inVolume = 0;
	}

	mSoundSettings.volumePercentage = inVolume;
	mSoundSettings.SaveSettings();

	setVolumeCommand = "ModifySoundClass Master Vol=" $ inVolume;
	mPlayerController.ConsoleCommand( setVolumeCommand );
}

function array< string > GetAvailableResolutions()
{
    local array< string > resolutionList;
    local string tempString;
    local int i, j;

    tempString = mPlayerController.ConsoleCommand( "DUMPAVAILABLERESOLUTIONS", false );
    ParseStringIntoArray( tempString, resolutionList, "\n", true );

    // Need to make sure that there are no duplicate entries.
    for( i = 0; i < resolutionList.Length; i++ )
    {
        for( j = i+1; j < resolutionList.Length; j++ )
        {
            if( resolutionList[ i ] == resolutionList[ j ] )
            {
                resolutionList.Remove( j, 1 );
                j--;
            }
        }
    }

    return resolutionList;
}

function int GetLevelOfDetail()
{
	local GameEngine Engine;

	Engine = GameEngine(Class'Engine'.static.GetEngine());
	return Engine.GetSystemSettingInt( "DetailMode" );
}

function int GetCurrentVolumeIndex()
{
	local float volume;
	
	volume = mSoundSettings.volumePercentage;

	if( volume < 0 )
	{
		return -1;
	}
	if( volume == 0 )
	{
		return 0;
	}

	return ( 1.0f - volume ) * 10 + 1;
}

function int GetCurrentVolumeLinear() {
	local float volume;
	
	volume = mSoundSettings.volumePercentage;

	if( volume < 0 )
	{
		return -1;
	}
	if( volume == 0 )
	{
		return 0;
	}

	return volume * 10;
}

DefaultProperties
{
	WAIT_BETWEEN_RESOLUTION_CHANGES = 1500; 
}
