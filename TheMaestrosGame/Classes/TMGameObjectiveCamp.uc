class TMGameObjectiveCamp extends TMNeutralCamp
	placeable
	ClassGroup(Common)
	hidecategories(Collision);

var bool mFirstSpawn;
var const string GAME_OBJECTIVE_SPAWN_NOTIFICATION;

function SpawnUnits()
{
	local TMPlayerController tempTMPC;

	super.SpawnUnits();

	if (ShouldSendSpawnNotification())
	{
		foreach AllActors(class'TMPlayerController', tempTMPC)
		{
			tempTMPC.ClientPlayNotification(GAME_OBJECTIVE_SPAWN_NOTIFICATION, 2000);
		}
	}
	mFirstSpawn = false;
}

function bool ShouldSendSpawnNotification()
{
	if ( m_spawnDelay > 0 || !mFirstSpawn )
	{
		return true;
	}

	return false;
}

DefaultProperties
{
	mFirstSpawn=true
	GAME_OBJECTIVE_SPAWN_NOTIFICATION="A Game Objective Has Spawned";
}
