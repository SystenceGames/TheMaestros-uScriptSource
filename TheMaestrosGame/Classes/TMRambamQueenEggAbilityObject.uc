/* TMRambamQueenEgg
	Spawns rambam queen eggs when it hits.
*/
class TMRambamQueenEggAbilityObject extends TMAbilityObject;

var TMPlayerReplicationInfo mPlayerReplicationInfo;

var float mPushbackRadius;
var float mPushbackPower;

var array<TMPawn> mEggsList;


static function TMRambamQueenEggAbilityObject Create( TMAbilityHelper inAbilityHelper, TMPlayerReplicationInfo inTMPlayerRepInfo, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, Vector inLocation, float inRadius, float inPushbackPower )
{
	local TMRambamQueenEggAbilityObject object;
	object = new class'TMRambamQueenEggAbilityObject'();
	object.mPlayerReplicationInfo = inTMPlayerRepInfo;
	object.Setup( inAbilityHelper, inTMPC, inAllyID, inPlayerID, inTeamColorIndex, inLocation, inRadius );
	object.mPushbackRadius = inRadius;
	object.mPushbackPower = inPushbackPower;
	return object;
}

function Start()
{
	local TMPawn newUnit;
	local int i;

	m_TMPC.m_RamBamQueenEggAbilityObjects.AddItem( self );

	if( m_TMPC.IsAuthority() )
	{
		// Spawn 3 eggs
		for( i = 0; i < 3; i++ )
		{
			newUnit = TMGameInfo(m_TMPC.WorldInfo.Game).RequestUnit("EggSpecial", mPlayerReplicationInfo, m_Location, false, m_Location, None, false);
			newUnit.SendFastEvent(class'TMFastEventSpawn'.static.create(newUnit.pawnId, newUnit.Location, true));
			newUnit.SendFastEvent(class'TMEggSetupFE'.static.create(newUnit.pawnId, "RamBamSpecial"));
			mEggsList.AddItem( newUnit );
		}
	}

	m_AbilityHelper.DoKnockbackInRadius( mPushbackRadius, mPushbackPower, m_Location );

	super.Start();
}

function Stop()
{
	local TMPawn egg;

	m_TMPC.m_RamBamQueenEggAbilityObjects.RemoveItem( self );

	foreach mEggsList( egg )
	{
		egg.Destroy();
	}

	super.Stop();
}
