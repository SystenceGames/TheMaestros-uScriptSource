class TMComponentAttackRailGun extends TMComponentAttack;

var ParticleSystem m_railGunParticle;

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentAttackRailGun newcomp;
	newcomp= new () class'TMComponentAttackRailGun' (self);
	newcomp.m_owner=newowner;
	newcomp.m_iDamage = m_iDamage;
	newcomp.m_iRange = m_iRange;
	newcomp.m_rateOfFire = m_rateOfFire;
	newcomp.m_bAttackMoveIsActive = false;
	newcomp.m_State = AS_NOTHING;
	newcomp.m_projectileSpeed = m_projectileSpeed;
	newcomp.m_onHitParticle = m_onHitParticle;
	newcomp.m_NeutralDamageBonus = m_NeutralDamageBonus;
	newcomp.m_fireAndForget = m_fireAndForget;
	newcomp.m_idleDuration = m_idleDuration;
	newcomp.m_fireAndForgetDistance = m_fireAndForgetDistance;
	return newcomp;
}



simulated function DoPassiveAbility()
{
	local Actor tempActor;
	local TMPawn tempPawn;
	local TMPawn tempTargetPawn;
	local Vector vHitLoc, vHitNorm;
	local Vector targetLocation;
	local Vector beamVector;

	tempTargetPawn  = m_target == none ? m_clientTarget : m_target;
	targetLocation = Normal(tempTargetPawn.Location - m_owner.Location)*m_iRange + m_owner.Location;
	
//	m_owner.GetActor().DrawDebugLine(m_owner.Location, targetLocation, 255, 255, 255, false);

	if( m_owner.m_TMPC.IsClient() )
	{
		m_owner.Mesh.GetSocketWorldLocationAndRotation('ProjectileSpawn',beamVector);
		beamVector.X = m_owner.Location.X;
		beamVector.Y = m_owner.Location.Y;
		m_owner.m_TMPC.m_ParticleSystemFactory.CreateBeam(m_railGunParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), beamVector, targetLocation, 2);
		m_owner.m_TMPC.m_ParticleSystemFactory.Create(m_onHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), tempTargetPawn.Location);
	}

	foreach m_owner.WorldInfo.TraceActors(class'Actor', tempActor, vHitLoc, vHitNorm, m_owner.Location, targetLocation)
	{
		tempPawn = TMPawn(tempActor);

		// Make sure I got a valid pawn
		if (tempPawn != none && tempPawn != tempTargetPawn)
		{
			// If the actor is a bad guy, deal damage to him
			if (TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId)
			{       
				m_owner.m_TMPC.m_ParticleSystemFactory.Create(m_onHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), tempPawn.Location);
				ApplyDamage(tempPawn);
			}
		}
	}
}

DefaultProperties
{
	m_onHitParticle = ParticleSystem'VFX_Leo.Particles.vfx_DoughBoy_Hit_Small_Red';
	m_railGunParticle =ParticleSystem'VFX_Sniper.Particles.P_Sniper_MineTrail';
}
