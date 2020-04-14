class TMUnit extends Object;

var TMPawn m_owner;

struct UnitJsonData
{
	var int health;
	var int moveSpeed;
	var float animRatio;
	var SkeletalMesh m_skeletalMesh;
	var int mPopulationCost;
};

//used in attack comp and inited in animation
struct AnimationInfo
{
	var float attackTimeNotification;
	var float animationDuration;
};

var AnimationInfo m_attackInfo;


var float m_AlchTransformTime;
var UnitJsonData m_Data;
var string m_unitDataPath;
var string m_UnitName;
var float m_scale;
var float m_helpRadius;
var float m_healAmount;
var float m_healRadius;
var float m_lineOfSight;

var float m_BruteNexus1v1Health;
var float m_BruteNexus2v2Health;
var float m_BruteNexus3v3Health;//this is used 
var float m_fSpeedPercentIncrease;
var float m_fDamagePercentIncrease;


var float m_agroRange;
var string m_meshName;
var string m_staticMesh;
var float m_attackRange;
//add other types here, this is just temp stuff
enum UnitType {COMMANDER, BASIC};
var UnitType m_eUnitType; /** i.e. COMMANDER, BASIC, etc. */

var array<TMComponent> m_componentArray;
var TMAbility m_ComponentAbility;

var float m_fEngageRange;

var float m_fMoveSpeed;

function LoadUnitData(JSONObject unitJson)
{
	InitUnitData(unitJson);
	ParseComponents(unitJson);
}

function DoUpdateCopy(TMUnit unit, TMPawn owner) {
	local int i;
	local vector meshoffset;
	local float maxHorizontal;

	m_owner=owner;
	if(unit.m_meshName != "")
	{
		m_Data.m_skeletalMesh = SkeletalMesh(DynamicLoadObject(unit.m_meshName,class'SkeletalMesh',false));
		m_owner.Mesh.SetSkeletalMesh(m_Data.m_skeletalMesh);
		m_owner.Mesh.SetScale(m_scale);
	}
	
	unit.m_attackInfo.animationDuration = m_attackInfo.animationDuration;
	unit.m_attackInfo.attackTimeNotification = m_attackInfo.attackTimeNotification; 
	meshoffset=m_owner.Mesh.Translation;
	meshoffset.Z-= m_owner.Mesh.Bounds.BoxExtent.Z;
	m_owner.Mesh.SetTranslation(meshoffset * m_scale);
	if(m_owner.IsAuthority())
	{
		m_owner.HealthMax = m_Data.health;
		m_owner.Health = m_Data.health;
		i = TMGameInfo(owner.WorldInfo.Game).NumBots + TMGameInfo(owner.WorldInfo.Game).NumPlayers;
		if(i <= 2 && m_BruteNexus1v1Health != 0)
		{
			m_owner.Health = m_BruteNexus1v1Health;
			if( m_UnitName == "Nexus" || m_UnitName == "Brute" || m_UnitName == "Brute_Tutorial" ) 	// This is kinda BS. These unit name checks should be something else
			{
				m_owner.Health = m_BruteNexus1v1Health / 2;
			}
			m_owner.HealthMax = m_BruteNexus1v1Health;
			unit.m_Data.health = m_BruteNexus1v1Health;
		}
		else if(i <=4 && m_BruteNexus2v2Health != 0)
		{
			m_owner.Health = m_BruteNexus2v2Health;
			if( m_UnitName == "Nexus" || m_UnitName == "Brute")
			{
				m_owner.Health = m_BruteNexus2v2Health / 2;
			}
			m_owner.HealthMax = m_BruteNexus2v2Health;
			unit.m_Data.health =m_BruteNexus2v2Health;
		}
		else if( i <=6 && m_BruteNexus3v3Health != 0)
		{
			m_owner.Health = m_BruteNexus3v3Health;
			if( m_UnitName == "Nexus" || m_UnitName == "Brute")
			{
				m_owner.Health = m_BruteNexus3v3Health / 2;
			}
			m_owner.HealthMax =m_BruteNexus3v3Health;
			unit.m_Data.health =m_BruteNexus3v3Health;
		}
		
	}
	
	m_owner.PopulationCost = m_Data.mPopulationCost;
	m_fMoveSpeed = m_Data.moveSpeed;
	m_owner.GroundSpeed = m_Data.moveSpeed;
	m_fDamagePercentIncrease = 1;

	if(unit.m_UnitName == "Nexus" && m_owner.m_TMPC.IsClient())
	{
		m_owner.m_nexusDestructable = m_owner.m_TMPC.mDestructableShrine;
		meshoffset = m_owner.Location;
		meshoffset.Z -= m_owner.Mesh.Bounds.BoxExtent.Z * m_scale;
		m_owner.m_nexusDestructable.SetLocation( meshoffset );
		m_owner.m_nexusDestructable.SetHidden( true );
	}

	maxHorizontal = Max((m_owner.Mesh.Bounds.BoxExtent.X), (m_owner.Mesh.Bounds.BoxExtent.Y));
	m_owner.SetCollisionSize((maxHorizontal * m_scale) * 0.5f, (m_owner.Mesh.Bounds.BoxExtent.Z) * m_scale);
	
	for(i=0; i<unit.m_componentArray.Length; i++) {
		m_componentArray[i]=unit.m_componentArray[i].makeCopy(owner);
	}
}

