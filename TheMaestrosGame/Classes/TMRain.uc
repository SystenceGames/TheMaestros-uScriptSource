class TMRain extends Actor;

var TMCamera m_owner;

var StaticMeshComponent m_rain;
var MaterialInstanceConstant m_matInst;

var LinearColor m_tint;
var float m_fIntensity;

simulated event PostBeginPlay()
{
	m_matInst = new(None) Class'MaterialInstanceConstant';
	m_matInst.SetParent(m_rain.GetMaterial(0));
	m_matInst.SetTextureParameterValue('PingTexture', Texture'SelectionCircles.Textures.WhiteSelection');	
	m_rain.SetMaterial(0, m_matInst);
}

simulated event Tick(float dt)
{
	local Rotator rot;
	rot = Owner.Rotation;
	rot.Pitch = 0;
	rot.Yaw = 0;
	self.SetRelativeRotation(rot);

	SetLocation(TMCamera(Owner).CurrentLocation);

	m_matInst.SetVectorParameterValue('RainColor', m_tint);	
	m_matInst.SetScalarParameterValue('RainIntensity', m_fIntensity);
}

DefaultProperties
{
	bAlwaysRelevant=true
	//bStatic=false
	
	m_tint=(R=0.5f, G=0.7f, B=0.5f, A=1.0f)
	m_fIntensity=0.25f

	Begin Object Class=StaticMeshComponent Name=Rain
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatPlane'
		Materials(0)= Material'JC_Material_Sandbox.Materials.RainDropletMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
		Rotation=(Pitch=0, Yaw=0, Roll=16384)
		Translation=(X=0.0f, Y=0.0f, Z=-300.0f)
		Scale=100.0f
	End Object
	m_rain=Rain
	Components.Add(Rain)
}
