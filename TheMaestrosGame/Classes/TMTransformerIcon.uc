class TMTransformerIcon extends Actor
	placeable;

// Composite
var StaticMeshComponent m_background;
var StaticMeshComponent m_transformedUnit;
var StaticMeshComponent m_baseUnit;
var StaticMeshComponent m_baseNum;
var array<StaticMeshComponent> m_bars;

var StaticMeshComponent barTemplate;

var TMPlayerController m_TMPC;

// Exposed to editor
var() TMTransformer m_owner;
var() int m_attackNum;
var() int m_defenseNum;
var() int m_abilityNum;

var bool m_bIsSpectator;

var float m_time;
var Vector m_defaultLocation;

enum BarType { BT_AD, BT_DF, BT_AP };

simulated event PostBeginPlay()
{
	m_time = 0.0f;
	m_defaultLocation = Location;
	m_bIsSpectator = false;
	m_owner.m_icon = self;
	

	if (m_owner == none)
	{
		`log("THIS TRANSFORM ICON HAS NO OWNER! WHAT'S HAPPENINGGGGGGGGGG LOOOOK AT ME I'M AN ERROR", true, 'jchen');
	}
}

simulated function PickTextures(string race)
{
	local int i;
	local MaterialInstanceConstant matInst;

	if (race == "Spectator")
	{
		m_bIsSpectator = true;
		m_background.SetHidden(true);
		m_transformedUnit.SetHidden(true);
		m_baseUnit.SetHidden(true);
		m_baseNum.SetHidden(true);
		return;
	}

	// Background
	matInst = new(None) Class'MaterialInstanceConstant';
	matInst.SetParent(m_background.GetMaterial(0));
	if (race == "Alchemist")
	{
		matInst.SetTextureParameterValue('IconTexture', Texture'TransformPoint.TransformIcons.AlchemistBackground');		
	}
	else
	{
		matInst.SetTextureParameterValue('IconTexture', Texture'TransformPoint.TransformIcons.Background');	
	}	
	m_background.SetMaterial(0, matInst);

	// Transformed Unit
	matInst = new(None) Class'MaterialInstanceConstant';
	matInst.SetParent(m_transformedUnit.GetMaterial(0));
	if (race == "Alchemist")
	{
		matInst.SetTextureParameterValue('IconTexture', Texture(DynamicLoadObject("TransformPoint.TransformIcons.TransformedUnit_"$m_owner.PotionType, class'Texture')));	
	}
	else
	{
		matInst.SetTextureParameterValue('IconTexture', Texture(DynamicLoadObject("TransformPoint.TransformIcons.TransformedUnit_"$m_owner.UnitTwoType, class'Texture')));	
	}	
	m_transformedUnit.SetMaterial(0, matInst);

	// Base Unit
	matInst = new(None) Class'MaterialInstanceConstant';
	matInst.SetParent(m_baseUnit.GetMaterial(0));
	if (race == "Alchemist")
	{
		matInst.SetTextureParameterValue('IconTexture', Texture(DynamicLoadObject("JC_Material_SandBox.Textures.clearTexture", class'Texture')));	
	}
	else
	{
		matInst.SetTextureParameterValue('IconTexture', Texture(DynamicLoadObject("TransformPoint.TransformIcons.BaseUnit_"$m_owner.UnitOneType, class'Texture')));	
	}
	m_baseUnit.SetMaterial(0, matInst);

	// Base Num
	matInst = new(None) Class'MaterialInstanceConstant';
	matInst.SetParent(m_baseNum.GetMaterial(0));
	if (race == "Alchemist")
	{
		matInst.SetTextureParameterValue('IconTexture', Texture(DynamicLoadObject("JC_Material_SandBox.Textures.clearTexture", class'Texture')));	
	}
	else
	{
		matInst.SetTextureParameterValue('IconTexture', Texture(DynamicLoadObject("TransformPoint.TransformIcons.Number_"$m_owner.UnitOneCount, class'Texture')));	
	}
	m_baseNum.SetMaterial(0, matInst);
	
	for (i = 0; i < m_attackNum; i++)
	{
		CreateBar(BT_AD, i);
	}

	for (i = 0; i < m_defenseNum; i++)
	{
		CreateBar(BT_DF, i);
	}

	for (i = 0; i < m_abilityNum; i++)
	{
		CreateBar(BT_AP, i);
	}
}

simulated function CreateBar(BarType bt, int i)
{
	local StaticMeshComponent smc;
	local Vector barVec;
	local MaterialInstanceConstant matInst;

	smc = new Class'StaticMeshComponent'(barTemplate);

	matInst = new(None) Class'MaterialInstanceConstant';
	matInst.SetParent(smc.GetMaterial(0));
	switch (bt)
	{
	case BT_AD:
		matInst.SetTextureParameterValue('IconTexture', Texture'TransformPoint.TransformIcons.AttackBar');	
		break;
	case BT_DF:
		matInst.SetTextureParameterValue('IconTexture', Texture'TransformPoint.TransformIcons.DefenseBar');	
		break;
	case BT_AP:
		matInst.SetTextureParameterValue('IconTexture', Texture'TransformPoint.TransformIcons.AbilityBar');	
		break;
	}
	smc.SetMaterial(0, matInst);

	// Scale and Translation
	barVec.X = 75 + 29*i;
	switch (bt)
	{
	case BT_AD:
		barVec.Y = -75;
		break;
	case BT_DF:
		barVec.Y = -20;
		break;
	case BT_AP:
		barVec.Y = 35;
		break;
	}
	barVec.Z = 1;
	smc.SetTranslation(barVec);

	barVec.X = 0.3f;
	barVec.Y = 0.3f;
	barVec.Z = 1.0f;
	smc.SetScale3D(barVec);

	AttachComponent(smc);
	m_bars.AddItem(smc);
}

simulated function ShowComposite()
{
	local StaticMeshComponent smc;

	if (m_bIsSpectator)
	{
		return;
	}

	m_background.SetHidden(false);
	m_baseUnit.SetHidden(false);
	m_baseNum.SetHidden(false);

	foreach m_bars(smc)
	{
		smc.SetHidden(false);
	}
}

simulated function HideComposite()
{
	local StaticMeshComponent smc;

	if (m_bIsSpectator)
	{
		return;
	}

	m_background.SetHidden(true);
	m_baseUnit.SetHidden(true);
	m_baseNum.SetHidden(true);

	foreach m_bars(smc)
	{
		smc.SetHidden(true);
	}
}

DefaultProperties
{
	bNoDelete=true
	bAlwaysRelevant=true
	bAlwaysTick=true
	bStatic=false

	Begin Object Class=StaticMeshComponent Name=Background
		HiddenGame=true
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatPlane'
		Materials(0)= Material'TransformPoint.TransformIcons.TransformIconMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_World
		Scale3D=(X=4.7325f, Y=3.0f, Z=1.0f)
	End Object
	m_background=Background
	Components.Add(Background)

	Begin Object Class=StaticMeshComponent Name=TransformedUnit
		HiddenGame=false
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatCircle'
		Materials(0)= Material'TransformPoint.TransformIcons.TransformIconMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
		Translation=(X=-108f, Y=-24.0f, Z=1.0f)
		Scale=2.1f
	End Object
	m_transformedUnit=TransformedUnit
	Components.Add(TransformedUnit)

	Begin Object Class=StaticMeshComponent Name=BaseUnit
		HiddenGame=true
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatCircle'
		Materials(0)= Material'TransformPoint.TransformIcons.TransformIconMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
		Translation=(X=165f, Y=102.0f, Z=1.0f)
		Scale=0.6f
	End Object
	m_baseUnit=BaseUnit
	Components.Add(BaseUnit)

	Begin Object Class=StaticMeshComponent Name=BaseNum
		HiddenGame=true
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatCircle'
		Materials(0)= Material'TransformPoint.TransformIcons.TransformIconMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
		Translation=(X=30.0f, Y=102.0f, Z=1.0f)
		Scale=1.0f
	End Object
	m_baseNum=BaseNum
	Components.Add(BaseNum)

	Begin Object Class=StaticMeshComponent Name=Bar
		HiddenGame=true
		StaticMesh=StaticMesh'SelectionCircles.Meshes.FlatPlane'
		Materials(0)= Material'TransformPoint.TransformIcons.TransformIconMat'
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
	End Object
	barTemplate=Bar

}
