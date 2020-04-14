/* TMAbilityObject
	An Ability Object is an object that is placed by an ability. AbilityObjects have a location and owner.
	It will do something when Start() is called.
*/
class TMAbilityActor extends TMFOWActor implements(TMIAbilityObject);

var TMAbilityHelper m_AbilityHelper;
var int 	m_PlayerID;
var int 	m_TeamColorIndex;


/* Setup()
	Helper function for AbilityActors to set these standard variables.
*/
function Setup( TMAbilityHelper inAbilityHelper, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, int inRadius = 100 )
{
	m_AbilityHelper = inAbilityHelper;
	m_PlayerID = inPlayerID;
	m_TeamColorIndex = inTeamColorIndex;
	
	super.SetupFoWActor( inTMPC, inAllyID );
}

/* Start()
	Removes the target reticle.
	Child classes need to implement this function to begin their behavior
*/
function Start()
{
	m_TMPC.AddAbilityObject( self );
}

function Stop()
{
	self.Destroy();
}

event Destroyed()
{
	m_TMPC.RemoveAbilityObject( self );
}

/* SetHidden()
	AbilityActors need to implement SetHidden() for FoW to work.
*/
function SetIsHidden( bool inIsHidden )
{
	// Hide the actor
	self.SetHidden( inIsHidden );
}

function int GetAllyID()
{
	return m_AllyID;
}

function int GetTeamColorIndex()
{
	return m_TeamColorIndex;
}
