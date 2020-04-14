class TMTeamInfo extends UDKRTSTeamInfo;

var TMAllyInfo allyInfo;

function KilledBy( pawn EventInstigator )
{
	`log('KilledBy');
	Super.KilledBy(EventInstigator);
}

function Spawned()
{
	
}

DefaultProperties
{
}
