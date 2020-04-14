class TMTransformer extends UDKRTSTransformer
	placeable;

// Configure these in the editor
var() string UnitOneType;
var() string UnitTwoType;
var() int UnitOneCount;
var() int UnitTwoCount;
var() float TransformationTime; // in seconds
var() string PotionType;

var StaticMeshComponent m_TransformerMesh;
var StaticMeshComponent m_UnitOcclusionMesh;
var MaterialInstanceConstant OccludedMatInst;
var int CurrentPlayerId;
var bool SuccessfulTransform;
var TMTransformerCollider m_Collider;
var ParticleSystem m_PotionProjEffect;

var TMTransformerIcon m_icon;

var TMPawn m_CachedCommander; // Used to make sure the player's commander is still alive
var int m_TransformingPlayerAllyId;

enum ETransformerState {
	NOTACTIVE, ACTIVE, TRANSFORMING
};

enum EPotionFarmingState {
	NOTACTIVE, ACTIVE
};

var EPotionFarmingState mFarmingState;

var int mReadyCount;
var int mActiveType;
var TMPlayerReplicationInfo mRepInfo;
var ETransformerState mTransformerState;
var array<TMPawn> mTypeOneQueue;
var array<TMPawn> mTypeTwoQueue;
var array<TMPawn> mActiveQueue;
var array<TMPawn> mArrivedPawns;
var TMRallyPoint mRallyPoint;
var array<TMPawn> mFarmingQueue; // Commanders queued to farm potions
var TMPawn mFarmer;

var int TransformerId;
var bool showingTooltip;
var bool highlighted;

var TMPawn mCurrentTower; 	// used only for nexus commanders mode


/* returns true if we currently have a tower build on the transform point */
function bool HaveTower()
{
	return class'UDKRTSPawn'.static.IsValidPawn(mCurrentTower);
}

replication
{
	if(bNetInitial)
		UnitOneType, UnitTwoType;
}

function AddPawnToQueue(TMPawn pawn)
{
	if(pawn.m_UnitType == UnitOneType)
	{
		if(mTypeOneQueue.Find(pawn) == INDEX_NONE)
		{
			mTypeOneQueue.AddItem(pawn);
		}
	}
	else if(pawn.m_UnitType == UnitTwoType)
	{
		if(mTypeOneQueue.Find(pawn) == INDEX_NONE)
		{
			mTypeTwoQueue.AddItem(pawn);
		}
	}

	if(mTransformerState == NOTACTIVE)
	{
		CheckIfQueuesAreFull();
	}
	
	// if the pawn isn't a valid unit type, it is ignored.
}

function RemovePawnFromQueue(TMPawn pawn)
{
	if(pawn.m_UnitType == UnitOneType)
	{
		mTypeOneQueue.RemoveItem(pawn);
	}
	else if(pawn.m_UnitType == UnitTwoType)
	{
		mTypeTwoQueue.RemoveItem(pawn);
	}
}

function CheckIfQueuesAreFull()
{
	// if any player has enough units for the transformation, 
	// set CurrentPlayer and call GatherQueuedUnits()

	// Don't do our transformation if there is a tower here
	if(HaveTower())
	{
		return;
	}
	
	if(mTypeOneQueue.Length >= UnitOneCount)
	{
		if(CheckQueue(mTypeOneQueue, UnitOneCount))
		{
			GatherQueuedUnits(1);
			return;
		}
	}
	if(mTypeTwoQueue.Length >= UnitTwoCount)
	{
		if(CheckQueue(mTypeTwoQueue, UnitTwoCount))
		{
			GatherQueuedUnits(2);
			return;
		}
	}
}

function bool CheckQueue(array<TMPawn> units, int reqCount)
{
	local array<int> players;
	local array<int> counts;
	local int i;
	local int j;
	local bool found;

	for(i = 0; i < units.Length; i++)
	{
		// first run only
		if(players.Length == 0)
		{
			if(reqCount == 1)
			{
				CurrentPlayerId = units[i].m_owningPlayerId;
				return true;
			}
			else
			{
				players.AddItem(units[i].m_owningPlayerId);
				counts.AddItem(1);
				continue;
			}
		}

		// a map would be way better for this...
		found = false;

		for(j = 0; j < players.Length; j++)
		{
			if(units[i].m_owningPlayerId == players[j])
			{
				found = true;
				counts[j]++;

				if(counts[j] >= reqCount)
				{
					CurrentPlayerId = players[j];
					return true;
				}

				break;
			}
		}

		if(!found)
		{
			players.AddItem(units[i].m_owningPlayerId);
			counts.AddItem(1);
		}
	}
	return false;
}

