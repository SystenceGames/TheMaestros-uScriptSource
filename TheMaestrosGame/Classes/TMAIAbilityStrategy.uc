Interface TMAIAbilityStrategy;


function Setup( TMPawn inPawn );

// Will attempt to cast the ability. It will only cast the ability if it can be done "instantly"
function TryToCastAbility();
