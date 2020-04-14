/* TMAbilityObject
	An Ability Object is an object that is placed by an ability. AbilityObjects have a location and owner.
	It will do something when Start() is called.
*/
class TMAbilityObject extends Object implements(TMIAbilityObject);

var TMAbilityHelper 	m_AbilityHelper;
var TMPlayerController  m_TMPC;
var int 				m_AllyID;
var int   				m_PlayerID;
var int 				m_TeamColorIndex;
var Vector  			m_Location;

/* Create()
	Child classes should create their own static create functions for abilities to use.
	This is only an example implementation of what the Create function should look like.
	
static function TMAbilityObject Create( TMPlayerController inTMPC, int inAllyID, int inPlayerID, Vector inLocation )
{
	local TMAbilityObject object;
	object = new class'TMAbilityObject'();
	object.Setup( inTMPC, inAllyID, inPlayerID, inLocation );
	return object;
}*/

/* Setup()
	Helper function for AbilityObjects to set these standard variables.
*/
function Setup( TMAbilityHelper inAbilityHelper, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, Vector inLocation, int inRadius = 100 )
{
	m_AbilityHelper = inAbilityHelper;
	m_TMPC = inTMPC;
	m_AllyID = inAllyID;
	m_PlayerID = inPlayerID;
	m_TeamColorIndex = inTeamColorIndex;
	m_Location = inLocation;
}

/* Start()
	Child classes need to implement this function.
*/
function Start()
{
	m_TMPC.AddAbilityObject( self );
}

/* Stop()
	Cleans up the ability object and stops all running logic
*/
function Stop()
{
	m_TMPC.RemoveAbilityObject( self );
}

function int GetAllyID()
{
	return m_AllyID;
}

function int GetTeamColorIndex()
{
	return m_TeamColorIndex;
}