function GatherQueuedUnits(int type)
{
	local int numReqUnits;
	local int i;
	local int currentUnits;
	local array<int> indices;
	local array<TMPawn> queue;
	local TMTransformationFE fe;

	mTransformerState = ACTIVE;
	mActiveType = type;
	queue = GetQueue(type);
	numReqUnits = GetUnitCount(type);
	currentUnits = 0;

	// find the first three units in the queue belonging to the player
	// add them to the active queue and save the indices (for removal_
	for(i=0; i < queue.Length; i++)
	{
		if(queue[i].m_owningPlayerId == CurrentPlayerId)
		{
			indices.AddItem(i);
			mActiveQueue.AddItem(queue[i]);
			currentUnits++;
			if(currentUnits == numReqUnits)
			{
				break;
			}
		}
	}

	// remove the units that were moved to the active queue
	for(i = indices.Length - 1; i >= 0; i--)
	{
		RemoveFromQueue(type, i, 1);
	}

	// send events to each unit
	for(i=0; i < mActiveQueue.Length; i++)
	{
		fe = class'TMTransformationFE'.static.create(0, "TRANSFORM", mActiveQueue[i].pawnId);
		mActiveQueue[i].SendFastEvent(fe);
	}
	
	SuccessfulTransform = false;
}

event Tick(float dt)
{
	local TMPawn tempPawn;
	local float distance;

	// Do a distance check to see if active pawns have arrived in the center of the transform point
	if(mTransformerState == ACTIVE)
	{
		foreach mActiveQueue(tempPawn)
		{
			if (class'UDKRTSPawn'.static.IsValidPawn(tempPawn) == false && SuccessfulTransform == false)
			{
				FixDeadlock();
			}

			distance = VSize(tempPawn.Location - self.Location);
			if(distance < 150.f)
			{
				PawnArrived(tempPawn);
			}
		}
	}
}

function ScheduleTransformation()
{
	SuccessfulTransform = true;
	mReadyCount = 0;
	mRepInfo = TMPlayerReplicationInfo(mActiveQueue[0].OwnerReplicationInfo);
	mTransformerState = TRANSFORMING;

	m_CachedCommander = TMPawn(mActiveQueue[0].m_TMPC.Pawn);
	m_TransformingPlayerAllyId = mActiveQueue[0].GetAllyId();
	SetTimer(0.05f, false, 'BroadcastEffect', self);
	SetTimer(TransformationTime, false, 'CreateResultUnits', self);
}

function FixDeadlock()
{
	local int i;
	local TMTransformationFE fe;

	mTransformerState = NOTACTIVE;
		
	for(i = 0; i < mActiveQueue.Length; i++)
	{
		// send cancel events to the waiting units
		fe = class'TMTransformationFE'.static.create(0, "CANCEL", mActiveQueue[i].pawnId);
		mActiveQueue[i].SendFastEvent(fe);
	}
		
	// Clear queue
	mActiveQueue.Length = 0;

	// Check queued units
	mTransformerState = NOTACTIVE;
	mArrivedPawns.Length = 0;
	CheckIfQueuesAreFull();
}

function DestroyActiveUnits()
{
	local int i;
	
	for(i=0; i < mActiveQueue.Length; i++)
	{
		mActiveQueue[i].OwnerReplicationInfo.Population -= mActiveQueue[i].PopulationCost;
		mActiveQueue[i].removeActiveSelection();
		mActiveQueue[i].Destroy();
	}
	
	mActiveQueue.Length = 0;
	mReadyCount = 0;
}

function CreateResultUnits()
{
	local string typeToCreate;
	local int numToCreate;
	local vector tempVector;
	local int i;
	local TMPawn newUnit;

	if(m_CachedCommander == None)
	{
		return;
	}
	else if(m_CachedCommander.m_TMPC.bIsDead)
	{
		mTransformerState = NOTACTIVE;
		mActiveQueue.Length = 0;
		CheckIfQueuesAreFull();
		return;
	}

	DestroyActiveUnits();

	if(mActiveType == 1)
	{
		typeToCreate = UnitTwoType; 
		numToCreate = UnitTwoCount;
	}
	if(mActiveType == 2)
	{
		typeToCreate = UnitOneType;
		numToCreate = UnitOneCount;
	}

	for(i=0; i < numToCreate; i++)
	{
		newUnit = TMGameInfo(WorldInfo.Game).RequestUnit(typeToCreate, mRepInfo, self.Location, false, tempVector, None, true);
		newUnit.SendFastEvent(  class'TMFastEventSpawn'.static.create( newUnit.pawnId , newUnit.Location , true,, true, mRallyPoint.Location ) );
		newUnit.m_currentState = TMPS_MOVING;
	}

	mTransformerState = NOTACTIVE;
	CheckIfQueuesAreFull();
}


