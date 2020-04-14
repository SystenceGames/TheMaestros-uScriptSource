class SFMFrontEndLoading extends SFMFrontEnd;

function bool Start(optional bool startPaused = false) {
	local bool retVal;
	local string mapName;
	local string typeName;
	retVal = super.Start(startPaused);
	SetMotD(myPC.MotD);
	CurrentMenu = "Loading";
	
	mapName = myPC.mapToLoad;
	`log("Now loading: " $ myPC.mapToLoad);

	if (Len(mapName) == 0) {
		mapName = "unknown";
	}


	//this if-block exists to default and prevent crashes in case new maps are added in the future and the loading screen isn't updated
	if (mapName == "Crater") {
		mapName = "crater";
	} else if (mapName == "Fissure") {
		mapName = "fissure";
	} else if (mapName == "SacredArena") {
		mapName = "sacred";
	} else if (mapName == "Terra") {
		mapName = "terra";
	} else if (mapName == "SunsetIsle") {
		mapName = "sunset";
	} else {
		mapName = "unknown";
		GetVariableObject("root").GetObject("errorText").SetVisible(true);
		GetVariableObject("root").GetObject("loadingAnim").SetVisible(false);
		GetVariableObject("root").GetObject("tooltipText").SetVisible(false);
	}
	
	if (mapName != "unknown" ) {
		if (myPC.gameTypeToLoad == "TheMaestrosGame.TMRoundBasedGameInfo") {
			typeName = "Round";
		} else if (myPC.gameTypeToLoad == "TheMaestrosGame.TMDMGameInfo") {
			typeName = "Tdm";
		} else if (myPC.gameTypeToLoad == "TheMaestrosGame.TMNexusCommandersGameInfo") {
			typeName = "NexusCommanders";
		} else {
			typeName = "Stock";
		}
	}
	
	//`log(mapName $ " " $ typeName, true, 'Mark');
	GetVariableObject("root").GetObject(mapName $ typeName).SetVisible(true);

	//GetVariableObject("root").GetObject("background" $ int(RandRange(0, 5))).SetVisible(true);

	if(!bIsSpecLoading) {
		bIsSpecLoading = true;
	}

	LoadTooltip();

	return retVal;
}

function SetMotD(string motd) {
	GetVariableObject("root").GetObject("motdText").SetText(motd);
}

function SetError(string error) {
	local string preText;
	if(error != "")
		preText = "ERROR: ";
	GetVariableObject("root").GetObject("errorText").SetText(preText $ error);
}

function SetTooltip(string tooltip) {
	GetVariableObject("root").GetObject("tooltipText").SetText(tooltip);
}

private function JsonObject LoadTooltipJSON() {
	local string filePath;
	local string jsonString;
	local TMJsonParser jsonParser;
	local JsonObject json;
	filePath = "GlobalVariables\\Tips.json";

	jsonParser = new class'TMJsonParser';
	jsonString =jsonParser.LoadJsonString(filePath);
    json = class'JsonObject'.static.DecodeJson(  jsonString );
	json = json.GetObject("tips"); //this is what the map name is in bearbuilder
	return json;
}

function LoadTooltip() {
	local JsonObject json;
	local int randomIndex;

	//this json will contain the tooltip
	json = LoadTooltipJson();
	randomIndex = Rand(json.GetIntValue("tipCounts"));
	SetTooltip(Caps(json.GetStringValue(string(randomIndex))));
}

DefaultProperties
{
	MovieInfo=SwfMovie'ScaleformMenuGFx.SFMFrontEnd.SF_LoadingGeneric'
}
