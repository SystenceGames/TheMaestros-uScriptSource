class TMAbilitySalvatorSnake extends TMAbility;


const SPAWN_TELEPORT_VFX = "C_Spawn_Teleport_VFX";

var float mDuration;

var TMSalvatorSnake mSnake1, mSnake2;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);

	m_sAbilityName = "SalvatorSnake";
	mDuration = json.GetFloatValue( "duration" );
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilitySalvatorSnake newcomp;
	newcomp= new () class'TMAbilitySalvatorSnake'(self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function Cleanup()
{
	if( mSnake1 != none ) {
		mSnake1.RemoveSnake();
	}
	if( mSnake2 != none ) {
		mSnake2.RemoveSnake();
	}

	super.Cleanup();
}

function ReceiveFastEvent( TMFastEvent fe )
{
	local TMAbilityFE abFE;

	if( fe.commandType == SPAWN_TELEPORT_VFX )
	{
		abFE = class'TMAbilityFe'.static.fromFastEvent( fe );
		m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale(ParticleSystem'VFX_Adam.Particles.P_NeutralOrb_Spawn', m_owner.m_allyId, m_owner.GetTeamColorIndex(), abFE.abilityLocation, 2.0f);
	}

	super.ReceiveFastEvent( fe );
}

function CastAbility()
{
	local Vector selfSpawnLocation;

	// Make sure the Z value of both portals are equal
	selfSpawnLocation = m_owner.Location;
	selfSpawnLocation.Z += m_owner.Mesh.Translation.Z;

	mSnake1 = m_owner.Spawn( class'TMSalvatorSnake',,, selfSpawnLocation );
	mSnake2 = m_owner.Spawn( class'TMSalvatorSnake',,, m_TargetLocation );
	mSnake1.Setup( m_owner, mSnake2, mDuration, selfSpawnLocation );
	mSnake2.Setup( m_owner, mSnake1, mDuration, m_TargetLocation );

	super.CastAbility();
}