function PawnArrived(TMPawn Other)
{
	local int i;
	local TMPawn pawn;

	if(mTransformerState != ACTIVE) { return; }

	// increment the ready count if the pawn is in the active queue
	for(i=0; i < mActiveQueue.Length; i++)
	{
		if(mActiveQueue[i] == Other)
		{
			// Check that it hasn't already arrived
			foreach mArrivedPawns(pawn)
			{
				if(Other == pawn)
				{
					return;
				}
			}
			
			mArrivedPawns.AddItem(Other);
			mReadyCount++;
			break;
		}
	}

	// if every pawn in the active queue has made contact, proceed
	if(mReadyCount == GetUnitCount(mActiveType) &&
		HaveTower() == false)
	{
		mArrivedPawns.Length = 0;
		ScheduleTransformation();
	}
}

simulated function int GetUnitCount(int type)
{
	if(type == 1)
	{
		return UnitOneCount;
	}
	if(type == 2)
	{
		return UnitTwoCount;
	}
}

simulated function string GetUnitType(int type)
{
	if(type == 1)
	{
		return UnitOneType;
	}
	if(type == 2)
	{
		return UnitTwoType;
	}
}

function array<TMPawn> GetQueue(int type)
{
	if(type == 1)
	{
		return mTypeOneQueue;
	}
	else if(type == 2)
	{
		return mTypeTwoQueue;
	}
}

function RemoveFromQueue(int queue, int index, int count)
{
	if(queue == 1)
	{
		mTypeOneQueue.Remove(index, count);
	}
	if(queue == 2)
	{
		mTypeTwoQueue.Remove(index, count);
	}
}

simulated event PostBeginPlay()
{
	// find the closest queue and rally points
	local TMRallyPoint rallyPoint;

	mRallyPoint = None;
	m_PotionProjEffect = ParticleSystem'transformpoint.Particles.P_Potion_Projectile';

	// material setup
	m_UnitOcclusionMesh.SetStaticMesh(m_TransformerMesh.StaticMesh);
	OccludedMatInst = new(None) Class'MaterialInstanceConstant';
	OccludedMatInst.SetParent(m_UnitOcclusionMesh.GetMaterial(0));
	OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', 1000);
	m_UnitOcclusionMesh.SetMaterial(0, OccludedMatInst);
	
	foreach AllActors(class'TMRallyPoint', rallyPoint)
	{
		if(mRallyPoint == None)
		{
			mRallyPoint = rallyPoint;
		}
		else
		{
			if(VSize(self.Location - rallyPoint.Location) < VSize(self.Location - mRallyPoint.Location))
			{
				mRallyPoint = rallyPoint;
			}
		}
	}
	
	AssignTransformerID();
	
	m_Collider = Spawn(class'TMTransformerCollider');
	m_Collider.SetUpCollider(self);
}

simulated function PlayEffect(int aID)
{
	local vector effectLocation;
	local TMPawn pw;
	effectLocation = self.Location;
	effectLocation.Z += 0;

	foreach AllActors(class'TMPawn', pw)
	{
		if(pw != none)
		{
			if(pw.m_allyId == aID)
			{
				break;
			}
		}
	}
	if(pw != None && pw.m_TMPC!= none )
	{
		pw.m_TMPC.m_ParticleSystemFactory.CreateWithScale(ParticleSystem'transformpoint.Particles.Transform_Main_PS', aID, 0, effectLocation, 1.5f, 3.0f);
	}
}

simulated function PlayPotionEffect(int aID, int commanderID)
{	
	local TMPawn commander;
	local TMPlayerController tmcont;
	local TMPlayerController temp;
	local vector LocPlusZ;
	local TMPotionProjectile proj;

	foreach AllActors(class'TMPlayerController', temp)
	{
		tmcont = temp;
		break;
	}

	commander = tmcont.GetPawnByID(commanderID);
	LocPlusZ = Location;
	LocPlusZ.Z += 100;	
	
	proj = Spawn(class'TMPotionProjectile',,, LocPlusZ, Rotation);
	proj.FirePotionProjectile(commander,commander,m_PotionProjEffect,700,"dontSend", PotionType);
}

function BroadcastEffect()
{
	TMGameInfo(WorldInfo.Game).BroadcastTransformEffect(TransformerId, m_TransformingPlayerAllyId);
}

function BroadcastPotionEffect(int aID, int commanderID)
{
	TMGameInfo(WorldInfo.Game).BroadcastPotionEffect(TransformerId, aID, commanderID);
}

function AddToFarmingQueue(TMPawn pawn)
{
	mFarmingQueue.AddItem(pawn);

	if(mFarmingQueue.Length > 0) 
	{
		// Other cases will be handled when the current farmer finishes
		FarmPotion();
	}
}

function RemoveFromFarmingQueue(TMPawn pawn)
{
	mFarmingQueue.RemoveItem(pawn);

	if(mFarmingQueue.Length == 0)
	{
		mFarmingState = NOTACTIVE;
	}
}

