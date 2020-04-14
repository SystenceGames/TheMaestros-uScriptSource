class TMEndGameStats extends Object;

var int numPlayers;
var string playerNames[6];
var string commanderTypes[6];
var string race[6];
var int allyid[6];
var int isBot[6];

var int kills[6];
var int deaths[6];
var int assists[6];

var int unitsCreated[6];
var int unitsKilled[6];

var int doughboy[6];
var int oiler[6];
var int splitter[6];
var int conductor[6];
var int sniper[6];
var int skybreaker[6];

var int disruptor[6];
var int grappler[6];
var int rambam[6];
var int vinecrawler[6];
var int turtle[6];
var int regenerator[6];

var bool victory;
var string mapName;
var string gameTime;

function save(string playerName)
{
	local string gameStatsSaveFile;

	gameStatsSaveFile = "GameStats"$playerName$".bin";
	if (!class'Engine'.static.BasicSaveObject(self, gameStatsSaveFile, false, 0))
	{
		`warn("Didn't save game stats to "$gameStatsSaveFile);
	}
}

DefaultProperties
{
}
