/* TMCommands
	Contains all the various command strings we pass all through fast events.

	Examples:
		"C_Attack"
		"C_Stop"

	To reference a command use the following:
	class'TMCommands'.default.COMMAND_NAME
*/

class TMCommands extends Object;


///// All of our COMMANDS /////
var const string ATTACK;
var const string MOVE;
var const string AI_MOVE;
var const string STOP_MOVE;
var const string RESUME_ATTACK_MOVE;


///// Assign strings for each of our commands /////
DefaultProperties
{
	ATTACK = "C_Attack";
	MOVE = "C_Move";
	AI_MOVE = "C_AI_Move";
	STOP_MOVE = "C_Stop_Move";
	RESUME_ATTACK_MOVE = "C_Resume_Attack_Move";
}
