class TMPawn extends UDKRTSPawn;

var(Pawn) ProtectedWrite editconst StaticMeshComponent abilityRangeMesh;
var bool bAbilityMeshScaleSet;
var int MINISPLITTERS_PER_SPLITTER;

enum TMPawnState
{
	TMPS_IDLE,
	TMPS_INVISBLE_SPAWN,
	TMPS_ATTACK,
	TMPS_MOVING,
	TMPS_MOVING_FOLLOW,
	TMPS_STUNNED,
	TMPS_ABILITY,
	TMPS_JUGGERNAUT
};

var TMDestructableShrine m_nexusDestructable;
var TMComponentAttack m_attackComponent;
var TMComponentMove m_moveComponent;
var TMAbility m_abilityComponent;
var TMComponentAnimation mAnimationComponent;
var TMComponentDecay m_decayComponent;
var TMComponentTugOfWar m_tugOfWarComponent;
var TMPawnState m_currentState;
var TMUnit m_Unit;
var TMPawn mPushedBy;
var float SMALL_PUSH_MAGNITUDE;
var bool m_UpdateHash;
var SkeletalMeshComponent m_UnitSkeletal;
var float m_lastMomentHealth;
var Material healthBarMat;
var MaterialInstanceConstant m_healthBarMatInst;
var bool mIsHighlighted,
		 b_hasDecay;
var LinearColor mHighlightColor;

var TMPlayerController m_TMPC;
var TMController m_Controller;

//var int numSpawn;
var bool bIsTransforming;
var bool m_bIsAbilityReady;
var bool bReceivingPotion;

var UDKRTSNavMeshObstacle m_obstable;
var Vector m_pathDestination;
var bool m_bRegistered;
var bool bStunned;
var bool bTeamMaterialSet;
var bool m_bHasLanded;
var bool bFrozen;
var bool mHasBumpedGuyAtDestinationTransitively;
var bool mIsPushable;
var int m_spawnUnveilCount;
var bool bIsCommander;
//this means that after you click with an active command it wont go inactive. used with the 
//skybreaker
var bool mbDontDeselectOnCommandActive;
var MaterialInstanceConstant OccludedMatInst;
var float fDesaturateAmount;
var float fDarkenAmount;

// Target halos
var(Pawn) ProtectedWrite editconst StaticMeshComponent DragSelectionMesh;
var MaterialInstanceConstant DragMeshMatInst;
var(Pawn) ProtectedWrite editconst StaticMeshComponent TargetMesh;
var MaterialInstanceConstant TargetMeshMatInst;
var TMAbilityIndicator AbilityIndicator;
var(Pawn) ProtectedWrite editconst StaticMeshComponent AbilityTargetMesh;
var MaterialInstanceConstant AbilityTargetMeshMatInst;
var TMPawn m_followTarget; /** for following freindlies, so we don't push them around */
var Pawn TargetedPawn;
var TMTransformer TargettedTransformer;
var float TargetFadeAmount;
var MaterialInstanceConstant m_dottedSelectionMesh;
var MaterialInstanceConstant m_filledSelectionMesh;

var bool m_bPaintTarget;
var vector m_vPaintTargetLocation;

var bool bCanBeHitByNuke;

var bool forceTick;
var float missedTicks;
var bool bIsInitialized;
var bool bCanBeKnockedUp;
var bool bCanBeKnockedBack;

var bool mIsGhost;
var bool mIsShowingTookDamage;

var TMComponent m_TransformComponent;

enum TargetType {
	ENONE,
	ELOCATION,
	EPAWN,
	EABILITY,
	ETRANSFORMER,
};
var TargetType CurrTargetType;

/** Whether this unit is subject to visibility checks, or not. */
var bool bApplyFogOfWar;
var SkeletalMeshComponent m_UnitOcclusionMesh;

var float m_currentLifeTime; //how long has this unit been living for

var array<TMFastEvent> m_CommandQueue;
// Player replication info that owns this pawn
//var RepNotify ProtectedWrite TMPlayerReplicationInfo OwnerReplicationInfo;

var repnotify int m_allyId; // allyId represents a team of players   // DO NOT CHANGE, IT WILL NOT REPLICATE AS IS
var repnotify int m_owningPlayerId; // playerId represents the player controlling this unit   // DO NOT CHANGE, IT WILL NOT REPLICATE AS IS
var repnotify string m_UnitType;
var repnotify int pawnId; // DO NOT CHANGE, IT WILL NOT REPLICATE

/** The number of tiles that are visible to this pawn in each direction. */
var repnotify int sightRadiusTiles;

// Temporarily use this to keep track of our current tower unit in nexus commanders
var string nexuscommander_current_unit;

replication
{
	if(bNetDirty)
		m_UnitType, m_currentState, bIsInitialized;//, m_UpdateHash;

	if(bNetInitial)
		pawnId, m_allyId, m_owningPlayerId, sightRadiusTiles;  // This stops them from replicating again. It should never change after it is initially set.
}

/**
 * You shouldn't use this for determining things in The Maestros!!! (it doesn't do what it implies)
 */
simulated function TeamInfo GetTeam()
{
	return super.GetTeam();
}

/** This function should never be called outside of TMFoWManager.ShowAPawn()!!!
 *  Shows this unit if it's hidden and subject to visibility checks. */
simulated function Show()
{
	if (bApplyFogOfWar)
	{
		SetHidden(false);
		Mesh.SetHidden(false);
	}
}

/** Dru's hacky solution to not throwing potions at the same dude */
simulated function SetReceivingPotion(bool isReceiving)
{
	bReceivingPotion = isReceiving;
	if ( isReceiving )
	{
		SetTimer(0.95, false, NameOf(DidntReceivePotion), );
	}
}

/** Dru's hacky solution to not throwing potions at the same dude, part 2 */
simulated function DidntReceivePotion()
{
	bReceivingPotion = false;
}

/** This function shouldn't be called outside of TMFoWManager.HideAPawn()!!!
 *  Hides this unit if it's visible and subject to visibility checks. */
simulated function Hide()
{
	if (bApplyFogOfWar)
	{
		SetHidden(true);
		Mesh.SetHidden(true);
	}
}

/**
 * Calculate power for a pawns  (varies between 0 to 1f)
 */
function float GetPower()
{
	local float power;
	power = 0;

	if (IsCommander())
	{
		power += (Health / float(HealthMax)) * 100;
	}
	else if(GetUnitType() == "DoughBoy")
	{
		power += PopulationCost * (Health / float(HealthMax)) * 25;
	}
	else
	{
		power += PopulationCost * (Health / float(HealthMax)) * 50;
	}
	power /= 1000.f;
	return power > 0 ? power : 0.f;
}

simulated event ReplicatedEvent( name VarName )
{
	local string cacheName;
	local TMPlayerController PC;
	local int i;
	local TMPlayerController tmpc;

	super.ReplicatedEvent( VarName );

	if( VarName == 'm_UnitType' )	
	{
		foreach self.WorldInfo.AllControllers(class'TMPlayerController', PC)
		{
			for(i = 0;i < PC.unitCache.Length; i++)
			{
				cacheName = m_TMPC.unitCache[i].m_UnitName;
				if(cacheName == self.m_UnitType)
				{
					SetupUnit(PC.unitCache[i]);
					CheckForSelection();
				}
			}
		}
	}

	if( VarName == 'pawnId' )
	{
		// Add to local hash
		foreach LocalPlayerControllers(class'TMPlayerController', tmpc)
		{
			tmpc.AddPawnToHash(pawnId, self);
			tmpc.AddTMPawnToTMPawnList(self);
		}
	}
	
	if( VarName == 'Health' )
	{
		// If our last moment is higher, than we took damage
		if(m_lastmomenthealth > Health)
		{
			ShowTookDamage();
		}
	}
}

//means this unit should be quick selected if his controller group is on deck
simulated function CheckForSelection()
{
	//  Taylor TODO: remove this check. Maybe add bIsSelectable?
	// God help us all, this is a ugly
	if( m_Unit.m_UnitName == "VineCrawler_Wall" )
	{
		// Never add the vinecrawler wall to selected units
		return;
	}

	if(m_TMPC != none )
	{
		if( m_TMPC.m_CurrentHotSelectedGroup == "All" && m_owningPlayerId == m_TMPC.PlayerId)
		{
			m_TMPC.AddActorAsSelected( self );
			self.CommandMesh.SetHidden(false);
		}
		else if(m_TMPC.m_CurrentHotSelectedGroup == self.m_UnitType && m_owningPlayerId == m_TMPC.PlayerId)
		{
			m_TMPC.AddActorAsSelected( self );
			self.CommandMesh.SetHidden(false);
		}
		else if (m_TMPC.m_CurrentHotSelectedGroup == "AllButCommander" && m_owningPlayerId == m_TMPC.PlayerId && TMPlayerReplicationInfo(OwnerReplicationInfo).commanderType != m_Unit.m_UnitName )
		{
			m_TMPC.AddActorAsSelected( self );
			self.CommandMesh.SetHidden(false);
		}
	}

}

simulated function bool IsInitialized()
{
	return bIsInitialized;
}


simulated function UpdateUnitState( TMPawnState newState )
{
	m_currentState = newState;
}


simulated function Selected()
{
	super.Selected();
	if (Health <= 0)
	{
		CommandMesh.SetHidden(true);
	}
	else
	{
		if(IsAuthority() && self.WorldInfo.RealTimeSeconds > 2 && !bHidden)
		{
			m_TMPC.m_AudioManager.requestPlayCharacterVO(C_SelectUnit, m_Unit.m_UnitName);
		}
		
	}
}

simulated function Deselected()
{
	super.Deselected();
}

simulated function TargetAPawn(Pawn theTarget, bool targetIsAlly)
{
	//if(theTarget.pawnId != pawnId)
	if(theTarget != self)
	{
		CurrTargetType = EPAWN;
		SetTimer(1.f, false, NameOf(Untarget));
		SetTimer(0.3f, true, NameOf(FadeTarget));

		TargetedPawn = theTarget;
		TargetMesh.SetHidden(false);
		if (targetIsAlly)
		{
			TargetMeshMatInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.GreenHSV.X);
		}
		else
		{
			TargetMeshMatInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.RedHSV.X);
		}
	}

	if ( TMSalvatorSnake( theTarget ) != None )
	{
		TargetMesh.SetScale( 4.0f );
	}
	else if ( TMPawn( theTarget ) != None  && TMPawn( theTarget ).m_UnitType == "Nexus")
	{
		TargetMesh.SetScale( 6.0f );
	}
	else
	{
		TargetMesh.SetScale( 1.0f );
	}
}

simulated function ShowMouseHoverEffect()
{
	SetHighlighted(true);
	SetHighlightColor(1.0f,1.0f,1.0f,1.0f);
}

simulated function HideMouseHoverEffect()
{
	// Currently our mouse hover effect is a highlight, which conflicts with our taken damage effect
	if( mIsShowingTookDamage )
	{
		TurnOnTookDamageHighlight();
		return;
	}

	SetHighlighted(false);
}

simulated function TurnOnTookDamageHighlight()
{
	local float r, g, b, a;

	// Don't damage highlight the dreadbeast or the shrine
	if(self.IsDreadbeast() || self.IsShrine())
	{
		return;
	}

	// Do different took damage highlights depending on who owns the pawn
	if(m_TMPC.PlayerID == GetOwningPlayerId())
	{
		// Color when your pawns are damaged
		r = 1.0f;
		g = 0.25f;
		b = 0.0f;
		a = 1.0f;
	}
	else if(m_TMPC.m_allyId == m_allyId)
	{
		// Color when your teammates' pawns are damaged
		r = 1.0f;
		g = 0.75f;
		b = 0.0f;
		a = 1.0f;
	}
	else
	{
		// Color when enemy pawns are damaged
		r = 1.0f;
		g = 0.0f;
		b = 0.0f;
		a = 1.0f;
	}

	mIsShowingTookDamage = true;
	SetHighlighted(true);
	SetHighlightColor(r, g, b, a);
}

