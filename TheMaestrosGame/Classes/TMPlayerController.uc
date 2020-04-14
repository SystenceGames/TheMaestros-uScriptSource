/**
 * Copyright 1998-2013 Epic Games, Inc. All Rights Reserved.
 */
class TMPlayerController extends UDKRTSPCPlayerController implements(TMController);

const TIME_BETWEEN_KILLS_FOR_KILLSPREE = 10;

var repnotify int PlayerId;
var int m_allyId;
var DruHashMap m_PawnHash; // maps PawnIDs to Pawns
var array<string> unitCacheString;
var array<string> statusEffectCacheString;
var array<TMUnit> unitCache;
var array<TMStatusEffect> statusEffectCache;
var bool m_gameEnded;
var bool m_roundEnded;
var TMJsonParser m_JsonParser;
var array<TMPawn> m_aConductors;    /** conductor who are casting "ConductorShock" */
var array<TMAbilityRegeneratorField> m_aRegenerators;   /** regenerators who are casting "RegeneratorField" */
var array< TMSalvatorSnake > mSalvatorSnakes;
var array<TMPawn> mTMPawnList;
var bool mLoggingOut;
var array<TMAllyInfo> mAllyInfos;
var array<TMMapPing> mMapPings;
var array<TMTransformer> mTransformers;

var bool mFootageFriendlyModeEnabled;

// cheat code vars
var bool m_BloomCheatActive;
var int m_SocialCluesNumber;
var bool m_bCole;
var bool m_bMiralab;
var float m_PreviousRainIntensity;
var array<string> m_CheatCodes;


// Related to Receiving commands in kismet to trigger actions
var bool m_bLookingForCommand;
var ECommand m_CommandImLookingFor;
var bool m_bReceivedCommandImLookingFor;

var string mObjectiveText; /** Tells a player their goal in the HUD in-game */

var array<TMFastEvent> m_cachedSpawnFes;
var array<TMTarSplotch> m_TarSplotches; /** active tar splotches */
var array<TMSniperMine> m_SniperMines;
var array<TMRambamQueenEggAbilityObject> m_RamBamQueenEggAbilityObjects;
var array<TMAbilityProjectile> m_AbilityProjectiles; 	// ability projectiles currently heading towards their target
var bool bHasDied;
var int m_iMaxNumStatusEffects;
var bool m_victory;
var bool m_bUnderMatineeControl;  // Added for Tutorial

var TM_GFxHUDPlayer TM_HUD;
var class<HUD> HUDClass;

var AudioManager m_AudioManager;
var TMGameInfo m_tmGameInfo;
var TMParticleSystemFactory m_ParticleSystemFactory;

var string commanderType;
//***** Fog of War
var int totalVision;

/** The manager for the fog of war handicaping this player. */
var private TMFOWManager mFoWManager;

/** The map this player plays on. */
var TMFOWMapInfoActor mapInfo;

//***************
var bool m_bTransformerIconInit;

var MaterialInstanceConstant DesatInst;
var MaterialInstanceConstant DamageInst;
var float DamageLastMoment;

var array<TMPotionStack> m_Potions;

var Vector actionCenter;
var array<TMPawn> attackingPawns;

var bool bIsDead;

var int killCount;
var int killSpreeCount;
var bool onKillSpree;
var bool bCameraFollowNuke;

var TMFOWRevealActor m_NexusRevealer;

var string m_CurrentPotionType;

var array< TMParticleSystem > mParticleSystemList;
var array< TMIAbilityObject > mActiveAbilityObjects;

var bool bGameStarted;
var float gameStartTime;
var bool bUseCheats;

var bool bShouldSpawnVFX;
var bool bGroupedMoveV2Enabled;

var TMDestructableShrine mDestructableShrine;

var string mGameMode; 	// used to check which game mode we are in on the clients

// Debug variables to enable
var bool bDebuggingBots;
var bool bBenchmarkingBots;


reliable client function ClientSetGameMode(string inGameMode)
{
	mGameMode = inGameMode;
}

/* IsCurrentGameMode
	Checks if the given game mode is what this client is playing.
*/
function bool IsCurrentGameMode(string inGameMode)
{
	return mGameMode == inGameMode;
}

state TMSpectating extends Spectating
{
	ignores RestartLevel, Suicide, ThrowWeapon, NotifyPhysicsVolumeChange, NotifyHeadVolumeChange;

	exec function StartFire( optional byte FireModeNum )
	{
		Global.StartFire(FireModeNum);
	}

	// Return to spectator's own camera.
	exec function StartAltFire( optional byte FireModeNum )
	{
		StartFire( 1 );
	}
}

event MatchStarting()
{
	super.MatchStarting();
	bGameStarted=true;
}

function PlayerDied()
{
	// noop for now
}

reliable client function ClientKillNexus()
{
	local TMPawn iterTMPawn;

	foreach AllActors(class'TMPawn', iterTMPawn)
	{
		if (iterTMPawn.m_nexusDestructable != None)
		{
			iterTMPawn.m_nexusDestructable.Destroy();
			iterTMPawn.m_nexusDestructable = None;
			mDestructableShrine = None;
			return;
		}
	}
}

reliable client function ClientSpawnDestructableNexus()
{
	SpawnDestructableNexus();
}

simulated function SpawnDestructableNexus()
{
	mDestructableShrine = Spawn(class'TMDestructableShrine',,, vect(0.0,0.0,0.0),,, true);
	if ( mDestructableShrine == None)
	{
		`warn("failed to spawn a new nexus");
	}
}

simulated event PreBeginPlay()
{
	if ( IsClient() )
	{
		SpawnDestructableNexus();
	}

	m_ParticleSystemFactory = new class'TMParticleSystemFactory'();
	m_ParticleSystemFactory.Setup( self );
}

/* This crashes the game. Don't use it.*/
exec function Crash()
{
	while(true)
	{
		m_PawnHash = None;
	}
}

simulated event PostBeginPlay() 
{
	super.PostBeginPlay();

	m_PawnHash = class'DruHashMap'.static.Create(256); // max units

	m_JsonParser = new() class'TMJsonParser';
	m_JsonParser.setup();

	//ClientSetHUD(HUDClass);
	m_AudioManager = new() class'AudioManager';
	if (m_AudioManager != none)
	{
		`log('AudioManager initialized', true, 'TMPlayerController PostBeginPlay');
	}
	m_AudioManager.Initialize(self);

	m_tmGameInfo = TMGameInfo(WorldInfo.Game);

	if( IsAuthority() )
	{
		SetTimer(1/8, true, 'CheckForAttackingUnits');
	}

	if( bDebuggingBots == true )
	{
		SetTimer(1, false, 'Bots');
	}

	if( bBenchmarkingBots == true )
	{
		class'WorldInfo'.static.GetWorldInfo().Game.SetGameSpeed(2.0f);
	}

	//SetTimer(60, true, 'ClearNoneInTMPawnList');
}

exec function DisableAllHUD( bool bShouldDisable )
{
	TM_HUD.disableAll( bShouldDisable );
}

exec function FootageFriendlyMode()
{
	mFootageFriendlyModeEnabled = !mFootageFriendlyModeEnabled;
	hideAllHUD(mFootageFriendlyModeEnabled);
	HideCursor(mFootageFriendlyModeEnabled);
	if (mFootageFriendlyModeEnabled)
	{
		mFoWManager.DisableFoW();		
	}
	else
	{
		mFoWManager.EnableFoW();
	}
}

exec function HideAllHUD( bool bHideAll )
{
	TM_HUD.hideAllHUD( bHideAll );
}

exec function HideCursor( bool bHideCursor )
{
	TM_HUD.hideCursor( bHideCursor );
}

exec function SpectatorUIMode( bool bGoSpectatorUIMode )
{
	TM_HUD.spectatorMode( bGoSpectatorUIMode );
}

exec function FollowNuke( bool bFollow )
{
	bCameraFollowNuke = bFollow;
}

function CommandIssued(ECommand command)
{
	if ( m_bLookingForCommand && command == m_CommandImLookingFor )
	{
		ReceivedCommandImLookingFor(command);
	}
}

reliable client function SetGameStartTime()
{
	gameStartTime = WorldInfo.RealTimeSeconds;
	`log("Game Start Time: " @gameStartTime, true, 'Ali');
}

function float GetGameTime()
{
	return WorldInfo.RealTimeSeconds - gameStartTime;
}

function StopLookingForCommand()
{
	m_bLookingForCommand = false;
	m_bReceivedCommandImLookingFor = false;
	m_CommandImLookingFor = ECommand.C_NONE;
}

function ReceivedCommandImLookingFor(ECommand command)
{
	m_bLookingForCommand = false;
	m_bReceivedCommandImLookingFor = true;
}

function StartLookingForCommand(string inCommandName)
{
	local int i;

	m_bLookingForCommand = true;
	m_bReceivedCommandImLookingFor = false;

	i = Ecommand.C_MAX;
	for (i = 0; i < ECommand.C_MAX; ++i)
	{
		if ( GetEnum(Enum'ECommand', i) == Name(inCommandName) )
		{
			m_CommandImLookingFor = ECommand(i);
		}
	}
}

function PlayerStarted()
{
	// noop for now, but so many possibilities!
}

function CheckForAttackingUnits()
{
	local int i;
	local TMComponentAttack attack;
	if( TMPlayerReplicationInfo(PlayerReplicationInfo) != none )
	{

		for(i = 0;i < TMPlayerReplicationInfo(PlayerReplicationInfo).m_PlayerUnits.Length; i++)
		{
			if( TMPlayerReplicationInfo(PlayerReplicationInfo).m_PlayerUnits[i] != none)
			{
				
				if( TMPlayerReplicationInfo(PlayerReplicationInfo).m_PlayerUnits[i].m_currentState  == TMPS_Attack )
				{
					attack = TMPlayerReplicationInfo(PlayerReplicationInfo).m_PlayerUnits[i].GetAttackComponent();
					if( attack != none && attack.m_Target != none && attack.m_Target.Health > 0)
					{
						SummonHelp( TMPlayerReplicationInfo(PlayerReplicationInfo).m_PlayerUnits[i] , attack.m_Target );
					}
					
				}
				
			}
			
		}
	}
}

function SummonHelp(TMPawn attackedPawn, TMPawn attackingPawn)
{
	local TMPawn tempPawn;
	local array<UDKRTSPawn> similarPawns;
	local bool bIsTransforming;
	local TMComponentAlchTransf transfComp;

	if(false == class'UDKRTSPawn'.static.IsValidPawn(attackedPawn))
	{
		return;
	}
	
	foreach attackedPawn.OverlappingActors(class'TMPawn', tempPawn, attackedPawn.m_Unit.m_helpRadius, attackedPawn.Location, true)
	{
		bIsTransforming = false;

		if(tempPawn.GetTransformComponent() != None)
		{
			transfComp = TMComponentAlchTransf(tempPawn.GetTransformComponent());

			if(transfComp != None)
			{
				bIsTransforming = transfComp.m_IsTransforming;
			}
		}

		//need to find allies around us that can help us
		if(tempPawn != none && 
		   TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId == TMPlayerReplicationInfo(attackedPawn.OwnerReplicationInfo).allyId && 
		   tempPawn.Health > 0 && 
		   tempPawn.m_currentState == TMPS_IDLE
		   && !bIsTransforming)
		{
			similarPawns.AddItem( tempPawn );
		}
	}
	if( similarPawns.Length > 0)
	{
		attackedPawn.HandleCommand(C_Attack,false,,attackingPawn, similarPawns, false);
	}
}

function AddAllyInfo(TMAllyInfo allyInfoToAdd)
{
	mAllyInfos.AddItem(allyInfoToAdd);
}

function RemoveAllyInfo(TMAllyInfo allyInfoToRemove)
{
	mAllyInfos.RemoveItem(allyInfoToRemove);
}

function bool IsAuthority()
{
	return ((WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone));
}

/**
 * Returns the TMPlayerReplicationInfo as per the TMController Interface's spec.
 */
function TMPlayerReplicationInfo GetTMPRI()
{
	return TMPlayerReplicationInfo(PlayerReplicationInfo);
}

/**
 * Returns bHasDied as per the TMController Interface's spec.
 */
function bool HasDied()
{
	return bHasDied;
}

/**
 * Sets bHasDied as per the TMController Interface's spec.
 */
function SetHasDied(bool HasDied)
{
	bHasDied = HasDied;
}

/**
 * Getters & Setters for CommanderType as per the TMController Interface's spec.
 */
function string GetCommanderType()
{
	return commanderType;
}
function SetCommanderType(string unitTypeOfCommander)
{
	commanderType = unitTypeOfCommander;
}

exec function RefillAbility()
{

	local TMPawn pawnItr;
	foreach AllActors(class'TMPawn', pawnItr)
	{
		if(pawnItr.GetAbilityComponent() != None)
		{
			pawnItr.GetAbilityComponent().m_fTimeInState = 0.0001f;
			pawnItr.GetAbilityComponent().mCooldown = 0.0001f;
		}
	}
}

exec function PrintTMPawnList()
{
	local int i;
	local array<TMPawn> TMPawnList;

	TMPawnList = GetTMPawnList();
	for(i = 0; i < TMPawnList.Length; ++i)
	{
		`log(TMPawnList[i]@"", true, 'Lang');
	}
	`log("# of TMPawns in TMPawnList: "@TMPawnList.Length, true, 'Lang');	

}

/*
function ClearNoneInTMPawnList()
{
	if(WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_StandAlone)
	{
		TMGameInfo(WorldInfo.Game).mTMPawnList.RemoveItem(none);
	}
	else if(WorldInfo.NetMode == NM_DedicatedServer)
	{
		mTMPawnList.RemoveItem(none);
	}
	`log("Nones in TMPawnList has been cleared", true, 'Lang');
}
*/

