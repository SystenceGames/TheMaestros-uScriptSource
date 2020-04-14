/* TMParticleSystem
	A particle system that handles FoW and team vision

	Use TMParticleSystemFactory to create these. If you want to create these without using
	the factory, ask Taylor first
 */
class TMParticleSystem extends TMFOWObject;


var ParticleSystemComponent mPSC;


function SetupParticleSystem( ParticleSystem inParticleSystem,
								TMPlayerController inTMPC, 	// TMPC isn't used for ownership, it just spawns the PS
								int inOwnerAllyId,
								int inTeamColorIndex,
								TMParticleSystemTeamColorChecker inColorChecker,
								Vector inLocation,
								float duration = 10,
								optional Actor inAttachToActor = none,
								optional Rotator inRotation )
{
	mTMPC = inTMPC;
	mLocation = inLocation;
	mOwnerAllyID = inOwnerAllyID;

	// Add myself to the list of all particle systems
	mTMPC.mParticleSystemList.AddItem( self );

	if( mTMPC.ShouldSpawnVFX() )
	{
		mPSC = mTMPC.WorldInfo.MyEmitterPool.SpawnEmitter( inParticleSystem, inLocation, inRotation, inAttachToActor );

		if( inColorChecker.DoesSupportTeamColoring(inParticleSystem) )
		{
			AssignTeamColorParameter( inTeamColorIndex );
		}
		if( inColorChecker.DoesSupportStaticMeshTeamColoring(inParticleSystem) )
		{
			AssignTeamColorToStaticMeshes( inTeamColorIndex );
		}

		Update();
		mTMPC.SetTimer( mUpdateFrequency, true, 'Update', self );
	}

	mTMPC.SetTimer( duration, false, 'Destroy', self );
}

function SetAlwaysShowTeam( bool inAlwaysShowTeam )
{
	mShouldAlwaysShowTeam = inAlwaysShowTeam;
}

function SetRotation( Rotator inRotation )
{
	if( mTMPC.ShouldSpawnVFX() )
	{
		mPSC.SetRotation( inRotation );
	}
}

function SetScale( float inScale )
{
	if( mTMPC.ShouldSpawnVFX() )
	{
		mPSC.SetScale( inScale );
	}
}

function SetHidden( bool inIsHidden )
{
	if( mTMPC.ShouldSpawnVFX() )
	{
		mPSC.SetHidden( inIsHidden );
	}
}

private function AssignTeamColorParameter( int inTeamColorIndex )
{
	local Vector vectTeamColor;
	local Color teamColor;

	teamColor = class'TMColorPalette'.static.GetTeamColorRGB( mOwnerAllyID, inTeamColorIndex );
	vectTeamColor.x = teamColor.r/255.0f;
	vectTeamColor.y = teamColor.g/255.0f;
	vectTeamColor.z = teamColor.b/255.0f;

	mPSC.SetVectorParameter('Color', vectTeamColor );
}

private function AssignTeamColorToStaticMeshes( int inTeamColorIndex )
{
	local StaticMeshComponent smc;
	local Vector HSV;
	local MaterialInstanceConstant MatInst;
	
	// Get team color
	HSV = class'TMColorPalette'.static.GetTeamColorHSV( mOwnerAllyID, inTeamColorIndex );

	foreach mPSC.SMComponents(smc)
	{
		MatInst = new(None) Class'MaterialInstanceConstant';
		MatInst.SetParent(smc.GetMaterial(0));
		MatInst.SetScalarParameterValue('HueShift', HSV.X);
		MatInst.SetScalarParameterValue('SaturationScale', HSV.Y);
		MatInst.SetScalarParameterValue('ValueScale', HSV.Z);

		smc.SetMaterial(0, MatInst);
	}
}

function Destroy()
{
	mTMPC.ClearTimer( 'Update', self );
	mTMPC.ClearTimer( 'Destroy', self );
	mTMPC.mParticleSystemList.RemoveItem( self );

	if( mTMPC.ShouldSpawnVFX() )
	{
		SetHidden( true );
		mPSC.DeactivateSystem();
		mPSC.KillParticlesForced();
	}
}
