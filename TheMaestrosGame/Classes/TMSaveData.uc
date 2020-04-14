class TMSaveData extends Object;

var bool basicTutStarted;
var bool basicTutComplete;
var bool advancedTutStarted;
var bool advancedTutComplete;
var bool battleStarted;
var bool battleCompleted;
var bool alchemistStarted;
var bool alchemistCompleted;
var bool justCompletedTutorial;

const SAVE_FILE_NAME = "SaveData.bin";


function SaveFile() {
	local bool wasSuccessful;
	wasSuccessful = class'Engine'.static.BasicSaveObject(self, SAVE_FILE_NAME, true, 1);

	if( !wasSuccessful ) {
		`warn( "TMSaveData::SaveFile() could not save file!" );
	}
	`log( "Saved game." );
	PrintSaveData();
}


static function TMSaveData LoadFile() {
	local TMSaveData data;
	local bool wasSuccessful;
	
	data = new class'TMSaveData'();
	wasSuccessful = class'Engine'.static.BasicLoadObject(data, SAVE_FILE_NAME, true, 1);

	if( !wasSuccessful ) {
		`warn( "TMSaveData::SaveFile() could not load save file!" );
	}
	`log( "Loaded save." );
	data.PrintSaveData();

	return data;
}


///// Set Functions w/ Save /////

function SetBasicTutorialStarted() {
	`log( "TMSaveData::BasicTutorialStarted()" );
	basicTutStarted = true;
	SaveFile();
}

function SetAdvancedTutorialStarted() {
	`log( "TMSaveData::SetAdvancedTutorialStarted()" );
	advancedTutStarted = true;
	SaveFile();
}

function SetBattleStarted() {
	`log( "TMSaveData::SetBattleStarted()" );
	battleStarted = true;
	battleCompleted = false; 	// battle is no longer completed. Need to track this way so we can tell when a player is leaving battle practice
	SaveFile();
}

/* DidJustCompleteBattlePractice()
	Returns true if the user just completed a battle practice.

	This function will only return true once until 'battleCompleted' is updated again.
*/
function bool DidJustCompleteBattlePractice() {
	if( battleCompleted )
	{
		battleCompleted = false;
		SaveFile();
		return true;
	}

	return false;
}

function SetAlchemistStarted() {
	`log( "TMSaveData::SetAlchemistStarted()" );
	alchemistStarted = true;
	SaveFile();
}

// Checks if any tutorials are in progress, and marks them as complete
function CompletedTutorial() {
	if( basicTutStarted ) {
		basicTutStarted = false;
		basicTutComplete = true;
		justCompletedTutorial = true;
	}
	if( advancedTutStarted ) {
		advancedTutStarted = false;
		advancedTutComplete = true;
		justCompletedTutorial = true;
	}
	if( battleStarted ) {
		battleStarted = false;
		battleCompleted = true;
		justCompletedTutorial = true;
	}
	if( alchemistStarted ) {
		alchemistStarted = false;
		alchemistCompleted = true;
		justCompletedTutorial = true;
	}

	SaveFile();
}

function ClearJustCompletedTutorial() {
	`log( "TMSaveData::ClearJustCompletedTutorial()" );
	justCompletedTutorial = false;
	SaveFile();
}

function ClearInProgressTutorials() {
	`log( "TMSaveData::ClearInProgressTutorials()" );
	basicTutStarted = false;
	advancedTutStarted = false;
	battleStarted = false;
	alchemistStarted = false;
}

function ResetSave() {
	basicTutStarted = false;
	basicTutComplete = false;
	advancedTutStarted = false;
	advancedTutComplete = false;
	battleStarted = false;
	battleCompleted = false;
	alchemistStarted = false;
	alchemistCompleted = false;
	justCompletedTutorial = false;
	SaveFile();
}

function PrintSaveData() {
	`log( "TMSaveData from " 		$ SAVE_FILE_NAME );
	`log( "basicTutStarted: " 		$ basicTutStarted );
	`log( "basicTutComplete: " 		$ basicTutComplete );
	`log( "advancedTutStarted: " 	$ advancedTutStarted );
	`log( "advancedTutComplete: " 	$ advancedTutComplete );
	`log( "battleStarted: " 		$ battleStarted );
	`log( "battleCompleted: " 		$ battleCompleted );
	`log( "alchemistStarted: " 		$ alchemistStarted );
	`log( "alchemistCompleted: " 	$ alchemistCompleted );
	`log( "justCompletedTutorial: " $ justCompletedTutorial );
}