simulated function TurnOffTookDamageHighlight()
{
	mIsShowingTookDamage = false;
	SetHighlightColor(1.0f,1.0f,1.0f,1.0f);
	SetHighlighted(false);
}

simulated function ShowTookDamage()
{
	if(m_TMPC.IsClient() == false)
	{
		return;
	}

	TurnOnTookDamageHighlight();
	SetTimer(0.5f, false, nameof(TurnOffTookDamageHighlight));
}

simulated function ShowReadyToCastAbility()
{
	// Use the TargetMesh to target myself with a green circle. This should be its own mesh in the future
	CurrTargetType = EPAWN;
	SetTimer(0.1f, false, NameOf(Untarget));

	TargetedPawn = self;
	TargetMesh.SetHidden(false);
	TargetMeshMatInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.GreenHSV.X);
	TargetMesh.SetScale( 1.0f );
}

simulated function HideReadyToCastAbility()
{
	Untarget();
}

simulated function TargetATransformer(TMTransformer transformer)
{
	CurrTargetType = ETRANSFORMER;
	SetTimer(1.f, false, NameOf(Untarget));
	SetTimer(0.3f, true, NameOf(FadeTarget));

	TargettedTransformer = transformer;
	TargetMesh.SetHidden(false);
	
	TargetMeshMatInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.GreenHSV.X);

	TargetMesh.SetScale( 5.0f );
}

simulated function FadeTarget()
{
	TargetFadeAmount -= 0.1f;
	if (TargetFadeAmount > 0)
	{
		TargetMeshMatInst.SetScalarParameterValue('FadeOut', TargetFadeAmount);
	}
	else
	{
		Untarget();
	}
}

simulated function Untarget()
{
	CurrTargetType = ENONE;
	ClearTimer(NameOf(FadeTarget));
	ClearTimer(NameOf(Untarget));
	TargetMesh.SetHidden(true);
	TargetedPawn = none;

	TargetFadeAmount = 1;
	TargetMeshMatInst.SetScalarParameterValue('FadeOut', TargetFadeAmount);
}

simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local TMAnimationFE animEvent;
	Super.PlayDying(DamageType, HitLoc);


	animEvent = new () class'TMAnimationFE';
	animEvent.m_commandType = "dead";
	animEvent.m_pawnID = pawnId;
	ReceiveFastEvent(animEvent.toFastEvent());
}

simulated function SetHighlighted(bool isHighlighted)
{
	// Don't highlight units that are dead
	if (self.Health <= 0)
	{
		isHighlighted = false;
	}

	// Don't highlight the vinecrawler wall (NOTE: this probably shouldn't be here? idk)
	if (m_Unit.m_UnitName == "VineCrawler_Wall")
	{
		isHighlighted = false;
	}

	m_UnitOcclusionMesh.SetHidden(!isHighlighted);

	if(OccludedMatInst != none)
	{
		if (isHighlighted != mIsHighlighted)
		{
			if (isHighlighted)
			{
				OccludedMatInst.SetScalarParameterValue('IsHighlighted', 1);
			}
			else
			{
				OccludedMatInst.SetScalarParameterValue('IsHighlighted', 0);
			}
			mIsHighlighted = isHighlighted;
		}
	}
}

simulated function SetHighlightColor(float r, float g, float b, float a)
{
	local LinearColor c;

	c.R = r;
	c.G = g;
	c.B = b;
	c.A = a;

	if(OccludedMatInst != none && mHighlightColor != c)
	{
		OccludedMatInst.SetVectorParameterValue('HighlightColor', c);
		mHighlightColor = c;
	}
}

simulated function int GetTeamColorIndex()
{
	return TMPlayerReplicationInfo(OwnerReplicationInfo).mTeamColorIndex;
}

simulated function Color GetTeamColorRGB()
{
	return class'TMColorPalette'.static.GetTeamColorRGB( m_allyId, GetTeamColorIndex() );
}

/**
 * Set hue based on team color index
 */
simulated function Vector GetTeamColorHue()
{
	return class'TMColorPalette'.static.GetTeamColorHSV( m_allyId, GetTeamColorIndex() );
}

/**
 * Use me to compare allyship
 */
simulated function int GetAllyId()
{
	return m_allyId;
}

/**
 * Use me to compare ownership
 */
simulated function int GetOwningPlayerId()
{
	return m_owningPlayerId;
}

/**
 * Not simulated for a reason, this should only be called by the server
 */
function SetOwningPlayerId(int id)
{
	m_owningPlayerId = id;
}

/**
 * Not simulated for a reason, this should only be called by the server
 */
function SetAllyId(int id)
{
	m_allyId = id;
}

simulated function bool UpdateAbilityMeshScale()
{
	local TMAbility ability;
	ability = GetAbilityComponent();
	if (ability == none)
	{
		bAbilityMeshScaleSet = true;
		return false;
	}

	abilityRangeMesh.SetScale(2.f * ability.m_iRange / 96);
	
	bAbilityMeshScaleSet = true;
	return true;
}

simulated function bool UpdateTeamMaterials()
{
	local Vector HSV;
	local MaterialInstanceConstant MatInst;
	local float MyMeshCollisionRadius;
	local float CollisionHeight;
	
	if (OwnerReplicationInfo == None)
	{
		`log("NO OWNERREPINFO CAN'T UPDATE MATERIALS YET", true, 'justin');
		return false;
	}
	
	// Default to no team color
	HSV.X = -1;
	HSV.Y = -1;
	HSV.Z = -1;

	// Get team color
	HSV = GetTeamColorHue();

	// Set unit mesh team color
	MatInst = new(None) Class'MaterialInstanceConstant';
	MatInst.SetParent(m_UnitSkeletal.GetMaterial(0));
	MatInst.SetScalarParameterValue('HueShift', HSV.X);
	MatInst.SetScalarParameterValue('SaturationScale', HSV.Y);
	MatInst.SetScalarParameterValue('ValueScale', HSV.Z);

	m_UnitSkeletal.SetMaterial(0, MatInst);

	// Set occlusion mesh skeletal mesh
	m_UnitOcclusionMesh.SetSkeletalMesh(m_UnitSkeletal.SkeletalMesh);

	// Set occlusion mesh team color
	OccludedMatInst = new(None) Class'MaterialInstanceConstant';
	OccludedMatInst.SetParent(m_UnitOcclusionMesh.GetMaterial(0));
	OccludedMatInst.SetScalarParameterValue('HueShift', HSV.X);
	OccludedMatInst.SetScalarParameterValue('SaturationScale', HSV.Y);
	OccludedMatInst.SetScalarParameterValue('ValueScale', HSV.Z);

	// Set occlusion mesh depth check
	OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', m_UnitOcclusionMesh.Bounds.SphereRadius);
	OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', 200);


	// TEMP FOR NEXUS
	if (m_Unit.m_UnitName == "Nexus")
	{
		OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', 20000);
	}

	// TEMP FOR BRUTE
	if (IsDreadbeast())
	{
		OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', 20000);
	}

	m_UnitOcclusionMesh.SetMaterial(0, OccludedMatInst);

	// vinecrawler wallz
	if (m_Unit.m_UnitName == "VineCrawler_Wall")
	{
		m_UnitOcclusionMesh.SetHidden(true);
	}

	// Set command mesh scale
	GetBoundingCylinder(MyMeshCollisionRadius, CollisionHeight);
	CommandMesh.SetScale(2 * MyMeshCollisionRadius / CommandMesh.Bounds.SphereRadius);
	
	// Set up ability indicator
	AbilityIndicator = new class'TMAbilityIndicator';
	AbilityIndicator.Initialize(self);

	// Set up last second health
	m_lastMomentHealth = HealthMax;

	bTeamMaterialSet = true;
	return true;
}

simulated function bool IsDreadbeast()
{
	return (m_Unit.m_UnitName == "Brute" || m_Unit.m_UnitName == "ConvertedBrute");
}

simulated function bool IsShrine()
{
	return (m_Unit.m_UnitName == "Nexus");
}

simulated function ToggleDottedSelectionMesh(bool bIsDotted)
{
	local float MyMeshCollisionRadius;
	local float CollisionHeight;
	local Vector meshPosition;

	if (bIsDotted)
	{
		GetBoundingCylinder(MyMeshCollisionRadius, CollisionHeight);
		DragSelectionMesh.SetScale( 1.25f * CommandMesh.Scale );
		meshPosition = Location;
		meshPosition.Z += Mesh.Translation.Z;
		DragSelectionMesh.SetTranslation( meshPosition );
		DragSelectionMesh.SetHidden( false );
	}
	else
	{
		DragSelectionMesh.SetHidden( true );
	}
}  

simulated function SetOwnerReplicationInfo(UDKRTSPlayerReplicationInfo NewOwnerReplicationInfo)
{
	super.SetOwnerReplicationInfo(NewOwnerReplicationInfo);

	OwnerReplicationInfo = TMPlayerReplicationInfo(NewOwnerReplicationInfo);

	SetAllyInfo();
}



simulated function SendFastEvent(TMFastEventInterface fe)
{
	if(m_TMPC != none) {
		m_TMPC.SendServerFastEvent(fe);
	}
}


simulated function HandleSpawning(TMFastEvent fe)
{
	local TMSpawnProjectile proj;
	local ParticleSystem onHitParticle;
	local Vector particleStartPosition;
	local TMFastEventSpawn spawnFE;
	local TMAttackFe atfe;

	spawnFE = class'TMFastEventSpawn'.static.fromFastEvent( fe );
	
	atfe = new () class'TMAttackFE';
	if( spawnFE.isStartingSpawn ) 	// what is "isStartingPawn"? If it means the units we start the game with it's not implemented that way
	{
		// your own visibility doesn't mean much to neutral unit on the server - no TMPC & thus no FoWManager.
		if ( WorldInfo.NetMode != NM_DedicatedServer || 
			!IsPawnNeutral( self ) )
		{
			if(m_Controller.GetFoWManager().IsLocationVisible(Location))
			{
				m_Controller.GetFoWManager().ShowAPawn(self);
			}
			else
			{
				m_Controller.GetFoWManager().HideAPawn(self);
			}
		}
			
		CheckForSelection();
		atfe.commandType = "C_SpawnFinished";
		atfe.pawnId = pawnId;
		SendFastEvent( atfe );

		if(m_Unit.m_UnitName == "Tower")
		{
			SendStopCommand();
		}
		else if( spawnFE.shouldMove )
		{
			SendFastEvent( class'TMMoveFe'.static.create(spawnFE.moveLocation , false, pawnId) );
		}

		return;
	}
	
	//doing it by name right now instead of race because the replicationinfo isnt replicating quick enoughhhh
	if(m_Unit.m_UnitName == "DoughBoy" )
	{
		onHitParticle =  ParticleSystem'VFX_Adam.Particles.P_NeutralOrb_SpawnTinkerers';
	}
	else
	{
		onHitParticle =ParticleSystem'VFX_Adam.Particles.P_NeutralOrb_SpawnAlchemist';
	}

	particleStartPosition = spawnFE.startLocation;
	particleStartPosition.Z += 20;
	proj = Spawn(class'TMSpawnProjectile',,,particleStartPosition,Rotation,,);
	proj.SetOnHitParticle( onHitParticle );
	proj.FireLobbedProjectileAtPosition(Location,self,ParticleSystem'VFX_Adam.Particles.P_NeutralOrb',800,"C_SpawnFinished");
}

simulated function ReceiveFastEvent(TMFastEvent fe)
{
	local string commandType;
	
	if(bIsTransforming && fe.commandType != "C_Trans") return;
	
	if(m_Unit == none) { 	// caused by running a local bot game
		`warn(self.Name $ " m_Unit is none!");
		return;
	}

	if(fe.commandType == "C_Move" && m_Unit.m_UnitName == "Tower") return;

	//Split into queued and non-queueing events

	commandType = fe.commandType;
	if (commandType == "C_StatusEffect")
	{
		m_Unit.SetActiveStatusEffect(class'TMStatusEffectFE'.static.fromFastEvent(fe).statusEffectEnum);
	}
	else if( commandType == "C_Spawn")
	{
		HandleSpawning(fe);
	}
	else if ( commandType == "C_SpawnFinished")
	{
		ClearTimer('CheckForMessages');
		CheckForSelection();
		UpdateUnitState( TMPS_IDLE );

		// your own visibility doesn't mean much to neutral unit on the server - no TMPC & thus no FoWManager.
		if ( WorldInfo.NetMode != NM_DedicatedServer || 
			PlayerReplicationInfo != TMGameInfo(WorldInfo.Game).m_TMNeutralPlayerController.PlayerReplicationInfo)
		{
			if( !m_Controller.GetFoWManager().IsLocationVisible(Location))
			{
				m_Controller.GetFoWManager().HideAPawn(self);
			}
			else
			{
				m_Controller.GetFoWManager().ShowAPawn(self);
			}
		}
	}
	else if(commandType == "KNOCKED_UP")
	{
		UpdateUnitState( TMPS_STUNNED );
		return;
	}
	//this is used for the TMPlayerAiController to know when someone has stopped attacking us
	else if(commandType == "AttackerDisengaged" && IsAuthority())
	{
		AttackerDisengaged( fe );
	}

	if( commandType == "C_Move" || commandType == "C_Follow" || commandType == "C_Stop" || commandType == "C_Attack" || commandType == "C_Ability" )
	{
		//Test the queue bool
		if( fe.bools.E == true )
		{   
			CommandQueueAdd( fe );
		}
		else
		{
			CommandQueueClear();
			CommandQueueAdd( fe );
			CommandQueueDo();
		}
	}
	else
	{  
		m_Unit.ReceiveFastEvent(fe);
	}
}

