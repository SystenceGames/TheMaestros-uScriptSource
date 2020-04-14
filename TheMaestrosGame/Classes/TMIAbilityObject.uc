/* TMIAbilityObject
	The interface for all ability objects to follow.
*/
Interface TMIAbilityObject;


// AbilityObjects just need to have a start function
function Start();

// Stops current logic and cleans up the ability object to be removed
function Stop();


function int GetAllyID();

function int GetTeamColorIndex();
