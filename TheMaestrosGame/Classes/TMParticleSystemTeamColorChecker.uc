/* TMParticleSystemTeamColorChecker
	This is a helper class used by TMParticleSystem to check which ParticleSystems support
	team coloring. Any ParticleSystems which suppport parameter coloring or StaticMesh coloring
	should be added to their respective arrays.

	When a TMParticleSystem is created these lists are checked to see if the ParticleSystem needs
	to be colored.

	NOTE: A ParticleSystem is allowed to have both parameter team coloring AND StaticMesh team
		coloring. It's okay to have the same ParticleSystem in both arrays.
*/
class TMParticleSystemTeamColorChecker extends Object;


var private array<ParticleSystem> mTeamColoredPSList;
var private array<ParticleSystem> mTeamColoredStaticMeshPSList;


// Setup is called by TMParticleSystemFactory when it's created
function Setup()
{
	// Fill up both particle system arrays
	AssignTeamColoredParticleSystems();
	AssignTeamColoredStaticMeshParticleSystems();
}

private function AssignTeamColoredParticleSystems()
{
	mTeamColoredPSList.AddItem(ParticleSystem'tm_tinkermeister.VFX_TimeStop.TimeStop_CHARGE');
	mTeamColoredPSList.AddItem(ParticleSystem'tm_tinkermeister.VFX_TimeStop.TimeStop_MAIN');
	mTeamColoredPSList.AddItem(ParticleSystem'TM_HiveLord.VFX_Swarmshift');
	mTeamColoredPSList.AddItem(ParticleSystem'TM_Cocoon.RBQ_SpecAttack_PS');
	mTeamColoredPSList.AddItem(ParticleSystem'transformpoint.Particles.Transform_Main_PS');
	mTeamColoredPSList.AddItem(ParticleSystem'VFX_Death.Death_PS');
	mTeamColoredPSList.AddItem(ParticleSystem'VFX_Bloodlust.Bloodlust_PS');
}

private function AssignTeamColoredStaticMeshParticleSystems()
{
	mTeamColoredStaticMeshPSList.AddItem(ParticleSystem'TM_Cocoon.RBQ_SpecAttack_PS');
}


function bool DoesSupportTeamColoring(ParticleSystem inPS)
{
	return (mTeamColoredPSList.Find(inPS) != INDEX_NONE);
}

function bool DoesSupportStaticMeshTeamColoring(ParticleSystem inPS)
{
	return (mTeamColoredStaticMeshPSList.Find(inPS) != INDEX_NONE);
}
