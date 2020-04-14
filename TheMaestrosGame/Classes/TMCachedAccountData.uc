class TMCachedAccountData extends Object;

var string accountName;

const SAVE_FILE_NAME = "Account.bin";


function SaveFile() {
	local bool wasSuccessful;
	wasSuccessful = class'Engine'.static.BasicSaveObject(self, SAVE_FILE_NAME, true, 1);

	if( !wasSuccessful ) {
		`warn( "TMCachedAccountData::SaveFile() could not save file!" );
	}
}

static function TMCachedAccountData LoadFile() {
	local TMCachedAccountData data;
	local bool wasSuccessful;
	
	data = new class'TMCachedAccountData'();
	wasSuccessful = class'Engine'.static.BasicLoadObject(data, SAVE_FILE_NAME, true, 1);

	if( !wasSuccessful ) {
		`warn( "TMCachedAccountData::LoadFile() could not load file!" );
	}

	return data;
}
