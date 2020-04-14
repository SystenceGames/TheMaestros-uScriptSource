/* TMAIAbilityHelper
	Adds functionality that allows our bots to cast abilities
 */
class TMAIAbilityHelper extends Object;

var TMPawn 				mPawn;
var TMAbility 			mAbilityComponent;


function Setup( TMPawn inPawn )
{
	mPawn = inPawn;
	mAbilityComponent = inPawn.GetAbilityComponent();
}


function CastAbility( Vector inTargetLocation )
{
	local array< TMPawn > similarIssuedPawns;

	`log( "TMAIAbilityHelper::CastAbility() casting ability " $ mAbilityComponent.m_sAbilityName );

	similarIssuedPawns.AddItem( mPawn );
	mPawn.SendFastEvent( class'TMAbilityFE'.static.create( mAbilityComponent.m_sAbilityName,, inTargetLocation, similarIssuedPawns ) );

}

function TMPawn GetNearestEnemy()
{
	local int i;
	local TMPawn tempPawn, closestPawn;
	local int tempDist, closestDist;
	local array<TMPawn> pawnList;

	pawnList = mPawn.m_TMPC.GetTMPawnList();
	closestPawn = pawnList[0];
	closestDist = VSizeSq2D( mPawn.Location - pawnList[0].Location );
	
	for( i = 1; i < pawnList.Length; i++ )
	{
		tempPawn = pawnList[i];
		if( IsPawnEnemyPlayer( tempPawn ) && tempPawn.health > 0 )
		{
			tempDist = VSizeSq2D( mPawn.Location - tempPawn.Location );
			if( tempDist < closestDist )
			{
				closestDist = tempDist;
				closestPawn = tempPawn;
			}
		}
	}

	return closestPawn;
}

function bool IsPawnEnemyPlayer( TMPawn inPawn )
{
	if( !mPawn.m_TMPC.IsPawnPlayer( inPawn ) )
	{
		return false;
	}

	return TMPlayerReplicationInfo( inPawn.OwnerReplicationInfo ).allyId != TMPlayerReplicationInfo( mPawn.OwnerReplicationInfo ).allyId;
}

function bool IsInRange( Vector inLocation, optional float inRange )
{
	if( inRange == 0 )
	{
		inRange = mAbilityComponent.m_iRange;
	}
	return mPawn.IsPointInRange2D( inLocation, inRange );
}

function bool IsAbilityOnCooldown()
{
	return mAbilityComponent.IsOnCooldown();
}