function FarmPotion()
{
	local float  fDist;

	// Failsafe: bail if the farming commander gets too far away
	if(mFarmingQueue[0] != None)
	{
		fDist = VSize(self.Location - mFarmingQueue[0].Location);
		if(fDist > 600.f)
		{
			mFarmingQueue.Length = 0;
		}
	}
	
	// GGH TODO: Set state appropriately for Teutonian queue interaction
	mFarmingState = ACTIVE;
	mFarmer = mFarmingQueue[0];
	SetTimer(1.f, false, 'GivePotion', self); // GGH TODO: Use proper time
}

function GivePotion()
{
	local TMPawn pawn;
	// local TMProjectileAbility proj;
	// local vector LocPlusZ;

	// Give potion to the pawn's TMPC
	// Manage queue
	// Restore state (queue - empty?)
	// GGH TODO: Teutonian queue interaction

	if(mFarmingQueue.Length > 0) // Ensure that the queuer hasn't cancelled
	{
		if(mFarmingQueue[0] == mFarmer)
		{
			pawn = mFarmingQueue[0];
			pawn.m_TMPC.AddPotion(PotionType);

			BroadcastPotionEffect(TMPlayerReplicationInfo(mFarmingQueue[0].OwnerReplicationInfo).allyId, mFarmingQueue[0].pawnId);

			/*
			LocPlusZ = Location;
			LocPlusZ.Z += 100;			
			proj = Spawn(class'TMProjectileAbility',,, LocPlusZ, Rotation);
			proj.FireAbilityProjectile(mFarmingQueue[0].Location, mFarmingQueue[0], m_PotionProjEffect, VSize(Location - mFarmingQueue[0].Location) * 2.0, "");
			*/
		}
		
		// Check if it is appropriate to begin farming again
		if(mFarmingQueue[0] == None || VSize(self.Location - mFarmingQueue[0].Location) > 500.f)
		{
			mFarmingQueue.Length = 0;
			mFarmingState = NOTACTIVE;
			return;
		}

		if(mFarmingState == ACTIVE)
		{
			FarmPotion();
		}
	}
	else
	{
		mFarmingQueue.Length = 0;
		mfarmingState = NOTACTIVE;
	}
}

simulated function AssignTransformerID()
{
	/*
	 * I'm having difficulties getting TMGameInfo-assigned IDs to replicate
	 * to clients, because the TMTransformer actors exist on the map. Instead,
	 * this function ranks them deterministically (based on distance), so
	 * that the IDs are consistent across the network.
	 */
	
	local int id;
	local float myDistance;
	local TMTransformer other;
	
	id = 0;
	myDistance = VSize(self.Location);
	
	// For every transformer that is closer to the origin than this one, ID++
	foreach AllActors(class'TMTransformer', other)
	{
		if( VSize(other.Location) < myDistance )
		{
			id++;
		}
	}
	
	self.TransformerId = id;
}

simulated function SetHighlighted(bool isHighlighted)
{
	if (isHighlighted)
	{
		if (m_icon != none)
		{
			m_icon.ShowComposite();
		}
		OccludedMatInst.SetScalarParameterValue('IsHighlighted', 1);
		highlighted = true;
	}
	else
	{
		if (m_icon != none)
		{
			m_icon.HideComposite();
		}
		OccludedMatInst.SetScalarParameterValue('IsHighlighted', 0);
		highlighted = false;
	}
}

DefaultProperties
{
	Begin Object Class=StaticMeshComponent Name=UnitStaticMesh
		StaticMesh=StaticMesh'transformpoint.Model.TransformationPoint_01'
	End Object
	m_TransformerMesh=UnitStaticMesh
	Components.Add(UnitStaticMesh)

	bCollideActors=true
	bBlockActors=true
	bPathColliding=true
	
	bAlwaysRelevant=true
	showingTooltip = false;
	highlighted = false;

	// bStatic=true
	bNoDelete=true

	mTransformerState=NOTACTIVE;
	mActiveType=0;
	SuccessfulTransform=false;
	TransformerId=0;

	Begin Object Class=StaticMeshComponent Name=OcclusionStaticMeshComponent
		Materials(0)=Material'JC_Material_SandBox.Masters.JC_TeamOutline_Master'
		StaticMesh=StaticMesh'transformpoint.Model.TransformationPoint_01'
		DepthPriorityGroup=SDPG_World
		CastShadow=false
		bCastDynamicShadow=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=true
		BlockRigidBody=true
		bAcceptsDynamicDecals=false
		bUseOnePassLightingOnTranslucency=true
		HiddenEditor=true
	End Object
	m_UnitOcclusionMesh=OcclusionStaticMeshComponent
	Components.Add(OcclusionStaticMeshComponent)

	mFarmingState = NOTACTIVE
}
