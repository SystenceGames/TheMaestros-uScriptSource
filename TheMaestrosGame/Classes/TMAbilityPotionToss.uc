/*
	Identifiers:
		ABILITY NAME (in Json): "PotionToss" (must == abfe.ability)
		(AbilityFE ability): "PotionToss"
		(FE commandType): "C_PotionHitUnit" for callback
*/

class TMAbilityPotionToss extends TMAbility
	DependsOn(TMFOWSightInfo);

var float TRANSFORM_RADIUS;

var ParticleSystem m_PotionProjEffect;
var string m_PotionType;

var ParticleSystem m_TransformParticleSystem;

var float POTION_PROJECTILE_SPEED;

//var bool m_bTossing;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_sAbilityName = "C_PotionToss";
	m_iRange = 1000;
	// m_PotionProjEffect = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Muzzle_Special_Projectile';
	m_PotionProjEffect = ParticleSystem'transformpoint.Particles.P_Potion_Projectile';

	mCooldown = json.GetIntValue("cooldown") / 100;
	m_iRange = json.GetIntValue("range");
	mIsInstantCast = true;
	m_PotionType = "Oiler";

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityPotionToss newcomp;
	newcomp = new () class'TMAbilityPotionToss'(self);
	newcomp.m_owner = newowner;
	newcomp.m_PotionProjEffect = m_PotionProjEffect;
	newcomp.m_PotionType = m_PotionType;
	newComp.mIsInstantCast = true;
	m_PotionType = "Oiler";

	m_PotionProjEffect = ParticleSystem'transformpoint.Particles.P_Potion_Projectile';

	return newComp;
}

function Cleanup()
{
	super.Cleanup();
	m_owner.ClearAllTimers( self );
}

function StopAbility()
{
	if ( m_AbilityState != AS_COOLDOWN )
	{
		m_owner.UpdateUnitState( TMPS_IDLE );
		m_AbilityState = AS_IDLE;
		m_owner.ClearAllTimers( self );
	}

	super.StopAbility();
}

function CastAbility()
{
	local TMPotionProjectile proj;
	local bool hasPotion;
	local string potionType;
	local TMPotionStack potionStack;
	local array<TMPawn> pawnList;
	local TMPawn closestRambam;
	local float minDist;
	local float distance;
	local TMPawn tempPawn;
	local TMAttackFE fe;
	
	/*
	if(m_Owner.m_TMPC.m_CurrentPotionType == m_Target.m_UnitType)
	{
		UDKRTSPCPlayerController(m_Owner.GetTMPC()).ClientPlayNotification("Invalid transformation!", 500);
		return;
	}
	
	if(m_Owner.OwnerReplicationInfo != m_Target.OwnerReplicationInfo)
	{
		UDKRTSPCPlayerController(m_Owner.GetTMPC()).ClientPlayNotification("Invalid transformation!", 500);
		return;
	}
	*/

	// Find the closest Rambam!
	closestRambam = None;
	pawnList = m_Owner.m_TMPC.GetTMPawnList();
	
	foreach pawnList(tempPawn)
	{
		if(tempPawn.m_UnitType == "RamBam" && 
			IsValidTransform(tempPawn, m_Owner.m_TMPC.m_CurrentPotionType) )
		{
			closestRambam = tempPawn;
			minDist = VSize(tempPawn.Location - m_Owner.Location);
			break;
		}
	}

	if(closestRambam == None)
	{
		if(m_Owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_Standalone)
		{
			UDKRTSPCPlayerController(m_Owner.GetTMPC()).ClientPlayNotification("No Rambams Nearby!", 100); // Make it overwrite if the current one is the same?
		}
		return;
	}

	foreach pawnList(tempPawn)
	{
		distance = VSize(m_Owner.Location - tempPawn.Location);

		if(distance < minDist && 
			tempPawn.m_UnitType == "RamBam" && 
			IsValidTransform(tempPawn, m_Owner.m_TMPC.m_CurrentPotionType) )
		{
			minDist = distance;
			closestRambam = tempPawn;
		}
	}
	
	if(minDist > TRANSFORM_RADIUS)
	{
		if(m_Owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_Standalone)
		{
			UDKRTSPCPlayerController(m_Owner.GetTMPC()).ClientPlayNotification("No nearby Rambams!", 100); // Make it overwrite if the current one is the same?
		}
		return;
	}

	m_Target = closestRambam;
	m_TargetLocation = closestRambam.Location;
	
	// Make sure the player has a potion of the current type
	hasPotion = false;
	potionType = m_Owner.m_TMPC.m_CurrentPotionType;
	
	foreach m_Owner.m_TMPC.m_Potions(potionStack)
	{
		if(potionStack.m_UnitType == potionType && potionStack.m_Count > 0)
		{
			hasPotion = true;
			break;
		}
	}
	
	if(!hasPotion)
	{
		if(m_Owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_Standalone)
		{
			UDKRTSPCPlayerController(m_Owner.GetTMPC()).ClientPlayNotification("Insufficient potions!", 100);
		}

		return;
	}

	if(m_Owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_Standalone)
	{
		m_Owner.m_TMPC.UsePotion(m_Owner.m_TMPC.m_CurrentPotionType);
	}
	else
	{
		m_Owner.m_TMPC.DecrementPotionLocally(m_Owner.m_TMPC.m_CurrentPotionType, 1);
	}

	// Dru TODO: It's dumb that this happens here, but then happens on client through FE, let's make them both occur through FE
	proj = m_Owner.Spawn(class'TMPotionProjectile',,, m_Owner.Location, m_Owner.Rotation);
	proj.FirePotionProjectile( m_Target, m_owner, m_PotionProjEffect, 1000, "C_PotionHitUnit", m_Owner.m_TMPC.m_CurrentPotionType );

	fe = new() class'TMAttackFE';
	fe.commandType = "C_SpawnPotionProjectile";
	fe.pawnId = m_Owner.pawnId;
	fe.targetId = m_Target.pawnId;
	m_Owner.SendFastEvent(fe);

	m_target.SetReceivingPotion( true ); // dru's hack
}

