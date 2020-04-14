/*  TMFOWObject
 *  An object with visibility restricted to its team's FOW vision
 */
class TMFOWObject extends Object;

var TMPlayerController  mTMPC;
var int                 mOwnerAllyID;   // ally ID for the owner of this object
var Vector              mLocation;

var bool                mShouldAlwaysShowTeam; // should we always show this object through FoW for our team?

var float               mUpdateFrequency;


function SetupFOWObject( TMPlayerController inTMPC, Vector inLocation, int inOwnerAllyID, optional bool inShouldAlwaysShowTeam )
{
	mTMPC = inTMPC;
	mLocation = inLocation;
	mOwnerAllyID = inOwnerAllyID;

	// Update the object immediately to ensure proper visibility
	Update();
	mTMPC.SetTimer( mUpdateFrequency, true, 'Update', self );
}

function Update()
{
	// Only do FoW visibility check on the client
	if( mTMPC.IsClient() )
	{
		// Check for always show my team
		if( mShouldAlwaysShowTeam &&
			mTMPC.GetTMPRI().allyId == mOwnerAllyID )
		{
			// This object is visible through FoW and is on my team
			SetHidden( false );
			return;
		}

		// Check if the object is in FoW
		SetHidden( !mTMPC.GetFoWManager().IsLocationVisible( mLocation ) );
	}
}

// Any class inheriting from TMFOWObject needs to implement their hide functionality
function SetHidden( bool inIsHidden ) {}

defaultproperties
{
	mUpdateFrequency = 0.1f;
}
