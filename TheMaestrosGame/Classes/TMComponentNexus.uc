class TMComponentNexus extends TMComponent;

var ParticleSystem mDeathEffect;
var SkelControlSingleBone pillarSkelControl;
var SkelControlSingleBone baseSkelControl;
var WorldInfo mWorldInfo;
var float time;
var TMGameObjectiveHelper gameObjectiveHelper;
var string notificationMessage;

var AnimTree loadedAnimTree;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	self.loadedAnimTree = AnimTree(DynamicLoadObject("Nexus.Nexus_Skel", class'AnimTree'));
}

simulated function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentNexus newcomp;
	local TMGameInfo tempGameInfo;
	local TMFOWRevealActor revealer;

	newcomp = new() class'TMComponentNexus' (self);
	newcomp.m_owner = newowner;
	newcomp.m_owner.Mesh.SetAnimTreeTemplate(self.loadedAnimTree);
	newcomp.mWorldInfo = newowner.m_TMPC.WorldInfo;
	newcomp.gameObjectiveHelper = new () class'TMGameObjectiveHelper';
	newcomp.gameObjectiveHelper.Init(newowner);
	newowner.bCanBeKnockedUp = false;
	newowner.bCanBeKnockedBack = false;

	revealer = newcomp.gameObjectiveHelper.SpawnFoWRevealer();

	if(newcomp.mWorldInfo.NetMode != NM_Client)
	{
		tempGameInfo = TMGameInfo(newComp.mWorldInfo.Game);
		tempGameInfo.bNexusIsUp = true;
		tempGameInfo.m_NexusRevealActor = revealer;
	}
	else
	{
		newowner.m_TMPC.m_NexusRevealer = revealer;
	}

	return newcomp;
}

function ReceiveFastEvent(TMFastEvent event)
{
	local TMGameInfo tempGameInfo;

	if(event.commandType == "dead")//"C_NexusDied")
	{
		if ( m_owner.m_TMPC.IsClient() )
		{
			PlayNexusDeathEffect();
		}
		CleanUpMesh();
		if ( mWorldInfo.NetMode != NM_Client )
		{
			tempGameInfo = TMGameInfo(mWorldInfo.Game);
			tempGameInfo.bNexusIsUp = false;
			tempGameInfo.m_NexusRevealActor = None;
		}
		gameObjectiveHelper.RemoveFoWRevealer();
	}
	if(event.commandType == class'TMCleanupFE'.const.CLEANUP_COMMAND_TYPE)
	{
		gameObjectiveHelper.RemoveFoWRevealer();
	}
	if(event.commandType == "C_Took_Damage")
	{
		gameObjectiveHelper.NotifyIAmHit(event, notificationMessage);
	}
}

function PlayNexusDeathEffect()
{
	local vector effectLoc;

	effectLoc = m_Owner.Location;
	//we can make this lower for more of a BOOM throw shit everywhere. right now it will just kinda crumble down
	effectLoc.Z += 250;
	m_owner.m_nexusDestructable.TakeRadiusDamage(none,400,1000,class'DamageType',100, effectLoc, true, none,);
	
	effectLoc = m_Owner.Location;
	effectLoc.Z -= 150;

	m_Owner.m_TMPC.m_ParticleSystemFactory.Create(mDeathEffect, m_owner.m_allyId, m_owner.GetTeamColorIndex(), effectLoc);

	if(!m_owner.bHidden)
	{
		m_Owner.m_TMPC.m_AudioManager.requestPlayEmitterSFX(mDeathEffect, m_Owner);
	}
}

function UpdateComponent(float dt)
{
	time += dt;
	if( pillarSkelControl == None )
	{
		m_Owner.m_UnitSkeletal.SetAnimTreeTemplate(AnimTree'Nexus.Nexus_Skel');
		baseSkelControl = SkelControlSingleBone(m_Owner.m_UnitSkeletal.FindSkelControl('Base'));
		baseSkelControl.BoneTranslation.X = 5;
		baseSkelControl.BoneRotation.Roll = 16384;
		pillarSkelControl = SkelControlSingleBone(m_Owner.m_UnitSkeletal.FindSkelControl('Pillar'));
	}
	
	pillarSkelControl.BoneTranslation.X = Sin(time*1.f) * 7.f;
	pillarSkelControl.BoneRotation.Roll = time * 700;
	super.UpdateComponent(dt);
}

function CleanUpMesh()
{
	m_Owner.Mesh.SetHidden(true);
	m_owner.Mesh.SetScale(0);
	m_Owner.SetHidden(true);
	if ( m_owner.m_TMPC.IsClient() )
	{
		m_owner.m_nexusDestructable.SetHidden(false);
	}
}

DefaultProperties
{
	time = 0.f
	notificationMessage = "The Shrine is under Attack!";

	mDeathEffect = ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion';
}
