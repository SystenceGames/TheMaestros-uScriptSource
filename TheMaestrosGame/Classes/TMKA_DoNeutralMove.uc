// extend UIAction if this action should be UI Kismet Action instead of a Level Kismet Action
class TMKA_DoNeutralMove extends SequenceAction;

var() string inSpawnPointName;
var int inX;
var int inY;

event Activated()
{
	local Vector destination;
	local TMMoveFE lMoveFE;
	local TMStopFE lStopFE;
	local TMPlayerController pc;
	local TMNeutralSpawnPoint inSpawnPoint;
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	foreach pc.AllActors(class'TMNeutralSpawnPoint', inSpawnPoint)
	{
		if(inSpawnPoint.Name == Name(inSpawnPointName))
		{
			break;
		}
	}

	if ( inSpawnPoint.mPawnHolden == None )
	{
		`log("InSpawnPoint.mPawnHolden was None in TMKA_DoNeutralMove.Activated()", true, 'dru');
		return;
	}

	destination.X = inX;
	destination.Y = inY;
	destination.Z = inSpawnPoint.mPawnHolden.Location.Z;

	lMoveFE = class'TMMoveFE'.static.create(destination, false, inSpawnPoint.mPawnHolden.pawnId);
	lStopFE = class'TMStopFE'.static.create(inSpawnPoint.mPawnHolden.pawnId);
	inSpawnPoint.mPawnHolden.SendFastEvent(lStopFE);
	inSpawnPoint.mPawnHolden.SendFastEvent(lMoveFE);
}

defaultproperties
{
	ObjName="DoNeutralMove"
	ObjCategory="TheMaestros"

	VariableLinks.Empty
	VariableLinks(0) = (ExpectedType=class'SeqVar_Int', LinkDesc="X", PropertyName=inX)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Int', LinkDesc="Y", PropertyName=inY)
	VariableLinks(2) = (ExpectedType=class'SeqVar_String', LinkDesc="Neutral Spawn Point Name", PropertyName=inSpawnPointName)
}
