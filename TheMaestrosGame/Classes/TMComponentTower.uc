/* TMComponentTower
	Adds functionality for Towers in NexusCommanders game mode.
*/
class TMComponentTower extends TMComponent;


var float mSpawnDuration;
var float mStartingHealthPercentage;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mSpawnDuration = json.GetFloatValue("spawn_time");
	mStartingHealthPercentage = json.GetFloatValue("starting_health_percentage");
}

simulated function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentTower newcomp;

	newcomp = new() class'TMComponentTower'(self);
	newcomp.m_owner = newowner;
	newowner.mShouldIgnoreSelectAll = true;
	newowner.bCanBeKnockedUp = false;
	newowner.bCanBeKnockedBack = false;

	newcomp.StartBuildingTower();

	return newcomp;
}

function StartBuildingTower()
{
	// Spawn with starting health
	m_owner.Health = m_owner.HealthMax * mStartingHealthPercentage;

	// Don't allow attacking
	m_owner.GetAttackComponent().mCanAttack = false;

	m_owner.SetTimer(mSpawnDuration, false, nameof(FinishBuildingTower), self);
}

function FinishBuildingTower()
{
	// Add the rest of your health to the tower
	m_owner.Health = m_owner.Health + m_owner.HealthMax * (1-mStartingHealthPercentage);

	// Turn back on attacking
	m_owner.GetAttackComponent().mCanAttack = true;
}
