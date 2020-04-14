class TMKA_DoNeutralAttack extends SequenceAction;

var string attackerSpawnPointName;
var string targetSpawnPointName;

event Activated()
{
	local TMPlayerController pc;
	local TMNeutralSpawnPoint tempSpawnPoint;
	local TMNeutralSpawnPoint attackerSpawnPoint;
	local TMNeutralSpawnPoint targetSpawnPoint;
	local TMPawn attacker;
	local TMPawn target;
	local TMStopFE stopFE;
	local TMAttackFE attackFE;


	// Make sure didn't get empty strings for spawn points
	if( Len( attackerSpawnPointName ) == 0 ) {
		`log( "TMKA_DoNeutralAttack::Activated() got empty attackerSpawnPointName." );
		return;
	}
	if( Len( targetSpawnPointName ) == 0 ) {
		`log( "TMKA_DoNeutralAttack::Activated() got empty targetSpawnPointName." );
		return;
	}


	// Find our attacker and target spawn points
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());
	foreach pc.AllActors(class'TMNeutralSpawnPoint', tempSpawnPoint)
	{
		if( attackerSpawnPoint == none &&
		 	tempSpawnPoint.Name == Name(attackerSpawnPointName) )
		{
			attackerSpawnPoint = tempSpawnPoint;
		}

		if( targetSpawnPoint == none &&
			tempSpawnPoint.Name == Name(targetSpawnPointName) )
		{
			targetSpawnPoint = tempSpawnPoint;
		}

		if( attackerSpawnPoint != none && targetSpawnPoint != none )
		{
			break;
		}
	}

	// Make sure we found a spawn point
	if( attackerSpawnPoint == none ) {
		`log( "TMKA_DoNeutralAttack::Activated() Couldn't find attackerSpawnPoint: " $ attackerSpawnPointName );
		return;
	}
	if( targetSpawnPoint == none ) {
		`log( "TMKA_DoNeutralAttack::Activated() Couldn't find targetSpawnPointName: " $ targetSpawnPointName );
		return;
	}
	

	attacker = attackerSpawnPoint.mPawnHolden;
	target = targetSpawnPoint.mPawnHolden;

	if( attacker == none ) {
		`log( "TMKA_DoNeutralAttack::Activated() missing mPawnHolden on attackerSpawnPoint: " $ attackerSpawnPointName );
		return;
	}
	if( target == none ) {
		`log( "TMKA_DoNeutralAttack::Activated() missing mPawnHolden on targetSpawnPoint: " $ targetSpawnPointName );
		return;
	}


	// Prevent attacks that are too far (in the tutorial some attacks are too far and break the intro)
	if( !attacker.IsPointInRange2D( target.Location, 500 ) ) {
		`log( "TMKA_DoNeutralAttack::Activated() got target that was too far. attackerSpawnPoint: " $ attackerSpawnPointName $ " Attacker: " $ attacker.name $ " targetSpawnPoint: " $ targetSpawnPointName $ " and target: " $ target.name );
		return;
	}

	attacker.OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', 5000000);
	target.OccludedMatInst.SetScalarParameterValue('MinOcclusionDepth', 5000000);

	stopFE = class'TMStopFE'.static.create(attacker.pawnId);
	attackFE = class'TMAttackFE'.static.create(target, attacker.pawnId);

	attacker.SendFastEvent(stopFE);
	attacker.SendFastEvent(attackFE);

	// Prevent animations or this state from being interrupted
	attacker.UpdateUnitState( TMPS_JUGGERNAUT );
}

DefaultProperties
{
	ObjName="DoNeutralAttack"
	ObjCategory="TheMaestros"

	VariableLinks.Empty
	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="Attacker Spawn Point Name", PropertyName=attackerSpawnPointName)
	VariableLinks(1) = (ExpectedType=class'SeqVar_String', LinkDesc="Target Spawn Point Name", PropertyName=targetSpawnPointName)
}