function bool IsAuthority()
{
	if(m_TMPC == none) { 	// sometimes happens when running bots locally. Hopefully can make the real fix and remove this.
		return true;
	}

	return ((m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_TMPC.WorldInfo.NetMode == NM_Standalone));
}


function AttackerDisengaged(TMFastEvent fe)
{
	local TMPlayerAIController ai;
	
	ai = TMPlayerAIController(Controller);
    if(ai != none)
	{
		ai.AttackerDisengaged( fe.targetId );
	}
}

simulated function ServerSetPawnController()
{
	local TMPlayerController pc;
	local TMTeamAIController aiC;

	foreach self.WorldInfo.AllControllers( class'TMPlayerController', pc )
	{
		if( pc.PlayerId == self.m_OwningPlayerId )
		{
			m_TMPC = pc;
			m_Controller = pc;
			break;
		}
	}

	foreach self.WorldInfo.AllControllers( class'TMTeamAIController', aiC )
	{
		if( aiC.GetTMPRI().PlayerID == self.m_OwningPlayerId )
		{
			m_Controller = aiC;
			break;
		}
	}

	if( TMPlayerController(m_Controller) == None )
	{
		// You're a bot! Give you a valid player controller
		foreach self.WorldInfo.AllControllers(class'TMPlayerController', PC)
		{
			if( WorldInfo.NetMode != NM_DedicatedServer || PC.m_allyId != class 'TMGameInfo'.const.SPECTATOR_ALLY_ID )  // Don't ever assign a bot to the spectator's player controller
			{
				m_TMPC = PC;
				break;
			}
		}
	}
}

simulated function SetPawnController()
{
	local TMPlayerController PC;
	foreach self.WorldInfo.AllControllers(class'TMPlayerController', PC)
	{
		if (WorldInfo.NetMode != NM_DedicatedServer || !(PC.m_allyId == class'TMGameInfo'.const.SPECTATOR_ALLY_ID))
		{
			m_TMPC = PC;
			m_Controller = PC;
		}
	}
}