simulated function PlayerTick(float dt)
{
	local TMParticleSystem tempParticleSystem;
	local TMTransformer transformer;
	local TMTransformerIcon icon;

	// Update all of the particle systems
	foreach mParticleSystemList( tempParticleSystem )
	{
		tempParticleSystem.Update();
	}
	
	// Give team for transform icons
	if (m_bTransformerIconInit)
	{
		if (self.PlayerReplicationInfo != none)
		{
			foreach self.AllActors(class'TMTransformerIcon', icon)
			{
				if(IsSpectator() == 1)
				{
					icon.PickTextures("Spectator");
				}
				else
				{
					icon.PickTextures(TMPlayerReplicationInfo(self.PlayerReplicationInfo).race);
				}
			}

			// piggybacking this 1-time init to do a transformer list init to remove the need for so many all actors calls
			foreach AllActors(class'TMTransformer', transformer)
			{
				mTransformers.AddItem(transformer);
			}

			m_bTransformerIconInit = false;
		}
	}

	super.PlayerTick(dt);

	// NOTE: This hack exists because free cam code exists in UDKRTSPlayerController but footage friendly mode is in TMPlayerController
	if( bFreeFlyCameraEnabled && AllKeyboardButtonStates[ KE_A ].Pressed )
	{
		if( UDKRTSCamera(PlayerCamera).bAutoMode && !mFootageFriendlyModeEnabled )
		{
			FootageFriendlyMode();
		}
	}

	if (m_AudioManager != None) m_AudioManager.tick();
}

// Used to initialize the post process effect material inst so we can actually use it because
// of some bDelayedGame = true lazy loading BS that prevents the post process from gettin
// properly initialized when we need it
simulated event ReceivedPlayer()
{
	local LocalPlayer LP;
	local MaterialEffect effect;
	
	super.ReceivedPlayer();

	LP = LocalPlayer(Player); 
	if(LP != None) 
	{ 
		LP.RemoveAllPostProcessingChains(); 
		LP.InsertPostProcessingChain(LP.Outer.GetWorldPostProcessChain(),INDEX_NONE,true); 
		if(myHUD != None)
		{
			myHUD.NotifyBindPostProcessEffects();
		}
		
		// Desaturation
		effect = MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess'));
		DesatInst = new(effect) class'MaterialInstanceConstant';
		DesatInst.SetParent(effect.Material);
		effect.Material = DesatInst;
		
		// Damaged commander
		effect = MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DamagePostProcess'));
		DamageInst = new(effect) class'MaterialInstanceConstant';
		DamageInst.SetParent(effect.Material);
		effect.Material = DamageInst;
	}

	if (IsClient())
	{
		// Set volume
		ConsoleCommand(class'TMSoundSettings'.static.LoadVolumeCommand());
	}
}

reliable client function ClientRegisterKill()
{
	killCount++;
	if (!onKillSpree)
	{
		onKillSpree = true;
		killSpreeCount = 1;
		SetTimer(TIME_BETWEEN_KILLS_FOR_KILLSPREE, false, NameOf(ClientEndKillSpree));
	}
	else
	{
		killSpreeCount++;

		ClearTimer(NameOf(ClientEndKillSpree));
		SetTimer(TIME_BETWEEN_KILLS_FOR_KILLSPREE, false, NameOf(ClientEndKillSpree));

		if (killSpreeCount == 2)
		{
			ClientPlayVO(SoundCue'VO_Main.Male_AlliedDoubleKill_Cue', true, true);
		}
		else if (killSpreeCount == 3)
		{
			ClientPlayVO(SoundCue'VO_Main.Male_AlliedTripleKill_Cue', true, true);
		}
	}
}

reliable client function ClientEndKillSpree()
{
	onKillSpree = false;
}

reliable client function ClientPlaySFX(SoundCue cue)
{
		m_AudioManager.requestPlaySFX(cue);
}

reliable client function ClientPlaySFXWithLocation(SoundCue cue, Vector loc)
{
		m_AudioManager.requestPlaySFXWithLocation(cue, loc);
}

reliable client function ClientPlaySFXWithActor(SoundCue cue, Actor actor)
{
		m_AudioManager.requestPlaySFXWithActor(cue, actor);
}

reliable client function ClientPlayVO(SoundCue cue, bool isGameVO, bool shouldCue)
{
	m_AudioManager.requestPlayVO(cue, isGameVO, shouldCue);
}

reliable client function ClientPlayNotification(string notificationText, int timeMillis)
{
	PlayNotification(notificationText, timeMillis);
}

function PlayNotification(string notificationText, int timeMillis)
{
	TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).addNotification(notificationText, timeMillis);
}

exec function Notify(string text)
{
	TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).addNotification(text, 2000);
}

reliable client function shrineDestroyed(int teamid, int killerid)
{
	local array<TMPawn> TMPawnList;
	local TMPawn iterPawn;

	TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).shrineDestroyed(teamid, killerid);

	// Search for nexus for camera kill zoom in
	TMPawnList = GetTMPawnList();
	foreach TMPawnList(iterPawn)
	{
		if(iterPawn.m_Unit.m_UnitName == "Nexus")
		{
			TMCamera(PlayerCamera).UpdateLastDiedCommander(iterPawn);
			return;
		}
	}
}

event InitInputSystem()
{
	local UDKRTSPCPlayerInput pcInput;

	Super.InitInputSystem();
	InputHandlerInactiveCommand = new class'TMInputHandlerCommandInactive';
	InputHandlerActiveCommand = new class'TMInputHandlerCommandActive';
	
	pcInput = UDKRTSPCPlayerInput(PlayerInput);
	pcInput.SetMousePosition(1,1); //// Dru TODO: this is our enemy. causes scrolling at beginning - or not???
	
	InputHandler = InputHandlerInactiveCommand;
	KeyboardEnumSize = EKeyboardEvent.KE_MAX;
	MouseEnumSize = EMouseEvent.EMouseEvent_MAX;
	InitButtonMappings();
}

exec function FoWHide()
{
	mFoWManager.FoWHide();

	//TM_HUD.parentHUD.HideMinimapFOW(true);
	if (!mFootageFriendlyModeEnabled)
	{
		SpectatorUIMode(True);
	}
}

exec function FoWShow()
{
	mFoWManager.FoWShow();

	//TM_HUD.parentHUD.HideMinimapFOW(false);
	if (!mFootageFriendlyModeEnabled)
	{
		if(IsSpectator() == 1)
		{
			SpectatorUIMode(true);
		}
		else
		{
			HideAllHUD(False);
		}
	}
}

exec function FoWDisable()
{
	FoWHide();
	mFoWManager.DisableFoW();
}

exec function FoWEnable()
{
	mFoWManager.EnableFow();
	FoWShow();
}

reliable client function ClientDisableFoW()
{	
	FoWDisable();
}

exec function TMTeamSay( string Msg )
{
	Msg = Left(Msg,128);

	if ( AllowTextMessage(Msg) )
		ServerTMTeamSay(Msg, TMPlayerReplicationInfo(PlayerReplicationInfo).allyId);

	`log(""@TMPlayerReplicationInfo(PlayerReplicationInfo).allyId);
}

function checkForCheatCode(string text)
{
	local string cheatCode;
	foreach m_CheatCodes(cheatCode)
	{
		if ( text ~= cheatCode )
		{
			ConsoleCommand( cheatCode );
		}
	}
}

unreliable server function ServerTMTeamSay( string Msg, int allyId )
{
	local PlayerController PC;

	// center print admin messages which start with #
	//if (PlayerReplicationInfo.bAdmin)
	//{
		foreach WorldInfo.AllControllers(class'PlayerController', PC)
		{
			if (m_tmGameInfo.BroadcastHandler.AllowsBroadCast(self, Len(Msg)) && 
				TMPlayerReplicationInfo(PC.PlayerReplicationInfo).allyId == allyId)
			{
				`log(""@TMPlayerReplicationInfo(PC.PlayerReplicationInfo).allyId);
				PC.ClientAdminMessage(Msg);

				TMPlayerController(PC).TeamMessage(self.PlayerReplicationInfo, Msg, 'TeamSay');
			}
		}
		return;
	//}
}

function byte IsSpectator()
{
	local TMPawn commander;

	if(TMPlayerReplicationInfo(PlayerReplicationInfo).bOnlySpectator)
	{
		return 1;
	}
	
	commander = GetCommander();
	if( commander == None || commander.Health <=0 )
	{
		return 2;
	}
	return 0;
}

/**
 * Prepares this player for the match, initializing the fog of war and
 * beginning to replicate APM statistics.
 * 
 * @param allyIndex
 *      the team index of this player, in case the GRI has not been replicated
 *      yet
 */
reliable client function ClientInitializeMatch(int allyIndex)
{	
	m_allyId = allyIndex;

	TMCamera(PlayerCamera).Initialize(self, allyIndex, mapInfo);

	if(PlayerReplicationInfo != none && IsSpectator() > 0)
	{
		SetTimer(1.f, true, 'UpdateActionCenter');
	}
}

