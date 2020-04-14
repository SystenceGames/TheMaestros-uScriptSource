/* TMAIMeleeAbilityStrategy
	A simple strategy for casting short range abilities.
	If the nearest enemy is really close, fire my ability at him.

	NOTE: This is currently only used for TinkerMeister bot.
*/
class TMAIMeleeAbilityStrategy extends Object implements(TMAIAbilityStrategy);

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
	if( mAIAbilityHelper.IsInRange( nearestEnemy.Location, 200 ) )
	{
		mAIAbilityHelper.CastAbility( nearestEnemy.Location );
	}
}