simulated function CheckForMessages()
{
	local TMAttackFe fe;

	if( m_spawnUnveilCount > 20)
	{
		`log("timed out for spawner");
		fe = new () class'TMAttackFE';
		fe.commandType = "C_SpawnFinished";
		fe.pawnId = pawnId;
		SendFastEvent( fe );
	}

	if( m_TMPC.CheckCachedSpawnedFEs( pawnId ) )
	{
		ClearTimer('CheckForMessages');
	}

	// DruTODO: Why are we hammering this?
	if( self.OwnerReplicationInfo != none)
	{
		if(IsPawnNeutral( self ) )
		{
			fe = new () class'TMAttackFE';
			fe.commandType = "C_SpawnFinished";
			fe.pawnId = pawnId;
			SendFastEvent( fe );
		}
	}
	m_spawnUnveilCount++;
}

simulated event PostBeginPlay() {

	super.PostBeginPlay();
	SetPawnController();

	m_TransformComponent = None;

	m_spawnUnveilCount = 0;
	SetTimer(1/10,true,'CheckForMessages');
	
	CommandMesh.SetSkeletalMesh(SkeletalMesh'SelectionCircles.Meshes.SelectionPlane');
	m_dottedSelectionMesh = new(None) Class'MaterialInstanceConstant';
	m_dottedSelectionMesh.SetParent(Material'SelectionCircles.Materials.whiteDottedSelectionMat');
	m_filledSelectionMesh = new(None) Class'MaterialInstanceConstant';
	m_filledSelectionMesh.SetParent(Material'SelectionCircles.Materials.whiteSelectionMat');
	
	// Init Drag Mesh
	DragSelectionMesh.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatCircle');
	DragSelectionMesh.SetMaterial(0, Material'SelectionCircles.Materials.whiteDottedSelectionMat');
	DragMeshMatInst = new(None) Class'MaterialInstanceConstant';
	DragMeshMatInst.SetParent(DragSelectionMesh.GetMaterial(0));
	DragSelectionMesh.SetMaterial(0, DragMeshMatInst);

	// Init Target Mesh
	TargetMesh.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatCircle');
	TargetMesh.SetMaterial(0, Material'SelectionCircles.Materials.MarkerMat');
	TargetMeshMatInst = new(None) Class'MaterialInstanceConstant';
	TargetMeshMatInst.SetParent(TargetMesh.GetMaterial(0));
	TargetMesh.SetMaterial(0, TargetMeshMatInst);

	m_healthBarMatInst = new(None) Class'MaterialInstanceConstant';
	m_healthBarMatInst.SetParent(healthBarMat);
	
	// old indicator
	AbilityTargetMesh.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatCircle');
	AbilityTargetMesh.SetMaterial(0, Material'SelectionCircles.Materials.TargetMat');
	AbilityTargetMeshMatInst = new(None) Class'MaterialInstanceConstant';
	AbilityTargetMeshMatInst.SetParent(AbilityTargetMesh.GetMaterial(0));
	AbilityTargetMeshMatInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.GreenHSV.X);
	AbilityTargetMesh.SetMaterial(0, AbilityTargetMeshMatInst);
	//
	CurrTargetType = ENONE;
	abilityRangeMesh.SetStaticMesh(StaticMesh'SelectionCircles.Meshes.FlatPlane');
	abilityRangeMesh.SetMaterial(0, Material'SelectionCircles.Materials.abilityRangeMat');
	
//	m_obstable = Spawn(class'UDKRTSNavMeshObstacle',,,self.Location,,,);
	//m_obstable.SetAsSquare(55);
//	m_obstable.Register();
	m_pathDestination.X = -69;
	m_pathDestination.Y = -69;
	m_pathDestination.Z = -69;
	m_bRegistered = false;

	/* PLEASE DO NOT UN-COMMENT: fogOfWarManager is not available on a simulated function and causes flickering on the minimap and all other kinds of crazy shit */

	/*if( m_TMPC.fogOfWarManager != none && !m_TMPC.fogOfWarManager.IsLocationVisible(Location))
	{
		Hide();
	}
	else
	{
		Show();
	}*/
	/* PLEASE DO NOT UN-COMMENT */

	SetTimer(1, false, 'DelayedForceInitialize');
}

simulated function DelayedForceInitialize()
{
	bIsInitialized = true;
}

simulated function SetAllyInfo()
{
	local TMAllyInfo ally;
	local TMPlayerReplicationInfo tmPRI;

	tmPRI = TMPlayerReplicationInfo(OwnerReplicationInfo);

	if(tmPRI == none) {
		return;
	}

	foreach self.WorldInfo.AllActors(class'TMAllyInfo', ally)
	{
		if( ally.allyIndex == tmPRI.allyId )
			tmPRI.allyInfo = ally;
	}
}

simulated function bool IsAttackRotating()
{
	local TMComponentAttack att;
	att = self.GetAttackComponent();

	if(att == none)
	{   
		return false;
	}   

	return (att.m_cachedPawn != none || att.m_Target != none);	
}

simulated function bool IsCommander()
{
	return bIsCommander;
}

simulated function SetupUnit(TMUnit unit)
{
	local TMPlayerReplicationInfo tmPRI;

	tmPRI = TMPlayerReplicationInfo(OwnerReplicationInfo);
	unit.m_owner=self;
	m_Unit = new () class 'TMUnit' (unit);
	m_unit.DoUpdateCopy(unit, self);
	mIsGhost = false;
	mIsPushable = true;

	if(tmPRI != none)
	{
		if (unit.m_UnitName == tmPRI.commanderType)
		{
			bIsCommander = true;
			tmPRI.bIsCommanderDead = false;
			m_TMPC.SetHotSelectionGroup("All"); 
			if ( unit.m_owner.m_owningPlayerId == m_TMPC.PlayerId )
			{
				m_TMPC.Pawn = self; // Force an update of your pawn temporarily to fix camera issues in the interim.  Because we know what's good for you.
				m_TMPC.CenterCameraOnCommander(1);
				m_TMPC.DesaturateScreen(false);
			}
		}
		tmPRI.AddPawn(self);
		
		if ( m_unit.m_UnitName == "VineCrawler_Wall" )
		{
			tmPRI.RemovePawn(self);
		}
	}

	if ( m_unit.m_UnitName == "VineCrawler_Wall" )
	{
		mIsPushable = false;
	}
}

function DoSmallPushIfForward( TMPawn tempPawn )
{
	if ( Normal(tempPawn.Location - Location) dot Normal(Velocity) > 0.0f )
	{
		DoSmallPush( tempPawn );
	}
}

function DoSmallPush( TMPawn tempPawn )
{
	local vector impulse;

	if (tempPawn == None)
	{
		return;
	}

	impulse = Normal(tempPawn.Location - Location);
	impulse *= SMALL_PUSH_MAGNITUDE;
	tempPawn.mPushedBy = self;

	tempPawn.GetPushed(impulse);
}

simulated event Bump(Actor Other, PrimitiveComponent OtherComp, Vector HitNormal)
{
	local TMPawn otherPawn;
	otherPawn = TMPawn(Other);

	//this will be for the new nexus that i added....Conrad...
	if(!class'UDKRTSPawn'.static.IsValidPawn(otherPawn))
	{
		return;
	}

	if (!otherPawn.mIsPushable || otherPawn.m_Unit.m_UnitName == "Tower" || otherPawn.m_Unit.m_UnitName == "NexusCommander")
	{
		return;
	}

	if (GetAllyId() == -1)
	{
		super.Bump(Other, OtherComp, HitNormal);
		return;
	}

	// Stop this pawn if he bumps somebody who has stopped and reached his same destination
	if ( (m_currentState == TMPS_MOVING || m_currentState == TMPS_MOVING_FOLLOW) &&
		(otherPawn.m_currentState == TMPS_IDLE /*|| otherPawn.m_currentState == TMPS_ATTACK*/) &&
		otherPawn.mPointToDetermineIfWeHaveSameDestination == mPointToDetermineIfWeHaveSameDestination &&
		otherPawn.mHasBumpedGuyAtDestinationTransitively)
	{
		mHasBumpedGuyAtDestinationTransitively = true;
		StopMove(false, Location);
	}

	// commanders should be able to push basically any ally in any state
	if ( IsCommander() )
	{
		if( (m_currentState == TMPS_MOVING || m_currentState == TMPS_MOVING_FOLLOW) &&
			m_allyId == otherPawn.m_allyId &&
			( otherPawn.mPointToDetermineIfWeHaveSameDestination != mPointToDetermineIfWeHaveSameDestination || 
			( otherPawn.m_currentState == TMPS_ATTACK && otherPawn.m_owningPlayerId == m_owningPlayerId) ) )
		{
			if ( !(m_currentState == TMPS_MOVING_FOLLOW && otherPawn == m_followTarget) )
			{
				DoSmallPushIfForward( otherPawn );
			}
		}
	}
	else
	{
		if( otherPawn != self &&
			(m_currentState == TMPS_MOVING || m_currentState == TMPS_MOVING_FOLLOW) &&
			otherPawn.m_currentState != TMPS_MOVING && otherPawn.m_currentState != TMPS_MOVING_FOLLOW &&
			m_allyId == otherPawn.m_allyId &&
			( otherPawn.mPointToDetermineIfWeHaveSameDestination != mPointToDetermineIfWeHaveSameDestination || 
			( otherPawn.m_currentState == TMPS_ATTACK && otherPawn.m_owningPlayerId == m_owningPlayerId) ) ) // allows us to push allies that are in our way when we're trying to attack

		{
			if ( !(m_currentState == TMPS_MOVING_FOLLOW && otherPawn == m_followTarget) )
			{
				DoSmallPushIfForward( otherPawn );
			}
		}
	}
	
	if (mPushedBy != None &&
		otherPawn.m_currentState != TMPS_MOVING && otherPawn.m_currentState != TMPS_MOVING_FOLLOW &&
		m_allyId == otherPawn.m_allyId )
	{
		mPushedBy.DoSmallPushIfForward( otherPawn );
	}

	super.Bump(Other, OtherComp, HitNormal);
}

function GetPushed(Vector pushVelocity)
{
	local float maxSpeed;

	if ( pushVelocity.Z > 0.0f)
	{
		pushVelocity.Z = 0.0f;
	}

	maxSpeed = Max( Vsize(Velocity), Vsize(pushVelocity) ); 

	AddVelocity(pushVelocity, Location, class'DamageType');

	ClampLength(Velocity, maxSpeed);
}

function GetForcePushed(Vector pushVelocity)
{
	local Vector zeroVector;

	// Set Aggressive flag/vectors, etc
	Velocity = zeroVector;
	GetPushed(pushVelocity);
}

function UpdateForceTick()
{
	forceTick = true;
}

simulated event Tick(float dt)
{
	local vector locationoffset;
	local TMPlayerReplicationInfo tmPRI;
	local int index;
	local EnvironmentVolume ev;

	tmPRI = TMPlayerReplicationInfo(OwnerReplicationInfo);

	// decreasing health from damage on hud
	if (m_lastmomenthealth > Health)
	{
		m_lastMomentHealth -= 2 * (m_lastMomentHealth - Health) * dt;
	}
	else
	{
		m_lastMomentHealth = Health;
	}
	
	if( tmPRI != none)
	{
		if(m_UnitType == tmPRI.commanderType)
		{
			m_currentLifeTime += dt;
		}
	}

	if(m_currentState == TMPS_INVISBLE_SPAWN && m_UnitType != "ConvertedBrute")
	{
		m_Controller.GetFoWManager().HideAPawn(self);
	}

	if(m_currentState == TMPS_INVISBLE_SPAWN && m_UnitType == "ConvertedBrute")
	{
		m_currentState = TMPS_IDLE;
	}

	// Update team materials and set occlusion mesh
	if (!bTeamMaterialSet)
	{
		UpdateTeamMaterials();
	}
	if (!bAbilityMeshScaleSet)
	{
		UpdateAbilityMeshScale();
	}

	if (VSizeSq(Velocity) == 0.0f)
	{
		mPushedBy = None;
		//GoHome();
	}

	// Taylor TODO: compare this to when we're actually invisible. Should be 1:1
	// Check if in bush
	ev = WorldInfo.FindEnvironmentVolume(Location);

	if (ev != none)
	{
		SetHighlighted(true);
	}

	locationoffset=Location;
	if(m_Unit!=none) {
		locationoffset.Z += Mesh.Translation.Z;
		m_unit.UpdateComponents(dt);
	}

	// Taylor TODO: clean up this chunk for painting ability meshes
	if(m_TMPC != None) {
	
		if( self.Health > 0) {
		
			// Set selection and range mesh location
			if ( locationoffset != CommandMesh.Translation)
			{
				CommandMesh.SetTranslation(locationoffset);
			}
			if ( locationoffset != abilityRangeMesh.Translation )
			{
				abilityRangeMesh.SetTranslation(locationoffset);
			}

			// Draw ability target
			if (m_TMPC.ActiveCommand != C_NONE)
			{
				if (m_TMPC.InputHandler == m_TMPC.InputHandlerActiveCommand && GetAbilityComponent() != None)
				{
					CurrTargetType = EABILITY;
					AbilityIndicator.Update();
				}

				index = m_TMPC.m_OnAbilityPawn.Find(self);
	
				if( index != -1 )
				{
					if (GetAbilityComponent().m_AbilityState == AS_IDLE && self == TMHUD(m_TMPC.myHUD).m_closestAbilityPawn) // I have this ability and I'm not on cooldown and I'm the closest to the cast point
					{
						TargetMesh.SetHidden(true);
						ShowReadyToCastAbility();
						abilityRangeMesh.SetHidden(false);
						AbilityIndicator.Show();
					}
					else // I don't have this ability, hide both meshes
					{
						HideReadyToCastAbility();
						abilityRangeMesh.SetHidden(true);
						TargetMesh.SetHidden(true);
						AbilityIndicator.Hide();
					}
				}
				else // Not using unit ability, hide range mesh
				{
					abilityRangeMesh.SetHidden(true);
					AbilityIndicator.Hide();
				}
			}
			else
			{
				abilityRangeMesh.SetHidden(true);
				AbilityIndicator.Hide();
			}
			
		} else { // I'm not selected, hide both meshes
			abilityRangeMesh.SetHidden(true);
			TargetMesh.SetHidden(true);
			AbilityIndicator.Hide();
		}
	}


	// Taylor TODO: don't we want to be able to cast on the minimap
	if (m_TMPC.myHUD != none)
	{
		if (TMHUD(m_TMPC.myHUD).bMouseOnMinimap)
		{
			AbilityIndicator.Hide();
		}
	}

	switch (CurrTargetType)
	{
	case ENONE:
		TargetMesh.SetHidden(true);
		AbilityIndicator.Hide();
		break;
	case ELOCATION:
		break;
	case EPAWN:
		locationoffset = TargetedPawn.Location;
		if (TargetedPawn.Mesh != None) {
			locationoffset.Z += TargetedPawn.Mesh.Translation.Z;
		}
		TargetMesh.SetTranslation(locationoffset);
		break;
	case EABILITY:
		break;
	case ETRANSFORMER:
		locationoffset = TargettedTransformer.Location;
		if (TargettedTransformer.m_TransformerMesh != None) {
			locationoffset.Z += TargettedTransformer.m_TransformerMesh.Translation.Z;
		}
		TargetMesh.SetTranslation(locationoffset);
		break;
	}
	
	if( mIsGhost )
	{
		SetHighlightColor(0.01f,1.0f,1.0f,1.0f);
		SetHighlighted(true);
	}

	// DruTODO: Get rid of numSpawn?  It appears to serve no purpose
	//if(tmPRI!= None && tmPRI.allyInfo != None && numSpawn != tmPRI.allyInfo.numSpawns) 
	//{
	//	numSpawn = tmPRI.allyInfo.numSpawns;
	//	//`log("Ali - Ally"@tmPRI.allyInfo.allyIndex@" spawn count updated "@numSpawn);
	//}

	if ( m_TMPC.m_bMiralab )
	{
		SetHighlighted( true );
	}
}

simulated function UnitIsIdle()
{
	local TMFastEvent fe;
	
	if (UDKRTSAiController(self.Controller).HasReachedPoint(UDKRTSAiController(self.Controller).Destination))
	{
	fe = new () class'TMFastEvent';
	fe.commandType = "C_ReachedDestination";
	fe.pawnId = pawnId;
	m_Unit.ReceiveFastEvent(fe);
}
}

simulated function bool IsAbilityCastable()
{
	local TMAbility ability;

	// Taylor TODO: this won't work for multi-ability units
	ability = GetAbilityComponent();
	if(ability != none)
	{
		if(ability.m_AbilityState == AS_IDLE)
		{
			return true;
		}
	}
	return false;

}

simulated function TMComponentAttack GetAttackComponent()
{
	local int i;

	if( self.m_attackComponent == none)
	{
		for(i = 0; i < m_Unit.m_componentArray.Length; i++)
		{
			if(m_Unit.m_componentArray[i].IsA('TMComponentAttack'))
			{
				m_attackComponent = TMComponentAttack(m_Unit.m_componentArray[i]);
				return m_attackComponent;
			}
		}
	}

	return m_attackComponent;
}

simulated function TMComponentMove GetMoveComponent()
{
	local int i;

	if( self.m_moveComponent == none)
	{
		for(i = 0; i < m_Unit.m_componentArray.Length; i++)
		{
			if(m_Unit.m_componentArray[i].IsA('TMComponentMove'))
			{
				m_moveComponent = TMComponentMove(m_Unit.m_componentArray[i]);
				return m_moveComponent;
			}
		}
	}

	return m_moveComponent;
}

simulated function TMComponentAnimation GetAnimationComponent()
{
	local int i;

	if( mAnimationComponent == none)
	{
		for( i = 0; i < m_Unit.m_componentArray.Length; i++ )
		{
			if( m_Unit.m_componentArray[i].IsA('TMComponentAnimation') )
			{
				mAnimationComponent = TMComponentAnimation( m_Unit.m_componentArray[i] );
				return mAnimationComponent;
			}
		}
	}

	return mAnimationComponent;
}

simulated function TMComponentHealthRegen GetHealthRegenComponent()
{
	local int i;

	for( i = 0; i < m_Unit.m_componentArray.Length; i++ )
	{
		if( m_Unit.m_componentArray[i].IsA('TMComponentHealthRegen') )
		{
			return TMComponentHealthRegen( m_Unit.m_componentArray[i] );
		}
	}

	return None;
}

simulated function TMComponentTugOfWar GetTugOfWarComponent()
{
	local int i;
	
	if( self.m_tugOfWarComponent == none )
	{
		if(m_Unit == none) { 	// caused by running a local bot game
			`warn(self.Name $ " m_Unit is none!");
			return none;
		}

		for(i = 0; i < m_Unit.m_componentArray.Length; i++)
		{
			if(m_Unit.m_componentArray[i].IsA('TMComponentTugOfWar'))
			{
				m_tugOfWarComponent = TMComponentTugOfWar(m_Unit.m_componentArray[i]);
				return m_tugOfWarComponent;
			}
		}
	}

	return m_tugOfWarComponent; 
	
}

simulated function TMComponentDecay GetDecayComponent()
{
	local int i;
	
	if(!b_hasDecay)
	{
		return none;
	}

	if( self.m_decayComponent == none && m_Unit != none)
	{
		for(i = 0; i < m_Unit.m_componentArray.Length; i++)
		{
			if(m_Unit.m_componentArray[i].IsA('TMComponentDecay'))
			{
				m_decayComponent = TMComponentDecay(m_Unit.m_componentArray[i]);
				return m_decayComponent;
			}
		}
	}

	return m_decayComponent; 
	
}


simulated function TMAbility GetAbilityComponent()
{
	local int i;
	
	if( self.m_abilityComponent == none && m_Unit != none)
	{
		for(i = 0; i < m_Unit.m_componentArray.Length; i++)
		{
			if(m_Unit.m_componentArray[i].IsA('TMAbility'))
			{
				m_abilityComponent = TMAbility(m_Unit.m_componentArray[i]);
				return m_abilityComponent;
			}
		}
	}

	return m_abilityComponent; 
	
}

simulated function TMAbility GetGhostAbilityComponent()
{
	local int i;
	
	if(m_Unit != none)
	{
		for(i = 0; i < m_Unit.m_componentArray.Length; i++)
		{
			if(m_Unit.m_componentArray[i].IsA('TMAbilityGhost'))
			{
				return TMAbility(m_Unit.m_componentArray[i]);
			}
		}
	}

	return none;
}


///// ANIMATION CALLBACKS /////
// These are functions called by our animations. It seems that they have to live in TMPawn :'(

//this is a call from the animation
simulated function DoDamage()   // Taylor TODO: rename this to AC_DoDamage
{
	ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(pawnId, "C_DoDamage") );
}

// Animation Callback for when we should do our ability
simulated function AC_CastAbility()
{
	ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(pawnId, "C_CastAbility") );
}

// Animation Callback for when the ability animation is done
simulated function AC_EndAbility()
{
	ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(pawnId, "C_EndAbility") );
}

// Animation Callbacks for ability animation phases
simulated function AC_AbilityPhase2() {
	CreateAndReceiveAbilityPhaseFastEvent(2);
}
simulated function AC_AbilityPhase3() {
	CreateAndReceiveAbilityPhaseFastEvent(3);
}
simulated function AC_AbilityPhase4() {
	CreateAndReceiveAbilityPhaseFastEvent(4);
}
simulated function AC_AbilityPhase5() {
	CreateAndReceiveAbilityPhaseFastEvent(5);
}
simulated function AC_AbilityPhase6() {
	CreateAndReceiveAbilityPhaseFastEvent(6);
}

simulated function CreateAndReceiveAbilityPhaseFastEvent(int inAbilityPhase)
{
	local TMAbilityPhaseFE abilityPhaseFE;
	abilityPhaseFE = class'TMAbilityPhaseFE'.static.create(pawnId, inAbilityPhase);
	ReceiveFastEvent(abilityPhaseFE.toFastEvent());
}

// SpawnAbilityProjectile is called by the ability animation
simulated function SpawnAbilityProjectile()                 // REMOVING
{
	ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(pawnId, "C_SpawnAbilityProjectile") );
}

// SpawnProjectile is called by the attack animation
simulated function SpawnProjectile()
{
	local TMComponentAttack att;
	local TMAttackFE attackFE;
	local TMPawn tempPawn;

		
	att = GetAttackComponent();
	if( att != none && (att.m_Target != none || att.m_clientTarget != none))
	{
		tempPawn = att.m_target == none ? att.m_clientTarget : att.m_target;
		attackFE = new () class'TMAttackFE';
		attackFE.commandType = "C_SpawnProjectile";
		
		attackFE.targetId = tempPawn.pawnId;
		attackFE.pawnId = pawnId;
		ReceiveFastEvent( attackFE.toFastEvent() );
	}
}

simulated function bool NotInteruptingCommand()
{
	if((m_currentState == TMPS_JUGGERNAUT || m_currentstate == TMPS_STUNNED || m_currentState == TMPS_INVISBLE_SPAWN))
	{
		return false;
	}

	return true;
}


function ForceSpawnDefaultController()
{
	if ( ControllerClass != None )
	{
		Controller = Spawn(ControllerClass);
	}

	if ( Controller != None )
	{
		Controller.Possess( Self, false );
	}
}

//used in UDKRTSInputhandler to get this palyer controllers camera
simulated function Vector GetCameraLocation()
{
	return m_TMPC.PlayerCamera.Location;
}


simulated function RemoveUnstopablePawns(out array<UDKRTSPawn> similarIssuedPawns)
{
	local int i;

	for(i=0;i < similarIssuedPawns.Length;i++)
	{
		if(similarIssuedPawns[i] == none)
		{
			similarIssuedPawns.RemoveItem(similarIssuedPawns[i]);
			i=-1;
		}
		else if(!TMPawn(similarIssuedPawns[i]).NotInteruptingCommand())
		{
			similarIssuedPawns.RemoveItem(similarIssuedPawns[i]);
			i=-1;
		}
	}
}

/** Ideally a helper, has some hacks for neutrals though */
function bool IsPawnHidden(TMPawn pawn)
{
	if (IsPawnNeutral(self))
	{
		return false;
	}

	return m_Controller.GetFoWManager().IsPawnHidden( pawn );
}

/**
 * Handles a unit command.
 *  @param command being called
 *  @param position of the command (optional: not all commands will have a position)
 *  @param target unit (optional: not all commands will have targets)
 */
simulated function HandleCommand(ECommand command, bool fromPlayerController, optional Vector position, optional UDKRTSPawn target,  optional array<UDKRTSPawn> similarIssuedPawns, optional bool queued)
{
	local TMSalvatorSnake iterSnake;

	RemoveUnstopablePawns(similarIssuedPawns);
	Untarget();

	if( m_TMPC != None )
	{
		m_TMPC.CommandIssued(command);
	}

	//doing this because all the units will be coming from this
	if(similarIssuedPawns.Length > 0)
	{
		if (fromPlayerController)
		{
			if (!(command == C_Ability1 && GetAbilityComponent().m_AbilityState == AS_COOLDOWN) && !bHidden)
			{
				m_TMPC.m_AudioManager.requestPlayCharacterVO(command, m_Unit.m_UnitName);
			}
		}

		switch (command)
		{
		case C_Move:
			if ( m_TMPC.mSalvatorSnakes.Length > 0 )
			{
				foreach m_TMPC.mSalvatorSnakes( iterSnake )
				{
					if ( iterSnake.mAllyID == m_TMPC.GetTMPRI().allyId && VSize2D( iterSnake.Location - position ) < iterSnake.GetCollisionRadius() )
					{
						TargetAPawn( iterSnake, true );
						break;
					}
				}
			}
			DoMoveCommand(position, fromPlayerController,similarIssuedPawns, target, , queued);
			break;
		case C_Attack:
			if( target != none && !IsPawnHidden(TMPawn(target)))
			{
				
				//probalby want to send if it was sent from the player controller or not
				if( fromPlayerController )
				{
				    TargetAPawn(TMPawn(target), (TMPlayerReplicationInfo(OwnerReplicationInfo).allyId == TMPlayerReplicationInfo(TMPawn(target).OwnerReplicationInfo).allyId) ? true : false);
				}
			   SendAttackCommand(TMPawn(target),similarIssuedPawns, queued, false );
			}
			else //attack move
			{
				TargetMeshMatInst.SetScalarParameterValue('HueShift', class'TMColorPalette'.default.RedHSV.X);
				DoMoveCommand(position,fromPlayerController,similarIssuedPawns,,queued,true);
			}
			break;
		case C_Hold:
			break;
		case C_Stop:
			self.SendStopCommand(similarIssuedPawns);
			break;
		case C_Ability1:
		case C_Ability2:
		case C_Ability3:
		case C_Ability4:
		case C_Ability5:
		case C_Ability6:
		case C_Ability7:
		case C_Ability8:    // this is the summoner ability
			SendAbilityCommand(command, position, TMPawn(target), similarIssuedPawns, queued);
			break;
		case C_Test:
			break;
		case C_Transform:
			DoTransformCommand(position, similarIssuedPawns);
			break;
		case C_AlchTransform:
			DoAlchTransformCommand(position, target);
			break;
		default:
			`log("ERROR: TMPawn was not passed a valid command in 'HandleCommand()'", true, 'Taylor');
		}
	}
}

simulated function DoTransformCommand(vector TransformerLocation, array<UDKRTSPawn> similarIssuedPawns)
{
	local TMTransformationFE fe;
	local TMTransformer transformer;
	local TMTransformer tempTrans;
	local array<UDKRTSPawn> tempPawnArray;
	local UDKRTSPawn tempPawn;
	local UDKRTSPawn firstPawn;

	RemoveUnstopablePawns(similarIssuedPawns);
	foreach AllActors(class'TMTransformer', tempTrans)
	{
		// I know what you're thinking. Another disgusting location check.
		// BUT! Its okay this time, because it is all local (no networking
		// involved). 
		if(tempTrans.Location == TransformerLocation)
		{
			transformer = tempTrans;
			break;
		}
	}

	if(similarIssuedPawns.Length != 0)
	{
		firstPawn = similarIssuedPawns[0];
		similarIssuedPawns.RemoveItem(firstPawn);
		while(similarIssuedPawns.Length > 20)
		{
			if(tempPawnArray.Length >= 20)
			{
				tempPawn = tempPawnArray[0];
				tempPawnArray.RemoveItem(tempPawn);
				fe = class'TMTransformationFE'.static.create(transformer.TransformerId, "ORDER", TMPawn(firstPawn).pawnId,tempPawnArray);
				tempPawnArray.Remove(0,tempPawnArray.Length-1);
				SendFastEvent(fe);
			}
			tempPawn = similarIssuedPawns[0];
			tempPawnArray.AddItem(tempPawn);
			similarIssuedPawns.RemoveItem(tempPawn);
		}

		if(tempPawnArray.Length != 0)
		{
			tempPawn = tempPawnArray[0];
			tempPawnArray.RemoveItem(tempPawn);
			fe = class'TMTransformationFE'.static.create(transformer.TransformerId, "ORDER", TMPawn(firstPawn).pawnId,tempPawnArray);
			SendFastEvent(fe);
		}

		//fast even the other sheeeet
		fe = class'TMTransformationFE'.static.create(transformer.TransformerId, "ORDER", TMPawn(firstPawn).pawnId, similarIssuedPawns);
		SendFastEvent(fe);
	}

	TargetATransformer(transformer);

	fe = class'TMTransformationFE'.static.create(transformer.TransformerId, "ORDER", self.pawnId);
	// self.m_Unit.ReceiveFastEvent(fe.toFastEvent());
	self.SendFastEvent(fe);
}

simulated function DoAlchTransformCommand(vector transformerLocation, UDKRTSPawn commander)
{
	local TMAlchTransFE fe;
	local TMTransformer transformer;
	local TMTransformer tempTrans;

	foreach AllActors(class'TMTransformer', tempTrans)
	{
		if(tempTrans.Location == TransformerLocation)
		{
			transformer = tempTrans;
			break;
		}
	}

	TargetATransformer(transformer);

	fe = class'TMAlchTransFE'.static.create(transformer.TransformerId, "ORDER", transformer.PotionType, TMPawn(commander).pawnId);
	self.SendFastEvent(fe);
}

// SendAbilityCommand is called on clients to send ability FastEvents to the server
simulated function SendAbilityCommand(ECommand command, optional Vector position, optional TMPawn target,optional array<UDKRTSPawn> similarIssuedPawns, optional bool queued )
{
	local TMAbilityFE abilityFE;
	local UDKRTSPawn tempPawn;
	local array<UDKRTSPawn> tempPawnArray;

	RemoveUnstopablePawns(similarIssuedPawns);
	if(similarIssuedPawns.Length != 0)
	{
		while(similarIssuedPawns.Length > 20)
		{
			if(tempPawnArray.Length >= 21)
			{
				tempPawn = tempPawnArray[0];
				tempPawnArray.RemoveItem(tempPawn);
				abilityFE = CreateAbilityFastEvent(command, position, target, similarIssuedPawns, queued, tempPawn.location);
				tempPawnArray.Remove(0,tempPawnArray.Length-1);
				SendFastEvent(abilityFE);
			}

			tempPawn = similarIssuedPawns[0];
			tempPawnArray.AddItem(tempPawn);
			similarIssuedPawns.RemoveItem(tempPawn);
		}

		if(tempPawnArray.Length != 0)
		{
			tempPawn = tempPawnArray[0];
			tempPawnArray.RemoveItem(tempPawn);
			abilityFE = CreateAbilityFastEvent(command, position, target, similarIssuedPawns, queued, tempPawn.location);
			SendFastEvent(abilityFE);
		}

		//fast even the other sheeeet
		abilityFE = CreateAbilityFastEvent(command, position, target, similarIssuedPawns, queued, self.location);
		SendFastEvent(abilityFE);
	}
	else
	{
		abilityFE = CreateAbilityFastEvent(command, position, target, similarIssuedPawns, queued);
		SendFastEvent(abilityFE);
	}
}
//this means only 1 unit can do the ability at once
//will probably need to be modified in the future
simulated function bool IsAbilitySingleCast(ECommand command)
{
	// Taylor TODO: make Dru happy. Make myself happy. Add this to helper class.
	// DruTODO: This is dumb.  why are you asking about abilities you don't have in TMPawn?
	switch (command)
	{
	case C_Ability1:    // Commander Ability: radar scan -OR- RosieTimeBubble
			return true;
		break;
	case C_Ability2:// conductor
			return false;
		break;
	case C_Ability3: // Sniper ability:
			return true;
		break;
	case C_Ability4:   // Splitter ability
			return true;
		break;
	case C_Ability5:    // Oiler ability:
			return true;
		break;
	case C_Ability6: //Skybreaker
			return true;
		break;
	case C_Ability7:
			return true;
		break;
	case C_Ability8:
			return true;
		break;
	}

	return false;
	
}

simulated function bool IsAbilityInstantCast()
{
	// Taylor TODO: doesn't work with multi-ability units
	local TMAbility ab;
	ab = GetAbilityComponent();

	if(ab != none)
	{
		return GetAbilityComponent().mIsInstantCast;
	}
	return false;
}


simulated function bool IsThisMyAbility(ECommand command)
{
	local TMPlayerReplicationInfo tmPRI;
	
	tmPRI = TMPlayerReplicationInfo(OwnerReplicationInfo);

	switch (command)
	{
	case C_Ability1:    // Commander Ability: radar scan -OR- RosieTimeBubble
		if (m_Unit.m_UnitName == tmPRI.commanderType)
		{
			return true;
		}
		break;
	case C_Ability2:    // Conductor ability: ConductorShock (doesn't need anything)
		if (m_Unit.m_UnitName == tmPRI.raceUnitNames[1])
		{
			return true;
		}
		break;
	case C_Ability3:    // Sniper ability: SniperMine (uses a location)
		if (m_Unit.m_UnitName == tmPRI.raceUnitNames[2])
		{
			return true;
		}
		break;
	case C_Ability4:    // Splitter ability: SplitterCharge (uses a position)
		if (m_Unit.m_UnitName == tmPRI.raceUnitNames[3])
		{
			return true;
		}
		break;
	case C_Ability5:    // Oiler ability: TarSplotch (uses a position)
		if (m_Unit.m_UnitName == tmPRI.raceUnitNames[4])
		{
			return true;
		}
		break;
	case C_Ability6:
		if (m_Unit.m_UnitName == tmPRI.raceUnitNames[5])
		{
			return true;
		}
		break;
	case C_Ability7:
		if(m_Unit.m_UnitName == "ConvertedBrute")
		{
			return true;
		}
		break;
	case C_Ability8: 	// Player ability
		//taylor, the ability will map to this button
		if(m_Unit.m_UnitName == tmPRI.commanderType)
		{
			return true;
		}
		break;
	}

	return false;
}

simulated function TMAbilityFE CreateAbilityFastEvent(ECommand command, optional Vector position, optional TMPawn target,optional array<UDKRTSPawn> similarIssuedPawns, optional bool queued, optional vector castingPawnLocation)
{
	local TMAbilityFE abilityFE;
	local string abilityName;

	abilityname = GetAbilityComponent().m_sAbilityName;

	// Well, this is hacky as shit :(
	if ( command == C_Ability8 )
	{
		abilityName = "Ghost";
	}

	abilityFE = class'TMAbilityFE'.static.create(abilityName, target, position, similarIssuedPawns, queued,, castingPawnLocation);

	return abilityFE;
}

simulated function StopMove(bool AttackMove, Vector AttackMoveLocation, optional UDKRTSPawn targetPawn)
{
	local TMMoveFE moveFE;
	moveFE = class'TMMoveFE'.static.create(Location, false, self.pawnId, , targetPawn, ,AttackMove, true);
	SendFastEvent(moveFE);
}

simulated function DoMoveCommand(Vector destination, bool isCommandFromPlayerController, array<UDKRTSPawn> similarIssuedPawns, optional UDKRTSPawn targetPawn , optional bool queued, optional bool attackMove, optional bool isTransformMove)
{
	local TMMoveFE moveFE;
	local array<UDKRTSPawn> tempPawnArray;
	local UDKRTSPawn tempPawn;
	local UDKRTSPawn firstPawn;

	HasPendingCommand = true;
	RemoveUnstopablePawns(similarIssuedPawns);
	if(similarIssuedPawns.Length != 0)
	{
		firstPawn = similarIssuedPawns[0];
		while(similarIssuedPawns.Length > 20)
		{
			if(tempPawnArray.Length >= 20)
			{
				tempPawn = tempPawnArray[0];
				tempPawnArray.RemoveItem(tempPawn);
				moveFE = class'TMMoveFE'.static.create(destination, isCommandFromPlayerController, TMPawn(firstPawn).pawnId ,tempPawnArray,targetPawn, queued, attackMove, false, false, isTransformMove );
				tempPawnArray.Remove(0,tempPawnArray.Length-1);
				SendFastEvent(moveFE);
			}
			tempPawn = similarIssuedPawns[0];
			tempPawnArray.AddItem(tempPawn);
			similarIssuedPawns.RemoveItem(tempPawn);
		}

		if(tempPawnArray.Length != 0)
		{
			tempPawn = tempPawnArray[0];
			tempPawnArray.RemoveItem(tempPawn);
			moveFE = class'TMMoveFE'.static.create( destination, isCommandFromPlayerController, TMPawn(firstPawn).pawnId, tempPawnArray, targetPawn, queued, attackMove, false, false, isTransformMove );
			SendFastEvent(moveFE);
		}

		moveFE = class'TMMoveFE'.static.create( destination, isCommandFromPlayerController, TMPawn(firstPawn).pawnId, similarIssuedPawns, targetPawn, queued, attackMove, false, false, isTransformMove );
		SendFastEvent(moveFE);
	}
}

simulated event OnAnimEnd(AnimNodeSequence SeqNode, float PlayedTime, float ExcessTime) 
{
	super.OnAnimEnd(SeqNode, PlayedTime, ExcessTime);

	if(SeqNode.AnimSeqName == 'spawn01')
	{
		UpdateUnitState( TMPS_IDLE );
		DoIdleAnimation();
	}
}

function DoIdleAnimation()
{
	self.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(pawnId,"Idle"));
}

