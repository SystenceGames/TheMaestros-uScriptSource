class TMAbilityConductorShock extends TMAbility
	DependsOn(TMFOWSightInfo);

var int m_iDamage;
var array<TMPawn> m_aLinkedConductors;  // the conductors I'm responsible for linking to
var array<TMPawn> mShockedEnemies;
var float mCastDuration;    // how long for the unit to hold the ability cast (needs to be greater than zero to allow conductors to find each other and link)

var ParticleSystem mConductorParticleSystem;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);
	
	m_iDamage = json.GetIntValue("damage");
	mIsInstantCast = true;
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMAbilityConductorShock newcomp;
	newcomp= new () class'TMAbilityConductorShock'(self);
	newcomp.m_owner=newowner;
	newcomp.m_iDamage = m_iDamage;
	newcomp.mIsInstantCast = true;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function Cleanup()
{
	m_owner.m_TMPC.m_aConductors.RemoveItem(m_owner);   // remove myself from the list of conductors who are casting
	m_owner.ClearAllTimers( self );

	super.Cleanup();
}

function CastAbility()
{
	CastShock();

	m_owner.SetTimer( mCastDuration, false, 'TEMP_EndAbility', self );
}

// NOTE: this function is added only to keep conductor with its old delay. Not sure why there is a delay, but we have it
function TEMP_EndAbility()
{
	super.CastAbility();
}

function BeginCooldown()
{
	ClearLinkedConductors();
	ClearShockedEnemies();
	m_owner.m_TMPC.m_aConductors.RemoveItem(m_owner);   // remove myself from the list of conductors who are casting
	m_owner.UpdateUnitState( TMPS_IDLE );

	super.BeginCooldown();
}

function UpdateComponent( float dt )
{
	if ( m_AbilityState == AS_CASTING )
	{
		HighlightEnemies();
	}

	super.UpdateComponent( dt );
}

function CastShock()
{
	local int i;

	// Add myself to the list of conductor who want to cast shock
	m_owner.m_TMPC.m_aConductors.AddItem(m_owner);

	for (i = 0; i < m_owner.m_TMPC.m_aConductors.Length; i++)
	{
		if (m_owner.m_TMPC.m_aConductors[i] != m_owner)
		{
			if (IsInRange(m_owner.Location, m_owner.m_TMPC.m_aConductors[i].Location, m_iRange))
			{
				m_aLinkedConductors.AddItem(m_owner.m_TMPC.m_aConductors[i]);
			}
		}
	}

	DoShockLink();
}

function DoShockLink()
{
	local int i;
	local TMPawn temp;

	for (i = 0; i < m_aLinkedConductors.Length; i++)
	{
		temp = m_aLinkedConductors[i];
		ShockEnemies(m_owner.Location, temp.Location);
		PlayBeamEffect(temp);
	}

	if (m_aLinkedConductors.Length == 0)    // don't have a link, but need to zap myself for visual consistency
	{
		PlayBeamEffect(m_owner);
	}
}

function ShockEnemies(vector pos1, vector pos2)
{
	local Actor tempActor;
	local TMPawn tempPawn;
	local Vector vHitLoc, vHitNorm;

	foreach m_owner.WorldInfo.TraceActors(class'Actor', tempActor, vHitLoc, vHitNorm, pos1, pos2)
	{
		tempPawn = TMPawn(tempActor);

		// Make sure I got a valid pawn
		if (tempPawn != none)
		{
			// If the actor is a bad guy, deal damage to him
			if (TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId)
			{
				//tempPawn.SetHighlighted(true);
				//tempPawn.SetHighlightColor(0.01f,1.0f,1.0f,1.0f);
				//mShockedEnemies.AddItem( tempPawn );
				m_AbilityHelper.DoDamageToTarget( m_iDamage, tempPawn );
			}
		}
	}
}

function ClearLinkedConductors()
{
	m_aLinkedConductors.Remove( 0, m_aLinkedConductors.Length );

	if ( m_aLinkedConductors.Length > 0 ) 	// We have this check because of a past bug. Will remove this if don't see log message soon
	{
		`log( "ERROR: ClearLinkedConductors didn't clear list", true, 'TMAbilityConductorShock' );
	}
}

function ClearShockedEnemies()
{
	local int i;
	for (i = 0; i < mShockedEnemies.Length; i++)
	{
		mShockedEnemies[i].SetHighlighted( false );
	}

	mShockedEnemies.Remove( 0, mShockedEnemies.Length );
}


simulated function PlayBeamEffect(TMPawn target)
{
	local Vector targetPosition;
	local Vector myPosition;

	if(m_owner == none)
	{
		return;
	}

	if(m_owner.m_TMPC.IsClient())
	{
		m_owner.Mesh.GetSocketWorldLocationAndRotation('Top_Socket',myPosition);
		target.Mesh.GetSocketWorldLocationAndRotation('Top_Socket',targetPosition);
		m_owner.m_TMPC.m_ParticleSystemFactory.CreateBeam(mConductorParticleSystem, m_owner.m_allyId, m_owner.GetTeamColorIndex(), myPosition, targetPosition, 2);
	}
}

function HighlightEnemies()
{
	local int i;
	for (i = 0; i < mShockedEnemies.Length; i++)
	{
		mShockedEnemies[i].SetHighlighted( true );
		mShockedEnemies[i].SetHighlightColor(0.01f,1.0f,1.0f,1.0f);
	}
}

defaultproperties
{
	mHasNoAnimation = true;
	mCastDuration = 0.1f;

	mConductorParticleSystem = ParticleSystem'VFX_Conductor.Particles.P_Conductor_Chain';
}