function InitUnitData(JsonObject json)
{
	local string choice;
	local float value;
	local int intVal;
	choice = "";

	
	m_fEngageRange = 800;

	m_fDamagePercentIncrease = 1;

	
	// load name
	choice = "";
	choice = json.GetStringValue("UN");
	if(choice != "")
	{
		self.m_UnitName = choice;
	}


	// load mesh
	choice = json.GetStringValue("SM");
	//if we have these choices then we are a skeletal, otherwise we will be a static mesh
	if(choice != "")
	{
		m_meshName=choice;
		m_Data.m_skeletalMesh = SkeletalMesh(DynamicLoadObject(m_meshName,class'SkeletalMesh',false));
	}
	else
	{
		m_staticMesh=choice;
	}	

	m_lineOfSight = json.GetFloatValue("LOS");
	if(m_lineOfSight == 0)
	{
		m_lineOfSight = 1;
	}

	//help radius 
	m_helpRadius = json.GetFloatValue("HR");
	if(m_helpRadius == 0)
	{
		m_helpRadius = 1;
	}

	//this is the amount a unit is healed in the radius around the commander
	m_healAmount = json.GetFloatValue("HealAmount");

	m_scale = json.GetFloatValue("S");
	if(m_scale == 0)
	{
		m_scale = 1;
	}



	// Get the unit's health
	intVal = json.GetIntValue("H");
	if(intVal != 0)
	{
		m_Data.health = intVal;
	}
	else
	{
		m_Data.health = 100;    // default values
	}

	// Get the unit's population cost
	intVal = json.GetIntValue("PC");
	m_Data.mPopulationCost = intVal;


	// Get the units movement speed
	value = json.GetFloatValue("MS");
	m_Data.moveSpeed = value;

	value = json.GetFloatValue("AR");
	if(value != 0.0f)
	{
		m_Data.animRatio = value * m_Data.moveSpeed;
	}
	else
	{
		m_Data.animRatio = 1.0f;
	}


	value = json.GetFloatValue("AG");
	if(value != 0.0f)
	{
		m_agroRange = value;
	}
	else
	{
		m_agroRange = 300;
	}
}

