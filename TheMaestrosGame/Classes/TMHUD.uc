class TMHUD extends UDKRTSPCHUD;

/** The texture showing the terrain of the map, the fog-of-war, the unit positions and the view frustrum. */
var ScriptedTexture MinimapFOWTexture;

/** The map shown by this minimap. */
var TMFOWManager FoWManager;

/** The texture that contains visibility information for the local player. */
var ScriptedTexture FogOfWarTexture;

/** The color fog of war is drawn with on the minimap. */
var LinearColor FogOfWarColor;

/** The color visible areas are drawn with on the minimap. */
var LinearColor VisibleColor;

/** The final blend alpha of fow on minimap. */
var float MinimapFOWAlpha;

/** Whether the fog of war is shown on the minimap, or not. */
var bool bShowFogOfWar;

/** The height and width of the minimap on the screen, in pixels. */
var int MinimapSize;

/** The quotient of the minimap and the map tile resolution. */
var float ZoomFactor;

/** Threshold for mouse movement after pressing T that instantly brings up the radial menu. */
var float MOUSE_DELTA_LIMIT;

/** String placed before all-chat messages to identify them to players */
var const string ALL_CHAT_IDENTIFIER;

/** Color to use for the line between units queuing to transform and the point */
var const Color goingToTransformLineColor;

/** String placed before team-chat messages to identify them to players */
var const string TEAM_CHAT_IDENTIFIER;

/** The longest possible chat header */
var const string MAX_LENGTH_CHAT_HEADER;

var Vector2D HudMovieSize;
var bool initialized;
var Vector MouseWorldLocation;
var bool bMouseOnMinimap;
var Texture targetTexture;
var Material rangeMat;
var MaterialInstanceConstant FoWMaterialInst;
var Material tugofwarMat;
var MaterialInstanceConstant brute_tugofwar[2];
var MaterialInstanceConstant nexus_tugofwar[2];

enum HealthBarVisibility
{
	ALWAYS,
	NEVER,
	DAMAGED,
};
var HealthBarVisibility eHealthBarVisibility;

var TM_GFxMoviePlayer PauseMenuMovie;

var Vector CameraLocation;
var float LastSizeX, LastSizeY;
var bool bLastFullscreen;
var bool bLastWindowHasFocus;

var TMPawn m_closestAbilityPawn;

// Radial menu
var Texture m_tRadialDefault;
var Texture m_tRadialSelection[5];
var bool m_bRadialVisible;
var Vector m_initialRadialMousePos;
var bool m_bRadialTimerOn;
var float m_fRadialTimer;
var const float m_fDelayUntilRadial;
var Vector m_MousePosOnTransformButtonPress;
var int m_radialSize;
var bool mIsRadialPotionMenuDisabled;

/**
 * Initializes this minimap, remembering the local player for drawing all units
 * using the correct color, and preparing a texture for rendering the fog of
 * war.
 */
simulated function Initialize(TMFOWManager manager)
{
	local MaterialInterface FoWMaterial;

	FoWMaterial = MaterialInterface( Material'FX_FogOfWar.M_FX_FogOfWar_Minimap' );
	if(manager!=None)
	{
		FoWManager = manager;
		SetMinimapSize(MinimapSize);
		FoWMaterialInst = new(None) Class'MaterialInstanceConstant';
		FoWMaterialInst.SetParent( FoWMaterial );
		FoWMaterialInst.SetTextureParameterValue('FogOfWarTexture', FowManager.GetMinimapFogOfWarTexture());
	}
}

/**
 * Set the width and height of this minimap to the specified number of pixels.
 * 
 * @param NewMinimapSize
 *      the new width and height of this minimap
 */
function SetMinimapSize(int NewMinimapSize)
{
	MinimapSize = NewMinimapSize;

	MinimapFOWTexture = ScriptedTexture(class'ScriptedTexture'.static.Create(MinimapSize, MinimapSize,, VisibleColor));
	MinimapFOWTexture.Render = RenderMinimapTexture;
	MinimapFOWTexture.bNeedsUpdate = true;
	ZoomFactor = MinimapSize / FoWManager.GetNumberOfTilesXY();
}

function DrawGoingToTranformLine(TMPawn source, Vector destination)
{
	destination.Z += source.Mesh.Bounds.BoxExtent.Z;
	self.Draw3DLine(source.Location, destination, goingToTransformLineColor);
}

function DrawChatBox(int XPos, int YPos, float width, float height)
{
	Canvas.SetPos( XPos, YPos );
	Canvas.DrawColor = class'TMColorPalette'.default.BlackTransparentRGBA;
	Canvas.DrawRect( width , height );
	Canvas.SetPos( XPos, YPos ); // set position top-left of chat
	Canvas.DrawColor = class'TMColorPalette'.default.GoldColorRGB;
	Canvas.DrawBox( width, height );
}

function DisplayConsoleMessages()
{
    local int Idx, XPos, YPos;
    local float chatBodyLength, charHeight, chatBoxYPos;
    local float headerLength, headerHeight;
	local int messageSplitLocation;
	local string chatHeader;
	local string chatBody;

	if ( ConsoleMessages.Length == 0 )
		return;

    for (Idx = 0; Idx < ConsoleMessages.Length; Idx++)
    {
		if ( ConsoleMessages[Idx].Text == "" /*|| ConsoleMessages[Idx].MessageLife < WorldInfo.TimeSeconds*/ )
		{
			ConsoleMessages.Remove(Idx--,1);
		}
    }

	if ( ConsoleMessages[ConsoleMessages.Length - 1].MessageLife < WorldInfo.TimeSeconds )
	{
		return;
	}

    XPos = (ConsoleMessagePosX * HudCanvasScale * Canvas.SizeX) + (((1.0 - HudCanvasScale) / 2.0) * Canvas.SizeX);
    YPos = (ConsoleMessagePosY * HudCanvasScale * Canvas.SizeY) + (((1.0 - HudCanvasScale) / 2.0) * Canvas.SizeY);
	
    Canvas.Font = class'Engine'.Static.GetSmallFont();
    Canvas.DrawColor = ConsoleColor;

    Canvas.TextSize ("A", chatBodyLength, charHeight);
    chatBoxYPos = YPos - charHeight * ConsoleMessageCount;
    DrawChatBox( XPos, chatBoxYPos, Canvas.SizeX - Xpos, ConsoleMessageCount * charHeight );

    for (Idx = ConsoleMessages.Length - 1; Idx >= 0; Idx--)
    {
		if( ShouldShowConsoleMessage(ConsoleMessages[Idx]) == FALSE )
		{
			continue;
		}

		// Split message and header
		messageSplitLocation = DetermineMessageSplitLocation(ConsoleMessages[Idx].Text);
		chatHeader = Left(ConsoleMessages[Idx].Text, messageSplitLocation + 1);
		chatBody = Right(ConsoleMessages[Idx].Text, (Len(ConsoleMessages[Idx].Text) - messageSplitLocation - 1) );

		Canvas.StrLen( chatHeader, headerLength, headerHeight );	
		Canvas.StrLen( chatBody, chatBodyLength, charHeight );
		YPos -= charHeight * FCeil(chatBodyLength / (Canvas.SizeX - (XPos + headerLength)));

		if ( YPos < chatBoxYPos)
		{
			ConsoleMessages.Remove(0,Idx);	
			break;
		}

		// Draw Chat Header
		Canvas.SetPos( XPos, YPos );
		Canvas.DrawColor = ConsoleMessages[Idx].TextColor;
		Canvas.DrawText( chatHeader, false );

		// Draw Chat message
		Canvas.DrawColor = class'LocalMessage'.static.GetConsoleColor(ConsoleMessages[Idx].PRI);
		Canvas.DrawText( chatBody, false );
    }
}

