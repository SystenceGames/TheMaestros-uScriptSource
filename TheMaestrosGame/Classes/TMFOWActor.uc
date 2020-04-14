/*  TMFOWActor
 *  An actor with visibility restricted to its team's FOW vision
 */
class TMFOWActor extends Actor;

var TMPlayerController  m_TMPC;
var int                 m_AllyID;

///// FoW Variables /////
var bool    m_ShouldUseFoW;
var bool    m_ShowTeamThroughFoW;
var float   m_CheckFoWFrequency;


function SetupFoWActor( TMPlayerController inTMPC, int inAllyID )
{
    m_TMPC = inTMPC;
    m_AllyID = inAllyID;

    // Start FoW Checks
    if( m_TMPC.IsClient() )
    {
        // Update the object immediately to ensure proper visibility
        UpdateFoW();

        m_TMPC.SetTimer( m_CheckFoWFrequency, true, 'UpdateFoW', self );
    }
}

function UpdateFoW()
{
    // Only do FoW visibility check on the client
    if( m_ShouldUseFoW )
    {
        // Check for always show my team
        if( m_ShowTeamThroughFoW &&
            m_TMPC.GetTMPRI().allyId == m_AllyID )
        {
            // This object is visible through FoW and is on my team
            SetIsHidden( false );
            return;
        }

        // Check if the object is in FoW
        SetIsHidden( !m_TMPC.GetFoWManager().IsLocationVisible( location ) );
    }
}

event Destroyed()
{
    if( m_ShouldUseFoW && m_TMPC.IsClient() )
    {
        m_TMPC.ClearTimer( 'UpdateFoW', self );
    }
}

// Any class inheriting from TMFOWObject needs to implement their hide functionality
function SetIsHidden( bool inIsHidden ) {}

defaultproperties
{
    m_ShouldUseFoW = true;
    m_ShowTeamThroughFoW = false;
    m_CheckFoWFrequency = 0.1;
}