function bool IsValidTransform(TMPawn pawn, string potionType)
{
	if ( !m_owner.IsValidPawn( pawn ) || 
		pawn.m_UnitType == potionType ||
		pawn.bReceivingPotion ||
		pawn.OwnerReplicationInfo != m_owner.OwnerReplicationInfo)
	{
		return false;
	}

	return true;
}

function PotionHitUnit(TMFastEvent fe)
{
	local vector targetLoc;
	local TMPawn newUnit;
	local TMPlayerReplicationInfo repInfo;
	local int popCost;
	local TMPawn iterPawn;

	iterPawn = m_Owner.m_TMPC.GetPawnByID(fe.targetId);

	if ( m_owner != None && !m_owner.IsValidPawn( iterPawn ) )
	{
		return;
	}

	// Spawn cocoon and delete target pawn
	// On server - go through TMPC?

	targetLoc = iterPawn.Location;
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale(m_TransformParticleSystem, m_owner.m_allyId, m_owner.GetTeamColorIndex(), targetLoc, 0.75f);

	if(m_Owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_Standalone)
	{
		targetLoc = iterPawn.Location;
		repInfo = TMPlayerReplicationInfo(m_Owner.OwnerReplicationInfo);

		// Only spawn once - on the server!
		popCost = TMGameInfo(m_Owner.WorldInfo.Game).GetPopulationCost(m_Owner.m_TMPC.m_CurrentPotionType);

		if(popCost <= repInfo.PopulationCap - (repInfo.Population - iterPawn.m_Unit.m_Data.mPopulationCost))
		{
			// iterPawn.TakeDamage(99999, m_Owner.m_TMPC, iterPawn.Location, Vect(0.f, 0.f, 0.f), None);
			iterPawn.OwnerReplicationInfo.Population -= iterPawn.PopulationCost;
			iterPawn.removeActiveSelection();
			iterPawn.Destroy();
			// m_Owner.m_TMPC.UsePotion(m_Owner.m_TMPC.m_CurrentPotionType);

			/* GGH: OLD (WORKING) POTION CODE!
			newUnit = TMGameInfo(m_Owner.WorldInfo.Game).RequestUnit(fe.string1, TMPlayerReplicationInfo(m_Owner.OwnerReplicationInfo), targetLoc, false, targetLoc, None, true);
			newUnit.SendFastEvent(class'TMFastEventSpawn'.static.create(newUnit.pawnId, newUnit.Location, true));
			*/
			newUnit = TMGameInfo(m_Owner.WorldInfo.Game).RequestUnit("Egg", TMPlayerReplicationInfo(m_Owner.OwnerReplicationInfo), targetLoc, false, targetLoc, None, true);
			newUnit.SendFastEvent(class'TMFastEventSpawn'.static.create(newUnit.pawnId, newUnit.Location, true));

			newUnit.SendFastEvent(class'TMEggSetupFE'.static.create(newUnit.pawnId, fe.string1));
		}
		else
		{
			// Alert!
			UDKRTSPCPlayerController(m_Owner.GetTMPC()).ClientPlayNotification("Population limit reached!", 500);
		}
	}
}

function HandleAbility()
{
	m_TargetLocation = m_Owner.Location;

	if (m_AbilityState != AS_IDLE)  // ability is on cooldown
	{
		return;
	}

	if (mIsInstantCast ||  IsInRange(m_owner.Location, m_TargetLocation, m_iRange) )
	{
		m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, "C_StopAttack" ) );
		CastAbility();
	}
	else
	{
		MoveToTargetLocation();
	}
}

function ReceiveFastEvent(TMFastEvent fe)
{
	local TMAbilityFE abilityFE;

	if(fe.commandType == ABILITY_COMMAND_TYPE)
	{
		abilityFE = class'TMAbilityFE'.static.fromFastEvent(fe);

		if(abilityFE.ability == m_sAbilityName)
		{
			// `log("SHIT IS GOING DOWN", true, 'Graham');
			m_PotionType = abilityFE.detailString;
		}
	}

	if(fe.commandType == "C_SpawnPotionProjectile")
	{
		SpawnPotionProjectile(fe.targetId);
	}

	super.ReceiveFastEvent(fe);
	
	if(fe.commandType == "C_PotionHitUnit")
	{
		// `log("Potion hit unit!", true, 'Graham');
		PotionHitUnit(fe);
	}

	
}

simulated function SpawnPotionProjectile(int pawnId)
{
	local TMPawn target;
	local TMPotionProjectile proj;

	// Don't do this on server/listen/standalone
	if(m_Owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_Owner.m_TMPC.WorldInfo.NetMode == NM_Standalone)
	{
		return;
	}

	target = m_Owner.m_TMPC.GetPawnByID(pawnId);
	proj = m_Owner.Spawn(class'TMPotionProjectile',,, m_Owner.Location, m_Owner.Rotation);
	proj.FirePotionProjectile( target, m_Owner, m_PotionProjEffect, 1000 , "dontSend", "" ); // only on client, so we say "dontSend", and doesn't look like an attack ("") - dru
}


DefaultProperties
{
	TRANSFORM_RADIUS = 600;
	POTION_PROJECTILE_SPEED = 2.0f;
	m_PotionType = "Oiler";

	m_TransformParticleSystem =	ParticleSystem'VFX_Adam.Particles.P_NeutralOrb_SpawnAlchemist';
}
