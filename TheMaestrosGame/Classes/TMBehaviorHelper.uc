class TMBehaviorHelper extends Object;

var TMTeamAiController mTMTeamAiController;
var TMTeamAIKnowledge mKnowledge;
var TMBehavior mTMBehavior; 	// current TMBehavior we are serving

var Vector mCurrentArmyLocation; 	// updated on each Update() tick

var float DURATION_UNTIL_BUDGE;
var float BUDGE_DURATION;
var float MAX_DISTANCE_FOR_BUDGE;	//  budge won't happen unless the bot has moved less than this distance
var float MAX_ARMY_STD_DEV; 		// the largest stddev an army can be spread out during a move command before receiving a "center" command
var float CENTER_DURATION;
var float REISSUE_MOVE_INTERVAL; 	// how often to reissue our move command (sometimes it helps to keep spamming the same move location)

/* Army movement */
var bool 	mIsMovingToLocation;
var Vector 	mTargetMoveLocation;
var float 	mTargetMoveRange;
var float   mMoveStartTime;
var float   mRecenterStartTime;
var Vector 	mMoveStartLocation;

var bool 	mIsRecentering;
var bool 	mIsBudging;

var TMEventTimer mTMEventTimer; 	// used to time events so we can log bot speed


function Initialize(TMTeamAiController teamAiController)
{
	mTMTeamAiController = teamAiController;
	mKnowledge = teamAiController.knowledge;

	MAX_ARMY_STD_DEV = 30;
	CENTER_DURATION = 0.25f;

	mTMEventTimer = class'TMEventTimer'.static.Create(mTMTeamAiController.GetTMPRI().PlayerName $ " AI", false);
}

function SetCurrentBehavior(TMBehavior inTMBehavior)
{
	mTMBehavior = inTMBehavior;
}

function bool IsCurrentBehavior(TMBehavior inBehavior)
{
	return inBehavior == mTMBehavior;
}

/* ClearTimers
	Clears all currently set timers for this object.
	Use this whenever we switch behaviors.
*/
function ClearTimers()
{
	mTMTeamAiController.ClearAllTimers(self);
}

function Update(float dt)
{
	local float avgArmyStdDev;
	local int numUnits;

	mCurrentArmyLocation = mTMTeamAiController.knowledge.GetMySmartLocation(avgArmyStdDev);

	if( mIsMovingToLocation )
	{
		numUnits = mTMTeamAiController.knowledge.GetMyPawnCount();	
		if( numUnits > 0 )
		{
			avgArmyStdDev /= numUnits;
		}

		// Check if we reached our destination
		if( IsArmyLocationInRange( mCurrentArmyLocation, mTargetMoveLocation, mTargetMoveRange ) )
		{
			mTMTeamAiController.Log( "TMBehaviorHelper::Tick() reached move location!` Notifying current " $ mTMBehavior.GetName() );
			mTMTeamAiController.ClearTimer('ReissueMoveCommand', self);
			mIsMovingToLocation = false;
			mMoveStartTime = 0.0f;
			mTMBehavior.NotifyMoveComplete( mTargetMoveLocation );
		}
		// ARMY RECENTERING
		// 	Currently disabled because it's probably a bad idea. Can delete local vars if this is a good idea
		// Check if our army needs to be centered
		// else if( mTMBehavior.ShouldKeepArmyCentered() && avgArmyStdDev > MAX_ARMY_STD_DEV )
		// {
		// 	mTMTeamAiController.Log( "TMBehaviorHelper: Recentering army! Current average std dev is " $ avgArmyStdDev );
		// 	mTMTeamAiController.IssueMoveCommand( mTMTeamAiController.knowledge.GetMyPawns(), armySmartLocation );
		// 	mTMTeamAiController.SetTimer(CENTER_DURATION, false, NameOf(EndRecenter), self);
		// 	mIsRecentering = true;
		// }
		// Check if our army is potentially stuck
		else if ( mKnowledge.GetCurrentTime() - mMoveStartTime > DURATION_UNTIL_BUDGE )
		{
			// Only budge if our army's smart center hasn't moved far enough (AKA we're probably stuck)
			if( VSize( mMoveStartLocation - mCurrentArmyLocation ) < MAX_DISTANCE_FOR_BUDGE )
			{
				mTMTeamAiController.Log( "TMBehaviorHelper: INITIATE BUDGE! I think we're stuck." );
				mMoveStartTime = mKnowledge.GetCurrentTime();
				mTMTeamAiController.MoveToSafeLocation();
				mTMTeamAiController.SetTimer(BUDGE_DURATION, false, NameOf(EndBudge), self);
				mIsBudging = true;
			}
			else
			{
				mMoveStartLocation = mCurrentArmyLocation;
				mMoveStartTime = mKnowledge.GetCurrentTime();
			}
		}
	}
}