//default stop is stop all
simulated function SendStopCommand(optional array<UDKRTSPawn> similarIssuedPawns,optional string stopCommandType)
{
	local TMStopFE stopFe;
	local array<UDKRTSPawn> tempPawnArray;
	local UDKRTSPawn tempPawn;
	local string command;
	
	//RemoveUnstopablePawns(similarIssuedPawns);

	if(stopCommandType != "")
	{
		command = stopCommandType;
	}
	else
	{
		command = "C_Stop";
	}

	if(similarIssuedPawns.Length != 0)
		{
			while(similarIssuedPawns.Length > 20)
			{
				if(tempPawnArray.Length >= 21)
				{
					tempPawn = tempPawnArray[0];
					tempPawnArray.RemoveItem(tempPawn);
					stopFe = class'TMStopFE'.static.create(TMPawn(tempPawn).pawnId,similarIssuedPawns,command);
					tempPawnArray.Remove(0,tempPawnArray.Length-1);
					SendFastEvent(stopFe);
				}
				tempPawn = similarIssuedPawns[0];
				tempPawnArray.AddItem(tempPawn);
				similarIssuedPawns.RemoveItem(tempPawn);
			}

			if(tempPawnArray.Length != 0)
			{
				tempPawn = tempPawnArray[0];
				tempPawnArray.RemoveItem(tempPawn);
				stopFe = class'TMStopFE'.static.create(TMPawn(tempPawn).pawnId,similarIssuedPawns,command);
				SendFastEvent(stopFe);
			}

			//fast even the other sheeeet
			stopFe = class'TMStopFE'.static.create(self.pawnId,similarIssuedPawns,command);
			SendFastEvent(stopFe);
		}
		else
		{
			stopFe = class'TMStopFE'.static.create(self.pawnId,,command);
			SendFastEvent(stopFe);
		}

}