/**
 * Add a new console message to display.
 */
function AddConsoleMessage(string M, class<LocalMessage> InMessageClass, PlayerReplicationInfo PRI, optional float LifeTime)
{
	local int Idx, MsgIdx;
	local TMPlayerReplicationInfo tmpri;
	tmpri = TMPlayerReplicationInfo(PRI);

	MsgIdx = -1;
	// check for beep on message receipt
	if( bMessageBeep && InMessageClass.default.bBeep )
	{
		PlayerOwner.PlayBeepSound();
	}
	// find the first available entry
	if (ConsoleMessages.Length < ConsoleMessageCount)
	{
		MsgIdx = ConsoleMessages.Length;
	}
	else
	{
		// look for an empty entry
		for (Idx = 0; Idx < ConsoleMessages.Length && MsgIdx == -1; Idx++)
		{
			if (ConsoleMessages[Idx].Text == "")
			{
				MsgIdx = Idx;
			}
		}
	}
    if( MsgIdx == ConsoleMessageCount || MsgIdx == -1)
    {
		// push up the array
		for(Idx = 0; Idx < ConsoleMessageCount-1; Idx++ )
		{
			ConsoleMessages[Idx] = ConsoleMessages[Idx+1];
		}
		MsgIdx = ConsoleMessageCount - 1;
    }
	// fill in the message entry
	if (MsgIdx >= ConsoleMessages.Length)
	{
		ConsoleMessages.Length = MsgIdx + 1;
	}

    ConsoleMessages[MsgIdx].Text = M;
	if (LifeTime != 0.f)
	{
		ConsoleMessages[MsgIdx].MessageLife = WorldInfo.TimeSeconds + LifeTime;
	}
	else
	{
		ConsoleMessages[MsgIdx].MessageLife = WorldInfo.TimeSeconds + InMessageClass.default.LifeTime;
	}

	if (tmpri != None)
	{
		ConsoleMessages[MsgIdx].TextColor = class'TMColorPalette'.static.GetTeamColorRGB(tmpri.allyId, tmpri.mTeamColorIndex);
		ConsoleMessages[MsgIdx].PRI = PRI;
	}
	else
	{
	    ConsoleMessages[MsgIdx].TextColor = InMessageClass.static.GetConsoleColor(PRI);
		ConsoleMessages[MsgIdx].PRI = PRI;
	}
}

simulated function int DetermineMessageSplitLocation(string message)
{
	local int retVal;
	
	retVal = InStr(message, TEAM_CHAT_IDENTIFIER);
	if ( retVal > 0 )
	{
		return retVal + Len(TEAM_CHAT_IDENTIFIER) + 1;
	}

	retVal = InStr(message, ALL_CHAT_IDENTIFIER);
	if ( retVal > 0 )
	{
		return retVal + Len(ALL_CHAT_IDENTIFIER) + 1;
	}

	return -1;
}

simulated function RenderMinimapTexture(Canvas Ccanvas)
{
	if( isDisabled || bHideMinimap )
	{
		return;
	}

	// draw fog of war
	if (FoWManager.GetMinimapFogOfWarTexture() != None && bShowFogOfWar)
	{
		MinimapFOWTexture.bNeedsUpdate = true;
		Ccanvas.SetPos(0, 0); 
		Ccanvas.SetDrawColor(FogOfWarColor.R, FogOfWarColor.G, FogOfWarColor.B, FogOfWarColor.A);
		//Ccanvas.DrawTexture( FoWManager.MinimapFogOfWarTextures[0], 8.0f );
		Ccanvas.DrawMaterialTile( FoWMaterialInst , MinimapSize, MinimapSize );
	}
}

event OnLostFocusPause(bool bEnable)
{	
	bLastWindowHasFocus = bWindowHasFocus;
	super.OnLostFocusPause(bEnable);
}

function ScriptedTexture GetFOWTexture()
{
	return MinimapFOWTexture;
}

function float GetFOWTextureAlpha()
{
	return MinimapFOWAlpha;
}

function HideMinimapFOW(bool hide)
{
	if(hide)
	{
		MinimapFOWAlpha = 0.f;
	}else{
		MinimapFOWAlpha = default.MinimapFOWAlpha;
	}
}

simulated function PostBeginPlay()
{
	local float x0, y0, x1, y1;
	super.PostBeginPlay();
	initialized = false;
	GFxMovie = new class'TM_GFxHUDPlayer';
	TM_GFxHUDPlayer(GFxMovie).parentHUD = self;
	if(!initialized) 
	{
		GFxMovie.Init(LocalPlayer(PlayerOwner.Player));
		GFxMovie.Start();
		initialized = true;
	}
	GFxMovie.SetTimingMode(TM_Real);
	GFxMovie.GetVisibleFrameRect(x0, y0, x1, y1);
	HudMovieSize.X = x1 - x0;
	HudMovieSize.Y = y1 - y0;
	LastSizeX = HudMovieSize.X;
	LastSizeY = HudMovieSize.Y;

	class'Engine'.static.GetEngine().bPauseOnLossOfFocus = true;
	bLastFullscreen = false;
	eHealthBarVisibility = DAMAGED;

	brute_tugofwar[0] = new(none) class'MaterialInstanceConstant';
	brute_tugofwar[0].SetParent(tugofwarMat);
	brute_tugofwar[1] = new(none) class'MaterialInstanceConstant';
	brute_tugofwar[1].SetParent(tugofwarMat);
	nexus_tugofwar[0] = new(none) class'MaterialInstanceConstant';
	nexus_tugofwar[0].SetParent(tugofwarMat);
	nexus_tugofwar[1] = new(none) class'MaterialInstanceConstant';
	nexus_tugofwar[1].SetParent(tugofwarMat);

	TogglePauseMenu();

	bMouseOnMinimap = false;
}


function RevertCamera()
{
	TMCamera(TMPlayerController(PlayerOwner).PlayerCamera).SetCameraLocation(CameraLocation);
	TMPlayerController(PlayerOwner).CenterCameraOnCommander( 1 );
}

/**
 * This function is used as a janky fix to a terrain bug in UDK :(
 */
