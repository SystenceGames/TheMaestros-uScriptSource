/* TMPopSpring
	Launches a unit in the air, stunning it.
	While the spring is active, units can't walk through it
*/
class TMPopSpring extends TMAbilityActor;

var int 	m_Radius;
var TMPawn 	m_PopSprungPawn;


static function TMPopSpring Create( TMAbilityHelper inAbilityHelper, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, Vector inLocation, Rotator inRotation, int inRadius )
{
	local TMPopSpring object;
	local Rotator startRotation;
	object = inTMPC.Spawn( class'TMPopSpring',,, inLocation, startRotation );
	object.Setup( inAbilityHelper, inTMPC, inAllyID, inPlayerID, inTeamColorIndex, inRadius );
	object.m_Radius = inRadius;
	return object;
}

function Start()
{
	local float psScale;

	// Create VFX
	psScale = class'TMHelper'.static.GetScaleFromRadius( m_Radius );
	m_TMPC.m_ParticleSystemFactory.CreateWithScale( ParticleSystem'VFX_Popspring.PopSpring_Ability_VFX', m_AllyID, m_TeamColorIndex, Location, psScale, 2 );
	
	PopSpringNearestEnemy();

	super.Start();
}

function Stop()
{
	if( m_PopSprungPawn != none )
	{
		m_PopSprungPawn.m_Unit.RemoveFrozenStatusEffect();
		//m_PopSprungPawn.TakeDamage( 0, m_TMPC, m_PopSprungPawn.Location, m_PopSprungPawn.Location, class'DamageType',, m_TMPC ); 	// get aggro
	}

	super.Stop();
}

function PopSpringNearestEnemy()
{
	local TMPawn tempPawn;
	local array< TMPawn > pawnList;
	local float pawnDistance;
	local TMPawn nearestPawn;
	local float nearestPawnDistance;

	// Ready to cleanup target reticle
	super.Start();

	// Start blocking actors
	bBlockActors = true;

	nearestPawnDistance = m_Radius; 	// the nearest pawn must be less than or equal to m_Radius distance

	// Look for the nearest enemy that's in range
	pawnList = m_TMPC.GetTMPawnList();
	foreach pawnList( tempPawn )
	{
		// If is an enemy
		if( !m_TMPC.IsPawnOnSameTeam( tempPawn ) &&
			tempPawn.bCanBeKnockedUp )
		{
			// And is closer than any pawns
			pawnDistance = VSize2D( tempPawn.Location - Location );
			if( pawnDistance < nearestPawnDistance &&
				!tempPawn.m_Unit.IsStatusEffectActive( SE_POPSPRING_KNOCKUP ) ) 	// And it isn't already knocked up (into the air. This isn't a pregnancy test...)
			{
				// This is the new nearest pawn
				nearestPawn = tempPawn;
				nearestPawnDistance = pawnDistance;
			}
		}
	}

	// Pop spring if we have a nearest pawn (who we now know is in the radius)
	if( nearestPawn != none )
	{
		nearestPawn.m_Unit.SendStatusEffect( SE_POPSPRING_KNOCKUP );
		m_PopSprungPawn = nearestPawn;
		Launch( m_PopSprungPawn, 1200 ); 	// launching into the air is temp, this isn't the best solution
	}

	// Remove the status effect in a second. It's hardcoded as a second because somehow it's already being removed by something else
	m_TMPC.SetTimer( 2, false, 'Stop', self );
}

// Launching into the air isn't currently supported in our game.
// 	This function is a temporary solution that is ONLY for testing the
// 	feel of this ability. We should make a proper launch function in the future.
function Launch( TMPawn inPawn, float inPower )
{
	local Vector launchForce;
	local Vector zeroVector;
	launchForce.z = 1;
	launchForce = launchForce * inPower;

	inPawn.velocity = zeroVector;
	inPawn.AddVelocity( launchForce, inPawn.location, class'DamageType' );
}

DefaultProperties
{
	bCollideActors=true;
	bBlockActors=false
	bStatic = false
	bNoDelete = false
	bMovable = false
    
    Begin Object Class=CylinderComponent Name=CylinderComp
        CollisionRadius=32
        CollisionHeight=48
        CollideActors=true
        BlockActors=true
    End Object
    
    Components.Add( CylinderComp )
    CollisionComponent=CylinderComp    
}
