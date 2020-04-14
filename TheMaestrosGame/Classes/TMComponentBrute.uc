class TMComponentBrute extends TMComponent;

var string notificationMessage;
var TMGameObjectiveHelper gameObjectiveHelper;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_Owner = parent;
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentBrute newcomp;

	newcomp = new() class'TMComponentBrute' (self);
	newcomp.m_owner = newowner;
	newcomp.gameObjectiveHelper = new () class'TMGameObjectiveHelper';
	newcomp.gameObjectiveHelper.Init(newowner);
	newowner.bCanBeKnockedUp = false;
	newowner.bCanBeKnockedBack = false;

	newcomp.gameObjectiveHelper.SpawnFoWRevealer();

	return newcomp;
}

function ReceiveFastEvent(TMFastEvent event)
{
	if(event.commandType == "dead" || event.commandType == class'TMCleanupFE'.const.CLEANUP_COMMAND_TYPE)
	{
		m_Owner.SetTimer(1.0f, false, NameOf(m_Owner.HideMesh));
		gameObjectiveHelper.RemoveFoWRevealer();
	}
	if(event.commandType == "C_Took_Damage")
	{
		gameObjectiveHelper.NotifyIAmHit(event, notificationMessage);
	}
}

DefaultProperties
{
	notificationMessage = "The Dreadbeast is under Attack!";
}