function MoveCameraBackAndForth()
{
	local Vector camloc;

	camloc = TMCamera(TMPlayerController(PlayerOwner).PlayerCamera).Location;
	CameraLocation = camloc;
	camloc.X -= 10000;
	TMCamera(TMPlayerController(PlayerOwner).PlayerCamera).SetCameraLocation(camloc);
	SetTimer(0.3f, false, 'RevertCamera');
	TMPlayerController(PlayerOwner).FoWDisable();
	TMPlayerController(PlayerOwner).FoWEnable();
}

event PostRender()
{
	local TMPlayerController playerController;
	local TMPawn pawn;
	local TMTransformer transformer;
	// Highlight things
	local TMPawn mouseOverPawn;
	local TMTransformer mouseOverTransformer;
	// Finding bar width per pawn
	local float barWidth;
	local Vector2D healthBarSize, cooldownBarSize;
	local Vector pawnXRadius, v2left, v2right;
	// Draw player's name
	local string playerName;
	local Vector2D textSize;
	local FontRenderInfo fri;
	local Vector pawnHeight, pos;
	// Drawing ability stuff to the minimap
	local array<TMPawn> pawnsWithActiveAbility;
	local Vector pawnLocationPlusRange;
	local Vector2D pawnMinimapPos, pawnMinimapRange;
	local TMAbility ability;
	// Mouse screen position
	local UDKRTSPCPlayerInput RTSPCPlayerInput;
	local Vector2D mousePos;
	local Vector2d screenSize;
	local float widthScaled, heightScaled;
	local TMMapPing ping;

	// Check if resolution has changed or fullscreen has been toggled, if it has, jump and revert camera	
	TM_GFxHUDPlayer(GFxMovie).GetGameViewportClient().GetViewportSize(screenSize);
	if (playerController != None && playerController.bGameStarted == true && (screenSize.X != LastSizeX || screenSize.Y != LastSizeY || bLastFullscreen != TM_GFxHUDPlayer(GFxMovie).GetGameViewportClient().IsFullScreenViewport() || (bLastFullscreen && bLastWindowHasFocus != bWindowHasFocus) ) )
	{
		MoveCameraBackAndForth();
	}
	bLastFullscreen = TM_GFxHUDPlayer(GFxMovie).GetGameViewportClient().IsFullScreenViewport();
	bLastWindowHasFocus = bWindowHasFocus;
	LastSizeX = screenSize.X;
	LastSizeY = screenSize.Y;

	// RENGAR DA RADIAL
	RenderRadial(canvas);

	// Render health/status bars
	if(!TM_GFxHUDPlayer(GFxMovie).hidden) 
	{
		super.PostRender();

		playerController = TMPlayerController(PlayerOwner);
		
		// Get mouse screen position
		RTSPCPlayerInput = UDKRTSPCPlayerInput(playerController.PlayerInput);
		mousePos.X = RTSPCPlayerInput.MousePosition.X;
		mousePos.Y = RTSPCPlayerInput.MousePosition.Y;

		// Cache mouse world location
		MouseWorldLocation = TMHUD(playerController.myHUD).TransformScreenToWorldSpaceOnTerrain(mousePos);
		bMouseOnMinimap = (self.InputMouse(mousePos) == PR_Minimap) ? true : false;

		// Settings for drawing text
		fri.bClipText = true;
		fri.bEnableShadow = false;

		//playerController.visi
		foreach playerController.DynamicActors(class'TMPawn', pawn)
		{
			if (self == None || Canvas == None || pawn.bHidden || !pawn.IsInitialized() || pawn.Health <= 0 || pawn.OwnerReplicationInfo == None)
			{
				continue;
			}

			// Unhighlight all units
			pawn.HideMouseHoverEffect();

			// Check if any pawn has active ability
			if (playerController.m_OnAbilityPawn.Find( pawn ) != -1)
			{
				pawnsWithActiveAbility.AddItem(pawn);
			}

			// Get bar width based on unit size
			pawnXRadius = pawn.GetCollisionExtent();
			pawnXRadius.Y = 0; pawnXRadius.Z = 0;
			v2left = Canvas.Project(pawn.Location);
			v2right = Canvas.Project(pawn.Location + pawnXRadius);
			barWidth = VSize(v2right-v2left); // Projected size
			barWidth *= 2;
			if (barWidth <= 0)
			{
				continue; // Probably offscreen or something
			}

			// Draw commander names
			if (pawn.m_UnitType == TMPlayerReplicationInfo(pawn.OwnerReplicationInfo).commanderType
				&& eHealthBarVisibility != NEVER)
			{
				playerName = pawn.OwnerReplicationInfo.PlayerName;
				if (Len(playerName) != 0)
				{
					// Find top of pawn
					pawn.GetBoundingCylinder(pawnHeight.X, pawnHeight.Y);
					pawnHeight.X = 0;
					pos = Canvas.Project(pawn.Location - pawnHeight);
					Canvas.SetDrawColor(255, 255, 255, 255);
					Canvas.TextSize(playerName, textSize.X, textSize.Y, 1.f, 1.f);
					Canvas.SetPos(pos.X - textSize.X/2, pos.Y - textSize.Y/2 - 20);
					Canvas.DrawText(playerName, true, 1.f, 1.f, fri);
				}
			}

			// Commanders, brute, nexus have long health bars
			if (pawn.m_UnitType == TMPlayerReplicationInfo(pawn.OwnerReplicationInfo).commanderType)
			{
				healthBarSize.X = 120;
				healthBarSize.Y = 8;
				cooldownBarSize.X = 120;
				cooldownBarSize.Y = 4;
			}
			else if (pawn.m_UnitType == "Brute" || pawn.m_UnitType == "ConvertedBrute" || pawn.m_UnitType == "Brute_Tutorial" || pawn.m_UnitType == "Nexus")
			{
				healthBarSize.X = 180;
				healthBarSize.Y = 12;
				cooldownBarSize.X = 180;
				cooldownBarSize.Y = 4;
			}
			else
			{
				healthBarSize.X = 30;
				healthBarSize.Y = 4;
				cooldownBarSize.X = 30;
				cooldownBarSize.Y = 4;
			}


			// Get pawn location
			pawn.GetBoundingCylinder(pawnHeight.X, pawnHeight.Y);
			pawnHeight.X = 0;
			pos = Canvas.Project(pawn.Location - pawnHeight);
			pos.X -= healthBarSize.X/2;

			// Draw health and cooldowns
			switch (eHealthBarVisibility)
			{
			case ALWAYS:
					DrawHealthBar(pawn, pos, healthBarSize);
					DrawCooldownBar(pawn, pos, healthBarSize);
				break;
			case NEVER:
				break;
			case DAMAGED:
				// Only draw health bar for noncommander units if they have less than full health
				if(pawn.GetTugOfWarComponent() != none)
				{
					self.DrawTugOfWarBar(pawn, pos, healthBarSize);
				}
				else if (pawn.m_UnitType == TMPlayerReplicationInfo(pawn.OwnerReplicationInfo).commanderType)
				{
					DrawHealthBar(pawn, pos, healthBarSize);
				}
				else if (pawn.Health != pawn.HealthMax)
				{
					DrawHealthBar(pawn, pos, healthBarSize);
				}
				DrawCooldownBar(pawn, pos, cooldownBarSize);
				break;
			}
		}

		// Draw ability target and range on minimap
		if (pawnsWithActiveAbility.Length != 0)
		{
			if(InputMouse(mousePos) == PR_Minimap)
			{
				Canvas.SetPos(mousePos.X-16, mousePos.Y-16);
				Canvas.DrawTile(targetTexture, 32, 32, 0, 0, 256, 256, MakeLinearColor(1,0,0,1),, BLEND_Additive);
			}
			foreach pawnsWithActiveAbility(pawn)
			{
				ability = pawn.GetAbilityComponent();
				if (ability.m_AbilityState == AS_IDLE
					&& MinimapSize > 2*ability.m_iRange)
				{
					pawnMinimapPos = ConvertWorldLocationToMinimapPosition(pawn.Location);
					pawnXRadius.X = 1; // Right unit vector
					pawnLocationPlusRange = pawn.Location + pawnXRadius;
					pawnMinimapRange = ConvertWorldLocationToMinimapPosition(pawnLocationPlusRange);
					pawnMinimapRange -= pawnMinimapPos;
					pawnMinimapRange *= ability.m_iRange;
					Canvas.SetPos(pawnMinimapPos.X-pawnMinimapRange.X, pawnMinimapPos.Y-pawnMinimapRange.X);
					Canvas.DrawMaterialTile(rangeMat, pawnMinimapRange.X*2, pawnMinimapRange.X*2);
				}
			}
		}

		// Draw transform crap
		foreach playerController.mTransformers(transformer)
		{
			if (self == None || Canvas == None)
			{
				continue;
			}
			if(transformer.showingTooltip && !transformer.highlighted)
			{
				TM_GFxHUDPlayer(GFxMovie).hideTooltip();
				transformer.showingTooltip = false;
			}
			// Unhighlight all transform points
			transformer.SetHighlighted(false);
		}
	
		// Draw pings
		foreach playerController.mMapPings(ping)
		{
			if (self == None || Canvas == None)
			{
				continue;
			}

			if(ping.m_ownerAllyId == TMPlayerReplicationInfo(playerController.PlayerReplicationInfo).allyId)
			{
				pawnMinimapPos = ConvertWorldLocationToMinimapPosition(ping.Location);
				Canvas.SetPos(pawnMinimapPos.X - 16, pawnMinimapPos.Y - 32);
				Canvas.SetDrawColor(255,255,255,255);
				// Draw Ping
				switch (ping.m_type)
				{
				case 0:
					Canvas.DrawTile(Texture'JC_Material_Sandbox.Textures.AlertTexture', 32, 32, 0, 0, 1024, 1024,,,BLEND_Translucent);
					break;
				case 1:
					Canvas.DrawTile(Texture'JC_Material_Sandbox.Textures.OMWTexture', 32, 32, 0, 0, 1024, 1024,,,BLEND_Translucent);
					break;
				case 2:
					Canvas.DrawTile(Texture'JC_Material_Sandbox.Textures.LookTexture', 32, 32, 0, 0, 1024, 1024,,,BLEND_Translucent);
					break;
				}
				// Draw Pulse
				if (ping.m_timeElapsed < 1)
				{
					Canvas.SetPos(pawnMinimapPos.X - 16 * (1-ping.m_timeElapsed), pawnMinimapPos.Y - 16 * (1-ping.m_timeElapsed));
					Canvas.DrawTile(Texture'SelectionCircles.Textures.WhiteSelection', 32 * (1-ping.m_timeElapsed), 32 * (1-ping.m_timeElapsed), 0, 0, 1024, 1024,,,BLEND_Translucent);
				}
			}
		}
	

		// Highlight unit under mouse
		mouseOverPawn = TMPawn(GetUDKRTSPawnFromCurrentFrameActors());
		if (mouseOverPawn != none && mouseOverPawn.Health > 0)
		{
			mouseOverPawn.ShowMouseHoverEffect();
		}
	
	
		// Highlight transform point under mouse
		mouseOverTransformer = TMTransformer(GetTransformerFromCurrentFrameActors());
		if (mouseOverTransformer != none)
		{
			mouseOverTransformer.SetHighlighted(true);
			/*
			if(!mouseOverTransformer.showingTooltip) 
			{
				if(mouseOverTransformer.UnitTwoType != "Sniper" && mouseOverTransformer.UnitTwoType != "Splitter")
				{
					TM_GFxHUDPlayer(GFxMovie).showTooltip(mouseOverTransformer.UnitTwoType@ "Transform", "Transforms between "@mouseOverTransformer.UnitOneCount@"Doughboys and a"@mouseOverTransformer.UnitTwoType, true, mouseOverTransformer.UnitOneType, mouseOverTransformer.UnitTwoType);
				}
				else if(mouseOverTransformer.UnitTwoType == "Sniper")
				{
					TM_GFxHUDPlayer(GFxMovie).showTooltip("Javelin Transform", "Transforms between "@mouseOverTransformer.UnitOneCount@"Doughboys and a Javelin", true, mouseOverTransformer.UnitOneType, mouseOverTransformer.UnitTwoType);
				}
				else if(mouseOverTransformer.UnitTwoType == "Splitter")
				{
					TM_GFxHUDPlayer(GFxMovie).showTooltip("Juggernaut Transform", "Transforms between "@mouseOverTransformer.UnitOneCount@"Doughboys and a Juggernaut", true, mouseOverTransformer.UnitOneType, mouseOverTransformer.UnitTwoType);
				}
				mouseOverTransformer.showingTooltip = true;
			}
			*/
		}

		widthScaled = screenSize.X * (210.0 / 1600.0);
		heightScaled = (210.0 / 900.0) * screenSize.Y;

		CurrentMinimapSize.X = widthScaled;
		CurrentMinimapSize.Y = heightScaled;

		RenderDebug();
	}
}

