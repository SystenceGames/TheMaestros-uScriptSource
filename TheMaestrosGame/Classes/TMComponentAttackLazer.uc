class TMComponentAttackLazer extends TMComponentAttack;

var int m_iMultiplier;
var int m_iBaseDamage;
var float m_fTimePerPhase;
var float m_time;
var ParticleSystem m_tier1Particle;
var ParticleSystem m_tier2Particle;
var ParticleSystem m_tier3Particle;

var ParticleSystem m_BeamLevel1;
var ParticleSystem m_BeamLevel2;
var ParticleSystem m_BeamLevel3;

var ParticleSystem m_onBeamHitSmall;
var ParticleSystem m_onBeamHitLarge;


var ParticleSystemComponent m_currentPartcile;



var ParticleSystem m_currentParticleOnHit;
var ParticleSystem m_currentParticleBeam;

var bool m_bResetPassive;

var ParticleSystemComponent psc;

enum SkyBreakerLaserState
{
	NotCharging,
	Charging,
};
var SkyBreakerLaserState m_currentstate;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json,parent);
	m_iMultiplier = json.GetIntValue("multiplier");
	m_iBaseDamage = json.GetIntValue("damage");
	m_fTimePerPhase = json.GetFloatValue("timePerPhase")/100;

	m_currentstate = NotCharging;
	m_tier1Particle = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Charge_Tier01';
	m_tier2Particle = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Charge_Tier02';
	m_tier3Particle = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Charge_Tier03';

	m_BeamLevel1 = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Beam_Sm';
	m_BeamLevel2 = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Beam_Mid';
	m_BeamLevel3 = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Beam_Lg';

	m_onBeamHitSmall  = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Beam_Hit';
	m_onBeamHitLarge  = ParticleSystem'VFX_Skybreaker.Particles.vfx_Skybreaker_Beam_Hit_Lg';
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentAttackLazer newcomp;
	newcomp= new () class'TMComponentAttackLazer'(self);
	newcomp.m_owner=newowner;
	newcomp.m_iRange = m_iRange;
	newcomp.m_iDamage = m_iDamage;
	newcomp.m_rateOfFire = m_rateOfFire;

	newcomp.m_iBaseDamage = m_iBaseDamage;
	newcomp.m_iMultiplier = m_iMultiplier;
	newcomp.m_iDamage = m_iBaseDamage;
	newcomp.m_owner = newowner;
	newcomp.m_tier1Particle = m_tier1Particle;
	newcomp.m_tier2Particle = m_tier2Particle;
	newcomp.m_tier3Particle = m_tier3Particle;


	newcomp.m_BeamLevel1 = m_BeamLevel1;
	newcomp.m_BeamLevel2 = m_BeamLevel2;
	newcomp.m_BeamLevel3 = m_BeamLevel3;

	newcomp.m_onBeamHitSmall = m_onBeamHitSmall;
	newcomp.m_onBeamHitLarge = m_onBeamHitLarge;
	return newcomp;
}


