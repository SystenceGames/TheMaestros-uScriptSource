class TMAbilityRoboMeisterNuke extends TMAbility;


const PLAY_VFX = "C_RoboMeister_Nuke_Hit";

var float mProjectileSpeed;

var float mDamagePercentage;
var int mExplosionRadius;
var int mCollisionRadius;
var int mSightRadius;
var int mMaxDamage;

var TMProjectileRoboMeisterNuke mProjectile;

var ParticleSystem mProjectileParticle;
var ParticleSystem mProjectileOnHitParticle;

var TMFOWRevealActor mRevealPawn;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mDamagePercentage = json.GetFloatValue("damPercentage")/100;
	mProjectileSpeed = json.GetIntValue("projSpeed");
	mExplosionRadius = json.GetIntValue("explosionRadius");
	mSightRadius = json.GetIntValue("sightRadius");
	mMaxDamage = json.GetIntValue("maxDamage");
	mCollisionRadius = 200;
	mProjectileParticle = ParticleSystem'TM_Robomeister.Particles.vfx_Robomeister_nuke';
	mProjectileOnHitParticle = ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_SpecialExplosion';

	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityRoboMeisterNuke newcomp;
	newcomp= new () class'TMAbilityRoboMeisterNuke'(self);
	newcomp.m_owner=newowner;
	newcomp.mProjectileParticle = mProjectileParticle;
	newcomp.mProjectileOnHitParticle = mProjectileOnHitParticle;
	return newcomp;
}

function ReceiveFastEvent(TMFastEvent fe)
{
	super.ReceiveFastEvent(fe);

	if ( fe.commandType == PLAY_VFX )
	{
		if( mProjectile == none || m_AbilityState == AS_CASTING )  // haven't fired the Nuke yet on client, but server already had a collision!
		{
			PlayNukeExplosionForClient();   // client wants to see his VFX
		}
		else
		{
			mProjectile.ExplodeNuke();
		}
	}
}

function StartAbility()
{
	RotateToTarget();
	super.StartAbility();
}

function CastAbility()
{
	ShootNuke();
	super.CastAbility();
}

function ShootNuke()
{
	local Vector socketLoc;
	local Rotator nukeRotation;

	// Get nuke position and rotation
	m_owner.Mesh.GetSocketWorldLocationAndRotation('ProjectileSocket',socketLoc);
	nukeRotation = Rotator( m_TargetLocation - m_CastingStartLocation );
	nukeRotation.Pitch = 0;
	nukeRotation.Roll = 0;

	mProjectile = m_owner.Spawn(class'TMProjectileRoboMeisterNuke',,,m_CastingStartLocation, nukeRotation);
	mProjectile.SetOnHitParticle( mProjectileOnHitParticle );
	m_TargetLocation.Z = socketLoc.Z;   // make the target be level with me

	m_TargetLocation.Z = m_owner.Location.Z;   // TEMP hack

	mProjectile.FireNuke( m_TargetLocation, m_owner, mProjectileParticle, mProjectileSpeed, mDamagePercentage, mMaxDamage, mExplosionRadius, mCollisionRadius, mSightRadius );
}

function PlayNukeExplosionForClient()   // this is for when the server explodes the Nuke before the client can even spawn his. The client wants to see the boom
{
	local Vector socketLoc;
	local rotator socketRot;

	m_owner.Mesh.GetSocketWorldLocationAndRotation('ProjectileSocket',socketLoc,socketRot,);	

	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithRotationAndScale(mProjectileOnHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), socketLoc, m_owner.Rotation, 2.0f);

	if(!m_owner.bHidden)
	{
		m_owner.m_TMPC.m_AudioManager.requestPlaySFXWithActor(SoundCue'SFX_Dynamics.Dynamics_SFX_Shrine_Explosion', m_owner);
	}
}

function AddSightToExplosion( Vector pos )
{
	mRevealPawn = m_owner.Spawn( class'TMFOWRevealActorStatic',,, pos,,, true);
	mRevealPawn.Setup( TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyInfo.allyIndex, m_owner.m_Controller.GetFoWManager(), mSightRadius );
	m_owner.SetTimer( 1, false, 'RemoveSightFromExplosion', self );
}

function RemoveSightFromExplosion()
{
	mRevealPawn.Destroy();
}

DefaultProperties
{
	mAnimationDurationFallback = 2.0f; 	// give longer wait time while waiting for ability

	m_AbilityIndicatorStyle = AIS_NUKE;
}