simulated function DrawTugOfWarBar(TMPawn pawn, Vector pos, Vector2D healthBarSize)
{
	local MaterialInstanceConstant redSide;
	local MaterialInstanceConstant blueSide;
	local float fHealth, fHealthMax;
	
	if (pawn.Health <= 0)
	{
		return;
	}

	if (pawn.m_UnitType == "Nexus")
	{
		redSide = nexus_tugofwar[0];
		blueSide = nexus_tugofwar[1];
	}
	else
	{
		redSide = brute_tugofwar[0];
		blueSide = brute_tugofwar[1];
	}

	fHealth = pawn.Health;
	fHealthMax = pawn.HealthMax;

	// Round float values...
	pos.X = Round(pos.X);
	pos.Y = Round(pos.Y);
	pos.Z = Round(pos.Z);
	healthBarSize.X = Round(healthBarSize.X);
	healthBarSize.Y = Round(healthBarSize.Y);
	
	// Render health border
	Canvas.SetPos(pos.X - 2, pos.Y - healthBarSize.Y - 2);
	Canvas.SetDrawColor(0, 0, 0, 191);
	Canvas.DrawRect(healthBarSize.X + 4, healthBarSize.Y + 4);

	// Render red side
	Canvas.SetPos(pos.X, pos.Y - healthBarSize.Y);
	Canvas.SetDrawColor(255,255,255,255);
	redSide.SetScalarParameterValue('HueShift', 0);
	redSide.SetScalarParameterValue('SaturationScale', 1);
	redSide.SetScalarParameterValue('ValueScale', 1);
	redSide.SetScalarParameterValue('bGoesRight', 0);
	redSide.SetScalarParameterValue('bIsMoving', (pawn.GetTugOfWarComponent().m_recentRedDamage) ? 1 : 0);
	Canvas.DrawMaterialTile(redSide, healthBarSize.X * fHealth/fHealthMax, healthBarSize.Y, 0, 0, 1, 1);
	
	// Render blue side
	Canvas.SetPos(pos.X + healthBarSize.X * fHealth/fHealthMax, pos.Y - healthBarSize.Y);
	Canvas.SetDrawColor(255,255,255,255);
	blueSide.SetScalarParameterValue('HueShift', 240);
	blueSide.SetScalarParameterValue('SaturationScale', 1);
	blueSide.SetScalarParameterValue('ValueScale', 1);
	blueSide.SetScalarParameterValue('bGoesRight', 1);
	blueSide.SetScalarParameterValue('bIsMoving', (pawn.GetTugOfWarComponent().m_recentBlueDamage) ? 1 : 0);
	Canvas.DrawMaterialTile(blueSide, healthBarSize.X * (1.0f - fHealth/fHealthMax), healthBarSize.Y, 0, 0, 1, 1);
}