reliable client function ClientInitializeMap(TMFOWMapInfoActor TheMap, int allyId)
{
	mapInfo = TheMap;
	m_allyId = allyId;

	mapInfo.Initialize();

	mFoWManager = Spawn(class'TMFOWManagerClient', self);
	mFoWManager.Initialize(mapInfo, m_allyId);

	`log(WorldInfo.GetMapName(), true, 's');
	m_AudioManager.requestPlayMapTrack(TMMapInfo(WorldInfo.GetMapInfo()).AmbientSoundCue);
}

exec function SetCameraZoom(float newZoom)
{
	ServerSetCameraZoom(newZoom);
}

reliable server function ServerSetCameraZoom(float newZoom)
{
	local TMController tempController;

	foreach m_tmGameInfo.mAllTMControllers(tempController)
	{
		if (TMPlayerController(tempController) != none)
		{
			TMPlayerController(tempController).ClientSetCameraZoom(newZoom);
		}
	}
}

reliable client function ClientSetCameraZoom(float newZoom)
{
	TMCamera(PlayerCamera).SetZoom(newZoom);
}

reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	super.ClientSetHUD(newHUDType);
	TMHUD(myHUD).Initialize(mFoWManager);
}

reliable client function ClientInitRespawn()
{
	local int i;

	if ( TMCamera(PlayerCamera).endGameSpectator )
	{
		TMCamera(PlayerCamera).EndEndGameSpectator();
	}

	if(bCameraLocked)
	{
		bCameraLocked = false; // so that it does not toggle it to false inside LockCameraToCommander
		UnlockCamera();

		SetTimer(0.5f, false, 'LockCameraToCommander' );
	}

	// Reset camera zoom and position settings for players
	if( m_allyId != class'TMGameInfo'.const.SPECTATOR_ALLY_ID )
	{
		InitCameraProperties();
	}

	// HACKY way to reset ability radials
	if (TM_HUD != none)
	{
		TM_HUD.resetAbilityRadials();
	}

	// Clear all ability objects
	m_TarSplotches.Remove( 0, m_TarSplotches.Length );

	for( i = m_SniperMines.Length-1; i >= 0; i-- )
	{
		m_SniperMines[ i ].ExplodeMine();
	}

	for( i = m_RamBamQueenEggAbilityObjects.Length-1; i >= 0; i-- )
	{
		m_RamBamQueenEggAbilityObjects[i].Stop();
	}
	m_RamBamQueenEggAbilityObjects.Remove( 0, m_RamBamQueenEggAbilityObjects.Length );
}


reliable client function ClientDesaturateScreen(bool bDesaturate)
{
	if( Player == none )
	{
		// TODO: make it so this isn't even called if Player is none
		return;
	}

	if (bDesaturate)
	{
		DesatInst.SetScalarParameterValue('DesaturateAmount', 1);
		MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess')).Material = DesatInst;
		LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess').bShowInGame = true;
		LocalPlayer(Player).TouchPlayerPostProcessChain();
		
	}
	else
	{
		DesatInst.SetScalarParameterValue('DesaturateAmount', 0);
		MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess')).Material = DesatInst;
		LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess').bShowInGame = false;
		LocalPlayer(Player).TouchPlayerPostProcessChain();
	}
}

reliable client function ClientDecideStartSpectating( bool endGame = true)
{
	if(endGame)
	{
		SetTimer(3, false, 'StartEndGameSpectatorIfNoRespawnIsLeftBlahBlah');
	}
}

function StartEndRoundSpectator()
{
	TMCamera(PlayerCamera).StartEndGameSpectator();
}

function StartEndGameSpectatorIfNoRespawnIsLeftBlahBlah()
{
	local TMPawn commander;
	commander = GetCommander();
	if(commander == None || commander.Health <= 0 && GetTMPRI().bNotRespawning)
	{
		TMCamera(PlayerCamera).StartEndGameSpectator();
		//DesaturateScreen( false ); // Players are going to get so confused, I'm not doing this - Dru
	}
}

function DesaturateScreen(bool bDesaturate)
{
	if(LocalPlayer(Player) == None)
	{
		return;
	}


	if (bDesaturate)
	{
		DesatInst.SetScalarParameterValue('DesaturateAmount', 1);
		MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess')).Material = DesatInst;
		LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess').bShowInGame = true;
		LocalPlayer(Player).TouchPlayerPostProcessChain();
		
	}
	else
	{
		DesatInst.SetScalarParameterValue('DesaturateAmount', 0);
		MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess')).Material = DesatInst;
		LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DesaturatePostProcess').bShowInGame = false;
		LocalPlayer(Player).TouchPlayerPostProcessChain();
	}
}

reliable client function CommanderDamaged(float DamageTaken, bool IsAlive)
{
	if (IsAlive)
	{
		DamageLastMoment += DamageTaken;
		SetTimer(0.1f, true, NameOf(DecreaseDamageLastMoment));
	}
}

simulated function DecreaseDamageLastMoment()
{
	DamageLastMoment *= 0.9f;
	if (DamageLastMoment < 10)
	{
		ClearTimer(NameOf(DecreaseDamageLastMoment));
	}

	DamageInst.SetScalarParameterValue('DamageRatio', DamageLastMoment / 500);
	MaterialEffect(LocalPlayer(Player).PlayerPostProcess.FindPostProcessEffect('DamagePostProcess')).Material = DamageInst;
	LocalPlayer(Player).TouchPlayerPostProcessChain();
}

simulated function DelayedRestartPlayer()
{
	ServerRestartPlayer();
}

function RespawnIn(float seconds)
{
	SetTimer(seconds, false, NameOf(DelayedRestartPlayer));
}

/**
 * type = 0 // Off
 * type = 1-6 // Quality levels
 */
exec function SetAntiAliasing(int type)
{
	local PostProcessEffect PPE;

	Clamp(type, 0, 6);

	PPE = LocalPlayer(Player).GetPostProcessChain(0).FindPostProcessEffect('GeneralPostProcess');
	UberPostProcessEffect(PPE).PostProcessAAType = EPostProcessAAType(type);
}

exec function ToggleHealthBars()
{
	switch (TMHUD(myHUD).eHealthBarVisibility)
	{
	case ALWAYS:
		TMHUD(myHUD).eHealthBarVisibility = NEVER;
		BREAK;
	case NEVER:
		TMHUD(myHUD).eHealthBarVisibility = DAMAGED;
		BREAK;
	case DAMAGED:
		TMHUD(myHUD).eHealthBarVisibility = ALWAYS;
		BREAK;
	}
}

exec function SetHealthBarVisibility(HealthBarVisibility v)
{
	TMHUD(myHUD).eHealthBarVisibility = v;
}

//// Dru TODO: What is the purpose of this function? 
reliable client function ClientArbitratedMatchEnded()
{
	super.ClientArbitratedMatchEnded();
}

reliable server function ServerRestartPlayer()
{
	//`log("ServerRestartPlayer called. Player:"@self.PlayerId, true, 'Lang');
	m_tmGameInfo.RestartPlayer(self);
}

exec function ChangePopulationCap(int newCap)
{
	UDKRTSPlayerReplicationInfo(self.PlayerReplicationInfo).PopulationCap = newCap;
}

exec function su(string unitType)
{
	SpawnUnit(unitType);
}

exec function SpawnUnit(string unitType)
{
	ServerSpawnUnit(unitType);
}

exec function SpawnNUnits(int unitCount, string unitType)
{
	SeverSpawnMany(unitCount, unitType);
}

exec function SpawnMany()
{
	SeverSpawnMany();
}