// Dru TODO: WASH ME PLZ, I'M 300 LINES LONG
function ParseComponents(JSONObject unitJson)
{
	//here we will find out what components the unit will have
	local TMComponent comp;
	local string choice;
	local JsonObject json;
	local string abilityName;
	local string unitName;

	unitName = unitJson.GetStringValue("UN");

	// Add the attack component
	json = unitJson.GetObject("attack");
	if(json != none)
	{
		comp = new() class'TMComponentAttack';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
		m_attackRange = TMComponentAttack(comp).m_iRange;
	}


	json = unitJson.GetObject("healRadius");
	if(json != none)
	{
		m_healRadius = json.GetFloatValue("distance");
	}


	json = unitJson.GetObject("HealthScaling");
	if(json != none)
	{
		m_BruteNexus1v1Health = json.GetFloatValue("1v1");
		m_BruteNexus2v2Health = json.GetFloatValue("2v2");
		m_BruteNexus3v3Health = json.GetFloatValue("3v3");
	}

	json = unitJson.GetObject("spawnBuff");
	if(json != none)
	{
		comp = new() class'TMComponentSpawnBuffs';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp = none;
	json = unitJson.GetObject("attackKnockBack");
	if(json != none)
	{
		comp = new() class'TMComponentAttackPushBack';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
		m_attackRange = TMComponentAttack(comp).m_iRange;
	}
	comp = none;
	json = unitJson.GetObject("attackLaser");
	if(json != none)
	{   
		comp = new() class'TMComponentAttackLazer';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
		m_attackRange = TMComponentAttack(comp).m_iRange;
	}
	comp = none;
	json = unitJson.GetObject("attackRailGun");
	if(json != none)
	{
		comp = new() class'TMComponentAttackRailGun';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
		m_attackRange = TMComponentAttack(comp).m_iRange;

	}
	comp = none;
	json = unitJson.GetObject("attackOiler");
	if(json != none)
	{
		comp = new() class'TMComponentAttack';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
		m_attackRange = TMComponentAttack(comp).m_iRange;
	}

	comp = none;
	
	if(unitJson.HasKey("HealthR"))
	{
		comp = new() class'TMComponentHealthRegen';
		comp.SetUpComponent(unitJson, m_owner);
		m_componentArray.AddItem(comp);
	}

	// NOTE!!!! This must be added before potion toss or ghost. It's hacky as shit, but this needs to be the first ability added to salvator's component array
	json = unitJson.GetObject("abilityWormHole");
	if(json != none)
	{
		comp = new() class'TMAbilitySalvatorSnake';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp = none;
	json = unitJson.GetObject("AlchemistTransform");
	if(json != none)
	{
		m_AlchTransformTime = json.GetFloatValue("time");
		comp = new() class'TMComponentAlchTransf';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp = none;
	json = unitJson.GetObject("TugOfWar");
	if(json != none)
	{
		comp = new() class'TMComponentTugOfWar';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp = none;
	json = unitJson.GetObject("JustEggyThings");
	if(json != none)
	{
		comp = new() class'TMComponentEgg';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	// Add the unit's ability (if applicable)
	json = unitJson.GetObject("ability");
	if(json != none)
	{
		abilityName = json.GetStringValue("abilityName");
		// Choose the abiltiy to create
		if (abilityName == "SniperMine")
		{
			comp = new() class'TMAbilitySniperMine';
		}
		else if (abilityName == "TarSplotch")
		{
			comp = new() class'TMAbilityTarSplotch';
		}
		else if (abilityName == "SplitterCharge")
		{
			comp = new() class'TMAbilitySplitterCharge';
		}
		else if( abilityName == "PopSpring" )
		{
			comp = new() class'TMAbilityPopSpring';
		}
		else if( abilityName == "ConductorShock")
		{
			comp = new () class'TMAbilityConductorShock';
		}
		else if( abilityName == "Teleport")
		{
			comp = new () class'TMAbilityTeleport';
		}
		else if( abilityName == "RosieTimeBubble")
		{
			comp = new () class'TMAbilityRosieTimeBubble';
		}
		else if( abilityName == "DisruptorTrail")
		{
			comp = new () class'TMAbilityDisruptorTrail';
		}
		else if( abilityName == "RegeneratorField")
		{
			comp = new () class'TMAbilityRegeneratorField';
		}
		else if( abilityName == "roboMeisterNuke" )
		{
			comp = new () class'TMAbilityRoboMeisterNuke';
		}
		else if ( abilityName == "RocketTurtleMissle" )
		{
			comp = new () class'TMAbilityRocketTurtleMissle';
		}
		else if ( abilityName == "RamBamEgg" )
		{
			comp = new () class'TMAbilityRambamQueenEgg';
		}
		else if ( abilityName == "HiveLordBuzz" )
		{
			comp = new () class'TMAbilityHiveLordBuzz';
		}
		else if ( abilityName == "ShotgunBlast" )
		{
			comp = new () class'TMAbilityShotgunBlast';
		}

		if(comp != none)
		{
			comp.SetUpComponent(json, m_owner);
			m_componentArray.AddItem(comp);
			m_ComponentAbility = TMAbility(comp);
		}
	}

	// Add potion toss if it's an alchemist commander
	json = unitJson.GetObject("VineBurrow");
	if(json != None)
	{
		comp = new () class'TMComponentVineBurrrow';
		comp.SetUpComponent(json, m_Owner);
		m_componentArray.AddItem(comp);
	}
	

	json = unitJson.GetObject("PotionToss");
	if(json != None)
	{
		comp = new () class'TMAbilityPotionToss';
		comp.SetUpComponent(json, m_Owner);
		m_componentArray.AddItem(comp);
	}

	json = unitJson.GetObject("abilityVineCrawlerWaller");
	if(json != none)
	{
		comp = new() class'TMAbilityVineCrawlerWaller';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp=none;
	json = unitJson.GetObject("abilityGhost");
	if(json != none)
	{
		comp = new() class'TMAbilityGhost';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp =none;
	json = unitJson.GetObject("Decay");
	if(json != none)
	{
		comp = new() class'TMComponentDecay';
		comp.SetUpComponent(json, m_owner);
		m_componentArray.AddItem(comp);
	}

	comp = none;

	json = unitJson.GetObject("VineCrawler_Wall_Info");
	if(json != None)
	{
		if(unitName == "VineCrawler_Wall")
		{
			comp = new() class'TMComponentVineCrawlerWall';
			comp.SetUpComponent(json, m_Owner);
			m_ComponentArray.AddItem(comp);
		}
	}

	comp = none;

	json = unitJson.GetObject("Nexus");
	if(json != None)
	{
		if(unitName == "Nexus")
		{
			comp = new() class'TMComponentNexus';
			comp.SetUpComponent(json, m_Owner);
			m_ComponentArray.AddItem(comp);
		}
	}

	json = unitJson.GetObject("NexusCommander");
	if(json != None)
	{
		if(unitName == "NexusCommander")
		{
			comp = new() class'TMComponentNexusCommander';
			comp.SetUpComponent(json, m_Owner);
			m_ComponentArray.AddItem(comp);
		}
	}

	json = unitJson.GetObject("Tower");
	if(json != None)
	{
		if(unitName == "Tower")
		{
			comp = new() class'TMComponentTower';
			comp.SetUpComponent(json, m_Owner);
			m_ComponentArray.AddItem(comp);
		}
	}

	comp = none;
	json = unitJson.GetObject("Brute");
	if(json != None)
	{
		if(unitName == "Brute")
		{
			comp = new() class'TMComponentBrute';
			comp.SetUpComponent(json, m_Owner);
			m_ComponentArray.AddItem(comp);
		}
	}

	comp = none;
	choice = unitJson.GetStringValue("AT");
	if(choice != "")
	{   
		comp = new () class'TMComponentAnimation';
		comp.SetUpComponent(unitJson,m_owner);
		m_componentArray.AddItem(comp);
	}

	comp = new() class'TMComponentTransformer';
	comp.SetUpComponent(unitJson, m_owner);
	m_componentArray.AddItem(comp);

	if ( m_UnitName != "VineCrawler_Wall" && m_UnitName != "WormHole" ) // this is hacky too. Don't let the vinecrawler wall have a move component
	{
		comp = new () class 'TMComponentMove';
		m_componentArray.AddItem(comp);
	}
}

function UpdateComponents(float dt)
{
	local int i;
	for(i =0; i < m_componentArray.Length; i++)
	{
		m_componentArray[i].UpdateComponent(dt);
	}
}

simulated function StopAttack()
{
	local TMStopFE fe;

	fe = class'TMStopFE'.static.create(self.m_owner.pawnId);
	fe.commandType = "C_Stop_Attack";
	ReceiveFastEvent(fe.toFastEvent());
}

function SendStatusEffect(int statusEffectEnum)
{
	local TMStatusEffectFE seFE;

	if( m_owner.IsAuthority() && m_owner.bCanBeDamaged )
	{
		seFE = class'TMStatusEffectFE'.static.create( m_owner.pawnId, statusEffectEnum );
		m_owner.SendFastEvent( seFE );
	}
}

// If the unit does not currently have the status effect, get a copy of it from the playerController
function SetActiveStatusEffect(int statusEffectEnum)
{
	local TMComponent comp;

	if (IsStatusEffectActive(statusEffectEnum))
	{
		return;
	}

	// If I got to this point, I need the status effect from the playerController
	if (m_owner.WorldInfo.NetMode == NM_DedicatedServer)
	{
		comp = TMGameInfo(m_owner.WorldInfo.Game).StatusEffectCache[statusEffectEnum].makeCopy(m_owner);
	}
	else
	{
		comp = m_owner.m_TMPC.statusEffectCache[statusEffectEnum].makeCopy(m_owner);
	}

	m_componentArray.AddItem(comp);
}

function bool IsStatusEffectActive(int statusEffectEnum)
{
	local int i;
	local TMStatusEffect se;

	// Check if I already have it
	for (i = 0; i < m_componentArray.Length; ++i)
	{
		se = TMStatusEffect(m_componentArray[i]);
		if (se != none)
		{
			if (se.m_StatusEffectName == statusEffectEnum)
			{
				return true; // I already have it!
			}
		}
	}

	return false;   // I don't have it
}

// Removes a status effect from my components list
function RemoveStatusEffect( TMComponent comp )
{
	m_componentArray.RemoveItem(comp);
}

function RemoveFrozenStatusEffect()
{
	local int i;
	local TMStatusEffectFrozen se;

	for (i = 0; i < m_componentArray.Length; i++)
	{
		se = TMStatusEffectFrozen(m_componentArray[i]);
		if (se != none)
		{
			se.End();
			return;
		}
	}
}

function ReceiveFastEvent(TMFastEvent fe)
{
	local int i;
	for(i =0; i < m_componentArray.Length; i++)
	{
		m_componentArray[i].ReceiveFastEvent(fe);
	}
}

defaultproperties
{
	m_fDamagePercentIncrease=1
}