/* TMTimeBubble
 * 
 * Stuns enemy units who step within the time bubble's radius.
 * Enemy units become un-stunned when the time bubble disappears.
 */
class TMTimeBubble extends TMAbilityObject;

var TMPawn 	m_PawnToFollow;
var TMPlayerReplicationInfo mTMPRI;

var float 	m_Delay;
var float   m_Duration;
var float   m_Radius;
var float   m_CheckFrequency;

var array< TMPawn > mStunnedUnitsList;


static function TMTimeBubble Create( TMAbilityHelper inAbilityHelper, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, Vector inLocation, float inDuration, float inRadius, float inCheckFrequency, float inDelay, TMPawn inPawnToFollow )
{
	local TMTimeBubble object;
	object = new class'TMTimeBubble'();
	object.Setup( inAbilityHelper, inTMPC, inAllyID, inPlayerID, inTeamColorIndex, inLocation, inRadius );
	object.m_Duration 		= inDuration;
	object.m_Radius 		= inRadius;
	object.m_CheckFrequency	= inCheckFrequency;
	object.m_Delay			= inDelay;
	object.m_PawnToFollow 	= inPawnToFollow;
	object.mTMPRI 			= TMPlayerReplicationInfo( inPawnToFollow.OwnerReplicationInfo );
	return object;
}

function Start()
{
	DoInitialVFX();
	m_TMPC.SetTimer( m_Delay, false, 'DelayedStart', self );

	super.Start();
}

function DelayedStart()
{
	m_Location = m_PawnToFollow.Location;
	DoFullVFX();
	UpdateBubble();

	m_TMPC.SetTimer( m_CheckFrequency, true, 'UpdateBubble', self );
	m_TMPC.SetTimer( m_Duration, false, 'Stop', self );
}

function Stop()
{
	ClearStunnedUnits();

	super.Stop();
}

// Check for units within my radius to stun
function UpdateBubble()
{
	local TMFastEvent pauseAnimEvent;
	local array<TMPawn> pawnArray;
	local TMPawn tempPawn;
	local int i;

	// Pause animation event which we'll send to pawns
	pauseAnimEvent = new () class'TMFastEvent';
	pauseAnimEvent.commandType = "Pause_Animation";
	

	// Loop through every TMPawn
	pawnArray = m_TMPC.GetTMPawnList();
	for( i =0; i< pawnArray.Length ; i++ )
	{
		tempPawn = pawnArray[ i ];

		// If is an enemy AND is in range
		if( self.m_AllyID != tempPawn.m_allyId &&
			!tempPawn.IsGameObjective() &&
			tempPawn.IsInRange2D( tempPawn.Location, m_Location, m_Radius ) )
		{
			// If the unit isn't already stunned
			if( mStunnedUnitsList.Find( tempPawn ) == -1 )
			{
				// Pause the unit's animation
				tempPawn.ReceiveFastEvent( pauseAnimEvent );

				// Stun the unit
				if( m_TMPC.IsAuthority() )
				{
					tempPawn.m_Unit.SendStatusEffect( SE_TIME_FREEZE );
				}
				mStunnedUnitsList.AddItem( tempPawn );
			}
		}
	}
}

function ClearStunnedUnits()
{
	local int i;
	local TMFastEvent unpauseEvent; 

	unpauseEvent = new () class'TMFastEvent';
	unpauseEvent.commandType = "UnPause_Animation";

	m_TMPC.ClearTimer( 'UpdateBubble', self );

	// Unstun every unit in the stunned list
	for( i = 0; i < mStunnedUnitsList.Length; i++ )
	{
		if( mStunnedUnitsList[i] != none )
		{
			mStunnedUnitsList[i].ReceiveFastEvent( unpauseEvent );
			mStunnedUnitsList[i].m_Unit.RemoveFrozenStatusEffect();
			mStunnedUnitsList[i].TakeDamage( 0, m_TMPC, mStunnedUnitsList[i].Location, mStunnedUnitsList[i].Location, class'DamageType',, m_TMPC );
		}
	}

	// Clear the stunned units list
	mStunnedUnitsList.Remove(0, mStunnedUnitsList.Length);
}

function DoInitialVFX()
{
	local Vector castLocation;
	castLocation = m_PawnToFollow.GetTerrainAnchoredLocation();
	castLocation.Z += 15;

	m_TMPC.m_ParticleSystemFactory.CreateAttachedToActor(ParticleSystem'tm_tinkermeister.VFX_TimeStop.TimeStop_CHARGE', m_AllyID, m_TeamColorIndex, m_PawnToFollow, castLocation, m_Duration );
}

function DoFullVFX()
{
	local Vector castLocation;
	castLocation = m_PawnToFollow.GetTerrainAnchoredLocation();
	castLocation.Z += 15;

	m_TMPC.m_ParticleSystemFactory.Create(ParticleSystem'tm_tinkermeister.VFX_TimeStop.TimeStop_MAIN', m_AllyID, m_TeamColorIndex, castLocation, m_Duration );
}