function EndRecenter()
{
	MoveArmyToLocation(mTargetMoveLocation, mTargetMoveRange);
	mIsRecentering = false;
}

function EndBudge()
{
	mTMTeamAiController.Log( "TMBehaviorHelper: END BUDGE!" );
	MoveArmyToLocation(mTargetMoveLocation, mTargetMoveRange);
	mIsBudging = false;
}

/* MoveArmyToLocation
	inTargetRange - distance from target before it's considered reached
	Called by a TMBehavior to move the entire army to a location.
	Calls "NotifyMoveComplete" on the current TMBehavior when it reaches the destination.
*/
function MoveArmyToLocation( Vector inLocation, float inTargetRange = 250 )
{
	local array< TMPawn > pawnList;
	pawnList = mTMTeamAiController.knowledge.GetMyPawns();

	mTMTeamAiController.Log( "TMHelper::MoveArmyToLocation() starting move with " $ pawnList.Length $ " pawns. (" $ mTMBehavior.GetName() $ ")" );

	mIsMovingToLocation = true;
	mTargetMoveLocation = inLocation;
	mTargetMoveRange 	= inTargetRange;
	mMoveStartTime      = mKnowledge.GetCurrentTime();
	mMoveStartLocation 	= mCurrentArmyLocation;

	mTMTeamAiController.Log("TMHelper::MoveArmyToLocation() move is " $ VSize(inLocation - mMoveStartLocation) $ " away. (" $ mTMBehavior.GetName() $ ")");

	mTMTeamAiController.IssueMoveCommand( pawnList, inLocation );

	// Reissue this move command on a timer
	mTMTeamAiController.SetTimer(REISSUE_MOVE_INTERVAL, false, 'ReissueMoveCommand', self);
}

function ReissueMoveCommand()
{
	MoveArmyToLocation(mTargetMoveLocation, mTargetMoveRange);
}

function bool IsRecoveringFromBadMove()
{
	return mIsRecentering || mIsBudging;
}

// BOT TODO: rename this and make it correct
function bool IsArmyLocationInRange( Vector inArmyLocation, Vector inLocation, float inRange )
{
	local float sqRange;
	sqRange = inRange * inRange;
	return (sqRange >= VSizeSq( inLocation - inArmyLocation ));
}

function bool IsArmyInRange(Vector inLocation, float inRange)
{
	return IsArmyLocationInRange(mCurrentArmyLocation, inLocation, inRange);
}

function Vector GetClosestLocation( Vector inOriginLocation, array<Vector> inLocationList, float inMaxFuzz = 0 )
{
	local int i;
	local Vector tempLocation, closestLocation;
	local float tempDist, closestDist;

	closestLocation = inLocationList[0];
	closestDist = VSizeSq( closestLocation - inOriginLocation );
	closestDist = FuzzValue( closestDist, inMaxFuzz );

	for( i = 1; i < inLocationList.Length; i++ )
	{
		tempLocation = inLocationList[i];
		tempDist = VSizeSq( tempLocation - inOriginLocation );
		tempDist = FuzzValue( tempDist, inMaxFuzz );

		if( tempDist < closestDist )
		{
			closestLocation = tempLocation;
			closestDist = tempDist;
		}
	}

	return closestLocation;
}

