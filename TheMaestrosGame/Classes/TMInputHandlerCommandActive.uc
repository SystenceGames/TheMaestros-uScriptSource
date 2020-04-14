class TMInputHandlerCommandActive extends UDKRTSInputHandlerCommandActive;

var ParticleSystem m_psMove;
var ParticleSystem m_psAttack;

function HandleInput(UDKRTSPCPlayerController Pccontroller)
{
	local TMPawn mouseActor;

	super.HandleInput(Pccontroller);
	
	mouseActor = TMPawn(ActiveHUD.GetUDKRTSPawnFromCurrentFrameActors());

	if (mouseActor != none && !mouseActor.bHidden && mouseActor.IsInitialized()) {
		if(mouseActor.OwnerReplicationInfo != none)
		{
			if(TMPlayerReplicationInfo(mouseActor.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(controller.PlayerReplicationInfo).allyId 
				&& controller.CurrentSelectedActors.Length > 0
				&& mouseActor.Health > 0)
			{
				ActiveHUD.CursorColor = CURSOR_COLOR_ATTACK;
			}
		}
	}
	else
	{
		ActiveHUD.CursorColor = CURSOR_COLOR_DEFAULT;
	}
}

function PressedMouseLeft()
{
	local UDKRTSPCHUD LocalActiveHUD;
	local PCResponse hudResponse;
	local Vector WorldLocation;
	local Vector2D ScreenLocation;

	LocalActiveHUD = TMHUD(controller.myHUD);
	hudResponse = LocalActiveHUD.InputMouse(controller.AllMouseButtonStates[LeftMouseButton].PositionCurrent);

	// Clicked on minimap
	if(hudResponse == PR_Minimap)
	{
		WorldLocation = ActiveHUD.ConvertMinimapPositionToWorldLocation(controller.AllMouseButtonStates[LeftMouseButton].PositionCurrent);
	}
	// Clicked on regular map
	else
	{
		ScreenLocation = controller.AllMouseButtonStates[LeftMouseButton].PositionCurrent;
		WorldLocation = LocalActiveHUD.TransformScreenToWorldSpaceOnTerrain(ScreenLocation);
	}

	if(controller.AllKeyboardButtonStates[KE_ALT].Held || controller.AllKeyboardButtonStates[KE_LCTRL].Held)
	{
		// Spawn the ping!
		if (controller.AllKeyboardButtonStates[KE_ALT].Held && controller.AllKeyboardButtonStates[KE_LCTRL].Held)
		{
			TMPlayerController(controller).ServerTellTheGameInfoToSpawnThePing(TMPlayerReplicationInfo(controller.PlayerReplicationInfo).allyId, WorldLocation, class'TMMapPing'.const.LookType);
		}
		else if (controller.AllKeyboardButtonStates[KE_ALT].Held)
		{
			TMPlayerController(controller).ServerTellTheGameInfoToSpawnThePing(TMPlayerReplicationInfo(controller.PlayerReplicationInfo).allyId, WorldLocation, class'TMMapPing'.const.OmwType);
		}
		else if (controller.AllKeyboardButtonStates[KE_LCTRL].Held)
		{
			TMPlayerController(controller).ServerTellTheGameInfoToSpawnThePing(TMPlayerReplicationInfo(controller.PlayerReplicationInfo).allyId, WorldLocation, class'TMMapPing'.const.AlertType);
		}
	}
	else
	{
		if (controller.ActiveCommand == C_Attack)
		{
			TMPlayerController(controller).m_ParticleSystemFactory.CreateClientside(m_psAttack, WorldLocation);
		}

		super.PressedMouseLeft();
		TMHUD(controller.myHUD).m_closestAbilityPawn = none;
	}
}

function PressedMouseRight()
{
	local UDKRTSPCHUD LocalActiveHUD;
	local PCResponse hudResponse;
	local Vector WorldLocation;
	local Vector2D ScreenLocation;
	local TMPawn SelectedPawn;
	local TMSalvatorSnake iterSnake;
	local bool bDontPlayVFX;

	LocalActiveHUD = TMHUD(controller.myHUD);
	hudResponse = LocalActiveHUD.InputMouse(controller.AllMouseButtonStates[RightMouseButton].PositionCurrent);

	SelectedPawn = TMPawn(LocalActiveHUD.GetMouseActor());
	if( SelectedPawn != none && SelectedPawn.GetAllyId() != TMPlayerReplicationInfo(TMPlayerController(controller).PlayerReplicationInfo).allyId)
	{
		super.PressedMouseRight();
		return;
	}
	else
	{
		// Clicked on minimap
		if(hudResponse == PR_Minimap)
		{
			WorldLocation = ActiveHUD.ConvertMinimapPositionToWorldLocation(controller.AllMouseButtonStates[RightMouseButton].PositionCurrent);
		}
		// Clicked on regular map
		else
		{
			ScreenLocation = controller.AllMouseButtonStates[RightMouseButton].PositionCurrent;
			WorldLocation = LocalActiveHUD.TransformScreenToWorldSpaceOnTerrain(ScreenLocation);

			if ( TMPlayerController(controller).mSalvatorSnakes.Length > 0 )
			{
				foreach TMPlayerController(controller).mSalvatorSnakes( iterSnake )
				{
					if ( VSize2D( iterSnake.Location - WorldLocation ) < iterSnake.GetCollisionRadius() )
					{
						bDontPlayVFX = true;
						break;
					}
				}
			}
		}
		
		if ( !bDontPlayVFX )
		{
			if (controller.AllKeyboardButtonStates[KE_SHIFT].Held)
			{
				TMPlayerController(controller).m_ParticleSystemFactory.CreateClientside(m_psAttack, WorldLocation);
			}
			else
			{
				TMPlayerController(controller).m_ParticleSystemFactory.CreateClientside(m_psMove, WorldLocation);
			}
		}
	}

	super.PressedMouseRight();
}

//reliable server function TMMapPing SpawnPing(Vector loc)
//{
//	return controller.WorldInfo.Game.Spawn(class'TMMapPing',,, loc);
//}

DefaultProperties
{
	notOnHud =false
	m_psMove=ParticleSystem'VFX_Adam.Particles.P_Icon_Move'
	m_psAttack=ParticleSystem'VFX_Adam.Particles.P_Icon_Attack'
}
