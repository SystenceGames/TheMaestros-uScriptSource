/* TM_TEMP_PlayerNamesList
	Keeps track of all players who are in a match before it starts.

	NOTE: using this as a fix to make sure we don't completely break things before the saturday playtest.
	We should try checking for TMControllers instead of the TMPRIs at TMGameInfo::CreateEndGamePlayerStats()
*/
class TM_TEMP_PlayerNamesList extends Object;

var array<string> playerNames;
