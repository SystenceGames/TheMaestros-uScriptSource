class TMPlayerReplicationInfo extends UDKRTSPlayerReplicationInfo;

var repnotify TMAllyInfo allyInfo;
var repnotify int allyId;
var repnotify Bool bIsCommanderDead;
var repnotify int mTeamColorIndex;
var bool mIsBot;
var string commanderType; // replicated, but not notified
var string race;
var repnotify string raceUnitNames[6];
var TMUnit raceUnitArray[6];
var repnotify int UnitsPerNeutral;
var repnotify int mUnitCount[6];
var int mStats[PStats.PS_MAX];
var array<TMPawn> m_PlayerUnits;
var int m_startingUnits;
var string SessionToken;
var float m_firstConflictTime;
var array<float> m_deathTimeArray;
var bool bWon;
var bool bNotRespawning;
var int baseUnitsEarned;

// Temporarily use this to keep track of our current towers in nexus commanders
var array<TMPawn> nexuscommander_current_towers;

struct Antagonist
{
	var TMPlayerReplicationInfo tmpri;
	var float value;
};

var array<Antagonist> Antagonists;

// Replication block
replication
{
	if (bNetDirty)
		allyId, allyInfo, bIsCommanderDead, commanderType, raceUnitNames, mUnitCount, UnitsPerNeutral, race, m_startingUnits, bNotRespawning;
	if (bNetInitial)
		mTeamColorIndex, SessionToken, mIsBot;
}

function DestroyAllMyUnits()
{
	local TMPawn myComparePawn;	

	foreach AllActors(class'TMPawn', myComparePawn)
	{
		if ( myComparePawn.m_owningPlayerId == PlayerID )
		{
			myComparePawn.Destroy();
		}
	}
	Population = 0;
}

function KillAllMyUnits(Controller EventInstigator)
{
	local TMPawn myComparePawn;	

	foreach AllActors(class'TMPawn', myComparePawn)
	{
		if ( myComparePawn.m_owningPlayerId == PlayerID )
		{
			myComparePawn.TakeDamage(1000000, EventInstigator, myComparePawn.Location, myComparePawn.Location, class'DamageType', , self);
		}
	}

	// I want to do this :(  breaks single player in a weird way
	//foreach m_PlayerUnits(myComparePawn)
	//{
	//	myComparePawn.TakeDamage(1000000, Controller(self.Owner), myComparePawn.Location, myComparePawn.Location, class'DamageType', , self);
	//}
}

simulated function SetAntagonist(float DamageTaken, TMPlayerReplicationInfo DamageCausingPlayer) {
	local Antagonist cAntagonist;
	local int i;

	if( DamageCausingPlayer == none )
	{
		return;
	}

	cAntagonist.tmpri = DamageCausingPlayer;

	//cAntagonist.tmpri=TMPlayerReplicationInfo(TMPawn(DamageCauser).OwnerReplicationInfo);

	if(cAntagonist.tmpri == none) {
		return;
	}

	cAntagonist.value=DamageTaken;

	for(i=0; i<self.Antagonists.Length; i++) {
		if(self.Antagonists[i].tmpri == cAntagonist.tmpri) {
			self.Antagonists[i].value=self.Antagonists[i].value + cAntagonist.value;

			setTimer(8.0f, true, NameOf(DecayAntagonists));
			return;
		}
	}

	self.Antagonists.AddItem(cAntagonist);
	setTimer(8.0f, true, NameOf(DecayAntagonists));
}

simulated function ResetAntagonists() {
	local int i;
	for(i=0; i<self.Antagonists.Length; i++) {
			self.Antagonists[i].value=0;
	}
	clearTimer(NameOf(DecayAntagonists));
}

simulated function array<TMPlayerReplicationInfo> AssignAssists(TMPlayerReplicationInfo Killer) {
	local int i;
	local array<TMPlayerReplicationInfo> retval;
	for(i=0; i<self.Antagonists.Length; i++) {
		if(self.Antagonists[i].tmpri != Killer) {
			retval.AddItem(self.Antagonists[i].tmpri);
		}
	}
	return retval;
}

simulated function DecayAntagonists() {
	local int i;
	local int clearedVals;
	clearedVals=0;
	for(i=0; i<self.Antagonists.Length; i++) {
		if(self.Antagonists[i].value > 500.0f) {
			self.Antagonists[i].value=self.Antagonists[i].value-500.0f;
			continue;
		}
		else if(self.Antagonists[i].value > 0) {
			self.Antagonists[i].value=0;
		}
		clearedVals++;
	}

	if(self.Antagonists.Length == clearedVals) {
		clearTimer(NameOf(DecayAntagonists));
		return;
	}
	setTimer(2.0f, true, NameOf(DecayAntagonists));
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'allyInfo')
	{
		// Set the owner replication info
		SetAllyInfo(allyInfo);
	}
	else if (VarName == 'raceUnitNames')
	{
		BuildRaceUnitArray();
	}
	else
	{
		Super.ReplicatedEvent(VarName);		
	}
	
}

simulated function BuildRaceUnitArray()
{
	local array<TMUnit> unitCache;
	local int i;
	local TMUnit unit;

	if (WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone)
	{
		unitCache = TMGameInfo(WorldInfo.Game).unitCache;
	}
	else
	{
		unitCache = TMPlayerController(self.GetALocalPlayerController()).unitCache;
	}

	for (i = 0; i < 6; i++)
	{
		foreach unitCache(unit)
		{
			if (unit.m_UnitName == raceUnitNames[i])
			{
				raceUnitArray[i] = unit;
			}
		}
		if (Len(raceUnitArray[i]) == 0)
		{
			`warn("Unit name not found in cache");
		}
	}
}

simulated function SetAllyInfo(TMAllyInfo newAllyInfo)
{
	
	if (newAllyInfo == None || allyInfo == newAllyInfo)
	{
		return;
	}
	allyInfo = newAllyInfo;
}

simulated function AddPawn(TMPawn Pawn)
{
	// Check if the pawn is within the pawn array already
	if (m_PlayerUnits.Find(Pawn) == INDEX_NONE)
	{
		m_PlayerUnits.AddItem(Pawn);
	}
}

simulated function RemovePawn(TMPawn Pawn)
{
	local int Index;

	Index = m_PlayerUnits.Find(Pawn);
	if (Index != INDEX_NONE)
	{
		// Remove from the pawn array
		m_PlayerUnits.Remove(Index, 1);
	}
}

simulated function string GetRace()
{
	return race;
}

simulated function string GetCommanderName()
{
	local string commanderName;
	commanderName = commanderType;

	// Don't use Rosie as the commander name
	if( commanderName == "Rosie" )
	{
		commanderName = "BlastMeister";
	}

	return commanderName;
}

DefaultProperties
{
	allyId = -1
	commanderType="RoboMeister"
	bIsCommanderDead = false
	m_firstConflictTime = -69;
	NetPriority = 15
	NetUpdateFrequency = 100
	bForceNetUpdate = true
	
	UnitsPerNeutral=1
}
