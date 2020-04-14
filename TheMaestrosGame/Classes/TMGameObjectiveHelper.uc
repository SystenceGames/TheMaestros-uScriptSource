class TMGameObjectiveHelper extends Object;

const TIME_SECONDS_BETWEEN_NEXUS_ATTACK_NOTIFICATION = 20.0f;

var WorldInfo mWorldInfo;
var float notificationDuration;
var array<float> timesLastAttackedByAllyIndex;
var TMPawn mOwner;
var const int INDEX_FOR_SPECTATORS;
var const int GAME_OBJECTIVE_ALLY_ID;
var TMFOWRevealActor revealActor;

function Init(TMPawn owner)
{
	mOwner = owner;
	mWorldInfo = owner.WorldInfo;

	if(owner.WorldInfo.NetMode != NM_Client)
	{
		initializeTimesLastAttackedByAllyIndex();
	}
}

function int getIndexForAllyId(int allyId)
{
	if (class'TMGameInfo'.const.SPECTATOR_ALLY_ID == allyId)
	{
		return INDEX_FOR_SPECTATORS;
	}
	else
	{
		return allyId;
	}
}

function RemoveFoWRevealer()
{
	if (revealActor != None && revealActor.bDeleteMe == false)
	{
		revealActor.bApplyFogOfWar = false;
		revealActor.Destroy();
		revealActor = None;
	}
}

function TMFoWRevealActor SpawnFoWRevealer()
{
	revealActor = mOwner.Spawn( class'TMFOWRevealActorStatic',,, mOwner.Location,,, true); // this will spawn on server AND each client.  This may be ok for now.
	revealActor.Setup( GAME_OBJECTIVE_ALLY_ID, mOwner.m_Controller.GetFoWManager(), 4, true, true );
	revealActor.bApplyFogOfWar = true;

	return revealActor;
}

function NotifyIAmHit(TMFastEvent inEvent, string notificationMessage)
{
	local TMPlayerController tempPC;

	// Notify each player that isn't on the attacker's team
	foreach mWorldInfo.AllControllers(class'TMPlayerController', tempPC)
	{
		if( tempPC.m_allyId != inEvent.int1 && mWorldInfo.TimeSeconds - timesLastAttackedByAllyIndex[getIndexForAllyId(tempPC.m_allyId)] > TIME_SECONDS_BETWEEN_NEXUS_ATTACK_NOTIFICATION )
		{
			tempPC.ClientPlayNotification(notificationMessage, notificationDuration * 1000 );
			tempPC.ClientSpawnPing(tempPC.m_allyId, mOwner.Location, class'TMMapPing'.const.LookType);
			timesLastAttackedByAllyIndex[getIndexForAllyId(tempPC.m_allyId)] = mWorldInfo.TimeSeconds;
		}
	}
}

function initializeTimesLastAttackedByAllyIndex()
{
	local TMGameInfo lGameInfo;
	local int maxLength;
	local TMAllyInfo tempAllyInfo;
	local int i;

	lGameInfo = TMGameInfo(mWorldInfo.Game);

	foreach lGameInfo.allies(tempAllyInfo)
	{
		if (tempAllyInfo.allyIndex + 1 > maxLength)
		{
			maxLength = tempAllyInfo.allyIndex + 1;
		}
	}

	timesLastAttackedByAllyIndex.Length = maxLength + 1; // we want to always be able to index into this array with their allyId
	
	for (i = 0; i < timesLastAttackedByAllyIndex.Length; i++)
	{
		timesLastAttackedByAllyIndex[i] = -9000000.0f; // arbitrarily high, to make sure they always notify on the first time
	}
}

DefaultProperties
{
	notificationDuration = 2;
	INDEX_FOR_SPECTATORS = 2;
	GAME_OBJECTIVE_ALLY_ID = -2;
}