simulated function DrawHealthBar(TMPawn pawn, Vector pos, Vector2D healthBarSize)
{
	local float tickWidth;
	local int i;
	local Color blackColor;
	local int healthPerTick;
	local Vector teamColorHSV;

	if (pawn.Health <= 0)
	{
		return;
	}
	
	// Get team colors
	teamColorHSV = pawn.GetTeamColorHue();
	if (pawn.GetAllyId() == -1)
	{
		teamColorHSV.Y = 0;
		teamColorHSV.Z = 0.4f;
	}

	// Round float values...
	pos.X = Round(pos.X);
	pos.Y = Round(pos.Y);
	pos.Z = Round(pos.Z);
	healthBarSize.X = Round(healthBarSize.X);
	healthBarSize.Y = Round(healthBarSize.Y);
	
	// Flag next to allied commander health bars
	if (pawn.GetAllyId() == TMPlayerReplicationInfo(TMPlayerController(PlayerOwner).PlayerReplicationInfo).allyId
		&& pawn.m_UnitType == TMPlayerReplicationInfo(pawn.OwnerReplicationInfo).commanderType)
	{
		Canvas.SetPos(pos.X + healthBarSize.X, pos.Y - 3*healthBarSize.Y/2);
		Canvas.SetDrawColor(255, 255, 255, 255);
		if (pawn.GetAllyId() == 0)
		{
			Canvas.DrawTile(Texture'JC_Material_Sandbox.Textures.BlueFlag', 32, 32, 0, 0, 512, 512,,,BLEND_Masked);
		}
		else if (pawn.GetAllyId() == 1)
		{
			Canvas.DrawTile(Texture'JC_Material_Sandbox.Textures.RedFlag', 32, 32, 0, 0, 512, 512,,,BLEND_Masked);
		}
	}

	// Render health border
	Canvas.SetPos(pos.X - 2, pos.Y - healthBarSize.Y - 2);
	Canvas.SetDrawColor(0, 0, 0, 191);
	Canvas.DrawRect(healthBarSize.X + 4, healthBarSize.Y + 4);

	// Render last second's health
	Canvas.SetPos(pos.X, pos.Y - healthBarSize.Y);
	Canvas.SetDrawColor(255, 0, 0, 255);
	Canvas.DrawRect(healthBarSize.X * (pawn.m_lastMomentHealth / pawn.HealthMax), healthBarSize.Y);

	// Render health bar
	Canvas.SetPos(pos.X, pos.Y - healthBarSize.Y);
	Canvas.SetDrawColor(255,255,255,255);
	pawn.m_healthBarMatInst.SetScalarParameterValue('HueShift', teamColorHSV.X);
	pawn.m_healthBarMatInst.SetScalarParameterValue('SaturationScale', teamColorHSV.Y);
	pawn.m_healthBarMatInst.SetScalarParameterValue('ValueScale', teamColorHSV.Z);
	Canvas.DrawMaterialTile(pawn.m_healthBarMatInst, healthBarSize.X * pawn.Health/pawn.HealthMax, healthBarSize.Y, 0, 0, 1, 1);

	// Render health ticks
	healthPerTick = 250;
	tickWidth = Round(healthPerTick*(healthBarSize.X/pawn.HealthMax));
	Canvas.SetPos(pos.X + tickWidth, pos.Y - healthBarSize.Y);
	blackColor = MakeColor(0, 0, 0, 191);
	if (tickWidth > 0)
	{
		for (i = 1; i*tickWidth < healthBarSize.X; i++)
		{
			if (healthPerTick * i < pawn.Health)
			{
				Canvas.Draw2DLine(pos.X+i*tickWidth, pos.Y, pos.X+i*tickWidth, pos.Y-healthBarSize.Y, blackColor);
			}
		}
	}
}

simulated function DrawCooldownBar(TMPawn pawn, Vector pos, Vector2D cooldownBarSize)
{

	local TMAbility ability;
	local TMComponentDecay decay;
	local float cooldownPercent;

	if (pawn.Health <= 0)
	{
		return;
	}
	
	// Round float values...
	pos.X = Round(pos.X);
	pos.Y = Round(pos.Y);
	pos.Z = Round(pos.Z);
	cooldownBarSize.X = Round(cooldownBarSize.X);
	cooldownBarSize.Y = Round(cooldownBarSize.Y);

	// Render cooldown
	ability = pawn.GetAbilityComponent();
	if (ability != none)
	{
		if(ability.m_AbilityState == AS_COOLDOWN) {
			// Render cooldown border
			Canvas.SetPos(pos.X - 2, pos.Y - cooldownBarSize.Y + 6);
			/*
			Canvas.SetDrawColor(255, 255, 255, 255);
			Canvas.DrawTile(Texture'JC_Material_Sandbox.Textures.healthCooldownBar', healthBarSize.X, 4, 0, 0, 300, 52,,,BLEND_Masked);
			*/
			Canvas.SetDrawColor(0, 0, 0, 191);
			Canvas.DrawRect(cooldownBarSize.X + 4, 4);

			cooldownPercent = (ability.mCooldown - ability.m_fTimeInState) / ability.mCooldown;
			Canvas.SetPos(pos.X, pos.Y - 4 + 7);
			Canvas.SetDrawColor(255, 255, 255, 191);
			Canvas.DrawRect(cooldownBarSize.X * cooldownPercent, 2);

		}
	}

	decay = pawn.GetDecayComponent();
	if(decay != none)
	{
		Canvas.SetPos(pos.X - 2, pos.Y - cooldownBarSize.Y + 6);
		
		Canvas.SetDrawColor(0, 0, 0, 191);
		Canvas.DrawRect(cooldownBarSize.X + 4, 4);

		cooldownPercent = decay.m_currentTime / decay.m_timeDecay;
		Canvas.SetPos(pos.X, pos.Y - 4 + 7);
		Canvas.SetDrawColor(255, 255, 255, 191);
		Canvas.DrawRect(cooldownBarSize.X * cooldownPercent, 2);
	}

}

