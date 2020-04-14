/*  TMAbilityTargetPainter
 *  Paints the location where an ability is going to land.
 *  The targetpaint will follow FoW vision rules for the team

	Uses a pawn's ability target mesh
 */
class TMAbilityTargetPainter extends TMFOWObject;


// Would love to have my own static mesh, but UDK requires it to be on a pawn
var(Pawn) ProtectedWrite editconst StaticMeshComponent mTargetPaintMesh;

// Save the owner so we can make sure to keep this reticle hidden when he's dead
var TMPawn mOwner;


simulated function SetupAbilityTargetPainter( TMPawn inOwnerPawn, Vector inLocation, float inAbilityRadius )
{
	mOwner = inOwnerPawn;
	mTMPC = inOwnerPawn.m_TMPC;

	// Don't do anything if server
	if( !mTMPC.IsClient() )
	{
		return;
	}

	mLocation = inLocation;
	mOwnerAllyID = TMPlayerReplicationInfo( inOwnerPawn.OwnerReplicationInfo ).allyId;
	mShouldAlwaysShowTeam = true;

	mTargetPaintMesh = inOwnerPawn.AbilityTargetMesh;

	// Move the mesh to location
	mTargetPaintMesh.SetTranslation( inLocation );
	
	// Scale the mesh
	mTargetPaintMesh.SetScale( class'TMHelper'.static.GetScaleFromRadius( inAbilityRadius ) );
	
	// Set the proper team color
	inOwnerPawn.AbilityTargetMeshMatInst.SetScalarParameterValue('HueShift', inOwnerPawn.GetTeamColorHue().X);

	Update();

	// Only Update on the client
	mTMPC.SetTimer( mUpdateFrequency, true, 'Update', self );
}

simulated function SetHidden( bool inIsHidden )
{
	// ALWAYS hide the target painter if the pawn is now dead
	if( mOwner == None ||
		mOwner.Health <= 0 )
	{
		mTargetPaintMesh.SetHidden(true);
		return;
	}

	mTargetPaintMesh.SetHidden( inIsHidden );
}

// Make sure EVERY ability calls cleanup when it's destroyed
simulated function Cleanup()
{
	mTargetPaintMesh.SetHidden( true );
	mTMPC.ClearTimer( 'Update', self );
}
