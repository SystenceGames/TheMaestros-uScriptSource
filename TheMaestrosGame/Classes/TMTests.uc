/* TMTests
	Allows you to run various tests on our code.

	Relies on printing messages for test failures.

	NOTE: many of these are destructive to the data. Don't use them while you're running the actual game for real players.
 */
class TMTests extends Object;


/* TestBlacklistedCommanders
	Makes sure the blacklistedCommanders feature toggle works properly.
	WARNING: will change data in the TMMainMenuPlayerController passed in
*/
function TestBlacklistedCommanders(TMMainMenuPlayerController inTMPC)
{
	local string featureTogglesString;
	local JSONObject featureTogglesJson;
	local string playerInventoryString;

	// Set up player inventory to have all 3 teutonian commanders
	playerInventoryString = "{\"inventoryIds\":[\"RoboMeister\",\"Rosie\",\"TinkerMeister\"]}";
	inTMPC.mPlayerInventory = class'TMPlayerInventory'.static.DeserializeFromJson( class'JSONObject'.static.DecodeJson(playerInventoryString) );

	`log("Testing blacklisted commanders... (look for FAILED! in proceeding log lines)");

	///// No blacklisted tests /////
	featureTogglesString = "{\"isOnline\":true,\"multiplayerEnabled\":true,\"blacklistedCommanders\":[]}";
	featureTogglesJson = class'JsonObject'.static.DecodeJson(featureTogglesString);
	inTMPC.mFeatureToggles = inTMPC.featureTogglesFrom(featureTogglesJson);

	if(inTMPC.IsCommanderAvailable("RoboMeister") == false) {
		`log("Test 1 FAILED! RoboMeister should be available.");
	}

	///// Rosie blacklisted test /////
	featureTogglesString = "{\"isOnline\":true,\"multiplayerEnabled\":true,\"blacklistedCommanders\":[\"Rosie\"]}";
	featureTogglesJson = class'JsonObject'.static.DecodeJson(featureTogglesString);
	inTMPC.mFeatureToggles = inTMPC.featureTogglesFrom(featureTogglesJson);

	if(inTMPC.IsCommanderAvailable("RoboMeister") == false) {
		`log("Test 2 FAILED! RoboMeister should be available.");
	}
	if(inTMPC.IsCommanderAvailable("Rosie") == true) {
		`log("Test 2 FAILED! Rosie shouldn't be available.");
	}

	///// Multi-commander blacklist test /////
	featureTogglesString = "{\"isOnline\":false,\"multiplayerEnabled\":true,\"blacklistedCommanders\":[\"RoboMeister\",\"Rosie\"]}";
	featureTogglesJson = class'JsonObject'.static.DecodeJson(featureTogglesString);
	inTMPC.mFeatureToggles = inTMPC.featureTogglesFrom(featureTogglesJson);

	if(inTMPC.IsCommanderAvailable("RoboMeister") == true) {
		`log("Test 3 FAILED! RoboMeister shouldn't be available.");
	}
	if(inTMPC.IsCommanderAvailable("Rosie") == true) {
		`log("Test 3 FAILED! Rosie shouldn't be available.");
	}
	if(inTMPC.IsCommanderAvailable("TinkerMeister") == false) {
		`log("Test 3 FAILED! TinkerMeister should be available.");
	}

	`log("All tests finished. No FAILs means SUCCESS!");
}

