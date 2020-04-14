class TMMainMenuGameInfo extends GameInfo;

var string specifiedMenu;
var() AudioComponent themeMusic;
var() AudioComponent ambientMusic;
var() AudioComponent tinkermeisterSound, rosieSound, robomeisterSound, salvatorSound, hiveLordSound;

var string mInvitedLobbyGUID;
var string mInvitedLobbyPort;
var string mInvitedLobbyHost;

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	local TMMainMenuPlayerController tmpc;

	tmpc = TMMainMenuPlayerController(super.Login(Portal, Options, UniqueID, ErrorMessage));

	tmpc.username = ParseOption(Options, "PlayerName");
	tmpc.mSessionToken = ParseOption(Options, "SessionToken");

	ChangeName( tmpc, tmpc.username, true );

	return tmpc;
}

event InitGame (string Options, out string ErrorMessage)
{
	specifiedMenu = ParseOption( Options, "Menu" );
	mInvitedLobbyGUID = ParseOption( Options, "gameGUID" );
	mInvitedLobbyPort = ParseOption( Options, "port" );
	mInvitedLobbyHost = ParseOption( Options, "host" );

	Super.InitGame( Options, ErrorMessage );
}

DefaultProperties
{
	HUDType = class'TheMaestrosGame.TM_MainMenu'
	PlayerControllerClass=class'TheMaestrosGame.TMMainMenuPlayerController'
	Name="TMMainMenuGameInfo";

	Begin Object Class=AudioComponent Name=MusicClip
        SoundCue=SoundCue'ScaleformMenuGFx.MainTheme_Cue_MaxLoh';//SoundCue=SoundCue'ScaleformMenuGFx.Sounds.MainTheme_Cue';
    End Object
	themeMusic = MusicClip;

	Begin Object Class=AudioComponent Name=AmbientSoundClip
        SoundCue=SoundCue'SFX_SkyIsland.SkyIsland_MainAmbient';               
    End Object
	ambientMusic = AmbientSoundClip;

	Begin Object Class=AudioComponent Name=TinkermeisterSoundClip
        SoundCue=SoundCue'VO_Tinkermeister.Tinkermeister_Select_1_1_Cue';               
    End Object
	tinkermeisterSound = TinkermeisterSoundClip;

	Begin Object Class=AudioComponent Name=RosieSoundClip
        SoundCue=SoundCue'VO_Rosie.Rosie_Select_1_1_Cue';               
    End Object
	rosieSound = RosieSoundClip;

	Begin Object Class=AudioComponent Name=RobomeisterSoundClip
        SoundCue=SoundCue'VO_Robomeister.Robomeister_Select';               
    End Object
	robomeisterSound = RobomeisterSoundClip;

	Begin Object Class=AudioComponent Name=SalvatorSoundClip
        SoundCue=SoundCue'VO_Salvator.Salvator_Select';               
    End Object
	salvatorSound = SalvatorSoundClip;

	Begin Object Class=AudioComponent Name=HiveLordSoundClip
        SoundCue=SoundCue'VO_HiveLord.HiveLord_Move_4_Cue';               
    End Object
	hiveLordSound = HiveLordSoundClip;
}
