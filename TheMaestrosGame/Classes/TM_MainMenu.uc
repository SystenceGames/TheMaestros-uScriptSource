class TM_MainMenu extends UDKRTSHUDBase;

var GFxMoviePlayer GFxMovie;
// Tells whether or not the game's window is in focus - used for determining whether or not to perform certain actions
var bool bWindowHasFocus;
//var Vector2D HudMovieSize;
//var float MouseX, MouseY;

//Called on destroy
simulated event Destroyed()
{
	if ( GFxMovie != none )
	{
		GFxMovie.Close( true );
		GFxMovie = none;
	}

	super.Destroyed();
}

simulated function PostBeginPlay()
{
	//local float x0, y0, x1, y1;

	// make sure our base type is initialized
	super.PostBeginPlay();

	// create our flash object
	GFxMovie = new () class'SFMFrontEnd';
	GFxMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
	GFxMovie.SetTimingMode( TM_Real );  // need this so everything doesn't get paused in menu
	GFxMovie.Start(); // call our movies init
	SFMFrontEnd(GFxMovie).LoadMenu(class'SFMFrontEndLogin');

	class'Engine'.static.GetEngine().bPauseOnLossOfFocus = true; // enable the OnLostFocusPause event

	//GFxMovie.GetVisibleFrameRect(x0, y0, x1, y1);
	//HudMovieSize.X = x1 - x0;
	//HudMovieSize.Y = y1 - y0;
}

simulated event PostRender()
{
	if (mReenableTerrainInFrames > 0)
	{
		if (mReenableTerrainInFrames == 1)
		{
			reenableAllTerrain();
		}

		mReenableTerrainInFrames = mReenableTerrainInFrames - 1;
	}

	super.PostRender(); // make sure our super class (the mouse hud) handles this data as well
}

event OnLostFocusPause(bool bEnable)
{	
	// `log("windows has focus: "@!bEnable, true, 'justin');

	if (bWindowHasFocus && bEnable)
	{
		// `log("Going from having focus to not having focus", true, 'dru');
		if (GFxMovie.GetGameViewportClient().IsFullScreenViewport())
		{
			disableAllTerrain();
		}
	}

	if (!bWindowHasFocus && !bEnable)
	{
		mReenableTerrainInFrames = 1;
	}

	bWindowHasFocus = !bEnable;
	//super.OnLostFocusPause(bEnable); // uncommenting will make game actually pause
}

DefaultProperties
{
}
