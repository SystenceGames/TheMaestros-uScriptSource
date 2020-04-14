class TMAbilityDisruptorTrail extends TMAbility;

var float m_fFastMoveSpeed;
var float m_fDuration;
var int m_iPoisonRadius;
var float m_fPoisonDuration;
var float mPoisonCloudUpdateInterval;

var vector m_vPreviousPoisonSpawnLocation;
var int m_iPoisonSpawnDistance;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_fFastMoveSpeed = json.GetFloatValue("moveSpeed");
	m_fDuration = json.GetFloatValue("duration")/100;
	m_iPoisonRadius = json.GetIntValue("poisonRadius");     // NOTE: This is actually set in default properties for TMDisruptorPoisonCloud (can use "show collision" to see what it uses)
	m_iPoisonRadius = 100;  // Use same value as TMDisruptorPoisonCloud::DefaultProperties collision radius
	m_fPoisonDuration = json.GetIntValue("cloudDuration");
	mPoisonCloudUpdateInterval = json.GetFloatValue( "poisonCloudUpdateInterval" );
	m_iPoisonSpawnDistance = m_iPoisonRadius;   // this will allow poison clouds to overlap, but we're ok with this
	mIsInstantCast = true;
	super.SetUpComponent(json, parent);
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMAbilityDisruptorTrail newcomp;
	newcomp= new () class'TMAbilityDisruptorTrail'(self);
	newcomp.m_owner=newowner;
	newcomp.mIsInstantCast = true;
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
	
	m_owner.SetTimer(m_fDuration, false, 'BeginCooldown', self);
}

function BeginCooldown()
{
	// Update my current move location since it probably changed since casting


	// Reset my move speed to default
	m_owner.GroundSpeed = m_owner.m_Unit.m_fMoveSpeed;
	
	super.BeginCooldown();
}

function UpdateComponent(float dt)
{
	if (m_AbilityState == AS_CASTING)
	{
		// FORCE THE MOVE SPEED TO STAY FAST
		m_owner.GroundSpeed = m_fFastMoveSpeed;

		Check_For_Poison_Spawn();
	}

	super.UpdateComponent(dt);
}

function Check_For_Poison_Spawn()
{
	local TMDisruptorPoisonCloud poison;

	if (!IsInRange(m_vPreviousPoisonSpawnLocation, m_owner.Location, m_iPoisonSpawnDistance))
	{
		m_vPreviousPoisonSpawnLocation = m_owner.Location;
		poison = m_owner.Spawn(class'TMDisruptorPoisonCloud',,, m_owner.Location);
		poison.InitPoisonCloud( m_owner, m_iPoisonRadius, m_fPoisonDuration, mPoisonCloudUpdateInterval );
	}
}

DefaultProperties
{
	TEMP_dontStop = true;
	mHasNoAnimation = true;
}
