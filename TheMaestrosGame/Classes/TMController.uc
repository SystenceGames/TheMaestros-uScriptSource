interface TMController dependsOn(TMGameInfo);

function TMPlayerReplicationInfo GetTMPRI();

function bool HasDied();

function SetHasDied(bool HasDied);

function string GetCommanderType();

function SetCommanderType(string unitTypeOfCommander);

function TMFOWManager GetFoWManager();

function RespawnIn(float seconds);

function PlayerDied();

function PlayerStarted();

DefaultProperties
{
}
