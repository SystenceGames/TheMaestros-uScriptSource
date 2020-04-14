class TMFOWRevealActor extends Actor
	placeable;

var TMFOWManager mFowManager;
var() int allyId;
var() int sightRadiusTiles;
var() repnotify bool bApplyFogOfWar;

var bool uninterruptibleSight;
var bool shouldCacheVisibleTiles; /** This is only for reveal actors that don't move */
var private array<BytePoint> cachedVisibleTiles; /** This is only for reveal actors that don't move */

simulated function Setup(int allyIndex, TMFOWManager fowManager, int sightRangeInTiles, bool _uninterruptible = false, bool shouldCacheVisibileTiles = false)
{
	sightRadiusTiles = sightRangeInTiles;
	uninterruptibleSight = _uninterruptible;
	allyId = allyIndex;
	mFowManager = fowManager;
	self.shouldCacheVisibleTiles = shouldCacheVisibileTiles;

	mFowManager.AddRevealActor(self);
}

simulated event Destroyed()
{
	mFowManager.RemoveRevealActor(self);
}

simulated function array<BytePoint> getCachedTiles()
{
	return cachedVisibleTiles;
}

simulated function setCachedTiles(array<BytePoint> visibleTiles)
{
	if (!shouldCacheVisibleTiles)
	{
		return;
	}

	self.cachedVisibleTiles = visibleTiles;
}

DefaultProperties
{
	allyId = -2;
	bNoDelete=true;
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor'
		HiddenGame=TRUE
		AlwaysLoadOnClient=FALSE
		AlwaysLoadOnServer=FALSE
		SpriteCategoryName="Info"
	End Object
	Components.Add(Sprite)
	uninterruptibleSight = false
	shouldCacheVisibleTiles = false
	bApplyFogOfWar=true;
}
