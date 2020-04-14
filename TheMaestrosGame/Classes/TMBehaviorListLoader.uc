/* TMBehaviorListLoader
	Initializes all our available behaviors for bots.
	Allows TMTeamAIController to get prioritized lists of behaviors easily.
*/

class TMBehaviorListLoader extends Object;

struct TMLoadedBehavior
{
	var TMBehavior behavior;
	var int weight;
};

var array<TMLoadedBehavior> mLoadedBehaviorsList;

var TMBehaviorHelper mBehaviorHelper;


function Setup(TMBehaviorHelper inBehaviorHelper, JsonObject inBehaviorWeightsJson)
{
	local TMLoadedBehavior farm, trans, attack, flee, wander;

	mBehaviorHelper = inBehaviorHelper;

	farm.behavior = new class'TMFarmBehavior';
	farm.weight = mBehaviorHelper.LoadIntFromBehaviorJson("FarmWeight", inBehaviorWeightsJson);
	mLoadedBehaviorsList.AddItem(farm);

	trans.behavior = new class'TMTransformBehavior';
	trans.weight = mBehaviorHelper.LoadIntFromBehaviorJson("TransformWeight", inBehaviorWeightsJson);
	mLoadedBehaviorsList.AddItem(trans);

	attack.behavior = new class'TMAttackBehavior';
	attack.weight = mBehaviorHelper.LoadIntFromBehaviorJson("AttackWeight", inBehaviorWeightsJson);
	mLoadedBehaviorsList.AddItem(attack);

	flee.behavior = new class'TMFleeBehavior';
	flee.weight = mBehaviorHelper.LoadIntFromBehaviorJson("FleeWeight", inBehaviorWeightsJson);
	mLoadedBehaviorsList.AddItem(flee);

	wander.behavior = new class'TMWanderBehavior';
	wander.weight = mBehaviorHelper.LoadIntFromBehaviorJson("WanderWeight", inBehaviorWeightsJson);
	mLoadedBehaviorsList.AddItem(wander);
}


/* SelectOrderedBehaviorList
	Uses weighted selection to return an ordered behavior list.
	Behaviors with a higher weight will be more likely to be at the front of the list.
*/
function array<TMBehavior> SelectOrderedBehaviorList()
{
	local array<TMBehavior> orderedList, behaviorsToAdd;
	local array<int> behavoirWeights;
	local TMLoadedBehavior iterLoadedBehavior;
	local int selectedIndex;

	foreach mLoadedBehaviorsList(iterLoadedBehavior)
	{
		behaviorsToAdd.AddItem(iterLoadedBehavior.behavior);
		behavoirWeights.AddItem(iterLoadedBehavior.weight);
	}

	while(behaviorsToAdd.Length > 0)
	{
		selectedIndex = mBehaviorHelper.MakeWeightedSelection(behavoirWeights, mBehaviorHelper.mTMTeamAiController.mWeightExponent);

		orderedList.AddItem( behaviorsToAdd[selectedIndex] );
		behaviorsToAdd.Remove(selectedIndex, 1);
		behavoirWeights.Remove(selectedIndex, 1);
	}

	return orderedList;
}