exec function PrintPawnMap()
{
	local array<HashMapEntry> table;
	local HashMapEntry entry;
	table = m_PawnHash.getTable();

	foreach table(entry)
	{
		if(entry.value != None)
		{
			`log(string(entry.key) @ TMPawn(entry.value).m_UnitType @ string(TMPawn(entry.value).pawnId), true, 'Graham');
		}
	}
}

exec function PrintPawnID(int id)
{
	local TMPawn f_pawn;
	f_pawn = TMPawn(m_PawnHash.GetByIntKey(id));
	`log("Input:" @ string(id) @ "   ID:" @ f_pawn.pawnId @ "   Type:" @ f_pawn.m_UnitType, true, 'Graham');
}

//// Dru TODO: delete?
exec function DoughBoyAttackAnimation()
{
	local TMPawn lPawn;
	local TMAnimationFe animation;
	
	foreach self.AllActors(class'TMPawn', lPawn)
	{
		if(lPawn.m_UnitType == "DoughBoy")
		{
			animation = new () class'TMAnimationFe';
			animation.m_commandType = "Attack";
			animation.m_pawnID = lPawn.pawnId;
			lPawn.m_Unit.ReceiveFastEvent(animation.toFastEvent());
		}
	}
}

exec function PrintPawnMap2()
{
	ServerPrintPawnMap();
}

reliable server function ServerPrintPawnMap()
{
	TMGameInfo(self.WorldInfo.Game).PrintPawnz();
}


function UpdateUnits()
{
	`log("updating units");
	ServerUpdateUnits();
}


exec function FatLoot()
{
	if( !bUseCheats )
	{
		return;
	}

	SeverSpawnMany();
	ClientPlayNotification("You Acquired Some Fat Loot", 1000);
}

reliable server function ServerMakeUnitJump(int pawnId)
{
	local vector impulse;
	local TMPawn f_pawn;
	
	f_pawn = GetPawnByID(pawnId);

	if(f_pawn != None)
	{
		// Apply the knockback to the target using impulse
		impulse.X = 0;
		impulse.Y = 0;
		impulse.Z = 1;
		impulse *= 1000;
		f_pawn.AddVelocity(impulse, f_pawn.Location, class'DamageType');
	}
}

function MakeAllMyUnitsJump()
{
	local TMPawn f_pawn;

	foreach GetTMPRI().m_PlayerUnits(f_pawn)
	{
		if(f_pawn != none)
		{
			ServerMakeUnitJump(f_pawn.pawnId);
		}
	}
}

exec function Rhea()
{
	if( !bUseCheats )
	{
		return;
	}

	MakeAllMyUnitsJump();
	ClientPlayNotification("The Maestros, Now With Occulus Rift!", 1000);
}

exec function Cole()
{
	if( !bUseCheats )
	{
		return;
	}

	ColeEverywhere();
}

exec function Miralab()
{
	local TMRain rain;
	rain = TMCamera(self.PlayerCamera).rain;

	if (!m_bMiralab)
	{
		m_PreviousRainIntensity = rain.m_fIntensity;
		rain.m_fIntensity = 1.0f;
		//rain.m_waterPlane.SetHidden(false);
		ClientPlayNotification("ACQUATIC-RETRO-FUTURISM", 1000);
	}
	else
	{
		//rain.m_waterPlane.SetHidden(true);
		rain.m_fIntensity = m_PreviousRainIntensity;
	}

	m_bMiralab = !m_bMiralab;
}

function ColeEverywhere()
{
	local TMPawn outPawn;
	local MaterialInstanceConstant MatInst;

	if( !bUseCheats )
	{
		return;
	}

	if ( !m_bCole )
	{
		foreach AllActors(class'TMPawn', outPawn)
		{
			if (outPawn.m_UnitType == "Droplet" || outPawn.m_UnitType == "Slender" || outPawn.m_UnitType == "Brute" )
			{
				outPawn.Mesh.SetSkeletalMesh(SkeletalMesh(DynamicLoadObject("TM_Coal.Coal",class'SkeletalMesh',false)));
				outPawn.Mesh.SetScale(outPawn.m_Unit.m_scale);

				MatInst = MaterialInstanceConstant( DynamicLoadObject("TM_Coal.Masters.Mat_Coal", class'MaterialInstanceConstant', false ) );
				outPawn.Mesh.SetMaterial(0, MatInst);
			}
		}

		ClientPlayNotification("COLE EVERYWHERE", 1000);
	}
	else
	{
		foreach AllActors(class'TMPawn', outPawn)
		{
			if (outPawn.m_UnitType == "Droplet" || outPawn.m_UnitType == "Slender" || outPawn.m_UnitType == "Brute" )
			{
				outPawn.m_Unit.m_Data.m_skeletalMesh = SkeletalMesh(DynamicLoadObject(outPawn.m_Unit.m_meshName,class'SkeletalMesh',false));
				outPawn.Mesh.SetSkeletalMesh(outPawn.m_Unit.m_Data.m_skeletalMesh);
				outPawn.Mesh.SetScale(outPawn.m_Unit.m_scale);
				
				if ( outPawn.m_UnitType == "Droplet" )
				{
					MatInst = MaterialInstanceConstant( DynamicLoadObject("TM_Droplet.droplet_TF_MAT", class'MaterialInstanceConstant', false ) );
				}
				else if ( outPawn.m_UnitType == "Slender" )
				{
					MatInst = MaterialInstanceConstant( DynamicLoadObject("TM_Slender.Materials.Slender_Unit_Mat_INST", class'MaterialInstanceConstant', false ) );
				}
				else if ( outPawn.m_UnitType == "Brute" )
				{
					MatInst = MaterialInstanceConstant( DynamicLoadObject("TM_Brute.Materials.Brute_Unit_Mat_INST", class'MaterialInstanceConstant', false ) );
				}
				outPawn.Mesh.SetMaterial(0, MatInst);
				//outPawn.UpdateTeamMaterials();
			}
		}
	}

	m_bCole = !m_bCole;
}

function TMPawn GetClosestPawnTo(TMPawn goalPawn, array<TMPawn> from)
{
	local TMPawn closestPawn;
	local TMPawn outPawn;
	local float closestDistance;
	local float distance;
	closestDistance = 100000.0f;

	foreach from( outPawn )
	{
		distance = VSize( outPawn.Location - goalPawn.Location );
		if ( distance < closestDistance )
		{
			closestPawn = outPawn;
			closestDistance = distance;
		}
	}

	return closestPawn;
}

function FastSocialClues(TMPawn lastPawn, array<TMPawn> remainingPawns)
{
	local TMPawn closestPawn;
	local array<TMPawn> shortArray;

	closestPawn = GetClosestPawnTo(lastPawn, remainingPawns);
	shortArray.AddItem(closestPawn);
	closestPawn.DoMoveCommand( lastPawn.Location, true, shortArray, lastPawn,,);
	
	shortArray = copyPawnsArray(remainingPawns);
	shortArray.RemoveItem( closestPawn );

	if ( shortArray.Length > 0 )
	{
		FastSocialClues( closestPawn, shortArray );
	}
}

function array<TMPawn> copyPawnsArray(array<Tmpawn> arrayToCopy)
{
	local TMPawn outPawn;
	local array<TMpawn> copiedArray;

	foreach arrayToCopy(outPawn)
	{
		copiedArray.AddItem(outPawn);
	}

	return copiedArray;
}  

function StartFastSocialClues()
{
	local array<TMPawn> pawns;
	local TMPawn pawn0;

	pawns = copyPawnsArray( GetTMPRI().m_PlayerUnits );
	pawn0 = pawns[0];	
	pawns.RemoveItem( pawn0 );

	FastSocialClues( pawn0, pawns );
}

/* New Social Clues Method */
exec function SocialClues()
{
	local array<TMPawn> pawns;
	local TMPawn pawn0;
	local Vector forwardLocation;

	pawn0 = GetTMPRI().m_PlayerUnits[0];
	pawns.AddItem( pawn0 );
	forwardLocation = pawn0.Location + Vect(500.0f, 0.f, 0.f);
	pawn0.DoMoveCommand( forwardLocation, true, pawns, None, , ); // Start Moving your commander
	SetTimer( 0.4f, false, NameOf(StartFastSocialClues) );
	
	ClientPlayNotification("Sherlock says, \"Make a line\" behind"@TMPawn(Pawn).m_UnitType, 1000);
}

reliable client function ClientSetObjectiveText(string text)
{
	mObjectiveText = text;
	if ( TM_HUD != None )
	{
		TM_HUD.setGameTypeText( text );
	}
}

exec function Bloom()
{
	local TMComponent comp;
	local int i;

	if (m_BloomCheatActive)
	{
		for (i = 0; i < TMPawn(Pawn).m_Unit.m_componentArray.Length; ++i )
		{
			comp = TMPawn(Pawn).m_Unit.m_componentArray[i];
			if ( comp.IsA('TMAbilityBloom') )
			{
				TMAbilityBloom(comp).ShouldSpawnGrass(false);
			}
		}
		m_BloomCheatActive = false;		
	}
	else
	{
		for (i = 0; i < TMPawn(Pawn).m_Unit.m_componentArray.Length; ++i )
		{
			comp = TMPawn(Pawn).m_Unit.m_componentArray[i];
			if ( comp.IsA('TMAbilityBloom') )
			{
				TMAbilityBloom(comp).ShouldSpawnGrass(true);
				m_BloomCheatActive = true;
			}
		}

		if ( !m_BloomCheatActive )
		{
			comp = new () class'TMAbilityBloom';
			comp.SetUpComponent(none, TMPawn(Pawn));
			TMPawn(Pawn).m_Unit.m_componentArray.AddItem(comp);
			m_BloomCheatActive = true;
		}

		ClientPlayNotification("BLOOM BLOOM BLOOM BLOOM BLOOM", 1000);
	}
}

reliable server function ServerUpdateUnits()
{
	TMGameInfo(self.WorldInfo.Game).UpdateUnits();
}

reliable client function ClientRemoveTMPawnFromTMPawnList(int pawnID)
{
	local int i;
	local TMPawn targetPawn;

	targetPawn = none;
	for(i = 0; i < mTMPawnList.Length; ++i)
	{
		if(mTMPawnList[i].pawnId == pawnId)
		{
			targetPawn = mTMPawnList[i];
			break;
		}
	}

	if(targetPawn == none)
	{
		return;
	}

	mTMPawnList.RemoveItem(targetPawn);
	//`log(targetPawn@" is removed from client list", true, 'Lang');
}

simulated function AddTMPawnToTMPawnList(TMPawn pw)
{
	mTMPawnList.AddItem(pw);
	//`log(pw@" is added to mTMPawnList in "@self, true, 'Lang');
}

reliable client function ClientRemovePawnFromHash(int pawnID)
{
	// `log("Told to remove PawnID"@pawnID@"from hash", true, 'Graham');
	m_PawnHash.RemoveByIntKey(pawnID);
}

simulated function AddPawnToHash(int pawnId, TMPawn pw)
{
	m_PawnHash.PutByIntKey(pawnId, pw);
}

reliable server function SeverSpawnMany( int count = 15, string unitType = "NoUnitType")
{
	local int i;

	if ( unitType == "NoUnitType" )
	{
		unitType = GetTMPRI().raceUnitNames[0];
	}

	for(i= 0; i<count;i++)
	{
		TMGameInfo(WorldInfo.Game).RequestUnit(unitType, GetTMPRI(), Pawn.Location,false, Vect(100.f,0.f,100.f), None);
	}
}

reliable server function ServerTellTheGameInfoToSpawnThePing(int allyId, Vector loc, int type)
{
	TMGameInfo(self.WorldInfo.Game).TellClientsToSpawnPing(allyId, loc, type);
}

reliable client function ClientSpawnPing(int allyId, Vector loc, int type)
{
	local TMMapPing ping;
	ping = Spawn(class'TMMapPing',,, loc);
	ping.Init(allyId, loc, type);

	if (allyId == TMPlayerReplicationInfo(PlayerReplicationInfo).allyId)
	{
		if (type == 0)
		{
			m_AudioManager.requestPlaySFX(SoundCue'SFX_Notification.Notification_Alert_Cue');
		}
		else
		{
			m_AudioManager.requestPlaySFX(SoundCue'SFX_Notification.Notification_Ping_Cue');
		}
	}
}

reliable client function ClientSpawnBotPing(int allyId, Vector loc, int type) 	// spawns a ping without the ping noise, allows debugging bot movement
{
	local TMMapPing ping;
	ping = Spawn(class'TMMapPing',,, loc);
	ping.Init(allyId, loc, type);
}

unreliable client function ClientDrawDebugCircle(Vector inOrigin, float inRadius, byte inR, byte inG, byte inB) 	// NOTE: this is for debug only, expensive function
{
	self.DrawDebugCylinder( inOrigin, inOrigin, inRadius, 32, inR, inG, inB);
}

unreliable client function ClientDrawDebugTextOnPawn(string inText, TMPawn inAttachPawn, Vector inOffset, optional float inDuration)
{
	self.DrawDebugString(inOffset, inText, inAttachPawn,, inDuration);
}

reliable server function ServerSpawnUnit(string unitType)
{
	TMGameInfo(self.WorldInfo.Game).RequestUnit(unitType, TMPlayerReplicationInfo(self.PlayerReplicationInfo), Vect(500.f,100.f,500.f),false, Vect(100.f,0.f,100.f), None);
}

/*
reliable server function ServerSpawnUnitAtPos(string unitType, vector position)
{
	`log("Server spawning unit", true, 'Graham');
	TMGameInfo(self.WorldInfo.Game).RequestUnit(unitType, TMPlayerReplicationInfo(self.PlayerReplicationInfo), position, false, position, None);
}
*/

reliable server function ServerSpawnUnitAtPos(string unitType, vector position, int pawnID)
{
	local TMPawn f_pawn;
	local TMPlayerReplicationInfo repInfo;

	`log("Server spawning unit", true, 'Graham');
	// TMGameInfo(self.WorldInfo.Game).RequestUnit(unitType, TMPlayerReplicationInfo(self.PlayerReplicationInfo), position, false, position, None);
	
	foreach self.AllActors(class'TMPawn', f_pawn)
	{
		if(f_pawn.pawnId == pawnID)
		{
			repInfo = TMPlayerReplicationInfo(f_pawn.OwnerReplicationInfo);
		}
	}

	if(repInfo == None)
	{
		`log("Pawn ID not found on server", true, 'Graham');
	}

	TMGameInfo(self.WorldInfo.Game).RequestUnit(unitType, repInfo, position, false, position, None);
}


reliable server function ServerDestroyPawn(int unitID)
{
	// GGH TODO: Refactor to use m_PawnHash
	local TMPawn f_pawn;
	
	foreach self.AllActors(class'TMPawn', f_pawn)
	{
		if(f_pawn.pawnId == unitID)
		{
			// GGH:
			m_PawnHash.RemoveByIntKey(f_pawn.pawnId);
			f_pawn.Destroy();
		}
	}
}




function SendServerFastEvent(TMFastEventInterface event)
{
	local TMFastEvent fe;

	// break it down
	fe = event.toFastEvent();

	//send it off
	ServerExecuteFastEvent(fe.commandType,
							fe.pawnId,
							fe.PawnIDs1,
							fe.PawnIDs2,
							fe.PawnIDs3,
							fe.PawnIDs4,
							fe.targetId, 
							fe.position1, 
							fe.position2, 
							fe.float1, 
							fe.floats, 
							fe.int1, 
							fe.ints, 
							fe.string1, 
							fe.strings, 
							fe.bool1, 
							fe.bools);
}

reliable server function ServerExecuteFastEvent(
	string commandType, 
	int pawnId,
	intArray PawnIDs1,
	intArray PawnIDs2,
	intArray PawnIDs3,
	intArray PawnIDs4,
	int targetId, 
	Vector position1, 
	Vector position2, 
	float float1,
	floatArray floats,
	int int1,
	intArray ints,
	string string1,
	stringArray strings,
	bool bool1,
	boolArray bools)
{
	local TMFastEvent fe;
	local TMPawn f_pawn;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.PawnIDs1 = PawnIDs1;
	fe.PawnIDs2 = PawnIDs2;
	fe.PawnIDs3 = PawnIDs3;
	fe.PawnIDs4 = PawnIDs4;
	fe.targetId = targetId;
	fe.position1 = position1;
	fe.position2 = position2;
	fe.float1 = float1;
	fe.floats = floats;
	fe.int1 = int1;
	fe.ints = ints;
	fe.string1 = string1;
	fe.strings = strings;
	fe.bool1 = bool1;
	fe.bools = bools;

	if(fe.commandType == "RecivedUnitCache")
	{
		m_tmGameInfo.m_recievedUnitCache.AddItem( PlayerId );
		return;
	}

	f_pawn = GetPawnByID( pawnId );

	if(f_pawn != None && f_pawn.Controller == m_tmGameInfo.m_TMNeutralPlayerController)
	{
		m_tmGameInfo.HandleFastEvent(GetTMPRI(), f_pawn, fe, true);
	}
	else
	{
		m_tmGameInfo.HandleFastEvent(GetTMPRI(), f_pawn, fe, false);
	}
}

function ServerPassFastEventToClient(TMFastEvent fe)
{
	self.ClientReceiveFastEvent(fe.commandType,
							fe.pawnId,
							fe.PawnIDs1,
							fe.PawnIDs2,
							fe.PawnIDs3,
							fe.PawnIDs4,
							fe.targetId, 
							fe.position1, 
							fe.position2, 
							fe.float1, 
							fe.floats, 
							fe.int1, 
							fe.ints, 
							fe.string1, 
							fe.strings, 
							fe.bool1, 
							fe.bools);
}


reliable client function ClientReceiveFastEvent(
	string commandType, 
	int pawnId,
	intArray PawnIDs1,
	intArray PawnIDs2,
	intArray PawnIDs3,
	intArray PawnIDs4,
	int targetId, 
	Vector position1, 
	Vector position2, 
	float float1,
	floatArray floats,
	int int1,
	intArray ints,
	string string1,
	stringArray strings,
	bool bool1,
	boolArray bools)
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.commandType = commandType;
	fe.pawnId = pawnId;
	fe.PawnIDs1 = PawnIDs1;
	fe.PawnIDs2 = PawnIDs2;
	fe.PawnIDs3 = PawnIDs3;
	fe.PawnIDs4 = PawnIDs4;
	fe.targetId = targetId;
	fe.position1 = position1;
	fe.position2 = position2;
	fe.float1 = float1;
	fe.floats = floats;
	fe.int1 = int1;
	fe.ints = ints;
	fe.string1 = string1;
	fe.strings = strings;
	fe.bool1 = bool1;
	fe.bools = bools;

	GotFastEvent(fe);
}

reliable client function ClientUpdateStats(int inPlayerID, int StatToUpdate)
{
	local TMPlayerReplicationInfo tempTMPRI;

	foreach AllActors(class'TMPlayerReplicationInfo', tempTMPRI)
	{
		if ( tempTMPRI.PlayerID == inPlayerID )
		{
			tempTMPRI.mStats[StatToUpdate]++;
		}
	}
}

simulated function bool CheckCachedSpawnedFEs(int id)
{
	local int i;
	local TMPawn f_pawn;

	if( m_cachedSpawnFes.Length == 0)
	{
		return false;
	}

	for(i=0;i< m_cachedSpawnFes.Length; i++)
	{
		if(m_cachedSpawnFes[i].pawnId == id)
		{
			f_pawn = GetPawnById( id );
			if(f_pawn != none)
			{
				f_pawn.ReceiveFastEvent( m_cachedSpawnFes[i] );
			}

			m_cachedSpawnFes.RemoveItem( m_cachedSpawnFes[i] );
			
			return true;
		}
	}

	return false;
}

