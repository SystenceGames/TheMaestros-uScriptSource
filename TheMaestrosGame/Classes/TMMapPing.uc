class TMMapPing extends Actor;

var StaticMeshComponent m_ping;
var StaticMeshComponent m_pulse;
var MaterialInstanceConstant m_pingMatInst;
var MaterialInstanceConstant m_pulseMatInst;
var TMPlayerController mTmpc;
var float m_pingAlpha;
var float m_pulseScale;

var int m_ownerAllyId;
var int m_type;

var float m_duration;
var float m_timeElapsed;

const AlertType = 0;
const OmwType = 1;
const LookType = 2;

simulated function Init(int allyId, Vector pos, int type)
{
	local Rotator rot;

	mTmpc = TMPlayerController(GetALocalPlayerController());

	mTmpc.mMapPings.AddItem(self);

	m_ownerAllyId = allyId;
	SetLocation(pos);
	m_type = type;

	m_pingMatInst = new(None) Class'MaterialInstanceConstant';
	m_pingMatInst.SetParent(m_ping.GetMaterial(0));

	switch (type)
	{
	case 0:
		m_pingMatInst.SetTextureParameterValue('PingTexture', Texture'JC_Material_Sandbox.Textures.AlertTexture');	
		break;
	case 1:
		m_pingMatInst.SetTextureParameterValue('PingTexture', Texture'JC_Material_Sandbox.Textures.OMWTexture');
		break;
	case 2:
		m_pingMatInst.SetTextureParameterValue('PingTexture', Texture'JC_Material_Sandbox.Textures.LookTexture');
		break;
	}

	m_ping.SetMaterial(0, m_pingMatInst);

	rot = TMCamera(mTmpc.PlayerCamera).Rotation;
	rot.Pitch = 0;
	rot.Yaw = 0;
	
	self.SetRelativeRotation(rot);
}

simulated event PostBeginPlay()
{	
	m_timeElapsed = 0;

	m_pingAlpha = 1.0f;
	m_pulseScale = 0.0f;

	m_pulseMatInst = new(None) Class'MaterialInstanceConstant';
	m_pulseMatInst.SetParent(m_pulse.GetMaterial(0));
	m_pulseMatInst.SetTextureParameterValue('PingTexture', Texture'SelectionCircles.Textures.WhiteSelection');	
	m_pulse.SetMaterial(0, m_pulseMatInst);
}

simulated event Tick(float dt)
{
	// Destroy actor after duration has passed or if not on the caster's team
	if (TMPlayerReplicationInfo(GetALocalPlayerController().PlayerReplicationInfo).allyId != m_ownerAllyId
		|| m_timeElapsed > m_duration)
	{
		Destroy();
		TornOff();
		return;
	}

	m_timeElapsed += dt;

	if (m_timeElapsed > m_duration/2)
	{
		m_pingAlpha -= 2*dt/m_duration;
		m_pingMatInst.SetScalarParameterValue('Alpha', m_pingAlpha);
	}

	m_pulseScale += dt/m_duration;
	if (m_pulseScale > 1)
	{
		m_pulseScale = 1;
	}
	m_pulseMatInst.SetScalarParameterValue('Alpha', 1 - m_pulseScale);
	m_pulse.SetScale(2*m_pulseScale);
}

simulated event Destroyed()
{
	mTmpc.mMapPings.RemoveItem(self);
}

DefaultProperties
{
	bAlwaysRelevant=true
	//bStatic=false

	m_duration=3.0f

	Begin Object Class=StaticMeshComponent Name=Ping
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatPlane'
		Materials(0)= Material'JC_Material_Sandbox.Materials.PingMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
		Rotation=(Pitch=0, Yaw=0, Roll=16384)
		Translation=(X=0.0f, Y=0.0f, Z=150.0f)
		Scale=3.0f
	End Object
	m_ping=Ping
	Components.Add(Ping)

	Begin Object Class=StaticMeshComponent Name=Pulse
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatCircle'
		Materials(0)= Material'JC_Material_Sandbox.Materials.PingMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
		Translation=(X=0.0f, Y=0.0f, Z=0.0f)
		Scale=0.0f
	End Object
	m_pulse=Pulse
	Components.Add(Pulse)
}
