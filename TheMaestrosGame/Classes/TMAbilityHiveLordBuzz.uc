class TMAbilityHiveLordBuzz extends TMAbility;

var float   mDuration;
var int     mAoERadius;
var int     mAoEDamage;
var float   mAoETicksPerSecond;


function SetUpComponent( JsonObject json, TMPawn parent )
{
	mDuration = json.GetFloatValue( "duration" )/100;
	mAoERadius = json.GetFloatValue( "aoeRadius" );
	mAoEDamage = json.GetFloatValue( "aoeDamage" );
	mAoETicksPerSecond = json.GetFloatValue( "aoeTicksPerSecond" );
	mIsInstantCast = true;
	super.SetUpComponent( json, parent );
}

function TMComponent makeCopy( TMPawn newowner )
{
	local TMAbilityHiveLordBuzz newcomp;
	newcomp= new () class'TMAbilityHiveLordBuzz'(self);
	newcomp.m_owner=newowner;
	newcomp.mIsInstantCast = true;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function Cleanup()
{
	m_owner.ClearAllTimers( self );
	BeginCooldown();
	super.Cleanup();
}

function HandleAbility()
{
	m_TargetLocation = m_owner.Location;
	super.HandleAbility();
}

function CastAbility()
{
	m_AbilityState = AS_CASTING;
	m_fTimeInState = 0;
	m_owner.m_bIsAbilityReady = false;
	m_owner.UpdateUnitState( TMPS_ABILITY );

	m_owner.SetCollision( false );
	m_owner.bCanBeDamaged = false;
	m_owner.SetTimer( 1 / mAoETicksPerSecond, true, 'DoAoEDamage', self );
	m_owner.bCanBeKnockedUp = false;
	m_owner.bCanBeKnockedBack = false;

	PlayVFX();

	m_owner.bApplyFogOfWar = false;
	m_owner.Mesh.SetHidden( true );

	m_owner.GetAttackComponent().mCanAttack = false;
	m_owner.GetAttackComponent().StopAttack();
	
	m_owner.SetTimer( mDuration, false, 'BeginCooldown', self );
}

function PlayVFX()
{
	local TMParticleSystem tmps;

	if( m_owner.m_TMPC.IsClient() )
	{
		tmps = m_owner.m_TMPC.m_ParticleSystemFactory.CreateAttachedToActor(ParticleSystem'TM_HiveLord.VFX_Swarmshift', m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner, m_owner.Location, mDuration);
		tmps.SetScale( 3.0f );
	}
}

function BeginCooldown()
{
	m_owner.SetCollision( true );
	m_owner.bCanBeDamaged = true;
	m_owner.bCanBeKnockedUp = true;
	m_owner.bCanBeKnockedBack = true;
	m_owner.ClearTimer( 'DoAoEDamage', self );

	m_owner.bApplyFogOfWar = true;
	m_owner.GetAttackComponent().mCanAttack = true;

	super.BeginCooldown();
}

simulated function DoAoEDamage()
{
	m_AbilityHelper.DoDamageInRadius( mAoEDamage, mAoERadius, m_owner.Location );
}

DefaultProperties
{
	TEMP_dontStop = true;
	mHasNoAnimation = true;
}