function Vector GetClosestLocationNotInRadius( Vector inOriginLocation, array<Vector> inLocationList, Vector inOrigin2, float inRadius )
{
	local int i;
	local Vector tempLocation, closestLocation;
	local float tempDist, closestDist;

	closestDist = 999999999; 	// God help us

	for( i = 0; i < inLocationList.Length; i++ )
	{
		tempLocation = inLocationList[ i ];
		tempDist = VSize( tempLocation - inOriginLocation );

		if( tempDist < closestDist )
		{
			// Also make sure it's not in the radius
			if( VSize( tempLocation - inOrigin2 ) > inRadius )
			{
				closestLocation = tempLocation;
				closestDist = tempDist;
			}
		}
	}

	return closestLocation;
}

function TMPlayerReplicationInfo GetClosestEnemy( Vector inMyLocation, Array<TMPlayerReplicationInfo> inEnemyTMPRIs, float inMaxFuzz = 0 )
{
	local int i;
	local TMPlayerReplicationInfo tempEnemy, closestEnemy;
	local float tempDist, closestDist;

	closestEnemy = inEnemyTMPRIs[0];
	closestDist = VSizeSq( class'UDKRTSPawn'.static.SmartCenterOfGroup( closestEnemy.m_PlayerUnits ) - inMyLocation );
	closestDist = FuzzValue( closestDist, inMaxFuzz );

	for( i = 1; i < inEnemyTMPRIs.Length; i++ )
	{
		tempEnemy = inEnemyTMPRIs[i];
		tempDist = VSizeSq( class'UDKRTSPawn'.static.SmartCenterOfGroup( tempEnemy.m_PlayerUnits ) - inMyLocation );
		tempDist = FuzzValue( tempDist, inMaxFuzz );

		if( tempDist < closestDist )
		{
			closestEnemy = tempEnemy;
			closestDist = tempDist;
		}
	}

	return closestEnemy;
}

/* FuzzValue
	Takes a value and randomly increases/decreases it by an amount less than or equal to maxFuzz.

	inValue: value to fuzz
	inMaxFuzz: the largest percentage that the value can fuzz. 0.1f means the value will become up to 10% larger or smaller
*/
static function float FuzzValue( float inValue, float inMaxFuzz = 0.2f )
{
	local float percentageOfFuzz; 	// how much of our fuzz we'll use
	local int percentageVariance; 	// how many possible values our random value can be
	local float fuzzAmount;

	percentageVariance = 1000;
	percentageOfFuzz = rand( percentageVariance*2 );
	percentageOfFuzz -= percentageVariance; 	// percentage of fuzz is now between [-percentageVariance, percentageVariance]
	percentageOfFuzz /= percentageVariance; 	// now is a percentage between [-1, 1]

	fuzzAmount = inMaxFuzz * percentageOfFuzz;

	return inValue + inValue*fuzzAmount;
}

/* RemoveLocationsFromList
	Returns locationsList but with any locations in locationsToRemove removed from the list.
*/
function array<Vector> RemoveLocationsFromList(array<Vector> locationsToRemove, array<Vector> locationsList)
{
	local Vector iterLocation;
	local int i;

	// Check each location to remove and see if it matches one in our locations list
	foreach locationsToRemove(iterLocation)
	{
		for( i=locationsList.Length-1; i >= 0; i-- )
		{
			if( iterLocation.X == locationsList[i].X &&
				iterLocation.Y == locationsList[i].Y &&
				iterLocation.Z == locationsList[i].Z )
			{
				locationsList.Remove(i, 1);
			}
		}
	}

	return locationsList;
}

