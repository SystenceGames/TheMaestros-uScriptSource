class TMNeutralSpawnPoint extends NavigationPoint
	placeable
	ClassGroup(Common)
	hidecategories(Collision);

var() string mSpawnType;
var() float mInitialRotation;
var TMPawn mPawnHolden;
var() bool mShouldSpawnBaseUnits;

DefaultProperties
{
	mShouldSpawnBaseUnits = true;
}