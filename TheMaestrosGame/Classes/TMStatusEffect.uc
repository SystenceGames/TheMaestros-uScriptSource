class TMStatusEffect extends TMComponent;

const SE_COMMAND_TYPE = "C_StatusEffect";
const CLEANUP_COMMAND_TYPE = "C_Cleanup";

var bool m_bIsActive;
var float m_fDuration;
var float m_fDurationRemaing;

var TMParticleSystem mParticleSystem;

enum StatusEffectNames
{
	SE_DISRUPTOR_POISON,
	SE_GRAPPLER_SPEED,
	SE_OILER_SLOW,
	SE_REGENERATOR_HEAL,
	SE_CREEPKILL_HEAL,
	SE_SPLITTER_KNOCKUP,
	SE_POPSPRING_KNOCKUP,
	SE_TIME_FREEZE,
	SE_RAMBAMQUEEN_KNOCKBACK,
	SE_GRAPPLER_KNOCKBACK,
	// OLD SE'S BELOW
	SE_INVULNERABLE,
	SE_POISON,
	SE_SLOW,
	SE_STUNNED,
	SE_SLOW_TAR,
	SE_COMMANDER_KNOCKBACK,
	SE_SPLITTER_KNOCKBACK,
	SE_SKYBREAKER_KNOCKBACK,
	SE_FROZEN,
	SE_TELEPORT,
	SE_INSTANTDAMAGE,
	SE_GENERIC_ALL_TYPE
};

var StatusEffectNames m_StatusEffectName;
var StatusEffectNames m_currentStatus;
//init
function SetUpComponent(JsonObject json, TMPawn parent)
{
	if (m_owner != none)    // This will be none when setting up the status effect cache
	{
		m_owner = parent;
	}
	m_StatusEffectName = StatusEffectNames(json.GetIntValue( "StatusEffectEnumValue" ));
	m_fDuration = json.GetIntValue("duration");
	m_fDurationRemaing = m_fDuration;
	m_bIsActive = false;
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMStatusEffect newcomp;
	newcomp= new () class'TMStatusEffect' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function ReceiveFastEvent(TMFastEvent fe)
{
	if(fe.commandType == SE_COMMAND_TYPE)
	{
		HandleStatusEffectFE(class'TMStatusEffectFE'.static.fromFastEvent(fe));
	}
	else if ( fe.commandType == CLEANUP_COMMAND_TYPE )
	{
		Cleanup();
	}
}

function Cleanup()
{
	m_owner.ClearAllTimers( self );
	
	if ( mParticleSystem != none )
	{
		m_bIsActive = false;
		mParticleSystem.Destroy();
	}
}

simulated function HandleStatusEffectFE(TMStatusEffectFE seFE)
{
	if (seFE.statusEffectEnum == m_StatusEffectName)
	{
		if (m_bIsActive)
		{
			StackStatusEffect(seFE);
		}
		else
		{
			Begin();
		}
	}
}

// Basic stacking, just reset the timer back to max
function StackStatusEffect(TMStatusEffectFE seFE)
{
	m_fDurationRemaing = m_fDuration;
	m_owner.ClearTimer('End', self);
	m_owner.SetTimer(m_fDuration, false, 'End', self);
}

// Dru TODO: Why is there SPLITTER_KNOCKUP Code in the generic Status Effect?
//function to update whatever you need
simulated function UpdateComponent(float dt)
{
	m_fDurationRemaing -= dt;
	if(m_owner.m_bHasLanded && m_StatusEffectName == SE_SPLITTER_KNOCKUP || m_fDurationRemaing < -1)
	{
		End();
		m_owner.bBlockActors = true;
		m_owner.m_bHasLanded = false;
		m_owner.bStunned = false;
		m_owner.UpdateUnitState( TMPS_IDLE );
		m_bIsActive = false;
		m_owner.ClearTimer('End', self);
		m_owner.SetCollision( true );
		m_Owner.m_Unit.RemoveStatusEffect(self);
	}
}

function BeginVFX()
{
	local Vector attachLocation;
	local ParticleSystem ps;
	local float psScale;

	// Default Status Effect settings
	attachLocation = m_owner.Location;
	attachLocation.Z += 150;
	psScale = 2;
	ps = ParticleSystem'VFX_Adam.Particles.P_Icon_Dazed';

	// Specific settings for Status Effects
	switch ( m_StatusEffectName )
	{
	case SE_DISRUPTOR_POISON:
		ps = ParticleSystem'VFX_Adam.Particles.P_Icon_Posion';
		break;
	case SE_OILER_SLOW:
		ps = ParticleSystem'VFX_Adam.Particles.P_Icon_Slow';
		break;
	case SE_GRAPPLER_SPEED:
		ps = ParticleSystem'VFX_Bloodlust.Bloodlust_PS';
		attachLocation = m_owner.GetGroundedLocation();
		attachLocation.Z += 25;
		psScale = 1;
		break;
	case SE_REGENERATOR_HEAL:
	case SE_CREEPKILL_HEAL:
		ps = ParticleSystem'VFX_Adam.Particles.P_Icon_Health';
		break;
	}

	mParticleSystem = m_owner.m_TMPC.m_ParticleSystemFactory.CreateAttachedToActor( ps, m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner, attachLocation, m_fDuration );
	mParticleSystem.SetScale( psScale );
}

function EndVFX()
{
	if ( mParticleSystem != none )
	{
		mParticleSystem.Destroy();
		mParticleSystem = none;
	}
}

function Begin()
{
	BeginVFX();
	m_bIsActive = true;
	m_fDurationRemaing = m_fDuration;
	m_owner.SetTimer(m_fDuration, false, 'End', self);
}

function End()
{
	EndVFX();
	m_bIsActive = false;
	m_owner.ClearTimer('End', self);
	m_Owner.m_Unit.RemoveStatusEffect(self);
}

DefaultProperties
{
}