simulated function SendAttackCommand(TMPawn target, array<UDKRTSPawn> similarIssuedPawns, optional bool queued, optional bool attackMove, optional Vector attackMovePosition )
{
	local TMAttackFE atkFE;
	local array<UDKRTSPawn> tempPawnArray;
	local UDKRTSPawn tempPawn;
	local UDKRTSPawn firstPawn;
	
	RemoveUnstopablePawns(similarIssuedPawns);
	

	if(target == none)
	{
		if(similarIssuedPawns.Length != 0)
		{
			firstPawn = similarIssuedPawns[0];
			similarIssuedPawns.RemoveItem(firstPawn);
			while(similarIssuedPawns.Length > 20)
			{
				if(tempPawnArray.Length >= 21)
				{
					tempPawn = tempPawnArray[0];
					tempPawnArray.RemoveItem(tempPawn);
					atkFE = class'TMAttackFE'.static.create(target, TMPawn(firstPawn).pawnId,similarIssuedPawns, queued, attackMove, attackMovePosition);
					tempPawnArray.Remove(0,tempPawnArray.Length-1);
					SendFastEvent(atkFE);
				}
				tempPawn = similarIssuedPawns[0];
				tempPawnArray.AddItem(tempPawn);
				similarIssuedPawns.RemoveItem(tempPawn);
			}

			if(tempPawnArray.Length != 0)
			{
				tempPawn = tempPawnArray[0];
				tempPawnArray.RemoveItem(tempPawn);
				atkFE = class'TMAttackFE'.static.create(target, TMPawn(firstPawn).pawnId,similarIssuedPawns, queued, attackMove, attackMovePosition);
				SendFastEvent(atkFE);
			}

			//fast even the other sheeeet
			atkFE = class'TMAttackFE'.static.create(target, TMPawn(firstPawn).pawnId,similarIssuedPawns, queued, attackMove, attackMovePosition);
			SendFastEvent(atkFE);
			return;
		}
	}
	
	//should be higher up so it never gets here anyways
	if (TMPlayerReplicationInfo(target.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(OwnerReplicationInfo).allyId)
	{
		if(similarIssuedPawns.Length != 0)
		{
			firstPawn = similarIssuedPawns[0];
			similarIssuedPawns.RemoveItem(firstPawn);
			while(similarIssuedPawns.Length > 20)
			{
				if(tempPawnArray.Length >= 21)
				{
					tempPawn = tempPawnArray[0];
					tempPawnArray.RemoveItem(tempPawn);
					atkFE = class'TMAttackFE'.static.create(target, TMPawn(firstPawn).pawnId,similarIssuedPawns, queued, attackMove, attackMovePosition);
					tempPawnArray.Remove(0,tempPawnArray.Length-1);
					SendFastEvent(atkFE);
				}
				tempPawn = similarIssuedPawns[0];
				tempPawnArray.AddItem(tempPawn);
				similarIssuedPawns.RemoveItem(tempPawn);
			}

			if(tempPawnArray.Length != 0)
			{
				tempPawn = tempPawnArray[0];
				tempPawnArray.RemoveItem(tempPawn);
				atkFE = class'TMAttackFE'.static.create(target, TMPawn(firstPawn).pawnId,similarIssuedPawns, queued, attackMove, attackMovePosition);
				SendFastEvent(atkFE);
			}

			//fast even the other sheeeet
			atkFE = class'TMAttackFE'.static.create(target, TMPawn(firstPawn).pawnId,similarIssuedPawns, queued, attackMove, attackMovePosition);
			SendFastEvent(atkFE);
		}
		else
		{
			//atkFE = class'TMAttackFE'.static.create(target, self.pawnId, , queued, attackMove, attackMovePosition);
			//SendFastEvent(atkFE);
		}
	}
	else
	{
		DoMoveCommand(target.Location,false,similarIssuedPawns,none,,attackMove);
	}
}


/**
 * This timer loops until the owner replication info has a valid team info in order to perform the team update
 */
simulated function DesaturateOverTime()
{
	local MaterialInstanceConstant MatInst;

	SetHighlighted(false);
	fDesaturateAmount += 0.059f;
	fDarkenAmount += 2;
	if (fDesaturateAmount > 1)
	{
		ClearTimer(NameOf(DesaturateOverTime));
	}

	MatInst = MaterialInstanceConstant(m_UnitSkeletal.GetMaterial(0));
	MatInst.SetScalarParameterValue('DesaturationAmount', fDesaturateAmount);
	MatInst.SetScalarParameterValue('DarkenAmount', fDarkenAmount);

	
	m_UnitSkeletal.SetMaterial(0, MatInst);
}

simulated function int GetHealth()
{
	return Health;
}

simulated function removeActiveSelection() {
	// Graham: this looks like it was intended to be a client function, so I
	// added this check to prevent nonespam on the server
	if(TMPlayerController(GetALocalPlayerController()) == None) { return; }

	if (m_owningPlayerId == TMPlayerController(GetALocalPlayerController()).PlayerId)
	{
		m_TMPC.RemoveSelectedActor(self);
		m_TMPC.TM_HUD.removePawn(self);
	}
}

simulated function addActiveSelection() {
	if (m_owningPlayerId == TMPlayerController(GetALocalPlayerController()).PlayerID)
	{
		m_TMPC.AddActorAsSelected(self);
		self.CommandMesh.SetHidden(false);
	}
}

simulated function string GetPawnName()
{
	if(m_Unit == none)
	{   
		return "";
	}
	return m_Unit.m_UnitName;
}

simulated function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	// Killer is none when we kill all of our own units
	local TMPlayerController pc;
	local TMPlayerReplicationInfo tmPRI;
	local TMGameInfo tempTMGameInfo;

	// Hide our target mesh
	AbilityTargetMesh.SetHidden(true);
	DetachComponent(AbilityTargetMesh); 	// remove our reference to the ability mesh

	if( m_TMPC.m_gameEnded )
	{
		return super.Died(Killer, DamageType, HitLocation);
	}

	DoDiedBullshitCode(); 	// TODO: do the work to remove this bandaid function

	if( IsCommander() )
	{
		OnCommanderDied( Killer );
	}

	// Tell all of this pawn's components to clean up
	CleanupComponents();

	// Play death sound effect VO
	if(!bHidden)
	{
		m_TMPC.m_AudioManager.requestPlayCharacterVO(C_Die, m_Unit.m_UnitName);
	}

	if(m_TMPC != None)
	{
		if(self == m_TMPC.Pawn)
		{
			m_TMPC.bIsDead = true;
		}
	}

	if(IsAuthority())
	{
		self.OwnerReplicationInfo.Population -= self.PopulationCost;
	}

	tempTMGameInfo = TMGameInfo(WorldInfo.Game);
	tmpri = TMPlayerReplicationinfo(OwnerReplicationInfo);

	// Let the game mode know a pawn died
	if( IsAuthority() && Killer != None )
	{
		tempTMGameInfo.OnKilledUnit( TMPawn( Killer.Pawn ), self );
	}

	// Stop the AoE target from being painted
	m_bPaintTarget = false;
	m_UnitOcclusionMesh.SetHidden(true);
	CommandMesh.SetHidden(true);
	abilityRangeMesh.SetHidden(true);
	TargetMesh.SetHidden(true);
	if (tmPRI != None) {
		if (tmPRI.allyId != -1) {
			pc = TMPlayerController(GetALocalPlayerController());
			if(pc != none)
			{
				if (m_owningPlayerId == pc.PlayerId)
				{
					m_TMPC.RemoveSelectedActor(self);
					m_TMPC.TM_HUD.removePawn(self);
				}
			}
		}
	}

	SetTimer(0.1f, true, NameOf(DesaturateOverTime));

	LifeSpan = 3.f;
	return Super.Died(Killer, DamageType, HitLocation);
}

