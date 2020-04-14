/* TMParticleSystemFactory
	All particle systems created by TMParticleSystemFactory will abide by FoW rules. For custom or
	special TMParticleSystem handling, don't bother trying to use the TMParticleSystemFactory. However
	this factory should handle 99% of our use cases.

	Handles every possible combination of constuctors for TMParticleSystem.
	The goal is to allow 1-line particle system generation for callers.
	This class does all of the ugly creation stuff, so that callers and TMParticleSystem can
	be cleaner.

	UPDATE 5/6/18:
	Now that we have to pass allyId and teamColorId to each PS, we might want to have 2-line
	creational calling. 1-line creations of these particle systems has too many parameters.
 */
class TMParticleSystemFactory extends Object;


var TMPlayerController mTMPC;
var TMParticleSystemTeamColorChecker mPSTeamColorChecker;


function Setup(TMPlayerController inTMPC)
{
	mTMPC = inTMPC;
	mPSTeamColorChecker = new class'TMParticleSystemTeamColorChecker'();
	mPSTeamColorChecker.Setup();
}


private function TMParticleSystem FactoryCreate(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inLocation, float inDuration, Actor inAttachActor = none, optional Rotator inRotation)
{
	local TMParticleSystem tmps;

	tmps = new class'TMParticleSystem'();

	if( !mTMPC.ShouldSpawnVFX() )
	{
		// If we're on the server, just give him an empty TMParticleSystem object. By itself the object does no work and has a minimal memory footprint
		mTMPC.SetTimer(inDuration, false, 'Destroy', tmps); 	// Destroy the PS after it's duration
		tmps.mTMPC = mTMPC;
		return tmps;
	}

	tmps.SetupParticleSystem(inPS, mTMPC, inAllyId, inTeamColorIndex, mPSTeamColorChecker, inLocation, inDuration, inAttachActor, inRotation);
	tmps.SetAlwaysShowTeam( true );
	return tmps;
}


function TMParticleSystem Create(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inLocation, float inDuration = 1)
{
	return FactoryCreate(inPS, inAllyId, inTeamColorIndex, inLocation, inDuration);
}

function TMParticleSystem CreateWithScale(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inLocation, float inScale, float inDuration = 1)
{
	local TMParticleSystem tmps;

	tmps = FactoryCreate(inPS, inAllyId, inTeamColorIndex, inLocation, inDuration);
	tmps.SetScale( inScale );
	return tmps;
}

function TMParticleSystem CreateWithRotation(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inLocation, Rotator inRotation, float inDuration = 1)
{
	local TMParticleSystem tmps;

	tmps = FactoryCreate(inPS, inAllyId, inTeamColorIndex, inLocation, inDuration);
	tmps.SetRotation( inRotation );
	return tmps;
}

function TMParticleSystem CreateWithRotationAndScale(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inLocation, Rotator inRotation, float inScale, float inDuration = 1)
{
	local TMParticleSystem tmps;

	tmps = FactoryCreate(inPS, inAllyId, inTeamColorIndex, inLocation, inDuration);
	tmps.SetRotation( inRotation );
	tmps.SetScale( inScale );
	return tmps;
}

function TMParticleSystem CreateBeam(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inStartLocation, Vector inEndLocation, int inNumEndPoints, float inDuration = 1)
{
	return CreateBeamWithScale(inPS, inAllyId, inTeamColorIndex, inStartLocation, inEndLocation, inNumEndPoints, 1, inDuration);
}

function TMParticleSystem CreateBeamWithScale(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Vector inStartLocation, Vector inEndLocation, int inNumEndPoints, float inScale, float inDuration = 1)
{
	local TMParticleSystem tmps;
	local int i;

	tmps = FactoryCreate(inPS, inAllyId, inTeamColorIndex, inStartLocation, inDuration);

	for( i = 0; i < inNumEndPoints; i++ )
	{
		tmps.mPSC.SetBeamEndPoint(i, inEndLocation);
	}

	tmps.SetScale( inScale );
	return tmps;
}

function TMParticleSystem CreateAttachedToActor(ParticleSystem inPS, int inAllyId, int inTeamColorIndex, Actor inAttachActor, Vector inLocation, float inDuration = 1, optional Rotator inRotation)
{
	return FactoryCreate(inPS, inAllyId, inTeamColorIndex, inLocation, inDuration, inAttachActor, inRotation);
}

/* CreateClientside
	Creates a ParticleSystem that will only be on this client. Does not care about FoW.
	NOTE: does NOT create a TMParticleSystem, but a vanilla ParticleSystem
*/
function CreateClientside(ParticleSystem inPS, Vector inLocation)
{
	if( mTMPC.ShouldSpawnVFX() )
	{
		mTMPC.WorldInfo.MyEmitterPool.SpawnEmitter( inPS, inLocation );
	}
}