simulated function RenderDebug()
{
	local TMPawn tempActor;
	local TMPlayerController tmpc;

	tmpc = TMPlayerController(PlayerOwner);

	if ( ShouldDisplayDebug('AIMovementLines') || ShouldDisplayDebug('AiStates') || ShouldDisplayDebug('ComponentStates') || ShouldDisplayDebug('BoundingBoxes') )
	{
		foreach AllActors(class'TMPawn', tempActor, )
		{
			if ( ShouldDisplayDebug('AiStates') || ShouldDisplayDebug('AIMovementLines') )
			{
				RenderDebugAiStates(tempActor);
			}
			if ( ShouldDisplayDebug('ComponentStates') )
			{
				RenderDebugComponentStates(tempActor);
			}
			if ( ShouldDisplayDebug('BoundingBoxes') )
			{
				RenderDebugBoundingBoxes(tempActor);
			}
		}
	}

	if (tmpc == None)
	{
		return;
	}

	if ( ShouldDisplayDebug('MyAIMovementLines') || ShouldDisplayDebug('MyAiStates') || ShouldDisplayDebug('MyComponentStates') || ShouldDisplayDebug('MyBoundingBoxes') )
	{
		tempActor = None;
		foreach TMPlayerReplicationInfo(tmpc.PlayerReplicationInfo).m_PlayerUnits(tempActor)
		{
			if ( ShouldDisplayDebug('MyAiStates') || ShouldDisplayDebug('MyAIMovementLines') )
			{
				RenderDebugAiStates(tempActor);
			}
			if ( ShouldDisplayDebug('MyComponentStates') )
			{
				RenderDebugComponentStates(tempActor);
			}
			if ( ShouldDisplayDebug('MyBoundingBoxes') )
			{
				RenderDebugBoundingBoxes(tempActor);
			}
		}
	}
}

simulated function RenderDebugAiStates(TMPawn tempActor)
{
	local UDKRTSAIController UDKRTSAIController;

	if (tempActor != None)
	{
		UDKRTSAIController = UDKRTSAIController(tempActor.Controller);
		if (UDKRTSAIController != None)
		{
			UDKRTSAIController.RenderDebugState(Self);
		}
	}
}