/* DoDiedBullshitCode
	This function contains all of the bullshit stuff we were doing in Died() that we really
	shouldn't be. Fix these problems later. This function should be removed.
*/
simulated function DoDiedBullshitCode()
{
	if(self.m_nexusDestructable != none)
	{
		m_nexusDestructable.SetTimerToExpire();
	}
}

/* OnCommanderDied
	Called if this TMPawn dies and it was a commander
*/
simulated private function OnCommanderDied(Controller inKiller)
{
	local TMPlayerReplicationInfo tmpri;

	SpawnCommanderDeathVFX();

	m_TMPC.SetHotSelectionGroup("All"); //reset the hot selection to all so when you spawn you will have all units selected
	
	if( IsAuthority() )
	{
		m_TMPC.GetTMPRI().m_deathTimeArray.AddItem( m_currentLifeTime );

		tmpri = TMPlayerReplicationInfo( OwnerReplicationInfo );
		if( tmpri != none )
		{
			if( inKiller != None )
			{
				TMGameInfo(WorldInfo.Game).CommanderDied(tmpri, TMPlayerReplicationInfo(TMPawn(inKiller.Pawn).OwnerReplicationInfo));
			}
			else
			{
				TMGameInfo(WorldInfo.Game).CommanderDied(tmpri, None);
			}
		}
	}

	// Center camera on my dead commander
	if( m_TMPC.IsClient() )
	{
		if( m_TMPC.Pawn == self )
		{
			m_TMPC.CenterCameraOnCommander( 1 );
		}
	}
}

simulated function SpawnCommanderDeathVFX()
{
	local float vfxScale;
	local Vector spawnLocation;
	spawnLocation = GetGroundedLocation();
	spawnLocation.Z += 1;
	vfxScale = 1.0f;
	m_TMPC.m_ParticleSystemFactory.CreateWithScale(ParticleSystem'VFX_Death.Death_PS', m_allyId, GetTeamColorIndex(), spawnLocation, vfxScale, 3.0f );
}

simulated function CleanupComponents()
{
	// If we're the server send fast events to everyone
	if (IsAuthority())
	{
		//Cleanup ability and cancel any transformations
		SendFastEvent( class'TMTransformationFE'.static.create(0, "CANCEL", pawnId) );
		SendFastEvent( class'TMCleanupFE'.static.create(pawnId) );
	}

	// Immediately do a cleanup just in case the pawn is removed before cleanup
	ReceiveFastEvent( (class'TMCleanupFE'.static.create(pawnId)).toFastEvent() );
}

