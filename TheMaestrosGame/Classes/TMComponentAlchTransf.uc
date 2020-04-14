/* This component handles "potion farming" behavior
 * for the commander, as well as behavior for units
 * which the commander "casts" a potion on. */

class TMComponentAlchTransf extends TMComponent;

enum EAlchTransfState {
	NOSTATE, TRANSIT, FARMING
};

var EAlchTransfState mTransformState;
var bool bIsCommander; // Need a way to determine if m_Owner is a commander (check against m_TMPC's Pawn?) // Dru TODO: Is this used anywhere?
var TMTransformer mActiveTransformer;
var vector mFarmingLocation;

var bool m_IsTransforming;

function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_Owner = parent;
	mTransformState = NOSTATE;
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentAlchTransf newcomp;
	newcomp = new() class'TMComponentAlchTransf' (self);
	newcomp.m_owner = newowner;
	return newcomp;
}

function ReceiveFastEvent(TMFastEvent event)
{
	local TMAlchTransFE transEvent;

	if(m_Owner.m_TMPC != none)
	{
		if(m_Owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer && m_Owner.m_TMPC.WorldInfo.NetMode != NM_ListenServer && m_Owner.m_TMPC.WorldInfo.NetMode != NM_Standalone)
		{
			return; // we only want transformation logic running on the server!
		}
		
		if(event.commandType == "C_AlchTrans")
		{
			transEvent = class'TMAlchTransFE'.static.fromFastEvent(event);
			
			if(transEvent.TransEventType == "ORDER")
			{
				HandleOrder(transEvent);
			}
			else if(transEvent.TransEventType == "POTIONFARMED")
			{
				HandlePotionFarmed(transEvent.PotionType);
			}
		}
		// For cancelling
		else if(event.commandType == "C_Move" || event.commandType == "C_AI_Move" || event.commandType == "C_Attack" || event.commandType == "C_AttackMove")
		{
			if(mTransformState != NOSTATE)
			{
				HandleCancel();
			}
		}
	}
}

function UpdateComponent(float dt)
{
	local float distance;

	if(mTransformState == TRANSIT)
	{
		// Check if the farming location has been reached
		distance = VSize(m_Owner.Location - mFarmingLocation);
		
		if(distance <= 250.f)
		{
			ReachedFarmPoint();
		}
	}

}

function HandleOrder(TMAlchTransFE fe)
{
	local TMTransformer transformer;
	local vector vec;
	local array<UDKRTSPawn> unitsForCommand;

	if(m_Owner != m_Owner.m_TMPC.Pawn)
	{
		`log("Potion farming order issued to non-Commander pawn.", true, 'Graham');
		return;
	}

	if(mActiveTransformer != None && fe.TransformerID != mActiveTransformer.TransformerId && mTransformState != NOSTATE)
	{
		HandleCancel();
	}

	// Get the appropriate transformer
	foreach m_Owner.AllActors(class'TMTransformer', transformer)
	{
		if(fe.TransformerID == transformer.TransformerId)
		{
			mActiveTransformer = transformer;
			break;
		}
	}

	m_IsTransforming = true;

	vec = Normal(m_Owner.Location - mActiveTransformer.Location);
	vec.Z = 0;
	mFarmingLocation = (vec * 275) + mActiveTransformer.Location;

	unitsForCommand.AddItem(m_Owner);
	m_Owner.DoMoveCommand(mFarmingLocation, true, unitsForCommand);
	// GGH NOTE: Likely problem area (w.r.t. cancelling)
	mTransformState = TRANSIT;

	
}

function ReachedFarmPoint()
{
	mTransformState = FARMING;

	// Enqueue on the transformer
	mActiveTransformer.AddToFarmingQueue(m_Owner);
}

function HandlePotionFarmed(string unitType)
{
	
}

function HandleCancel()
{   
	// Dequeue from the transformer (if appropriate)
	if(mTransformState == FARMING)
	{
		mActiveTransformer.RemoveFromFarmingQueue(m_Owner);
	}

	m_IsTransforming = false;
	mTransformState = NOSTATE;
}   


DefaultProperties
{
	m_IsTransforming = false;
}


// GGH TODO: handle case where commander dies while farming