function Vector hitLocOnVolumeFromTrace(BlockingVolume iterVolume, Vector traceOrigin, Vector traceDestination)
{
	local Vector innerHitNorm;
	local BlockingVolume iterVolumeInner;
	local Vector hitLoc;

	foreach TraceActors(class'BlockingVolume', iterVolumeInner, hitLoc, innerHitNorm, traceDestination, traceOrigin)
	{
		if (iterVolumeInner == iterVolume)
		{
			return hitLoc;
		}
	}

	return vect(0.f, 0.f, 0.f);
}

function Vector castInOriginFrom(BlockingVolume iterVolume, Vector originallyIssuedPosition, float castZ)
{
	local Vector direction;
	local Vector castInOrigin;

	direction = Normal(originallyIssuedPosition - iterVolume.CollisionComponent.Bounds.Origin);
	castInOrigin = iterVolume.CollisionComponent.Bounds.Origin + (direction * (iterVolume.CollisionComponent.Bounds.SphereRadius * 10.f));
	castInOrigin.Z = castZ;

	return castInOrigin;
}

function Vector findNearPathableLocation(Vector originallyIssuedPosition, TMPawn issuedPawn)
{
	local Vector nearPathableLocation;
	local BlockingVolume iterVolume;
	local Vector hitLoc;
	local Vector hitNorm;
	local Vector volumeOriginHitLoc;
	local Vector pawnOriginHitLoc;
	local float volumeOriginHitDistance;
	local float pawnOriginHitDistance;
	local Vector closerHitLoc;
	local Vector direction;
	local Vector castInOrigin;

	// Trace straight up and determine if originallyIssuedPosition is in a blocking volume
	foreach TraceActors(class'BlockingVolume', iterVolume, hitLoc, hitNorm, originallyIssuedPosition, originallyIssuedPosition + vect(0.f, 0.f, 1000.f))
	{
		volumeOriginHitDistance = 100000000.f; // arbitrarily large number
		pawnOriginHitDistance = 100000000.f; // arbitrarily large number

		castInOrigin = castInOriginFrom(iterVolume, originallyIssuedPosition, issuedPawn.Location.Z);
		volumeOriginHitLoc = hitLocOnVolumeFromTrace(iterVolume, castInOrigin, originallyIssuedPosition);		
		if (volumeOriginHitLoc != vect(0.f, 0.f, 0.f))
		{
			volumeOriginHitDistance = VSizeSq2D(originallyIssuedPosition - volumeOriginHitLoc);
		}
		
		pawnOriginHitLoc = hitLocOnVolumeFromTrace(iterVolume, issuedPawn.Location, originallyIssuedPosition);
		if (pawnOriginHitLoc != vect(0.f, 0.f, 0.f))
		{
			pawnOriginHitDistance = VSizeSq2D(originallyIssuedPosition - pawnOriginHitLoc);
		}

		if (volumeOriginHitDistance == 100000000.f && pawnOriginHitDistance == 100000000.f)
		{
			return vect(0.f, 0.f, 0.f);
		}

		if (pawnOriginHitDistance < volumeOriginHitDistance) 
		{
			closerHitLoc = pawnOriginHitLoc;
			direction = Normal(issuedPawn.Location - originallyIssuedPosition);
		} else
		{
			closerHitLoc = volumeOriginHitLoc;
			direction = Normal(castInOrigin - originallyIssuedPosition);
		}

		// if our guesses didn't get us close, just abort
		if ( Vsize(closerHitLoc - originallyIssuedPosition) > 300.f) 
		{
			return vect(0.f, 0.f, 0.f);
		}

		nearPathableLocation = closerHitLoc + (direction * issuedPawn.GetCollisionRadius() * 1.5f);
		nearPathableLocation.Z = originallyIssuedPosition.Z;

		//DrawDebugLine(closerHitLoc, closerHitLoc + vect(0,0,1000), 0, 255, 0, true); // hitloc - green
		//DrawDebugLine(castInOrigin, castInOrigin + vect(0,0,1000), 255, 0, 0, true); // cast origin - red
		//DrawDebugLine(nearPathableLocation, nearPathableLocation + vect(0,0,1000), 0, 0, 255, true); // near pathable - blue

		if (!UDKRTSAIController(issuedPawn.Controller).GeneratePathTo(nearPathableLocation, issuedPawn.GetCollisionRadius(), true))
		{
			return vect(0.f, 0.f, 0.f);
		}

		return nearPathableLocation;
	}

	return vect(0.f, 0.f, 0.f);
}

function bool positionInSalvatorSnake(Vector position)
{
	local TMSalvatorSnake iterSnake;

	foreach mSalvatorSnakes( iterSnake )
	{
		if ( VSize2D( iterSnake.Location - position ) < iterSnake.GetCollisionRadius() && iterSnake.mAllyID == GetTMPRI().allyId )
		{
			return true;
		}
	}

	return false;
}

/** Moves a group of pawns to a formation on the given point, falling back on
 *  the existing pathfinding if it cannot form correctly */
function MakeMovementGrouped2( array<TMPawn> pawns, TMFastEvent fe )
{
	local TMPawn f_pawn;
	local Vector centerOfGroup;
	local Vector originallyIssuedPosition;
	local float stdDeviation;
	local bool reachable;
	local bool pathable;
	local Vector nearPathableLocation;
	local TMGroup group;
	local bool bSomebodyCouldPath;

	originallyIssuedPosition = fe.position1;
	fe.position2 = fe.position1;

	/* Make sure we get a pathable position before doing more work */
	if ( IsAuthority())
	{
		foreach pawns(f_pawn)
		{
			reachable = UDKRTSAIController(f_pawn.Controller).IsPointReachable(originallyIssuedPosition);
			pathable = UDKRTSAIController(f_pawn.Controller).GeneratePathTo(originallyIssuedPosition, f_pawn.GetCollisionRadius(), true);

			if (!reachable && !pathable)
			{
				nearPathableLocation = findNearPathableLocation(originallyIssuedPosition, f_pawn);

				// If this guy can't path, see if somebody else can.
				if (nearPathableLocation == vect(0.f, 0.f, 0.f))
				{
					continue;
				}

				originallyIssuedPosition = nearPathableLocation;
				fe.position1 = nearPathableLocation;
				fe.position2 = nearPathableLocation;
				break;
			}
			bSomebodyCouldPath = true;
		}
		
		if (!bSomebodyCouldPath)
		{
			return; // if you issue this command (into, e.g. the water), current movements will stop, which feels bad.

		}
	}

	if (pawns.Length == 1)
	{
		pawns[0].ReceiveFastEvent(fe);
		return;
	}

	/* If our point is near the center of us, just move directly to it */
	centerOfGroup = class'UDKRTSPawn'.static.SmartCenterOfGroup(pawns, stdDeviation);
	if ( VSize( centerOfGroup - originallyIssuedPosition ) < stdDeviation * 2.f )
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
		return;
	}

	// if we're too spread out, don't grouped move
	if ( stdDeviation > class'UDKRTSPlayerController'.static.calculateMaxStdDevForGroupedMove(pawns) )
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
		return;
	}

	// Don't grouped move to Salvator portals, or else units may not enter the portal
	if ( positionInSalvatorSnake(fe.position1) )
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
		return;
	}

	/* Finally, do a "grouped" move */
	if ( IsAuthority())
	{
		group = class'TMGroup'.static.MakeGroup(pawns, centerOfGroup, originallyIssuedPosition, stdDeviation);
		group.DoGroupedMove(fe);
	}
}

/** Moves a group of pawns to a formation on the given point, falling back on
 *  the existing pathfinding if it cannot form correctly */
function MakeMovementGrouped( array<TMPawn> pawns, TMFastEvent fe )
{
	local TMPawn f_pawn;
	local Vector centerOfGroup;
	local Vector offset;
	local Vector originallyIssuedPosition;
	local float stdDeviation;
	local bool reachable;
	local bool pathable;
	local Vector nearPathableLocation;
	local TMPawn leadPawn;
	local bool bSomebodyCouldPath;

	originallyIssuedPosition = fe.position1;
	fe.position2 = fe.position1;

	/* Make sure we get a pathable position before doing more work */
	if ( IsAuthority())
	{
		foreach pawns(f_pawn)
		{
			reachable = UDKRTSAIController(f_pawn.Controller).IsPointReachable(originallyIssuedPosition);
			pathable = UDKRTSAIController(f_pawn.Controller).GeneratePathTo(originallyIssuedPosition, f_pawn.GetCollisionRadius(), true);

			if (!reachable && !pathable)
			{
				nearPathableLocation = findNearPathableLocation(originallyIssuedPosition, f_pawn);
				
				// If this guy can't path, see if somebody else can.
				if (nearPathableLocation == vect(0.f, 0.f, 0.f))
				{
					continue;
				}

				originallyIssuedPosition = nearPathableLocation;
				fe.position1 = nearPathableLocation;
				fe.position2 = nearPathableLocation;
				break;
			}
			bSomebodyCouldPath = true;
		}
		
		if (!bSomebodyCouldPath)
		{
			return; // if you issue this, current movements will stop which feels bad.
		}
	}

	if (pawns.Length == 1)
	{
		pawns[0].ReceiveFastEvent(fe);
		return;
	}

	/* If our point is near the center of us, just move directly to it */
	centerOfGroup = class'UDKRTSPawn'.static.SmartCenterOfGroup(pawns, stdDeviation);
	if ( VSize( centerOfGroup - originallyIssuedPosition ) < stdDeviation * 2.f )
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
		return;
	}

	// if we're too spread out, don't grouped move
	if ( stdDeviation > class'UDKRTSPlayerController'.static.calculateMaxStdDevForGroupedMove(pawns) )
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
		return;
	}

	// Don't grouped move to Salvator portals, or else units may not enter the portal
	if ( positionInSalvatorSnake(fe.position1) )
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
		return;
	}

	/* Finally, do a "grouped" move with the same offset you currently have from the group's center */
	leadPawn = TMPawn(class'UDKRTSPawn'.static.MostCentralPawn(pawns));
	foreach pawns( f_pawn )
	{
		fe.position1 = originallyIssuedPosition;
		offSet = f_pawn.Location - centerOfGroup;
		fe.position1 = originallyIssuedPosition + offSet;

		/* If you're far from the group, collapse back in */
		if ( VSize( fe.position1 - originallyIssuedPosition ) > stdDeviation )
		{
			fe.position1 = originallyIssuedPosition + Normal( offSet ) * stdDeviation;
		} else if (leadPawn != None)
		{
			fe.int1 = leadPawn.pawnId;
		}

		f_pawn.ReceiveFastEvent(fe);
	}
}

reliable server function ServerSetGroupedMoveV2Enabled(bool enabled)
{
	TMGameInfo(WorldInfo.Game).SetGroupedMoveV2(enabled);
	`log("bGroupedMoveV2Enabled: "$enabled, true, 'dru');
}

exec function SetGroupedMoveV2Enabled(bool enabled)
{
	ServerSetGroupedMoveV2Enabled(enabled);
}

function GotFastEvent(TMFastEvent fe)
{
	local TMPawn f_pawn;
	local array<TMPawn> pawns;
	local array<int> pawnIds;
	local int i;
	
	pawnIds = fe.GetPawnIDs();
	
	for( i=0; i<pawnIds.Length; i++)
	{
		f_pawn = GetPawnByID(pawnIds[i]);
		
		if (f_pawn == None )
		{
			//this is for the first units that spawn, we need to reveal them, but they may not exist yet
			if(fe.commandType == "C_Spawn")
			{
				m_cachedSpawnFes.AddItem( fe );
			}
		}
		else
		{
			pawns.AddItem(f_pawn);
		}
	}

	if ( (fe.commandType == "C_Move" || fe.commandType == "C_AI_Move") && pawns.Length > 0 )
	{
		if (bGroupedMoveV2Enabled)
		{
			MakeMovementGrouped2( pawns, fe );
		} else
		{
			MakeMovementGrouped( pawns, fe );
		}
	}
	else
	{
		foreach pawns( f_pawn )
		{
			f_pawn.ReceiveFastEvent(fe);
		}
	}
}

exec function PrintAllUnits()
{
	local TMPawn f_pawn;

	foreach self.AllActors(class'TMPawn', f_pawn)
	{
		`log("Pawn Name: "@ f_pawn.Name @" PawnId: "@ f_pawn.pawnId);
	}
}

