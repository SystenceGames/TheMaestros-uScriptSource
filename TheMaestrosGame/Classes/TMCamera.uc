class TMCamera extends UDKRTSCamera;

var UDKRTSCameraProperties SavedOffProperties;
var int focusTeam;
var bool focusAction;
var bool focusPawn;
var bool lockFocus;

var TMPawn pawnToFocus;
var TMPawn lastDiedCommander;
var TMPlayerController tmpc;
var TMFOWMapInfoActor cameraBound;
var float endGameTimer;
var bool endGameStarted;
var bool endGameSpectator;
var float gameSpeed;

var float endRoundTimer;
var bool endRoundStarted;

var TMRain rain;
var MaterialInstanceConstant rainmat;

function Initialize(PlayerController PC, int allyId, TMFOWMapInfoActor thisCameraBounds)
{
	tmpc = TMPlayerController(PCOwner);

	if(allyId == -3)
	{
		SetTimer(5.f, true, 'UpdateActionFocus');
		focusAction = true;
		Properties.OffsetLength = tmpc.InputHandler.MaxScrollSpectator * 0.55f;
	}

	//`log("MAPNAME"@tmpc.WorldInfo.GetMapName());
	rain = Spawn(class'TMRain', self);

	if (tmpc.WorldInfo.GetMapName() != "terra")
	{
		rain.m_fIntensity = 0.0f;
	}
	else
	{
		rain.m_fIntensity = 0.25f;
	}

	cameraBound = thisCameraBounds;
	gameSpeed = 1;
}

function UpdateActionFocus(bool force = false)
{
	local float action;
	local int newFocusTeam;
	newFocusTeam = tmpc.GetHighestActionTeamId( action, endGameSpectator ); // out action
	if( force || action > tmpc.GetTeamAction(focusTeam) * 1.2f)
	{
		focusTeam = newFocusTeam;
	}
}

function ForceUpdateActionFocus()
{
	UpdateActionFocus( true );
}

function StartEndGameSpectator()
{
	endGameSpectator = true;
	UpdateActionFocus();
	SetTimer(5.f, true, 'UpdateActionFocus');
}

function EndEndGameSpectator()
{
	endGameSpectator = false;
	//UpdateActionFocus();
	ClearTimer('UpdateActionFocus');
	//SetTimer(2.f, true, 'UpdateActionFocus');
}

function SetFocusOnPawn(TMPawn thePawn, bool lock = false)
{
	focusAction = false;
	focusPawn = true;
	pawnToFocus = thePawn;
	lockFocus = lock;	
}

function UnlockFocus()
{
	lockFocus = false;
	focusPawn = false; 	// don't focus on a pawn. But why? These states seem messy
}

function bool IsLocked()
{
	return lockFocus;
}

function SetFocusAction(bool focus)
{
	focusAction = focus;
}


function CameraTick(float dt)
{
	LimitCameraToBoundingVolume(dt);
	super.CameraTick(dt);
	if(tmpc!= None && tmpc.m_gameEnded)
	{
		if(!endGameStarted)
		{
			tmpc.FoWDisable();
			endGameTimer = 0;
			gameSpeed = 1;
			endGameStarted = true;
		}

		if(lastDiedCommander != none)
		{
			FocusOnPawn(lastDiedCommander, 10, 1);
		}
		EndGameTick(dt);
	}
	else if(tmpc!= None && tmpc.m_roundEnded)
	{
		if(!endRoundStarted)
		{
			tmpc.FoWDisable();
			endRoundTimer = 0;
			gameSpeed = 1;
			endRoundStarted = true;
		}

		if(lastDiedCommander != none)
		{
			FocusOnPawn(lastDiedCommander, 10, 1);
		}
		EndRoundTick(dt);
	}
	else
	{
		if(focusAction || endGameSpectator)
		{
			FocusOnTeam(focusTeam);
		}
		else if(focusPawn && pawnToFocus != none)
		{
			FocusOnPawn(pawnToFocus);
		}
	}
}

simulated function EndGameTick(float dt)
{
	endGameTimer+= dt/gameSpeed;

	TickEndGameHUD();

	if(endGameTimer < 0.5f)
	{
		if( Properties != none )
		{
			Properties.OffsetLength = Lerp( Properties.OffsetLength, tmpc.InputHandler.MaxScroll * 0.7f, dt );
		}
	}

	if(endGameTimer > 0.7f)
	{
		gameSpeed = Lerp( gameSpeed, 0.1f, dt * 5.f );
		Properties.OffsetLength = Lerp( Properties.OffsetLength, tmpc.InputHandler.MaxScroll * 1.5f, dt );
	}
}

simulated function TickEndGameHUD()
{
	tmpc.GetLocalHUDPlayer().saveEndGameStats();

	if(endGameTimer > 5.5f)
	{
		tmpc.GetLocalHUDPlayer().showVictoryOrDefeatOverlay();
	}

	if(endGameTimer > 9.0f)
	{
		tmpc.GetLocalHUDPlayer().goToEndOfGameStats();
	}
}