simulated function bool IsPawnNeutral(TMPawn pawn)
{
	if(pawn != none)
	{
		if( TMGameInfo(WorldInfo.Game) != none)
		{
			if (pawn.OwnerReplicationInfo == TMGameInfo(WorldInfo.Game).m_TMNeutralPlayerController.PlayerReplicationInfo)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
	}
	return false;
}

simulated function bool IsInRange2D( Vector location1, Vector location2, int range )
{
	local int rangeSq;
	rangeSq = range*range;
	return ( VSizeSq2D( location1 - location2 ) < rangeSq );
}

function bool IsPointInRange2D( Vector inPoint, int inRange )
{
	local float distance;
	distance = VSize2D( self.Location - inPoint );
	distance -= self.GetCollisionRadius();
	return ( distance < inRange );
}

simulated event TornOff()
{
	if ( Health < 1) // THIS MEANS HE DIED
	{
		Died(none, class'DamageType', Location);
	}

	// Tell all of this pawn's components to clean up
	CleanupComponents();

	super.TornOff();
}

simulated event Destroyed()
{
	local int i;
	local TMPlayerReplicationInfo tmPRI;
	local TMComponent tempComponent;

	if ( m_TMPC.m_gameEnded )
	{
		super.Destroyed();
		return;
	}

	CleanupComponents();

	tmPRI = TMPlayerReplicationInfo(OwnerReplicationInfo);

	foreach m_Unit.m_componentArray(tempComponent)
	{
		tempComponent.m_owner = none;
	}
	if(WorldInfo.NetMode != NM_Client) {
		TMGameInfo(WorldInfo.Game).RemovePawnFromAllHashes(pawnID);
		TMGameInfo(WorldInfo.Game).RemovePawnFromAllTMPawnLists(pawnID);
	}

	if( tmPRI != none )
	{
		for(i = 0; i < ArrayCount(tmPRI.raceUnitNames); i++)
		{
			if(tmPRI.raceUnitNames[i] == self.m_UnitType)
			{
				tmPRI.mUnitCount[i]--;
				break;
			}
		}
	}

	m_Unit.m_owner = none;
	m_Unit = none;
	SetReceivingPotion( false );
	m_TMPC.RemoveSelectedActor(self);
	super.Destroyed();
}

simulated event Landed(vector HitNormal, Actor FloorActor)
{
	local TMAbilityFE fe;
	
	// DruTODO: Same logic? Converge?
	if(self.m_currentState == TMPS_ABILITY || self.m_currentState == TMPS_JUGGERNAUT)
	{
		fe = new () class'TMAbilityFE';
		fe.pawnId = pawnId;
		fe.commandType = "Landed";
		SendFastEvent(fe);
	}
	else if(m_currentState == TMPS_STUNNED )
	{
		fe = new () class'TMAbilityFE';
		fe.pawnId = pawnId;
		fe.commandType = "Landed";
		SendFastEvent(fe);
	}
	
	LastHitBy = None;
}

simulated function SuperTakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

function TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local TMAIController TMAIController;
	local TMPlayerReplicationInfo tmPRI;
	local TMComponentTugOfWar tugOfWarComponent;
	local TMPawn pw;
	local int i;

	// Send event to notify I was attacked
	if( TMPawn(DamageCauser) != none )
	{
		ReceiveFastEvent( class'TMTookDamageFastEvent'.static.create(pawnId, TMPawn(DamageCauser).pawnId, TMPawn(DamageCauser).m_allyId).toFastEvent() );
	}

	if (DamageType == class'DmgType_Crushed')
	{ 
		return; 
	}
	
	if ( (Role < ROLE_Authority) || (Health <= 0) )
	{
		return;
	}

	// Dru TODO: this is not how we're supposed to use components. Events should be passed down.
	tugOfWarComponent = GetTugOfWarComponent();
	if(tugOfWarComponent != none)
	{
		tugOfWarComponent.TakeDamage(DamageAmount,EventInstigator,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);

		TMAIController = TMAIController(Controller);
		if (TMAIController != None)
		{
			TMAIController.NotifyTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
		}

		return;
	}

	tmPRI = TMPlayerReplicationInfo(OwnerReplicationInfo);

	if(IsAuthority())
	{
		if (bCanBeDamaged)
		{
			Super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
		}

		// Notify the ai controller that its pawn was damaged
		TMAIController = TMAIController(Controller);
		if (TMAIController != None)
		{
			TMAIController.NotifyTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
		}
		
		//// DruTODO: This belongs in a passive ability component
		if( self.m_UnitType == "Splitter" )
		{
			if( self.Health <= 0)
			{
				if(self.IsAuthority()) 
				{
					for (i = 0; i < MINISPLITTERS_PER_SPLITTER; i++)
					{
						pw = None;
						pw = TMGameInfo(WorldInfo.Game).RequestUnit("MiniSplitter", TMPlayerReplicationInfo(OwnerReplicationInfo), Location, false, Location, None);
						if( pw != none)
						{
							pw.SendFastEvent( class'TMFastEventSpawn'.static.create( pw.pawnId ,  pw.Location , true) );
						}
					}
				}
			}
		}
		
		if(self.m_UnitType == tmPRI.commanderType)
		{
			if (self.Health < self.HealthMax / 2)
			{
				if( !IsPawnBotControlled() )
				{
					m_TMPC.CommanderDamaged(DamageAmount, (self.Health > 0) ? true : false);
				}
			}

			// Speed the attacker if I have lower than 20% health and was hit by a player
			if( self.Health <= self.HealthMax * 0.20f && self.Health > 0 )
			{
				if( TMPawn(DamageCauser) != none && !IsPawnNeutral( TMPawn(DamageCauser) ) )
				{
					TMPawn(DamageCauser).m_Unit.SendStatusEffect( SE_GRAPPLER_SPEED ); 	// Can make official SE later if we want to keep this feature
				}
			}

			if(!m_TMPC.IsDead()) 
			{
				if ( DamageCauser != None && UDKRTSPawn(DamageCauser) != None )
				{
					TMPlayerReplicationInfo(self.OwnerReplicationInfo).SetAntagonist(DamageAmount, TMPlayerReplicationInfo(UDKRTSPawn(DamageCauser).OwnerReplicationInfo));
				}
			}
		}

		// We will only be a client if we are in local "play" mode
		if( m_TMPC.IsClient() )
		{
			ShowTookDamage();
		}
	}
}

simulated function bool IsPawnBotControlled()
{
	return TMTeamAIController( m_Controller ) != none;
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

// Returns this pawn's location with Z value equal to terrain
simulated function Vector GetTerrainAnchoredLocation()
{
	local Vector returnLocation;
	local Vector traceEnd,
				hitloc,
				norm;
				
	local Actor traceA;

	returnLocation = Location;
	
	traceEnd = Location;
	traceEnd.Z = -1000;
	foreach TraceActors(class'Actor',traceA,hitloc,norm,traceEnd,Location)
	{
		if(traceA.Tag == 'Terrain')
		{
			returnLocation.Z = traceA.Location.Z;
			break;
		}
	}

	return returnLocation;
}

simulated function UpdateNavMeshObstable(vector destination)
{
	
	if(/*VSize(Location - m_obstable.Location) > 2  && */destination != m_pathDestination)
	{
		if(!m_bRegistered)
		{
			m_obstable.SetLocation(self.Location);
			m_obstable.Register();
			m_bRegistered = true;
			SetTimer(2,false,'UnregisterNaveMeshObstable');
		}	
	}
}

simulated function HideMesh()
{
	m_UnitSkeletal.SetScale(0.f);
}

simulated function UnregisterNaveMeshObstable()
{
	m_obstable.Unregister();
	m_bRegistered = false;
}


simulated function bool IsSameDestination(Vector destination)
{
	if(destination == m_pathDestination)
	{
		return true;
	}
	return false;
}

simulated function bool HasSameOwner(TMPawn inPawn)
{
	if( OwnerReplicationInfo == none ||
		inPawn.OwnerReplicationInfo == none )
	{
		return false;
	}

	return inPawn.OwnerReplicationInfo.PlayerID == OwnerReplicationInfo.PlayerID;
}

simulated function CommandQueueClear()
{
	m_CommandQueue.Length = 0;
}

simulated function CommandQueueAdd( TMFastEvent fe )
{
	m_CommandQueue.AddItem(fe);
}

simulated function CommandQueueDo()
{
	local TMFastEvent fe;

	if(m_CommandQueue.Length > 0 )
	{
		fe = m_CommandQueue[0];
		m_CommandQueue.RemoveItem(m_CommandQueue[0]);
		m_Unit.ReceiveFastEvent(fe);
	}
	else if(self.NotInteruptingCommand())
	{
		self.UpdateUnitState( TMPS_IDLE );
		SendStopCommand();
	}
}

simulated function string GetUnitType()
{

	return m_UnitType;
}

simulated function Controller GetTMPC()
{
	return self.m_TMPC;
}

function TMComponent GetTransformComponent()
{
	local TMComponent tempComp;
	local TMComponentAlchTransf alch;
	local int i;
	
	for(i = 0; i < m_Unit.m_componentArray.Length; i++)
	{
		tempComp = m_Unit.m_componentArray[i];
		alch = TMComponentAlchTransf(tempComp);

		if(alch != None)
		{
			m_TransformComponent = tempComp;
			return tempComp;
		}
	}

	return None;
}

function bool IsGameObjective() 	// Dru, is there a smarter way to do this?
{
	if( m_Unit.m_UnitName == "Nexus" || m_Unit.m_UnitName == "Brute" ) {
		return true;
	} else {
		return false;
	}
}

simulated function Vector GetGroundedLocation()
{
	local Vector groundedLocation;
	groundedLocation = Location;
	groundedLocation.Z += Mesh.Translation.Z;
	return groundedLocation;
}

defaultproperties
{
	MINISPLITTERS_PER_SPLITTER = 4;
	SMALL_PUSH_MAGNITUDE = 250.0;
	bIsMovingToTransformer=false
	m_currentState = TMPS_INVISBLE_SPAWN;
	bAlwaysRelevant=true
	m_currentLifeTime=0;
	bIsTransforming=false
	mbDontDeselectOnCommandActive = false;
    m_bHasLanded = false;

	ControllerClass=class'TMPlayerAIController'
	bPathColliding=true
	bCollideActors=true
	Begin Object Class=SkeletalMeshComponent Name=UnitSkele
		SkeletalMesh=SkeletalMesh'TM_DoughBoy.DoughBoy'
	End Object
	m_UnitSkeletal=UnitSkele

	
	Mesh=UnitSkele
	Components.Add(UnitSkele)


	healthBarMat=Material'JC_Material_SandBox.Materials.HealthBarMat'


	Begin Object Class=StaticMeshComponent Name=myOtherAbilityMesh
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		CollideActors=false
		CastShadow=false
	End Object
	abilityRangeMesh=myOtherAbilityMesh
	Components.Add(myOtherAbilityMesh);

	bAbilityMeshScaleSet=false

	//numSpawn=0
	bStunned=false;
	bCanBeDamaged = true;

	bTeamMaterialSet=false;
	fDesaturateAmount=0;
	fDarkenAmount=1;
	bApplyFogOfWar=true;

	Begin Object Class=SkeletalMeshComponent Name=OcclusionSkeletalMeshComponent
		Materials(0)=Material'JC_Material_SandBox.Masters.JC_TeamOutline_Master'
		DepthPriorityGroup=SDPG_Foreground
		CastShadow=false
		bCastDynamicShadow=false
		ParentAnimComponent=UnitSkele
		bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=true
		BlockRigidBody=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bUpdateKinematicBonesFromAnimation=true
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=false
		MinDistFactorForKinematicUpdate=0.2f
		bChartDistanceFactor=true
		bUseOnePassLightingOnTranslucency=true
		bPerBoneMotionBlur=false
	End Object
	m_UnitOcclusionMesh=OcclusionSkeletalMeshComponent
	Components.Add(OcclusionSkeletalMeshComponent)

	
	Begin Object Class=StaticMeshComponent Name=TargetMeshComponent
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		CollideActors=false
		DepthPriorityGroup=SDPG_World
		CastShadow=false
	End Object
	TargetMesh=TargetMeshComponent
	Components.Add(TargetMeshComponent);

	Begin Object Class=StaticMeshComponent Name=DragSelectionMeshComponent
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		CollideActors=false
		DepthPriorityGroup=SDPG_World
		CastShadow=false
	End Object
	DragSelectionMesh=DragSelectionMeshComponent
	Components.Add(DragSelectionMeshComponent);

	Begin Object Class=StaticMeshComponent Name=AbilityTargetMeshComponent
		HiddenGame=true
		AbsoluteTranslation=true
		AbsoluteRotation=true
		CollideActors=false
		CastShadow=false
	End Object
	AbilityTargetMesh=AbilityTargetMeshComponent
	Components.Add(AbilityTargetMeshComponent);
	
	AirControl=+0.00

	bCanCrouch=false
	m_bIsAbilityReady = true;

	// Fixing ramp issues?
	//MaxStepHeight=50.0
	//MaxJumpHeight=50.0
	//WalkableFloorZ=0.05		   // 0.7 ~= 45 degree angle for floor // 0.15 ~ 8.5 deg (radians)
	//LedgeCheckThreshold=4.0f
	//MaxOutOfWaterStepHeight=40.0
	bReducedSpeed = false;
	bFrozen = false;
	sightRadiusTiles=8;

	bCanBeHitByNuke = false;
	bMoveIgnoresDestruction=true;
	missedTicks = 0;
	bIsInitialized = false;
	b_hasDecay = false; //set to false for an optimization on getting the component
	bCanBeKnockedUp = true;
	bCanBeKnockedBack = true;
}
