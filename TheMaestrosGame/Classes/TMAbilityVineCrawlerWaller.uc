class TMAbilityVineCrawlerWaller extends TMAbility;

const SPAWNED_WALL = "C_SPAWNED_WALL";
const HIDDEN_MINIMAP_Y = 13245;

var TMPawn mWall;
var Vector mHiddenLocation;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent(json, parent);

	// Set the hidden location to be south of the map
	mHiddenLocation.X = 0;
	mHiddenLocation.Y = HIDDEN_MINIMAP_Y;
	mHiddenLocation.Z = 0;
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityVineCrawlerWaller newcomp;
	newcomp= new () class'TMAbilityVineCrawlerWaller'(self);
	newcomp.m_owner=newowner;
	newcomp.mHiddenLocation = mHiddenLocation;
	newcomp.SetupWall();
	return newcomp;
}

function SetupWall()
{
	if( m_owner.IsAuthority() )
	{
		mWall = m_owner.m_TMPC.m_tmGameInfo.RequestUnit( "VineCrawler_Wall", TMPlayerReplicationInfo( m_owner.OwnerReplicationInfo ), mHiddenLocation, false, mHiddenLocation, m_owner, true );
		mWall.SetPhysics( PHYS_None );
		HideWall();
	}
}

function HideWall()
{
	if( mWall != none )
	{
		mWall.SetHidden( true );
		mWall.SetLocation( mHiddenLocation );
	}
}

function StartAbility()
{
	RotateToTarget();
	super.StartAbility();
}

function CastAbility()
{
	local Rotator desiredRotation;
	local TMAbilityFE fe;
	
	desiredRotation = Rotator(m_TargetLocation - m_owner.Location);
	desiredRotation.Pitch = 0;
	desiredRotation.Roll = 0;

	// Spawn the wall
	if ( mWall != none )
	{
		// Set the vinecrawler wall to be high enough
		m_TargetLocation.Z += 100;

		mWall.SetCollision( false, false );
		mWall.bCollideWorld = false;
		mWall.SetLocation( m_TargetLocation );
		mWall.SetRotation( desiredRotation );
		mWall.SetHidden( true );    // make it hidden, FoW will handle its visibility
		mWall.SetCollision( true, true );

		fe = new () class'TMAbilityFE';
		fe.commandType = SPAWNED_WALL;
		fe.pawnId = mWall.pawnId;
		fe.abilityLocation = m_TargetLocation;
		mWall.SendFastEvent( fe );
	}
	else
	{
		`log( "ERROR: VineCrawler Wall hasn't been initialized!!!", true, 'TMAbilityVineCrawlerWaller' );
	}

	// Get a new wall for next time we cast
	SetupWall();

	super.CastAbility();
}
