/* TMAbilityHelper
	Performs actions that an ability might need to do.
	Actions won't be performed if the target is a game objective.
 */

class TMAbilityHelper extends Object;

var TMPlayerController 	m_TMPC;
var int 				m_AllyID;


function Setup( TMPlayerController inTMPC, int inAllyID )
{
	m_TMPC = 	inTMPC;
	m_AllyID = 	inAllyID;
}

function array<TMPawn> GetEnemiesInRadius( int inRadius, Vector inOrigin ) 	// TODO: test this function
{
	local int i;
	local TMPawn tempPawn;
	local array<TMPawn> enemyPawns;

	enemyPawns = m_TMPC.GetTMPawnList();
	for( i = enemyPawns.Length-1; i >= 0; i-- )
	{
		tempPawn = enemyPawns[i];
		if( TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId == m_AllyID ||
			tempPawn.IsGameObjective() ||
			!tempPawn.IsPointInRange2D( inOrigin, inRadius ) )
		{
			enemyPawns.Remove( i, 1 );
		}
	}

	return enemyPawns;
}

function DoDamageToTarget( int inDamage, TMPawn inTarget )
{
	// Abilities aren't allowed to deal damage to game objectives
	if( inTarget.IsGameObjective() )
	{
		return;
	}

	inTarget.TakeDamage( inDamage, m_TMPC, inTarget.Location, inTarget.Location, class'DamageType',, m_TMPC );
}

function DoDamageInRadius( int inDamage, int inRadius, Vector inOrigin )
{
	local TMPawn tempPawn;
	local array< TMPawn > pawns;

	pawns = GetEnemiesInRadius( inRadius, inOrigin );
	foreach pawns( tempPawn )
	{
		DoDamageToTarget( inDamage, tempPawn );
	}
}

function KnockbackTarget( TMPawn inTarget, Vector inOrigin, float inPower, int inStatusEffect )
{
	local Vector velocity;

	if( inTarget.bCanBeKnockedBack )
	{
		velocity = inTarget.Location - inOrigin;
		velocity = Normal( velocity ) * inPower;

		inTarget.m_Unit.SendStatusEffect( inStatusEffect );
		inTarget.GetForcePushed( velocity );
	}
}

function DoKnockbackInRadius( int inRadius, float inPower, Vector inOrigin, int inDamage = 0 )
{
	local TMPawn tempPawn;
	local array<TMPawn> pawns;

	pawns = GetEnemiesInRadius( inRadius, inOrigin );
	foreach pawns( tempPawn )
	{
		KnockbackTarget( tempPawn, inOrigin, inPower, SE_RAMBAMQUEEN_KNOCKBACK );
		DoDamageToTarget( inDamage, tempPawn );
	}
}