function array<Vector> GetLocationsInRange( Vector inOriginLocation, array<Vector> inLocationList, int inRange )
{
	local Vector tempLocation;
	local float tempDist;
	local array<Vector> returnLocations;
	local int sqRange;

	sqRange = inRange*inRange;

	foreach inLocationList( tempLocation )
	{
		tempDist = VSizeSq( tempLocation - inOriginLocation );

		if( tempDist < sqRange )
		{
			returnLocations.AddItem(tempLocation);
		}
	}

	return returnLocations;
}

/* MakeWeightedSelection
	Randomly selects an index from the array, where the array is a a list of weights.

	if inWeights was [1, 2, 3, 94], index 0 would have a 1% chance of being returned, while index 3 has 94% chance.
		NOTE: weights can sum over 100, this is just an example. Also there can be duplicate weights.

	Returns index of the weight which was selected.

	weightExponent will increase weights by an exponential factor, effectively making large weights selected more frequently.

	CREDIT: https://medium.com/@peterkellyonline/weighted-random-selection-3ff222917eb6
*/
function int MakeWeightedSelection(array<int> inWeights, optional float inWeightExponent=1)
{
	local int randomWeight, sumOfWeights;
	local int i;

	if(inWeights.Length == 0)
	{
		`warn("MakeWeightedSelection() empty array passed in.");
		return -1;
	}

	// Scale each weight by the exponent
	for(i=0; i < inWeights.Length; i++)
	{
		inWeights[i] = inWeights[i] ** inWeightExponent;
	}

	// Get the sum of the weights
	sumOfWeights = 0;
	for(i=0; i < inWeights.Length; i++)
	{
		if(inWeights[i] < 0)
		{
			inWeights[i] = 0;
		}

		sumOfWeights = sumOfWeights + inWeights[i];
	}

	// Pick our random weight to target (between 1 and the sum, hence add 1 to the result)
	randomWeight = rand(sumOfWeights) + 1;

	// Do the weighted selection
	for(i=0; i < inWeights.Length; i++)
	{
		randomWeight = randomWeight - inWeights[i];

		if(randomWeight <= 0)
		{
			return i;
		}
	}

	`warn("MakeWeightedSelection() didn't select a weight. Maybe all the weights were zero or less? Returning random index.");
	return Rand(inWeights.Length);
}

/* SelectNearestLocation
	Uses weighted selection to decide a location.
*/
function Vector SelectNearestLocation(Vector inOrigin, float inFalloffRadius, array<Vector> inLocations)
{
	local float distance, weight;
	local array<int> weights;
	local Vector iterLocation;
	local int selectedIndex;

	foreach inLocations(iterLocation)
	{
		distance = VSize(iterLocation - inOrigin);
		weight = inFalloffRadius - distance;
		weights.AddItem( weight );
	}

	if( weights.Length != inLocations.Length )
	{
		`warn("SelectNearestLocation() weights list doesn't match locations list size.");
		return inLocations[0];
	}

	selectedIndex = MakeWeightedSelection(weights, mTMTeamAiController.mWeightExponent);

	return inLocations[selectedIndex];
}

/* SelectNearestLocationWithScalars
	Uses weighted selection to choose a location, but additionally scales the weights by a scalar.

	This function is a little ugly right now. Want to figure out the best way to handle multiple weight scalars.
*/
function Vector SelectNearestLocationWithScalars(Vector inOrigin, float inFalloffRadius, float inMinimumDistance, array<Vector> inLocations1, float weight1, array<Vector> inLocations2, float weight2, array<Vector> inLocations3, float weight3)
{
	local array<Vector> newLocationsList;
	local array<int> weights;
	local float distance, weight;
	local Vector iterLocation;
	local int selectedIndex;

	foreach inLocations1(iterLocation)
	{
		newLocationsList.AddItem(iterLocation);
		distance = VSize(iterLocation - inOrigin);

		if(distance > inMinimumDistance)
		{
			weight = inFalloffRadius - distance;
			weights.AddItem( weight*weight1 );
		}
	}

	foreach inLocations2(iterLocation)
	{
		newLocationsList.AddItem(iterLocation);
		distance = VSize(iterLocation - inOrigin);

		if(distance > inMinimumDistance)
		{
			weight = inFalloffRadius - distance;
			weights.AddItem( weight*weight2 );
		}
	}

	foreach inLocations3(iterLocation)
	{
		newLocationsList.AddItem(iterLocation);
		distance = VSize(iterLocation - inOrigin);

		if(distance > inMinimumDistance)
		{
			weight = inFalloffRadius - distance;
			weights.AddItem( weight*weight3 );
		}
	}

	if( weights.Length == 0 )
	{
		`warn("Now locations in weights list! Return first item.");
		return newLocationsList[0];
	}

	selectedIndex = MakeWeightedSelection(weights, mTMTeamAiController.mWeightExponent);

	return newLocationsList[selectedIndex];
}

function JsonObject LoadBehaviorJsonObject(string inBehaviorJsonName)
{
	local string filePath;
	local string jsonString;
	local TMJsonParser jsonParser;
	local JsonObject json;

	filePath = "BotBehaviors\\" $ inBehaviorJsonName $ ".json";
	jsonParser = new class'TMJsonParser';
	jsonString = jsonParser.LoadJsonString(filePath);
    json = class'JsonObject'.static.DecodeJson( jsonString );

    return json;
}

/* LoadFloatFromJson
	Figures out which value we should grab from a behavior json, given our bot's selected difficulty.
	We need this because sometimes our selected difficulty won't have settings for a specific behavior, and will revert to default.
*/
function float LoadFloatFromBehaviorJson(string inKey, JsonObject inJson)
{
	local JsonObject innerJson;

	// Try loading our inner json for our selected difficulty
	innerJson = inJson.GetObject(mTMTeamAiController.mBotDifficulty);
	if( innerJson.HasKey(inKey) )
	{
		return innerJson.GetFloatValue(inKey);
	}

	// We don't have that entry for the difficulty, so just grab the default
	innerJson = inJson.GetObject("default");
	if( innerJson.HasKey(inKey) )
	{
		return innerJson.GetFloatValue(inKey);
	}

	`warn("Couldn't find entry for '" $ inKey $ "' in behavior JSON");
	return 0;
}

function float LoadIntFromBehaviorJson(string inKey, JsonObject inJson)
{
	local JsonObject innerJson;

	// Try loading our inner json for our selected difficulty
	innerJson = inJson.GetObject(mTMTeamAiController.mBotDifficulty);
	if( innerJson.HasKey(inKey) )
	{
		return innerJson.GetIntValue(inKey);
	}

	// We don't have that entry for the difficulty, so just grab the default
	innerJson = inJson.GetObject("default");
	if( innerJson.HasKey(inKey) )
	{
		return innerJson.GetIntValue(inKey);
	}

	`warn("Couldn't find entry for '" $ inKey $ "' in behavior JSON");
	return 0;
}

function bool LoadBoolFromBehaviorJson(string inKey, JsonObject inJson)
{
	local JsonObject innerJson;

	// Try loading our inner json for our selected difficulty
	innerJson = inJson.GetObject(mTMTeamAiController.mBotDifficulty);
	if( innerJson.HasKey(inKey) )
	{
		return innerJson.GetBoolValue(inKey);
	}

	// We don't have that entry for the difficulty, so just grab the default
	innerJson = inJson.GetObject("default");
	if( innerJson.HasKey(inKey) )
	{
		return innerJson.GetBoolValue(inKey);
	}

	`warn("Couldn't find entry for '" $ inKey $ "' in behavior JSON");
	return false;
}

DefaultProperties
{
	DURATION_UNTIL_BUDGE = 5
	BUDGE_DURATION = 1
	MAX_DISTANCE_FOR_BUDGE = 500
	REISSUE_MOVE_INTERVAL = 1
}