exec function PrintAllActors()
{
	local Actor actor;

	foreach self.AllActors(class'Actor', actor)
	{
		`log("Pawn Name: "@ actor);
	}
}

exec function SetUnitAnimModifier(string inType, float inModifier)
{
	local TMPawn currPawn;
	foreach self.AllActors(class'TMPawn', currPawn)
	{
		if(currPawn.m_UnitType == inType)
		{
			currPawn.m_Unit.m_Data.animRatio = inModifier;
		}
	}
}

function buildUnitCache(array<JsonObject> json)
{
	local int i;
	local TMUnit unit;
	local TMAttackFE fe;
	
	unitCache.Remove(0, unitCache.Length); // reset the array
	for(i=0;i<json.Length;i++) {
		unit = new () class 'TMUnit';
		unit.LoadUnitData(json[i]);
		unitCache.AddItem(unit);
	}

	fe = new() class'TMAttackFE';
	fe.commandType = "RecivedUnitCache";
	SendServerFastEvent( fe );
}

function buildStatusEffectCache(array<JsonObject> statusEffectJson)
{
	// CREATE EVERY STATUS EFFECT
	local int i;

	// Reset the array (sometime this gets initialized twice!)
	statusEffectCache.Remove(0, statusEffectCache.Length);

	m_iMaxNumStatusEffects = statusEffectJson.Length;

	// Create space in the array for all of the status effects
	statusEffectCache.Add(m_iMaxNumStatusEffects);  // NOTE: I need to do this since the cache is index specific

	for(i=0;i<statusEffectJson.Length;i++)
	{
		AddStatusEffect( statusEffectJson[i] );
	}
}

function AddStatusEffect(JsonObject json)
{
	local JsonObject jsonObjectSE;
	local TMComponent comp;
	local int statusEffectEnum;
	local string statusEffect;

	jsonObjectSE = GetStatusEffectJson( json );

	if ( jsonObjectSE == none )
	{
		`log( "ERROR: Got an unexpected status effect. Check 'GetStatusEffectJson' for valid status effects", true, 'TMGameInfo' );
	}

	statusEffect = jsonObjectSE.GetStringValue( "name" );

	switch (statusEffect)
	{
	case "DisruptorPoison":
		comp = new() class'TMStatusEffectPoison';   // Taylor TODO: switch to Disruptor Poison
		statusEffectEnum = SE_DISRUPTOR_POISON;
		break;
	case "GrapplerSpeed":
		comp = new() class'TMStatusEffectSpeed';     // Taylor TODO: switch to Grappler speed
		statusEffectEnum = SE_GRAPPLER_SPEED;
		break;
	case "OilerSlow":
		comp = new() class'TMStatusEffectSlowTar';  // Taylor TODO: switch to Oiler Slow
		statusEffectEnum = SE_OILER_SLOW;
		break;
	case "RegeneratorHeal":
		comp = new() class'TMStatusEffectRegeneratorHeal';
		statusEffectEnum = SE_REGENERATOR_HEAL;
		break;
	case "CreepKillHeal":
		comp = new() class'TMStatusEffectCreepKillHeal';
		statusEffectEnum = SE_CREEPKILL_HEAL;
		break;
	case "SplitterKnockup":
		comp = new() class'TMStatusEffectStunned';    // Taylor TODO: make this Knockup
		statusEffectEnum = SE_SPLITTER_KNOCKUP;
		break;
	case "PopspringKnockup":
		comp = new() class'TMStatusEffectPopspringKnockup';
		statusEffectEnum = SE_POPSPRING_KNOCKUP;
		break;
	case "TimeFreeze":
		comp = new() class'TMStatusEffectFrozen';   // Taylor TODO: make Time Freeze?
		statusEffectEnum = SE_TIME_FREEZE;
		break;
	case "RamBamQueenKnockback":
		comp = new() class'TMStatusEffectKnockback';
		statusEffectEnum = SE_RAMBAMQUEEN_KNOCKBACK;
		break;
	case "GrapplerKnockback":
		comp = new() class'TMStatusEffectKnockback';
		statusEffectEnum = SE_GRAPPLER_KNOCKBACK;
		break;
	default:
		`log( "ERROR: Status Effect cache got an invalid status effect", true, 'TMGameInfo' );
		return;
	}

	jsonObjectSE.SetIntValue( "StatusEffectEnumValue", statusEffectEnum );
	comp.SetUpComponent( jsonObjectSE, none );
	statusEffectCache.Remove( statusEffectEnum, 1 );
	statusEffectCache.InsertItem( statusEffectEnum, comp ); // use the enum value for the index
}

// Need this function because our status effect objects in json are wrapped by the name. This is a temp fix
function JsonObject GetStatusEffectJson( JsonObject json )
{
	local JsonObject tempJson;

	tempJson = json.getObject( "DisruptorPoison" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "GrapplerSpeed" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "OilerSlow" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "RegeneratorHeal" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "CreepKillHeal" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "SplitterKnockup" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "PopspringKnockup" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.getObject( "TimeFreeze" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.GetObject( "RamBamQueenKnockback" );
	if ( tempJson != none )
	{
		return tempJson;
	}
	tempJson = json.GetObject( "GrapplerKnockback" );
	if ( tempJson != none )
	{
		return tempJson;
	}

	`warn( "TMPlayerController::GetStatusEffectJson() missing json name for status effect!!!" );
}

exec function KillAllMyUnits()
{
	GetTMPRI().KillAllMyUnits(self);
}

exec function ApplyDamage(int damage)
{
	local UDKRTSPawn selectedActor;
	local TMPawn selectedTMPawn;

	foreach CurrentSelectedActors(selectedActor)
	{
		selectedTMPawn = TMPawn(selectedActor);
		if (selectedTMPawn != None)
		{
			TellServerToApplyDamage(selectedTMPawn.pawnId, damage);
		}
	}
}

/**
 * Added for use in an exec cheat function only
 */
function TellServerToApplyDamage(int PawnId, int damage)
{
	ServerApplyDamage(PawnId, damage);
}

/**
 * Added for use in an exec cheat function only
 */
reliable server function ServerApplyDamage(int PawnId, int damage)
{
	local TMPawn pawnToDamage;

	pawnToDamage = GetPawnByID(PawnId);

	pawnToDamage.TakeDamage(damage,self,pawnToDamage.Location,Vect(0.0f,0.0f,0.0f),None,,);
}

exec function ku()
{
	KillUnits();
}

exec function KillUnits()
{
	local UDKRTSPawn selectedActor;
	local TMPawn selectedTMPawn;

	foreach CurrentSelectedActors(selectedActor)
	{
		selectedTMPawn = TMPawn(selectedActor);
		if (selectedTMPawn != None)
		{
			TellServerToKillPawn(selectedTMPawn.pawnId);
		}
	}
}

exec function cd()
{
	Cooldown();
}

exec function Cooldown()
{
	local UDKRTSPawn selectedActor;
	local TMPawn selectedTMPawn;

	foreach CurrentSelectedActors(selectedActor)
	{
		selectedTMPawn = TMPawn(selectedActor);
		if (selectedTMPawn != None)
		{
			if ( selectedTMPawn.m_abilityComponent != none)
			{
				selectedTMPawn.m_abilityComponent.m_AbilityState = AS_IDLE;
			}
		}
	}
}

exec function SetCameraDestination(int x, int y)
{
	UDKRTSCamera(PlayerCamera).destinationLocation.X = x;
	UDKRTSCamera(PlayerCamera).destinationLocation.Y = y;
	UDKRTSCamera(PlayerCamera).destinationLocation.Z = -1;
}

exec function SetCameraManualPanningSpeed(int speed)
{
	UDKRTSCamera(PlayerCamera).manualPanningSpeed = speed;
}

function TellServerToKillPawn(int PawnId)
{
	ServerKillPawn(PawnId);
}

reliable server function ServerKillPawn(int PawnId)
{
	local TMPawn pawnToDie;

	pawnToDie = GetPawnByID(PawnId);

	pawnToDie.TakeDamage(999999,self,pawnToDie.Location,Vect(0.0f,0.0f,0.0f),None,,);
}

reliable client function setUnitCacheString(string jsonString, int index, int arraylen)
{
	if (m_JsonParser == None)
	{
		m_JsonParser = new() class'TMJsonParser';
		m_JsonParser.setup();
	}

	if(self.unitCacheString.Length != arraylen) {
		self.unitCacheString.Length=arraylen;
	}

	self.unitCacheString[index]=jsonString;
}



reliable client function setStatusEffectCacheString(string jsonString, int index, int arraylen)
{
	if (m_JsonParser == None)
	{
		m_JsonParser = new() class'TMJsonParser';
		m_JsonParser.setup();
	}

	if(self.statusEffectCacheString.Length != arraylen) {
		self.statusEffectCacheString.Length=arraylen;
	}

	self.statusEffectCacheString[index]=jsonString;
}

function array<string> arrayElementCompress( array<string> arrayin) {
	local array<string> arrayout;
	local string temp;
	local int indexin;

	for(indexin = 0; indexin < arrayin.Length; indexin++) {
		temp $= arrayin[indexin];
		if("!s!h!i!t!b!a!l!l!s!" == right(temp, 19)) {
			temp = left(temp, len(temp) - 19);
			arrayout.AddItem(temp);
			temp = "";
		}
	}

	return arrayout;
}

reliable client function initBuildUnitCache()
{
	local array<JsonObject> jsonObj;
	local int i;

	unitCacheString = self.arrayElementCompress(unitCacheString);

	for(i=0;i<unitCacheString.Length;i++)
	{
		jsonObj.AddItem(m_JsonParser.getJsonFromString(unitCacheString[i]));
	}

	buildUnitCache(jsonObj);
}

reliable client function initBuildStatusEffectCache()
{
	local array<JsonObject> jsonObj;
	local int i;
	
	statusEffectCacheString = self.arrayElementCompress(statusEffectCacheString);

	for(i=0;i<statusEffectCacheString.Length;i++)
	{
		jsonObj.AddItem(m_JsonParser.getJsonFromString(statusEffectCacheString[i]));
	}

	buildStatusEffectCache(jsonObj);
}

function registerHUD(TM_GFxHUDPlayer hud)
{
    TM_HUD = hud;
}

function array<TMPawn> GetTMPawnList()
{
	if(WorldInfo.NetMode == NM_StandAlone || WorldInfo.NetMode == NM_DedicatedServer)
	{
		return TMGameInfo(WorldInfo.Game).mTMPawnList;
	}
	
	return mTMPawnList;
}

exec function ToggleGo()
{
	local UDKRTSPawn iterPawn;

	bCanGo = !bCanGo;

	if (bCanGo)
	{
		foreach self.CurrentSelectedActors(iterPawn)
		{
			iterPawn.Controller.bPreciseDestination = true;
		}
	}
}

function TMPawn GetPawnByID(int pawnId)
{
	
	if(WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone || WorldInfo.NetMode == NM_DedicatedServer )
	{
		return TMPawn(m_TMGameInfo.m_PawnHash.GetByIntKey(pawnId));
	}
	else
	{
		return TMPawn(m_PawnHash.GetByIntKey(pawnId));
	}

	return none;
}

reliable client function InitAudioManager()
{
	if (m_AudioManager == none)
	{
		m_AudioManager = new() class'AudioManager';
		`log('AudioManager initialized', true, 'TMPlayerController');
	}
	m_AudioManager.Initialize(self);
}

exec function SinglePlayerEndGame(bool bVictory)
{
	ClientEndGameInVictory(bVictory);
}

reliable client function ClientEndGameInVictory(bool bVictory) 
{
	m_victory = bVictory;
	m_gameEnded = true;

	// Check if we were in a tutorial and need to save progress
	if( m_TMGameInfo != None && m_TMGameInfo.IsTutorial() ) 
	{
		CompleteTutorial();
	}
}

reliable client function ClientEndRoundInVictory(bool bVictory)
{
	if(TMPlayerReplicationInfo(self.playerReplicationInfo).race == "Alchemist")
	{
		TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected("VineCrawler", "0");
	}
	
	m_victory = bVictory;
	m_roundEnded = true;
}

reliable client function ClientUpdateLastCommanderDied(int inPlayerID)
{
	local array<TMPawn> TMPawnList;
	local TMPawn iterPawn;

	// Search for dead commander for camera kill zoom in
	TMPawnList = GetTMPawnList();
	foreach TMPawnList(iterPawn)
	{
		if(iterPawn.OwnerReplicationInfo.PlayerID == inPlayerID && iterPawn.IsCommander())
		{
			TMCamera(PlayerCamera).UpdateLastDiedCommander(iterPawn);

			return;
		}
	}
}

event NotifyDirectorControl(bool bNowControlling, SeqAct_Interp CurrentMatinee)
{
	TMCamera(PlayerCamera).ToggleMatineeCam();

	super.NotifyDirectorControl(bNowControlling, CurrentMatinee);
}

function array<UDKRTSPawn> GetOwnedPawns()
{
	local array<UDKRTSPawn> list;
	local int i;
	for (i=0;i<TMPlayerReplicationInfo(self.PlayerReplicationInfo).m_PlayerUnits.Length;i++)
	{
		list.AddItem( TMPlayerReplicationInfo(self.PlayerReplicationInfo).m_PlayerUnits[i] );
	} 

	return list;
}

function SelectSimilarPawns( Pawn myPawn )
{
	local TMPawn myTMPawn;
	local TMPawn myComparePawn;

	myTMPawn = TMPawn(myPawn);

	 m_CurrentHotSelectedGroup = myTMPawn.m_UnitType;
	//// Dru TODO: Use TMPC.m_PlayerUnits or whatever
	foreach self.PlayerReplicationInfo.AllActors(class'TMPawn', myComparePawn)
	{
		if (myComparePawn.m_owningPlayerId == self.PlayerID)
		{
			if(myComparePawn.m_Unit.m_UnitName == myTMPawn.m_Unit.m_UnitName )
			{
				if (myComparePawn.Health > 0)
				{
					self.AddActorAsSelected(myComparePawn);
					myComparePawn.CommandMesh.SetHidden(false);
				}
			}
		}
	}
}

function UpdateActionCenter()
{
	local TMPawn myPawn;
	attackingPawns.Length = 0;

	// save the attackingPawns to follow after attack
	
	foreach AllActors(class'TMPawn', myPawn)
	{ 
 		if(myPawn.m_currentState == TMPS_ATTACK)
		{
 			attackingPawns.AddItem(myPawn);	
		}
	}
	actionCenter = class'UDKRTSPawn'.static.SmartCenterOfGroup(attackingPawns);
}

function float GetPawnAction (TMPawn myPawn)
{
	local float action;

	action = 0;
	if( myPawn.Health <= 0 )
	{
		return 0;
	}

	if(myPawn.m_currentState == TMPS_ABILITY)
	{
		action += 5.5f;
	}
 	else if(myPawn.m_currentState == TMPS_ATTACK)
	{
		myPawn.GetAttackComponent();
		if(myPawn.m_attackComponent != None && myPawn.m_attackComponent.m_Target.GetAllyId() >= 0 ) // attacking a team
		{
			action += 4.5f;
		}
		else
		{
			action += 1.f;
		}
	}
	else if(myPawn.m_currentState == TMPS_MOVING)
	{
		action += 0.5f;
	}
	else
	{
		action += 0.1f;
	}

	return action;
}

function int GetHighestActionTeamId( out float actionValue, bool onlyAllies = false )
{
	local TMPawn myPawn;
	local array<float> teamActions;
	local int index, teamId, maxActionTeamId;
	local float action, maxActionYet;
	attackingPawns.Length = 0;

	// save the attackingPawns to follow after attack
	
	for (index=0; index < 6; index++)
	{
		teamActions.AddItem(0.f);
	}


	foreach AllActors(class'TMPawn', myPawn)
	{ 
		teamId = myPawn.OwnerReplicationInfo.GetTeamNum();

		if(teamId < 0 || teamId > 5 || myPawn.GetAllyId() < 0 || myPawn.Health <= 0) //2 -> neutrals
		{
			continue;
		}

		if(onlyAllies && myPawn.GetAllyId() != GetTMPRI().allyId)
		{
			continue;
		}

		action = teamActions[teamId];

		
		action += GetPawnAction(myPawn);

		if(action > maxActionYet)
		{
			maxActionYet = action;
			maxActionTeamId = teamId;
		}

		teamActions[teamId] = action;
	}
	
	actionValue = maxActionYet;
	return maxActionTeamId;
}

function float GetTeamAction(int team)
{
	local TMPawn myPawn;
	local float action;
	local int teamId;

	action = 0;

	foreach AllActors(class'TMPawn', myPawn)
	{ 
		teamId = myPawn.OwnerReplicationInfo.GetTeamNum();

		if(teamId != team)
		{
			continue;
		}

		action += GetPawnAction(myPawn);
		
	}
	return action;
}

function CenterCameraOnAction()
{
	//UpdateActionCenter();
	//LerpCameraTo(SmartCenterOfGroup(attackingPawns), 12);
	//CenterCamera(f_pawn.Location);
	TMCamera(PlayerCamera).SetFocusAction(true);
}

function CenterCameraOnCommander(float timeout)
{
	local TMPawn commander;
	commander = GetCommander();
	if(commander != None)
	{
		LerpCameraTo(commander.Location, 7, timeout);
	}
}

simulated function LockCameraToCommander()
{
	local TMPawn commander;
	//local TMCamera ActiveCamera;

	//ActiveCamera = TMCamera(PlayerCamera);
	commander = GetCommander();
	if(commander != None)
	{
		LockToPawn(commander);
		//ActiveCamera.SetFocusOnPawn(commander, true);
	}	
}

//// Dru TODO: rename to something like "ToggleCameraLockedToPawn(UDKRTSPawn,pw)"
function LockToPawn(TMPawn pw)
{
	local TMCamera ActiveCamera;
	ActiveCamera = TMCamera(PlayerCamera);

	if(!bCameraLocked)
	{
		ActiveCamera.SetFocusOnPawn(pw, true);
		bCameraLocked = true;
	}
	else
	{
		ActiveCamera.UnlockFocus();
		bCameraLocked = false;
	}
}

function UnlockCamera()
{
	local TMCamera ActiveCamera;
	ActiveCamera = TMCamera(PlayerCamera);
	ActiveCamera.UnlockFocus();
	bCameraLocked = false;
}

simulated function TMPawn GetTeamCommander( int team )
{
	local TMPawn myPawn;
	local int teamId;

	foreach AllActors(class'TMPawn', myPawn)
	{ 
		teamId = myPawn.OwnerReplicationInfo.GetTeamNum();

		if(teamId != team)
		{
			continue;
		}

		if(	myPawn.IsCommander() )
		{
			return myPawn;
		}
	}
	return none;
}

function CenterCameraOnTeamCommander( int team )
{
	local TMPawn myPawn;

	myPawn = GetTeamCommander( team );

	if( myPawn != none )
	{
		TMCamera(PlayerCamera).SetFocusOnPawn(myPawn);
	}
}

simulated function bool IsOnSameTeam( TMPlayerController inPlayer )
{
	//return TMPlayerReplicationInfo( inPlayer.PlayerReplicationInfo ).allyId == TMPlayerReplicationInfo( PlayerReplicationInfo ).allyId;
	return m_allyId == inPlayer.m_allyId;	// QUESTION: why does nobody else use m_allyId???
}

simulated function bool IsPawnOnSameTeam( TMPawn inPawn )
{
	// TODO: figure out why this doesn't work in play mode
	//return IsOnSameTeam( inPawn.m_TMPC );	<= this DOESN'T work in a local game because neutrals appear to be on same team

	// This works in play mode against neutrals
	return TMPlayerReplicationInfo( inPawn.OwnerReplicationInfo ).allyId == TMPlayerReplicationInfo( PlayerReplicationInfo ).allyId;
}

simulated function bool IsPawnEnemyPlayer( TMPawn inPawn )
{
	if( IsPawnOnSameTeam( inPawn ) )
	{
		return false;
	}

	if( !IsPawnPlayer( inPawn ) )
	{
		return false;
	}

	return true;
}

simulated function bool IsPawnPlayer( TMPawn inPawn )
{
	if( inPawn.IsGameObjective() ||
		inPawn.IsPawnNeutral( inPawn ) )
	{
		return false;
	}

	return true;
}

simulated function TMPawn GetCommander()
{
	return TMPawn(self.Pawn);
}

function CenterCameraOnGroup()
{
	if ( CurrentSelectedActors.Length == 0 )
	{
		return;
	}

	//CenterCamera( SmartCenterOfGroup( CurrentSelectedActors ) );
	LerpCameraTo( class'UDKRTSPawn'.static.SmartCenterOfGroup( CurrentSelectedActors ) , 8);
}

exec function PlayTransformerEffects()
{
	local TMTransformer transformer;

	foreach AllActors(class'TMTransformer', transformer)
	{
		transformer.PlayEffect(0);
	}
}

reliable client function PlayTransformEffect(int tID, int aID)
{
	local TMTransformer transformer;

	foreach AllActors(class'TMTransformer', transformer)
	{
		if(transformer.TransformerId == tID)
		{
			transformer.PlayEffect(aID);
			ClientPlaySFXWithActor(SoundCue'SFX_Transformer.Trans_SFX', transformer);
			break;
		}
	}
}

reliable client function PlayPotionEffect(int transformerID, int allyID, int pawnID)
{
	local TMTransformer transformer;

	foreach AllActors(class'TMTransformer', transformer)
	{
		if(transformer.TransformerId == transformerID)
		{
			transformer.PlayPotionEffect(allyID, pawnID);
			break;
		}
	}
}

reliable client function ClientSpawnBruteParticles(int inKillerAllyId, int inKillerTeamColorIndex, vector inLocation)
{
	local ParticleSystem bruteParticle;

	if( inKillerAllyId == 0 ) {
		bruteParticle = ParticleSystem'transformpoint.Particles.vfx_Transform_Activated_Blue';
	} else {
		bruteParticle = ParticleSystem'transformpoint.Particles.vfx_Transform_Activated_Red';
	}

	m_ParticleSystemFactory.CreateWithScale(bruteParticle, inKillerAllyId, inKillerTeamColorIndex, inLocation, 4.5f);
}

exec function ToggleFullGroupedMove()
{
	ServerToggleFullGroupedMove();
}

reliable server function ServerToggleFullGroupedMove()
{
	bFullGroupedMove = !bFullGroupedMove;
	`log("FullGroupedMove is: "$bFullGroupedMove, true, 'dru');
}

simulated function TM_GFxHUDPlayer GetLocalHUDPlayer()
{
	local TMPlayerController cont;
	local TMHUD tmHUD;
	local TM_GFxHUDPlayer tmHUDPlayer;

	tmHUD = none;

	foreach LocalPlayerControllers( class'TMPlayerController', cont )
	{
		tmHUD = TMHUD( cont.myHUD );
		if ( tmHUD != none )
		{
			tmHUDPlayer = TM_GFxHUDPlayer( tmHUD.GFxMovie );
		}
	}

	return tmHUDPlayer;
}

function SetCursorVisibility(bool bVisible)
{
	if (bVisible)
	{
		GetLocalHUDPlayer().hideCursor(false);
	}
	else
	{
		GetLocalHUDPlayer().hideCursor(true);
	}
}

state Dead
{
	ignores SeePlayer, HearNoise, KilledBy, NextWeapon, PrevWeapon;
	reliable server function ServerReStartPlayer()
	{
		//`log("ServerRestartPlayer called. Player:"@self.PlayerId, true, 'Lang');
		m_tmGameInfo.RestartPlayer(self);
	}
}

//// Dru TODO: Get rid of this in favor of the one above
auto state PlayerWaiting
{
	ignores SeePlayer, HearNoise, KilledBy;// NextWeapon, PrevWeapon;
	reliable server function ServerReStartPlayer()
	{
		//`log("ServerRestartPlayer called. Player:"@self.PlayerId, true, 'Lang');
		m_tmGameInfo.RestartPlayer(self);
	}
}

exec function GivePotion(string potionType)
{
	AddPotion(potionType);
}

reliable server function AddPotion(string unitType)
{
	local TMPotionStack stack;
	
	// If there is already a stack of that type, add to its count
	foreach m_Potions(stack)
	{
		if(stack.m_UnitType == unitType)
		{
			if(stack.m_Count >= 10)
				return;

			stack.m_Count++;
			ClientAddPotion(unitType, stack.m_Count);
			// ClientPlayNotification("Got" @ unitType @ "potion! || Count:" @ stack.m_Count, 250);
			// TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(stack.m_Count));
			SetPotion(unitType); // GGH TEMP!
			return;
		}
	}

	// No stack - make one
	stack = new() class'TMPotionStack';
	stack.m_UnitType = unitType;
	stack.m_Count = 1;
	m_Potions.AddItem(stack);
	TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(stack.m_Count));
	SetPotion(unitType); // GGH TEMP!

	ClientAddPotion(unitType, stack.m_Count);

	// ClientPlayNotification("Got" @ unitType @ "potion! || Count: 1", 250);
}

reliable server function bool UsePotion(string unitType)
{
	local TMPotionStack stack;
	
	foreach m_Potions(stack)
	{
		if(stack.m_UnitType == unitType && stack.m_Count > 0)
		{
			stack.m_Count--;
			ClientSetStackQuant(unitType, stack.m_Count);
			return true;
		}
	}

	return false;
}

reliable client function ClientAddPotion(string unitType, int count)
{
	local TMPotionStack stack;

	if(WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone)
	{  
		TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(count));
		return;
	}

	// If there is already a stack of that type, add to its count
	foreach m_Potions(stack)
	{
		if(stack.m_UnitType == unitType)
		{
			stack.m_Count++;
			TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(stack.m_Count));
			return;
		}
	}

	`log("No stack of type" @ unitType @ "found", true, 'Graham');

	// No stack - make one
	stack = new() class'TMPotionStack';
	stack.m_UnitType = unitType;
	stack.m_Count = 1;
	TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(stack.m_Count));
	m_Potions.AddItem(stack);
}

reliable client function ClientSetStackQuant(string unitType, int count)
{
	local TMPotionStack stack;

	if(WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone)
	{  
		TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(count));
		return;
	}

	foreach m_Potions(stack)
	{
		if(stack.m_UnitType == unitType)
		{
			stack.m_Count = count;
			TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(stack.m_Count));
			return;
		}
	}
}

simulated function DecrementPotionLocally(string unitType, int count)
{
	local TMPotionStack stack;

	foreach m_Potions(stack)
	{
		if(stack.m_UnitType == unitType)
		{
			stack.m_Count -= count;
			TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(unitType, string(stack.m_Count));
			return;
		}
	}
}

simulated function SetPotion(string potion)
{
	// ClientPlayNotification("Potion:" @ potion @ "|| Count:" @ GetPotionCount(potion), 250);
	if(myHUD != None)
	{
		TM_GFxHUDPlayer(TMHUD(myHUD).GFxMovie).potionSelected(potion, string(GetPotionCount(potion)));
	}
	m_CurrentPotionType = potion;
	ServerSetPotion(potion);
}

reliable server function ServerSetPotion(string potion)
{
	m_CurrentPotionType = potion;
}

reliable server function ServerLoseAllPotions()
{
	local TMPotionStack stack;
	
	foreach m_Potions(stack)
	{
		stack.m_Count = 0;
	}

	ClientLoseAllPotions();
}

reliable client function ClientLoseAllPotions()
{
	local TMPotionStack stack;

	foreach m_Potions(stack)
	{
		stack.m_Count = 0;
	}
}

exec function PrintPotionStacks()
{
	local TMPotionStack stack;

	if(m_Potions.Length == 0)
	{
		`log("No potions", true, 'Graham');
	}

	foreach m_Potions(stack)
	{
		`log(stack.m_UnitType @ "  " @ stack.m_Count, true, 'Graham');
	}
}

reliable server function PrintPots()
{
	local TMPotionStack stack;

	if(m_Potions.Length == 0)
	{
		`log("No potions", true, 'Graham');
	}

	foreach m_Potions(stack)
	{
		`log(stack.m_UnitType @ "  " @ stack.m_Count, true, 'Graham');
	}
}

simulated function int GetPotionCount(string potionType)
{
	local TMPotionStack stack;

	foreach m_Potions(stack)
	{
		if(stack.m_UnitType == potionType)
		{
			return stack.m_Count;
		}
	}

	return 0;
}

exec function ServerPrintPotions()
{
	PrintPots();
}

exec function ExecAddPotion(string unitType)
{
	TestAddPotion(unitType);
}

exec function ExecUsePotion(string unitType)
{
	TestUsePotion(unitType);
}

reliable server function TestAddPotion(string unitType)
{
	`log("TestAddPotion");
	AddPotion(unitType);
	ClientAddPotion(unitType, 1);
}

