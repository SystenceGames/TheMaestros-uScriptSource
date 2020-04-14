class TMPlayerProgressionData extends Object;

var string playerName;
var int currentLevel;
var int currentExperience;
var int experienceGained;
var int experienceForNextLevel;
var int gamesPlayed;

function DeserializeFromJson( JsonObject inJson )
{
	playerName = inJson.GetStringValue("playerName");
	currentLevel = inJson.GetIntValue("currentLevel");
	currentExperience = inJson.GetIntValue("currentXP");
	experienceGained = inJson.GetIntValue("xpDelta");
	experienceForNextLevel = inJson.GetIntValue("xpForNextLevel");
	gamesPlayed = inJson.GetIntValue("gamesPlayed");
}