simulated function RenderDebugComponentStates(TMPawn Pawn)
{
	local Vector V;
	local string Text;
	local float XL, YL;
	local TMComponent tempComponent;
	local TMComponentAttack attackComponent;
	local TMComponentMove moveComponent;

	if (Pawn.Health <= 0 || Pawn.bHidden || !Pawn.IsInitialized())
	{
		return;
	}

	foreach Pawn.m_Unit.m_componentArray(tempComponent)
	{
		if (TMComponentAttack( tempComponent ) != None )
		{
			attackComponent = TMComponentAttack( tempComponent );
		}
		else if ( TMComponentMove( tempComponent ) != None )
		{
			moveComponent = TMComponentMove( tempComponent );
		}
	}

	// Display the Component states
	V = Pawn.Location + Pawn.CylinderComponent.CollisionHeight * Vect(0.f, 0.f, 1.f);
	V = Canvas.Project(V);		
	Canvas.Font = class'Engine'.static.GetTinyFont();

	// Render the state debug
	Text = String(Pawn.m_currentState);
	Canvas.TextSize(Text, XL, YL);
	DrawBorderedText(self, V.X - (XL * 0.5f), V.Y - (YL * 3.f), Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

	Text = String(moveComponent.m_State);
	Canvas.TextSize(Text, XL, YL);
	DrawBorderedText(self, V.X - (XL * 0.5f), V.Y - (YL * 2.f), Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

	Text = String(attackComponent.m_State);
	Canvas.TextSize(Text, XL, YL);
	DrawBorderedText(self, V.X - (XL * 0.5f), V.Y - (YL * 1.f), Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);
}

simulated function RenderDebugBoundingBoxes(TMPawn tempActor)
{
	if (tempActor != None)
	{
		// Only care about pawns that have health
		if (tempActor.Health > 0)
		{
			tempActor.ScreenBoundingBox = CalculateScreenBoundingBox(Self, tempActor, tempActor.CollisionComponent);
			Canvas.SetPos(tempActor.ScreenBoundingBox.Min.X, tempActor.ScreenBoundingBox.Min.Y);
			Canvas.DrawColor = tempActor.BoundingBoxColor;
			Canvas.DrawBox(tempActor.ScreenBoundingBox.Max.X - tempActor.ScreenBoundingBox.Min.X, tempActor.ScreenBoundingBox.Max.Y - tempActor.ScreenBoundingBox.Min.Y);
		}
		else
		{
			// Reset the bounding box
			tempActor.ScreenBoundingBox = class'UDKRTSUtility'.default.NullBoundingBox;
		}
	}
}


function TogglePauseMenu()
{
	/*
	if (PauseMenuMovie != none && PauseMenuMovie.bMovieIsOpen)
	{
		GFxMovie.GetPC().SetPause(False);
		PauseMenuMovie.Close(False);  // Keep the Pause Menu loaded in memory for reuse.
		//SetVisible(True);
	}
	else
	{
		GFxMovie.GetPC().SetPause(True);

		if (PauseMenuMovie == None)
		{
			PauseMenuMovie = new class'TM_GFxMoviePlayer';
			PauseMenuMovie.MovieInfo = SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_Paused';
			PauseMenuMovie.bEnableGammaCorrection = False;
			PauseMenuMovie.LocalPlayerOwnerIndex = GFxMovie.LocalPlayerOwnerIndex;
			//PauseMenuMovie.LocalPlayerOwnerIndex = class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
			PauseMenuMovie.SetTimingMode(TM_Real);
			PauseMenuMovie.SetViewScaleMode(SM_ExactFit);
			PauseMenuMovie.bAllowInput = true;
			PauseMenuMovie.bAllowFocus = true;
		}

		//SetVisible(false);
		PauseMenuMovie.Start();
		PauseMenuMovie.Advance(0);

		// Do not prevent 'escape' to unpause if running in mobile previewer
		//if( !WorldInfo.IsPlayInMobilePreview() )
		//{
		//	PauseMenuMovie.AddFocusIgnoreKey('Escape');
		//}
	}
	*/
	GFxMovie.MovieInfo = SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_Paused';
}

function StartRadialTimer()
{
	local UDKRTSPCPlayerInput RTSPCPlayerInput;

	RTSPCPlayerInput = UDKRTSPCPlayerInput(PlayerOwner.PlayerInput);
	m_MousePosOnTransformButtonPress.X = RTSPCPlayerInput.MousePosition.X;
	m_MousePosOnTransformButtonPress.Y = RTSPCPlayerInput.MousePosition.Y;
	m_MousePosOnTransformButtonPress.Z = 0;

	if (TMPlayerReplicationInfo(TMPlayerController(PlayerOwner).PlayerReplicationInfo).GetRace() != "Alchemist")
	{
		return;
	}

	m_bRadialTimerOn = true;
}

function ShowRadial()
{
	// local UDKRTSPCPlayerInput RTSPCPlayerInput;

	if (TMPlayerReplicationInfo(TMPlayerController(PlayerOwner).PlayerReplicationInfo).GetRace() != "Alchemist" ||
		mIsRadialPotionMenuDisabled)
	{
		return;
	}

	// RTSPCPlayerInput = UDKRTSPCPlayerInput(PlayerOwner.PlayerInput);
	m_initialRadialMousePos.X = m_MousePosOnTransformButtonPress.X; // RTSPCPlayerInput.MousePosition.X;
	m_initialRadialMousePos.Y = m_MousePosOnTransformButtonPress.Y; // RTSPCPlayerInput.MousePosition.Y;
	m_initialRadialMousePos.Z = 0;

	m_bRadialVisible = true;
}

function HideRadial()
{
	local TMPlayerController tmpc;
	local TMAbilityFE abFE;
	
	if (TMPlayerReplicationInfo(TMPlayerController(PlayerOwner).PlayerReplicationInfo).GetRace() != "Alchemist")
	{
		return;
	}

	tmpc = TMPlayerController(PlayerOwner);

	// If the timer hasn't reached the necessary time to bring up the radial
	if (m_fRadialTimer < m_fDelayUntilRadial && !m_bRadialVisible)
	{
		m_bRadialVisible = false;
		m_bRadialTimerOn = false;
		m_fRadialTimer = 0;

		abFE = new class'TMAbilityFE'();
		abFE.pawnId = tmpc.GetCommander().pawnId;
		abFE.ability = "PotionToss";
		abFE.commandType = "C_Ability";
		abFE.detailString = tmpc.m_CurrentPotionType;
		tmpc.GetCommander().SendFastEvent( abFE );

		return;
	}

	switch (CalculateRadialSelection())
	{
		case 0: tmpc.SetPotion("Grappler"); break;
		case 1: tmpc.SetPotion("Disruptor"); break;
		case 2: tmpc.SetPotion("VineCrawler"); break;
		case 3: tmpc.SetPotion("Turtle"); break;
		case 4: tmpc.SetPotion("Regenerator"); break;
		default: `log("no potion selected", true, 'justin'); break;
	}

	m_bRadialVisible = false;
	m_bRadialTimerOn = false;
	m_fRadialTimer = 0;

}

function SetRadialPotionMenuDisabled( bool inIsDisabled = true )
{
	mIsRadialPotionMenuDisabled = inIsDisabled;

	if( inIsDisabled )
	{
		HideRadial();
	}
}

function RenderRadial(Canvas c)
{
	local TMPlayerController tmpc;
	local FontRenderInfo fri;
	local UDKRTSPCPlayerInput RTSPCPlayerInput;
	local Texture radialTexture;
	local TMPotionStack stack;
	local int numPotions;
	local Vector textSize;
	local float fontScale;
	local Font cacheFont;

	tmpc = TMPlayerController(PlayerOwner);

	if (tmpc.PlayerReplicationInfo == none)
	{
		return;
	}

	if (TMPlayerReplicationInfo(tmpc.PlayerReplicationInfo).GetRace() != "Alchemist")
	{
		return;
	}

	if (m_bRadialVisible)
	{
		fri.bClipText = true;
		fri.bEnableShadow = false;
		fontScale = 1;

		switch (CalculateRadialSelection())
		{
			case 0: radialTexture = m_tRadialSelection[0]; break;
			case 1: radialTexture = m_tRadialSelection[1]; break;
			case 2: radialTexture = m_tRadialSelection[2]; break;
			case 3: radialTexture = m_tRadialSelection[3]; break;
			case 4: radialTexture = m_tRadialSelection[4]; break;
			default: radialTexture = m_tRadialDefault; break;
		}
		
		c.SetPos(m_initialRadialMousePos.X - m_radialSize/2, m_initialRadialMousePos.Y - m_radialSize/2);
		c.SetDrawColor(255,255,255,255);
		c.DrawTile(radialTexture, m_radialSize, m_radialSize, 0, 0, 512, 512,,, BLEND_Translucent);

		// Draw line
		RTSPCPlayerInput = UDKRTSPCPlayerInput(PlayerOwner.PlayerInput);
		c.Draw2DLine(m_initialRadialMousePos.X, m_initialRadialMousePos.Y, RTSPCPlayerInput.MousePosition.X, RTSPCPlayerInput.MousePosition.Y, MakeColor(0, 255, 0, 255));

		// Get number of currently selected potion type
		fri.bClipText = true;
		fri.bEnableShadow = false;
		cacheFont = c.Font;
		c.Font = class'Engine'.static.GetLargeFont();
		if (tmpc.m_Potions.Length != 0)
		{
			foreach tmpc.m_Potions(stack)
			{
				numPotions = stack.m_Count;
					
				// Draw number of this type if not 0
				if (numPotions != 0)
				{
					if (stack.m_UnitType == "Grappler")
					{
						c.TextSize(numPotions, textSize.X, textSize.Y, fontScale, fontScale);
						c.SetPos(m_initialRadialMousePos.X - textSize.X/2 - m_radialSize/2 * (Sin(Pi/5)), m_initialRadialMousePos.Y - textSize.Y/2 - m_radialSize/2 * (Cos(Pi/5)));
						c.DrawText(numPotions, true, fontScale, fontScale, fri);
					}
					else if (stack.m_UnitType == "Disruptor")
					{
						c.TextSize(numPotions, textSize.X, textSize.Y, fontScale, fontScale);
						c.SetPos(m_initialRadialMousePos.X - textSize.X/2 - m_radialSize/2 * (Sin(3*Pi/5)), m_initialRadialMousePos.Y - textSize.Y/2 - m_radialSize/2 * (Cos(3*Pi/5)));
						c.DrawText(numPotions, true, fontScale, fontScale, fri);
					}
					else if (stack.m_UnitType == "VineCrawler")
					{
						c.TextSize(numPotions, textSize.X, textSize.Y, fontScale, fontScale);
						c.SetPos(m_initialRadialMousePos.X - textSize.X/2 - m_radialSize/2 * (Sin(5*Pi/5)), m_initialRadialMousePos.Y - textSize.Y/2 - m_radialSize/2 * (Cos(5*Pi/5)));
						c.DrawText(numPotions, true, fontScale, fontScale, fri);
					}
					else if (stack.m_UnitType == "Turtle")
					{
						c.TextSize(numPotions, textSize.X, textSize.Y, fontScale, fontScale);
						c.SetPos(m_initialRadialMousePos.X - textSize.X/2 - m_radialSize/2 * (Sin(7*Pi/5)), m_initialRadialMousePos.Y - textSize.Y/2 - m_radialSize/2 * (Cos(7*Pi/5)));
						c.DrawText(numPotions, true, fontScale, fontScale, fri);
					}
					else if (stack.m_UnitType == "Regenerator")
					{
						c.TextSize(numPotions, textSize.X, textSize.Y, fontScale, fontScale);
						c.SetPos(m_initialRadialMousePos.X - textSize.X/2 - m_radialSize/2 * (Sin(9*Pi/5)), m_initialRadialMousePos.Y - textSize.Y/2 - m_radialSize/2 * (Cos(9*Pi/5)));
						c.DrawText(numPotions, true, fontScale, fontScale, fri);
					}
				}
			}
		}
		c.Font = cacheFont;

	}
}

function int CalculateRadialSelection()
{
	local UDKRTSPCPlayerInput RTSPCPlayerInput;
	local Vector finalRadialMousePos;
	local Vector dir;
	local Vector upvector;
	local float calculashuns;

	RTSPCPlayerInput = UDKRTSPCPlayerInput(PlayerOwner.PlayerInput);
	finalRadialMousePos.X = RTSPCPlayerInput.MousePosition.X;
	finalRadialMousePos.Y = RTSPCPlayerInput.MousePosition.Y;
	finalRadialMousePos.Z = 0;

	if (finalRadialMousePos.X == m_initialRadialMousePos.X && finalRadialMousePos.Y == m_initialRadialMousePos.Y)
	{
		return -1;
	}

	dir = finalRadialMousePos - m_initialRadialMousePos;
	dir = Normal(dir);

	upvector.X = 0;
	upvector.Y = 1;
	upvector.Z = 0;
	
	calculashuns = Acos(upvector dot dir);
	if (dir.X < 0) // flip if on the left
	{
		calculashuns = -calculashuns;
	}
	calculashuns += Pi; // bias to 0-2pi
	calculashuns /= 2*Pi; // bias to 0-1
	calculashuns *= 5; // bias to 0-5

	return FFloor(calculashuns);
}

event Tick(float DeltaTime)
{
	local int i;
	local TMPlayerController tmpc;
	local float mousePosDelta;
	local vector currentMousePos;
	local UDKRTSPCPlayerInput RTSPCPlayerInput;

	super.Tick(DeltaTime);
    TM_GFxHudPlayer(GFxMovie).Tick(DeltaTime);

	// If the timer hasn't reached the necessary time to bring up the radial
	if (m_fRadialTimer < m_fDelayUntilRadial)
	{
		// Tick the timer if it is on
		if (m_bRadialTimerOn)
		{
			m_fRadialTimer += DeltaTime;
		}

		// Check if the mouse has moved beyond the threshold
		RTSPCPlayerInput = UDKRTSPCPlayerInput(PlayerOwner.PlayerInput);
		currentMousePos.X = RTSPCPlayerInput.MousePosition.X;
		currentMousePos.Y = RTSPCPlayerInput.MousePosition.Y;
		currentMousePos.Z = 0;

		mousePosDelta = VSize(currentMousePos - m_MousePosOnTransformButtonPress);

		if(mousePosDelta >= MOUSE_DELTA_LIMIT && m_bRadialTimerOn && !m_bRadialVisible)
		{
			ShowRadial();
		}
	}
	// Timer is on and past necessary delay
	else if (m_bRadialTimerOn && !m_bRadialVisible)
	{
		ShowRadial();
	}   

	// Find closest unit with ability to mouse
	tmpc = TMPlayerController(PlayerOwner);
	for(i = 0; i < tmpc.m_OnAbilityPawn.Length; i++)
	{
		if (tmpc.InputHandler == tmpc.InputHandlerActiveCommand)
		{
			if (tmpc.m_OnAbilityPawn[i].IsThisMyAbility(tmpc.ActiveCommand))
			{
				if(tmpc.m_OnAbilityPawn[i].IsAbilityCastable())
				{
					if(m_closestAbilityPawn == none)
					{
						m_closestAbilityPawn = TMPawn(tmpc.m_OnAbilityPawn[i]);
					}
					else if(Vsize(MouseWorldLocation - m_closestAbilityPawn.Location) > Vsize(MouseWorldLocation -  tmpc.m_OnAbilityPawn[i].Location))
					{
						m_closestAbilityPawn =  TMPawn(tmpc.m_OnAbilityPawn[i]);
					}
				}
			}
		}
	}
}

// "Overriding" HUD
function Message( PlayerReplicationInfo PRI, coerce string Msg, name MsgType, optional float LifeTime )
{
	local string ThePlayerName;

	if ( bMessageBeep )
	{
		PlayerOwner.PlayBeepSound();
	}

	if ( (MsgType == 'Say') || (MsgType == 'TeamSay') )
	{
		ThePlayerName = PRI != None ? PRI.PlayerName : "";
		if (MsgType == 'Say')
		{
			Msg = ThePlayerName $ ALL_CHAT_IDENTIFIER $ ": "$Msg;
		}
		else if (MsgType == 'TeamSay')
		{
			Msg = ThePlayerName $ TEAM_CHAT_IDENTIFIER $ ": "$Msg;
		}
	}

	AddConsoleMessage(Msg,class'TMLocalMessage',PRI,LifeTime);
}

simulated event Destroyed()
{
	super.Destroyed();
}

defaultproperties
{
	MOUSE_DELTA_LIMIT = 100;

	targetTexture=Texture'VFX_Leo.Textures.AOE_Target_01'
	rangeMat=Material'SelectionCircles.Materials.abilityRangeMat'
	tugofwarMat=Material'JC_Material_SandBox.Materials.TugOfWarMat'

	m_tRadialDefault=Texture'TM_RadialMenu.transformradial'
	m_tRadialSelection[0]=Texture'TM_RadialMenu.grappler'
	m_tRadialSelection[1]=Texture'TM_RadialMenu.disruptor'
	m_tRadialSelection[2]=Texture'TM_RadialMenu.crawler'
	m_tRadialSelection[3]=Texture'TM_RadialMenu.turtle'
	m_tRadialSelection[4]=Texture'TM_RadialMenu.regenerator'

	m_fDelayUntilRadial = 0.25f;
	m_radialSize = 250;

	// Chat
	ConsoleMessagePosX=0.7
	ConsoleMessagePosY=0.7
	ALL_CHAT_IDENTIFIER="(All)"
	TEAM_CHAT_IDENTIFIER="(Team)"
	MAX_LENGTH_CHAT_HEADER="WWWWWWWWWWWWWWWW(Team): " 	// TODO: we should use actual player name length

	// Fog of War
	bShowFogOfWar=true
	FogOfWarColor=(R=255,G=255,B=255,A=255)
	goingToTransformLineColor=(R=0,G=255,B=0,A=127)
	VisibleColor=(R=0,G=0,B=0,A=255)
	
	MinimapSize=512
	MinimapFOWAlpha=0.56f
}
