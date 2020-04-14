class TMComponentWormHole extends TMComponent;


var TMPawn  mOtherWormHole;
var int     mRange;
var float   mDuration;


function SetupWormHole( TMPawn inOwner, TMPawn inOtherWormHole, int inRange, float inDuration )
{
	m_owner = inOwner;
	mOtherWormHole = inOtherWormHole;
	mRange = inRange;
	mDuration = inDuration;
}

simulated function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentWormHole newcomp;
	newcomp = new() class'TMComponentWormHole' (self);
	newcomp.m_owner = newowner;
	return newcomp;
}

function UpdateComponent( float dt )
{
	super.UpdateComponent( dt );

	/* for each team actor in range */
		/* if the pawn has a destination within range of my position */
			/* teleport to other worm hole */
}

/* Teleports a pawn to the other wormhole */
function TeleportPawn( TMPawn inPawn )
{
	if ( mOtherWormHole == none || mOtherWormHole.Health <= 0 )
	{
		return;
	}
	
	// For now, just insta jump the pawn. Can do something fancier later
	inPawn.SetLocation( mOtherWormHole.Location );
}

DefaultProperties
{
}
