class TMAbilityIndicator extends Object;

enum AbilityIndicatorStyle
{
	AIS_AOE,
	AIS_TAR,
	AIS_MINES,
	AIS_WALL,
	AIS_DASH,
	AIS_NUKE,
	AIS_UNSET    // REMOVING THIS AFTER REWRITE
};

var AbilityIndicatorStyle m_Style;
var TMPawn m_owner;
var StaticMeshComponent m_indicator;
var MaterialInstanceConstant m_matInst;

simulated function Initialize(TMPawn p)
{
	m_owner = p;
	m_owner.AttachComponent(m_indicator);
	if (m_owner.GetAbilityComponent() != none)
	{
		m_Style = m_owner.GetAbilityComponent().m_AbilityIndicatorStyle;
	}
	// set type here
	//SetScale(2.0f / 97.0f * TMAbilitySniperMine(m_Unit.m_ComponentAbility).m_iMineRadius);
	

	// Set mesh and material based in type
	switch (m_Style)
	{
	case AIS_AOE:
		m_indicator.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatCircle');
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.TargetMat');
		break;
	case AIS_TAR:
		m_indicator.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatCircle');
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.TargetMat');
		break;
	case AIS_MINES:
		m_indicator.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatPlane');
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.IndicatorMinesMat');
		break;
	case AIS_WALL:
		m_indicator.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatPlane');
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.IndicatorWallMat');
		break;
	case AIS_DASH:
		m_indicator.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatPlane');
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.IndicatorArrowMat');
		break;
	case AIS_NUKE:
		m_indicator.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatPlane');
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.IndicatorNukeMat');
		break;
	default:
		`log("no type found", true, 'justin');
		break;
	}
	
	// Change material color
	m_matInst = new(None) Class'MaterialInstanceConstant';
	m_matInst.SetParent(m_indicator.GetMaterial(0));
	m_matInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.GreenHSV.X);
	m_indicator.SetMaterial(0, m_matInst);
}

// This function will be removed when this system gets rewritten
static function AbilityIndicatorStyle GetAbilityIndicatorStyle( string inAbilityIndicatorStyleString )
{
	local AbilityIndicatorStyle type;

	if (inAbilityIndicatorStyleString == "aoe")
	{
		type = AIS_AOE;
	}
	else if (inAbilityIndicatorStyleString == "mines")
	{
		type = AIS_MINES;
	}
	else if (inAbilityIndicatorStyleString == "wall")
	{
		type = AIS_WALL;
	}
	else if (inAbilityIndicatorStyleString == "dash")
	{
		type = AIS_DASH;
	}
	else if (inAbilityIndicatorStyleString == "nuke")
	{
		type = AIS_DASH;
	}
	else
	{
		type = AIS_AOE;
	}

	return type;
}

simulated function Update()
{
	local Vector newScale;
	local Vector mouseloc;
	local Vector ownerloc;
	local float distToMouse;
	local Vector maxrangeloc;
	local TMAbilityTarSplotch tarsplotch;
	local int i;
	
	mouseloc = TMHUD(m_owner.m_TMPC.myHUD).MouseWorldLocation;
	ownerloc = m_owner.Location;
	ownerloc.Z += m_owner.Mesh.Translation.Z;
	mouseloc.Z = ownerloc.Z; // Prevent weird scaling and rotation

	// Change the indicator color based on the cast location
	if( m_owner.GetAbilityComponent() != none ) 	// NOTE: i really don't want this check, I'll remove it
	{ 												// during the huge TMAbilityIndicator refactor
		if( m_owner.GetAbilityComponent().IsLocationCastable( mouseloc ) )
		{
			// I can cast the ability, so the indicator is green
			m_matInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.GreenHSV.X);
		}
		else
		{
			// I can't cast the ability, so make the indicator red
			m_matInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.RedHSV.X);
		}
	}

	switch (m_Style)
	{
	case AIS_AOE:
		m_indicator.SetTranslation(mouseloc);
		m_indicator.SetScale(4.0f); //temp
	case AIS_TAR:
		m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.TargetMat');
		tarsplotch = TMAbilityTarSplotch(m_owner.GetAbilityComponent());
		if (tarsplotch != none)
		{
			// See if there is a tarsplotch to ignite
			for (i = 0; i < m_owner.m_TMPC.m_TarSplotches.Length; i++)
			{
				if (!m_indicator.HiddenGame &&
					!m_owner.m_TMPC.m_TarSplotches[i].m_IsOnFire &&
					tarsplotch.IsInRange(mouseloc, m_owner.m_TMPC.m_TarSplotches[i].m_Location, tarsplotch.m_DamageRadius))
				{
					m_indicator.SetMaterial(0, Material'SelectionCircles.Materials.IndicatorFireMat');
					break;
				}
			}
		}
	case AIS_MINES:
		m_indicator.SetTranslation(mouseloc);
		m_indicator.SetScale( 2.5 );
		break;
	case AIS_WALL:
		m_indicator.SetTranslation(mouseloc);
		newScale.X = 1;
		newScale.Y = 5;
		newScale.Z = 1;
		m_indicator.SetScale3D(newScale);
		m_indicator.SetRotation(rotator(mouseloc - ownerloc));
		break;
	case AIS_DASH:
		if (m_owner.GetAbilityComponent() != none)
		{
			distToMouse = VSize(mouseloc-ownerloc);
			if (distToMouse > m_owner.GetAbilityComponent().m_iRange)
			{
				maxrangeloc = mouseloc - ownerloc;
				maxrangeloc /= distToMouse;
				maxrangeloc *= m_owner.GetAbilityComponent().m_iRange;
				mouseloc = ownerloc + maxrangeloc;
			}
		}
		m_indicator.SetTranslation((mouseloc + ownerloc) / 2);
		newScale.Y = 1;
		newScale.Z = 1;
		newScale.X = VSize(mouseloc - ownerloc) / 100;
		m_indicator.SetScale3D(newScale);
		m_indicator.SetRotation(rotator(mouseloc - ownerloc));
		break;
	case AIS_NUKE:
		m_indicator.SetTranslation(mouseloc);
		m_indicator.SetScale(5);
		m_indicator.SetRotation(rotator(mouseloc - ownerloc));
		break;
	default:
		`log("no type found", true, 'justin');
		break;
	}
}

simulated function Hide()
{
	m_indicator.SetHidden(true);
}

simulated function Show()
{
	m_indicator.SetHidden(false);
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=Indicator
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		CollideActors=false
		DepthPriorityGroup=SDPG_Foreground
	End Object
	m_indicator=Indicator
}