reliable server function TestUsePotion(string unitType)
{
	`log("TestUsePotion");
	UsePotion(unitType);
}

reliable client function TurnOffRevealer()
{
	if(m_NexusRevealer != none)
	{
		m_NexusRevealer.bApplyFogOfWar = false;
	}
}

exec function PrintPopulation()
{
	`log(TMPlayerReplicationInfo(PlayerReplicationInfo).Population, true, 'Graham');
}

exec function ToggleQuickcast()
{
	bQuickcastActive = !bQuickcastActive;
	if (bQuickcastActive)
	{
		self.InputHandler = self.InputHandlerQuickcast;
		`log("quickcast on");
	}
	else
	{
		self.InputHandler = self.InputHandlerInactiveCommand;
		`log("quickcast off");
	}
}

function AddAbilityObject( TMIAbilityObject inAbilityObject )
{
	mActiveAbilityObjects.AddItem( inAbilityObject );
}

function RemoveAbilityObject( TMIAbilityObject inAbilityObject )
{
	mActiveAbilityObjects.RemoveItem( inAbilityObject );
}

/* ClearAbilityObjects
	Cleans up all active ability objects and removes them from the ability object list.
	Called by TMGameInfo when the game or the round ends.
*/
function ClearAbilityObjects()
{
	local int i;

	// Reverse iterate through ability objects and stop them. NOTE: they remove themselves from the list
	for( i = mActiveAbilityObjects.Length-1; i >= 0; i-- )
	{
		mActiveAbilityObjects[ i ].Stop();
	}

	// If there are still ability objects in the list we have a problem
	if( mActiveAbilityObjects.Length > 0 )
	{
		// This happened because an ability messed up. Please tell taylor and send him logs :)
		`warn( "TMPlayerController::ClearAbilityObjects() have " $ mActiveAbilityObjects.Length $ " ability objects that didn't clear from list!" );
		mActiveAbilityObjects.Remove( 0, mActiveAbilityObjects.Length );
	}

	// If we're the server, tell the client to also clear the ability objects
	if( WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer )
	{
		ClientClearAbilityObjects();
	}
}

/* ClientClearAbilityObjects
	Called by the server to clear ability objects on a client.
*/
reliable client function ClientClearAbilityObjects()
{
	ClearAbilityObjects();
}

function ClearAbilityProjectiles()
{
	local int i;
	
	for( i = m_AbilityProjectiles.Length-1; i >= 0; i-- )
	{
		m_AbilityProjectiles[i].Destroy();
	}
	m_AbilityProjectiles.Remove( 0, m_AbilityProjectiles.Length );

	// If we're the server, tell the client to also clear the ability objects
	if( WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer )
	{
		ClientClearAbilityProjectiles();
	}
}

reliable client function ClientClearAbilityProjectiles()
{
	ClearAbilityProjectiles();
}

reliable client function ClientTriedToGetUnitAtMaxPop()
{
	TM_HUD.flashPopulationBar();
}

function SetFoWManager( TMFoWManager inFoWManager )
{
	mFoWManager = inFoWManager;
}

function TMFOWManager GetFoWManager()
{
	return mFoWManager;
}

simulated function bool IsClient()
{
	return ( self.WorldInfo.NetMode == NM_Client || self.WorldInfo.NetMode == NM_Standalone );
}

replication
{
	if(bNetInitial)
		PlayerId, commanderType;
	if(bNetDirty)
		bGroupedMoveV2Enabled;
}

exec function SetTransformPointsHidden(bool inIsHidden = true)
{
	local TMTransformer t;

	foreach AllActors(class'TMTransformer', t)
	{
		t.m_icon.SetHidden(inIsHidden);
	}
}

exec function AudioLoadTest(int inNumberOfSounds = 10, float inDuration = 1.0f)
{
	local TMAudioLoadTester audioLoadTester;
	audioLoadTester = Spawn(class'TMAudioLoadTester');
	audioLoadTester.StartTest(m_AudioManager, inNumberOfSounds, inDuration);
}

// Marks the currently in-progress tutorial as complete
simulated function CompleteTutorial()
{
	local TMSaveData save;
	save = class'TMSaveData'.static.LoadFile();
	save.CompletedTutorial();
}

exec function SetShouldSpawnVFX(bool shouldSpawnVFX)
{
	bShouldSpawnVFX = shouldSpawnVFX;
}

simulated function bool ShouldSpawnVFX()
{
	// Never spawn VFX if you aren't a client
	if(!IsClient())
	{
		return false;
	}
	
	return bShouldSpawnVFX;
}

// Logs a message so we can track down a bug when it happens (this is an override function)
function LogBug()
{
	local string playerName;
	playerName = GetTMPRI().PlayerName;

	`log(playerName $ ": I think there's a BUG!");
	ClientPlayNotification("Bug reported.", 1000);

	// If we are a client, log on the server also
	if (!IsAuthority())
	{
		PlayerLogBug(playerName);
	}
}

reliable server function PlayerLogBug(string playerName)
{
	`log(playerName $ " is reporting a suspected BUG!");
}

/* BotTalk
	Used to make bots talk in chat. They tell everyone in the game what
	they're doing.
*/
exec function BotTalk(bool shouldTalk)
{
	SetBotTalk(shouldTalk);
}

reliable server function SetBotTalk(bool shouldTalk)
{
	local TMController tempController;

	foreach m_tmGameInfo.mAllTMControllers(tempController)
	{
		if (TMTeamAIController(tempController) != none)
		{
			TMTeamAIController(tempController).bBotTalk = shouldTalk;
		}
	}
}

exec function BotDebug(bool shouldDebug)
{
	SetBotDebug(shouldDebug);
}

reliable server function SetBotDebug(bool shouldDebug)
{
	local TMController tempController;

	foreach m_tmGameInfo.mAllTMControllers(tempController)
	{
		if (TMTeamAIController(tempController) != none)
		{
			TMTeamAIController(tempController).bShowDebug = shouldDebug;
		}
	}
}

/* Bots
	Used to observe bots in their natural habitat.
	Turns on bot talk and disables fow
*/
exec function Bots()
{
	SetBotDebug(true);
	SetBotTalk(true);
	FoWDisable();
}

/* ShowRangeMarkers
	Shows little debug circles around your commander so it's easier for us to gauge distances.
*/
exec function ShowRangeMarkers(bool shouldShowRangeMarkers)
{
	if(shouldShowRangeMarkers)
	{
		SetTimer(0.1f, true, nameof(ShowRangeMarkersLoop));
	}
	else
	{
		ClearTimer(nameof(ShowRangeMarkersLoop));	
	}
}

function ShowRangeMarkersLoop()
{
	local Vector textOffset;

	m_TMGameInfo.TellClientsToDrawDebugCircle( GetCommander().location, 500, 255, 255, 255 );
	m_TMGameInfo.TellClientsToDrawDebugCircle( GetCommander().location, 1000, 255, 255, 255 );
	m_TMGameInfo.TellClientsToDrawDebugCircle( GetCommander().location, 1500, 255, 255, 255 );
	m_TMGameInfo.TellClientsToDrawDebugCircle( GetCommander().location, 2000, 255, 255, 255 );
	textOffset.Y = 500;
	m_TMGameInfo.TellClientsToDrawDebugText( "500", GetCommander(), textOffset, 0.1f );
	textOffset.Y = 1000;
	m_TMGameInfo.TellClientsToDrawDebugText( "1000", GetCommander(), textOffset, 0.1f );
	textOffset.Y = 1500;
	m_TMGameInfo.TellClientsToDrawDebugText( "1500", GetCommander(), textOffset, 0.1f );
	textOffset.Y = 2000;
	m_TMGameInfo.TellClientsToDrawDebugText( "2000", GetCommander(), textOffset, 0.1f );
}

defaultproperties
{
	m_gameEnded = false;
	m_bTransformerIconInit = true;
	HUDClass=class'TMHUD'
	bHasDied=false;
	commanderType = "RoboMeister";
	CameraClass=class'TheMaestrosGame.TMCamera'
	bIsDead=false
	m_CurrentPotionType="Oiler"
	bGroupedMoveV2Enabled=true

	m_CheatCodes.Add("miralab")
	m_CheatCodes.Add("fatloot")
	m_CheatCodes.Add("rhea")
	m_CheatCodes.Add("cole")
	m_CheatCodes.Add("socialclues")
	m_CheatCodes.Add("bloom")

	bCameraFollowNuke = false

	bUseCheats = true;
	bShouldSpawnVFX = true;

	bDebuggingBots = false;
	bBenchmarkingBots = false;
}
