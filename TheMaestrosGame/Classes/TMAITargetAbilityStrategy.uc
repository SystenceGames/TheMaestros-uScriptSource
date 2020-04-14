/* TMAITargetAbilityStrategy
	A simple strategy for casting targeted abilities.
	If the nearest enemy is in range, fire my ability at him.
*/
class TMAITargetAbilityStrategy extends Object implements(TMAIAbilityStrategy);

var TMPawn mPawn;
var TMAIAbilityHelper mAIAbilityHelper;


function Setup( TMPawn inPawn )
{
	mAIAbilityHelper = new class'TMAIAbilityHelper'();
	mAIAbilityHelper.Setup( inPawn );
}

function TryToCastAbility()
{
	local TMPawn nearestEnemy;

	if( mAIAbilityHelper.IsAbilityOnCooldown() )
	{
		return;
	}

	nearestEnemy = mAIAbilityHelper.GetNearestEnemy();
	if( mAIAbilityHelper.IsInRange( nearestEnemy.Location ) )
	{
		mAIAbilityHelper.CastAbility( nearestEnemy.Location );
	}
}