simulated function EndRoundTick(float dt)
{
	endRoundTimer += dt/gameSpeed;

	if(endRoundTimer < 0.5f)
	{
		Properties.OffsetLength = Lerp( Properties.OffsetLength, tmpc.InputHandler.MaxScroll * 0.7f, dt );
	}

	if(endRoundTimer > 0.7f)
	{
		gameSpeed = Lerp( gameSpeed, 0.1f, dt * 5.f );
		Properties.OffsetLength = Lerp( Properties.OffsetLength, tmpc.InputHandler.MaxScroll * 1.5f, dt );
	}

	if(endRoundTimer > 3.5f)
	{
		tmpc.m_roundEnded = false;
		endRoundStarted = false;
		if (!tmpc.mFootageFriendlyModeEnabled)
		{
			tmpc.FoWEnable();
		}
		EndEndGameSpectator();
		//tmpc.GetLocalHUDPlayer().hideVictoryOrDefeatOverlay();
	}
}

function UpdateLastDiedCommander( TMPawn myPawn )
{
	lastDiedCommander = myPawn;
}

function LimitCameraToBoundingVolume(float dt)
{
	local Vector limitPosition;

	if(cameraBound != none)
	{
		limitPosition = CurrentLocation;

		limitPosition.X = limitPosition.X > cameraBound.CameraBounds.BoxExtent.X + cameraBound.Location.X ? cameraBound.CameraBounds.BoxExtent.X + cameraBound.Location.X : limitPosition.X;
		limitPosition.X = limitPosition.X < -cameraBound.CameraBounds.BoxExtent.X + cameraBound.Location.X ? -cameraBound.CameraBounds.BoxExtent.X + cameraBound.Location.X : limitPosition.X;

		limitPosition.Y = limitPosition.Y > cameraBound.CameraBounds.BoxExtent.Y + cameraBound.Location.Y ? cameraBound.CameraBounds.BoxExtent.Y + cameraBound.Location.Y : limitPosition.Y;
		limitPosition.Y = limitPosition.Y < -cameraBound.CameraBounds.BoxExtent.Y + cameraBound.Location.Y ? -cameraBound.CameraBounds.BoxExtent.Y + cameraBound.Location.Y : limitPosition.Y;


		CurrentLocation.X = Lerp(CurrentLocation.X, limitPosition.X, dt * 5);
		CurrentLocation.Y = Lerp(CurrentLocation.Y, limitPosition.Y, dt * 5);
	}
}

function FocusOnPawn(TMPawn thePawn, float speed = 4, float timeout = 0)
{
	LerpTo( thePawn.Location, speed, timeout);
}

function SetCameraLocation(Vector loc)
{
	CurrentLocation = loc;
	cameraIsSnapping = false;
}

function FocusOnTeam(int team)
{
	// Ali - terrible implementation (for now)!!
	local int teamId;
	local array<TMPawn> pawns;
	local TMPawn myPawn;
	local Vector centerOfGroup;
	 
	// Dru TODO: Cache the TMPRIs and use TMPRI.m_PlayerUnits/TMPC.Pawn instead
	foreach AllActors(class'TMPawn', myPawn)
	{ 
		teamId = myPawn.OwnerReplicationInfo.GetTeamNum();

		if(teamId == team)
		{
			if(myPawn.IsCommander() && myPawn.Health <= 0)
			{
				SetTimer(2.f, false, 'ForceUpdateActionFocus');
				return;
			}
			pawns.AddItem(myPawn);
		}
	}

	if(pawns.Length > 0)
	{
		centerOfGroup = class'UDKRTSPawn'.static.SmartCenterOfGroup(pawns);
		if ( centerOfGroup != Vect( 0.0f, 0.0f, 0.0f ) )
		{
			LerpTo( centerOfGroup, 4);
		}
		else
		{
			`Warn("SmartCenterOfGroup() returned 0,0,0");
		}
	}
}

function ToggleMatineeCam()
{
	TMPlayerController(PCOwner).m_bUnderMatineeControl = !TMPlayerController(PCOwner).m_bUnderMatineeControl;

	if( TMPlayerController(PCOwner).m_bUnderMatineeControl )
	{
		if (SavedOffProperties == None)
		{
			SavedOffProperties = Properties;
		}
		Properties = None;
	}
	else
	{
		if ( Properties == None )
		{
			Properties = SavedOffProperties;
			Properties.OffsetLength = 2250;
		}
	}
}

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	//ToggleMatineeCam();

	super.UpdateViewTarget(OutVT, DeltaTime);
}

function StopSnapping()
{
	super.StopSnapping();
	focusAction = false;
	focusPawn = false;
}

DefaultProperties
{
	focusTeam = 0
	focusAction = false
	focusPawn = false
	lockFocus = false;
	endGameSpectator = false;
}