/* TestWeightedSelection
	Run some simple tests to make sure weighted selection is generally working.
*/
function TestWeightedSelection()
{
	local TMBehaviorHelper behaviorHelper;
	local array<int> testArray;
	local array<int> selectionOccurances;
	local int i, numIterationsToTest;
	local int tempIndex;

	behaviorHelper = new () class'TMBehaviorHelper';

	numIterationsToTest = 1000;

	`log("Running weighted selection tests with " $ numIterationsToTest $ " iterations.");

	///// Test that an overwhelming weight is usually selected /////
	testArray.AddItem(99);
	testArray.AddItem(1);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);

	for(i=0; i < numIterationsToTest; i++)
	{
		tempIndex = behaviorHelper.MakeWeightedSelection(testArray);
		selectionOccurances[tempIndex]++;
	}

	`log("Testing (99, 1), expecting many 99s");
	PrintWeightedSelectionResults(testArray, selectionOccurances);

	testArray.Remove(0, testArray.Length);
	selectionOccurances.Remove(0, selectionOccurances.Length);

	///// Test uniform distribution when all weights equal /////
	testArray.AddItem(1);
	testArray.AddItem(1);
	testArray.AddItem(1);
	testArray.AddItem(1);
	testArray.AddItem(1);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);

	for(i=0; i < numIterationsToTest; i++)
	{
		tempIndex = behaviorHelper.MakeWeightedSelection(testArray);
		selectionOccurances[tempIndex]++;
	}

	`log("Testing (1, 1, 1, 1, 1), expecting uniform distribution");
	PrintWeightedSelectionResults(testArray, selectionOccurances);

	testArray.Remove(0, testArray.Length);
	selectionOccurances.Remove(0, selectionOccurances.Length);

	///// Test single item /////
	testArray.AddItem(1);
	selectionOccurances.AddItem(0);

	for(i=0; i < numIterationsToTest; i++)
	{
		tempIndex = behaviorHelper.MakeWeightedSelection(testArray);
		selectionOccurances[tempIndex]++;
	}

	`log("Testing (1), expecting this single weight to have all the selections.");
	PrintWeightedSelectionResults(testArray, selectionOccurances);

	testArray.Remove(0, testArray.Length);
	selectionOccurances.Remove(0, selectionOccurances.Length);

	///// Test zero weight item /////
	testArray.AddItem(0);
	testArray.AddItem(1);
	testArray.AddItem(0);
	testArray.AddItem(1);
	testArray.AddItem(1);
	testArray.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);

	for(i=0; i < numIterationsToTest; i++)
	{
		tempIndex = behaviorHelper.MakeWeightedSelection(testArray);
		selectionOccurances[tempIndex]++;
	}

	`log("Testing (0, 1, 0, 1, 1, 0), expecting 0 weights to never have selection.");
	PrintWeightedSelectionResults(testArray, selectionOccurances);

	testArray.Remove(0, testArray.Length);
	selectionOccurances.Remove(0, selectionOccurances.Length);

	///// Test negative weight item /////
	testArray.AddItem(10);
	testArray.AddItem(-1);
	testArray.AddItem(5);
	testArray.AddItem(0);
	testArray.AddItem(-10);
	testArray.AddItem(10);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);

	for(i=0; i < numIterationsToTest; i++)
	{
		tempIndex = behaviorHelper.MakeWeightedSelection(testArray);
		selectionOccurances[tempIndex]++;
	}

	`log("Testing (10, -1, 5, 0, -10, 10), making sure negative numbers don't mess things up.");
	PrintWeightedSelectionResults(testArray, selectionOccurances);

	testArray.Remove(0, testArray.Length);
	selectionOccurances.Remove(0, selectionOccurances.Length);

	///// Test exponent weighted item /////
	testArray.AddItem(10);
	testArray.AddItem(-1);
	testArray.AddItem(5);
	testArray.AddItem(0);
	testArray.AddItem(-10);
	testArray.AddItem(10);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);
	selectionOccurances.AddItem(0);

	for(i=0; i < numIterationsToTest; i++)
	{
		tempIndex = behaviorHelper.MakeWeightedSelection(testArray, 1.2f);
		selectionOccurances[tempIndex]++;
	}

	`log("Testing (10, -1, 5, 0, -10, 10), with a 1.2f exponent.");
	PrintWeightedSelectionResults(testArray, selectionOccurances);

	testArray.Remove(0, testArray.Length);
	selectionOccurances.Remove(0, selectionOccurances.Length);
}

/* PrintWeightedSelectionResults
	Helper funciton for TestWeightedSelection()
	Prints out the occurrences of different weighted selections.

	Example:
	(0) Weight 3 selected X times.
	(1) Weight 12 selected Y times.
	(2) Weight 99 selected Z times.
*/
function PrintWeightedSelectionResults(array<int> inWeightsArray, array<int> inWeightSelectionsArray)
{
	local int i;

	if(inWeightsArray.Length != inWeightSelectionsArray.Length)
	{
		`warn("PrintWeightedSelectionResults() array lengths not equal! Cancelling print.");
		return;
	}

	for(i=0; i < inWeightsArray.Length; i++)
	{
		`log("  (" $ i $ ") Weight " $ inWeightsArray[i] $ " selected " $ inWeightSelectionsArray[i] $ " times.");
	}
}
