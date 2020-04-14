class TMAbilityRosieTimeBubble extends TMAbility;

var int 	m_Radius;
var float 	m_Duration;
var float 	m_Delay;
var float 	m_CheckFrequency;


function SetUpComponent( JsonObject inJSON, TMPawn inParent )
{
	m_Radius = 		inJSON.GetIntValue("radius");
	m_Duration = 	inJSON.GetFloatValue( "duration" );
	m_Delay = 		inJSON.GetFloatValue( "delay" );

	super.SetUpComponent( inJSON, inParent );
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityRosieTimeBubble newcomp;
	newcomp= new () class'TMAbilityRosieTimeBubble'(self);
	newcomp.m_owner=newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function CastAbility()
{
	// Create and start the time bubble
	local TMTimeBubble bubble;
	m_TargetLocation = m_owner.Location;//GetGroundedLocation();
	bubble = class'TMTimeBubble'.static.Create( m_AbilityHelper, m_owner.m_TMPC, m_owner.m_allyId, m_owner.m_owningPlayerId, m_owner.GetTeamColorIndex(), m_TargetLocation, m_Duration, m_Radius, m_CheckFrequency, m_Delay, m_owner );
	bubble.Start();

	super.CastAbility();
}

DefaultProperties
{
	m_CheckFrequency = 0.1;

	mIsInstantCast = true;
	mHasNoAnimation = true;
	TEMP_dontStop = true;
}
