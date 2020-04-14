class TMAIAbilityStrategyFactory extends Object;


static function TMAIAbilityStrategy CreateAIAbilityStrategy( TMPawn inPawn )
{
	local TMAIAbilityStrategy aiAbilityStrategy;
	local TMAbility abilityComponent;

	abilityComponent = inPawn.GetAbilityComponent();

	// No ability strategy
	if( abilityComponent == none ||
		TMAbilityConductorShock(abilityComponent) != none ||
		TMAbilityRoboMeisterNuke(abilityComponent) != none )
	{
		aiAbilityStrategy = new class'TMAINoAbilityStrategy'();
	}
	// Melee ability strategy
	else if( TMAbilityRosieTimeBubble(abilityComponent) != none )
	{
		aiAbilityStrategy = new class'TMAIMeleeAbilityStrategy'();
	}
	// Ranged ability strategy
	else
	{
		aiAbilityStrategy = new class'TMAITargetAbilityStrategy'();
	}

	aiAbilityStrategy.Setup( inPawn );

	return aiAbilityStrategy;
}