simulated function DoPassiveAbility()
{
	local Vector positioning;
	local TMPawn temppawn;
	if(m_owner != none)
	{
		if(m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
		{
			tempPawn = m_target == none ? m_clientTarget : m_target;
			if(m_currentParticleBeam != none && temppawn != none)
			{
				m_owner.Mesh.GetSocketWorldLocationAndRotation('Beam2_Socket',positioning);
				psc = m_owner.WorldInfo.MyEmitterPool.SpawnEmitter(m_currentParticleBeam,positioning,,,,,);
				psc.SetTemplate(m_currentParticleBeam);
				psc.SetBeamEndPoint(0,temppawn.Location);
				psc.SetBeamEndPoint(1,temppawn.Location);
				psc.SetBeamEndPoint(2,temppawn.Location);
				if( psc!=none && m_owner != None && m_owner.m_TMPC!= none )
				{
					psc.SetHidden(!m_owner.m_Controller.GetFoWManager().IsLocationVisible(m_owner.Location));
				}
			}

			if(temppawn != none && m_currentParticleOnHit != none)
			{
				psc = m_owner.WorldInfo.MyEmitterPool.SpawnEmitter(m_currentParticleOnHit,temppawn.Location,,,,,);
				psc.SetHidden( !m_owner.m_Controller.GetFoWManager().IsLocationVisible(tempPawn.Location) );
			}
		}


	}
	m_bResetPassive = true;
}


simulated function UpdateComponent(float dt)
{
	local bool hidden;
	if( psc!=none && m_owner != None && m_owner.m_TMPC!= none && m_currentPartcile != none )
	{
		hidden = !m_owner.m_Controller.GetFoWManager().IsLocationVisible(m_owner.Location);
		psc.SetHidden(hidden);
		m_currentPartcile.SetHidden(hidden);
	}

	super.UpdateComponent(dt);
	if(m_owner != none)
	{

		if(m_bResetPassive)
		{
			m_bResetPassive = false;
			if(m_currentPartcile != none && m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
			{
				m_currentPartcile.DeactivateSystem();
			}

			if(IsAuthority())
			{
				m_iDamage = m_iBaseDamage;
			}
			m_currentParticleBeam = m_BeamLevel1;
			m_currentParticleOnHit  = m_onBeamHitSmall;
			m_currentstate = NotCharging;
		}

		if((m_owner.m_currentState !=TMPS_ATTACK && m_owner.m_currentState != TMPS_JUGGERNAUT && m_owner.m_currentState != TMPS_ABILITY && m_currentstate != Charging))
		{
			m_currentstate = Charging;
			Setup_Phase1();
			m_time = m_fTimePerPhase;
		}
	}
	if(m_currentstate == Charging)
	{
		if(m_time > 0)
		{
			m_time -= dt;
		}
		else
		{
			if(m_currentParticleBeam == m_BeamLevel1)
			{
				Setup_Phase2();
				m_time = m_fTimePerPhase;
			}
			else if(m_currentParticleBeam == m_BeamLevel2)
			{
				Setup_Phase3();
			}
		}
	}


}


// Sets damage to 100% and starts timer to phase 2
simulated function Setup_Phase1()
{
	if(m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc  = m_owner.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(m_tier1Particle,m_owner.Mesh,'GlowingOrb',true,,);
		if(m_currentPartcile != none)
		{
			m_currentPartcile.DeactivateSystem();
		}
		m_currentPartcile = psc;
	}


	m_currentParticleBeam = m_BeamLevel1;
	m_currentParticleOnHit  = m_onBeamHitSmall;
}

// Sets damage to 100% + 50% multiplier and starts timer to phase 3
simulated function Setup_Phase2()
{
   if(m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc  = m_owner.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(m_tier2Particle,m_owner.Mesh,'GlowingOrb',true,,);
		if(m_currentPartcile != none)
		{
			m_currentPartcile.DeactivateSystem();
		}
		m_currentPartcile = psc;
	}

	if((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone))
	{
		m_iDamage = m_iBaseDamage * 1.75;
	}
	m_currentParticleBeam = m_BeamLevel2;
	m_currentParticleOnHit  = m_onBeamHitSmall;
}

simulated function Setup_Phase3()
{
	if(m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer)
	{
		psc = m_owner.WorldInfo.MyEmitterPool.SpawnEmitterMeshAttachment(m_tier3Particle,m_owner.Mesh,'GlowingOrb',true,,);
		if(m_currentPartcile != none)
		{
			m_currentPartcile.DeactivateSystem();
		}
		m_currentPartcile  = psc;
	}
	
	if((m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_ListenServer || m_owner.m_TMPC.WorldInfo.NetMode == NM_Standalone))
	{
		m_iDamage = m_iBaseDamage * 3;
	}
	m_currentParticleBeam = m_BeamLevel3;
	m_currentParticleOnHit  = m_onBeamHitLarge;
}







DefaultProperties
{
}
