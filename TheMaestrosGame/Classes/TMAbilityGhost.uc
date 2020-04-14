class TMAbilityGhost extends TMAbility;

var bool 	mIsGhosting;
var float   mMoveSpeedPercentage;
var float   mDuration;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);

	mMoveSpeedPercentage = json.GetFloatValue( "percentSpeedIncrease" )/100;
	mDuration = json.GetFloatValue( "duration" );
	m_sAbilityName = "Ghost"; 	// TODO: use ability name read from file
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMAbilityGhost newcomp;
	newcomp= new () class'TMAbilityGhost'(self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function Cleanup()
{
	if( mIsGhosting )
	{
		mIsGhosting = false;
		AllActorsClearTeam();
	}
	super.Cleanup();
	m_owner.ClearAllTimers( self );
}

function HandleAbility()
{
	m_TargetLocation = m_owner.Location;

	super.HandleAbility();
}


function CastAbility()
{
	mIsGhosting = true;
	SpeedupTeam();

	m_owner.SetTimer( mDuration, false, 'StopGhost', self );
	super.CastAbility();
}

function SpeedupTeam()
{
	local TMPawn            tempPawn;
	local array< TMPawn >   pawnList;

	pawnList = m_owner.m_TMPC.GetTMPawnList();

	foreach pawnList( tempPawn )
	{
		if ( tempPawn.OwnerReplicationInfo.PlayerID == m_owner.OwnerReplicationInfo.PlayerID )
		{
			tempPawn.mIsGhost = true;
			tempPawn.GroundSpeed = mMoveSpeedPercentage * tempPawn.m_Unit.m_fMoveSpeed;
		}
	}
}

function StopGhost()
{
	mIsGhosting = false;
	ClearTeam();
}

function ClearTeam()
{
	local TMPawn            tempPawn;
	local array< TMPawn >   pawnList;

	pawnList = m_owner.m_TMPC.GetTMPawnList();

	foreach pawnList( tempPawn )
	{
		if( m_owner.HasSameOwner(tempPawn) )
		{
			tempPawn.mIsGhost = false;
			tempPawn.GroundSpeed = tempPawn.m_Unit.m_fMoveSpeed;
			tempPawn.SetHighlightColor(1.0f,1.0f,1.0f,1.0f); // We need to set the highlight color back to white. See writeup at bottom of this file
		}
	}
}

function AllActorsClearTeam()
{
	local TMPawn            tempPawn;

	foreach m_owner.AllActors( class'TMPawn', tempPawn )
	{
		if ( tempPawn.OwnerReplicationInfo.PlayerID == m_owner.OwnerReplicationInfo.PlayerID )
		{
 			tempPawn.mIsGhost = false;
			tempPawn.GroundSpeed = tempPawn.m_Unit.m_fMoveSpeed;
			tempPawn.SetHighlightColor(1.0f,1.0f,1.0f,1.0f);
		}
	}
}

function UpdateComponent(float dt)
{
	if( mIsGhosting )
	{
		SpeedupTeam();
	}

	super.UpdateComponent(dt);
}

DefaultProperties
{
	mIsPlayerAbility = true;
	mIsInstantCast = true;
	TEMP_dontStop = true;
	mHasNoAnimation = true;
}

/* Why we reset the highlight color of a pawn to white (2/7/18)
	Right now we have multiple pawn states that rely on the mesh's highlight color
	Ghost is one of these features, and it turns the highlight color blue in the pawn.
		(other examples include making the pawn highlight white in a bush, or red when damaged)
	Our issue is when the ghost ability ends, the highlight mesh remains blue.
	In the future we could add some sort of stateful coloring system, but for now
	I'll just leave this comment to explain why we are messing with the highlight color

	Please let me know if you have any questions or concerns
	-Taylor
*/
