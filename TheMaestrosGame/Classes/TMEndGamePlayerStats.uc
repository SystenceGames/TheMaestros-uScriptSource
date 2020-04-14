class TMEndGamePlayerStats extends Object;

var string playerName;
var int currentExperience;
var int currentLevel;
var int gamesPlayed;
var int experienceForNextLevel;
var int experienceGained;
var int nextUnlockAt;
var array<string> unlockedItems;

function DeserializeFromJson( JsonObject inJson )
{
	local string tempItem;
	local JsonObject unlocksJson;

	playerName = inJson.GetStringValue("playerName");
	currentLevel = inJson.GetIntValue("currentLevel");
	currentExperience = inJson.GetIntValue("currentXP");
	experienceGained = inJson.GetIntValue("xpDelta");
	experienceForNextLevel = inJson.GetIntValue("xpForNextLevel");
	gamesPlayed = inJson.GetIntValue("gamesPlayed");
	nextUnlockAt = inJson.GetIntValue("nextUnlockableLevel");

	unlocksJson = inJson.GetObject( "lastUnlockedItemIds" );
	if( unlocksJson != none ) {
		foreach unlocksJson.ValueArray( tempItem ) {
			unlockedItems.AddItem( tempItem );
		}
	}
}

DefaultProperties
{
}
