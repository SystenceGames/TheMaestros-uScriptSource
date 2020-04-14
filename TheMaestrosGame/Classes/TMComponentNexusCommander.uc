class TMComponentNexusCommander extends TMComponent;


var int mVisionRadius;
var TMFOWRevealActor mRevealActor;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mVisionRadius = json.GetIntValue("visionRadius");
}

simulated function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentNexusCommander newcomp;

	newcomp = new() class'TMComponentNexusCommander'(self);
	newcomp.m_owner = newowner;
	newcomp.mRevealActor = newowner.Spawn( class'TMFOWRevealActorStatic',,, newowner.Location,,, true);
	newcomp.mRevealActor.Setup( newowner.m_allyId, newowner.m_Controller.GetFoWManager(), mVisionRadius, true, true );
	newcomp.mRevealActor.bApplyFogOfWar = true;
	newowner.mShouldIgnoreSelectAll = true;
	newowner.bCanBeKnockedUp = false;
	newowner.bCanBeKnockedBack = false;

	return newcomp;
}
