class TMFOWVisibilityMask extends Object;

/** The tiles the map consists of. A value greater than zero indicates that a tile is visible to the player. */
var array<byte> MapTiles;
var array<BytePoint> VisibleTiles;

/** The map this visibility mask is imposed on. */
var TMFOWMapInfoActor Map;

/** The team this visibility mask manages the vision of. */
var int AllyIndex;

var array<TMFOWRevealActor> mRevealActors;

/** The map tiles to hide in the next update. */
var array<BytePoint> PermanentTilesToHide;

var bool isReady;


/**
 * Initializes this visibility mask, resetting all tiles to hidden.
 * 
 * @param TheMap
 *      the map this visibility mask is imposed on
 * @param AllyId
 *      the team this visibility mask manages the vision of
 */
simulated function Initialize(TMFOWMapInfoActor TheMap, int AllyId)
{
	local TMFOWRevealActor revealActor;

	Map = TheMap;
	MapTiles.Length = Map.NumberOfTilesXY * Map.NumberOfTilesXY;
	AllyIndex = AllyId;

	foreach Map.AllActors(class'TMFOWRevealActor', revealActor)
	{
		if (revealActor.allyId == AllyIndex || revealActor.allyId == -2 )
		{
			mRevealActors.AddItem(revealActor);
		}
	}
}

simulated function PermanentHideMapTiles(array<BytePoint> tiles)
{
	local BytePoint Tile;

	foreach tiles(Tile)
	{
		PermanentTilesToHide.AddItem(Tile);
	}
}

/** Clears this visibility mask. */
simulated function ClearVisibilityMask()
{
	local int iterTileSightIndex;
	MapTiles.Length = 0;
	MapTiles.Length = Map.NumberOfTilesXY * Map.NumberOfTilesXY;
	VisibleTiles.Length = 0;

	foreach Map.tileSightIndicesRetrievedThisTick(iterTileSightIndex)
	{
		Map.sightInfo.tileSights[iterTileSightIndex].retrievedThisTick = 0;
	}
	Map.tileSightIndicesRetrievedThisTick.Length = 0;
}

/**
 * Reveals the passed map tiles spotted by the specified pawn.
 * 
 * @param Tiles
 *      the tiles to reveal on this visibility mask
 * @param Spotter
 *      the pawn that has vision on these tiles
 */
simulated function RevealMapTiles(array<BytePoint> Tiles, TMPawn Spotter)
{
	local BytePoint Tile;
	local int TileIndex;

	if (Spotter.Health > 0)
	{
		foreach Tiles(Tile)
		{
			TileIndex = Tile.Y * Map.NumberOfTilesXY + Tile.X;

			if (MapTiles[TileIndex] == 0)
			{
				MapTiles[TileIndex] = 1;
				VisibleTiles.AddItem(Tile);
			}
		}
	}
}


/**
 * Reveals the passed map tiles spotted by the specified pawn.
 * 
 * @param Tiles
 *      the tiles to reveal on this visibility mask
 * @param Spotter
 *      the TMFOWRevealActor that has vision on these tiles
 */
simulated function RevealMapTilesRevealActor(array<BytePoint> Tiles, TMFOWRevealActor Spotter)
{
	local BytePoint Tile;
	local int TileIndex;

	foreach Tiles(Tile)
	{
		TileIndex = Tile.Y * Map.NumberOfTilesXY + Tile.X;

		if (MapTiles[TileIndex] == 0)
		{
			MapTiles[TileIndex] = 1;
			VisibleTiles.AddItem(Tile);
		}
	}
}

/**
 * Returns true if the specified tile is hidden on this visibility mask, and
 * false otherwise.
 * 
 * @param Tile
 *      the tile to check
 * @return
 *      whether the specified tile is hidden on this visibility mask
 */
simulated function bool IsMapTileHidden(BytePoint Tile)
{
	local float visibilityWeight, sideRatio, diagonalRatio;
	local BytePoint thisTile;

	if (Tile.X >= Map.NumberOfTilesXY || Tile.Y >= Map.NumberOfTilesXY) // can't be less than 0 because bytepoints are 0-255
	{
		return false;
	}

	if(Map.IsPermanentTile( Tile ))     // make permanent visible tiles invisible to prevent bugs around bridges!
	{
		return true;
	}

	if( Map.IsBushTile( Tile ) )
	{
		return (MapTiles[Tile.Y * Map.NumberOfTilesXY + Tile.X] == 0);
	}
	

	sideRatio = 0.5f;
	diagonalRatio = 0.3535f;    // sqrt(2)/4
	visibilityWeight = 0.f;


	visibilityWeight += GetTileVisibilityWeight(Tile, 1.f);
	
	//******* calc diagonal tiles
	thisTile.X = Tile.X - 1;
	thisTile.Y = Tile.Y - 1;
	visibilityWeight += GetTileVisibilityWeight(thisTile, diagonalRatio);

	thisTile.X = Tile.X - 1;
	thisTile.Y = Tile.Y + 1;
	visibilityWeight += GetTileVisibilityWeight(thisTile, diagonalRatio);

	thisTile.X = Tile.X + 1;
	thisTile.Y = Tile.Y - 1;
	visibilityWeight += GetTileVisibilityWeight(thisTile, diagonalRatio);

	thisTile.X = Tile.X + 1;
	thisTile.Y = Tile.Y + 1;
	visibilityWeight += GetTileVisibilityWeight(thisTile, diagonalRatio);


	//******* calc side tiles
	thisTile.X = Tile.X + 1;
	thisTile.Y = Tile.Y;
	visibilityWeight += GetTileVisibilityWeight(thisTile, sideRatio);

	thisTile.X = Tile.X - 1;
	thisTile.Y = Tile.Y;
	visibilityWeight += GetTileVisibilityWeight(thisTile, sideRatio);

	thisTile.X = Tile.X;
	thisTile.Y = Tile.Y + 1;
	visibilityWeight += GetTileVisibilityWeight(thisTile, sideRatio);

	thisTile.X = Tile.X;
	thisTile.Y = Tile.Y - 1;
	visibilityWeight += GetTileVisibilityWeight(thisTile, sideRatio);
	return visibilityWeight < 0.75f;

}

/**
 * Return a visibility weight for a tile.
 */
simulated function float GetTileVisibilityWeight(BytePoint Tile, float weight )
{
	if ( !(Tile.X >= Map.NumberOfTilesXY || Tile.Y >= Map.NumberOfTilesXY ) ) // BytePoints are 0-255, so they cant be less than 0
	{
		return (MapTiles[Tile.Y * Map.NumberOfTilesXY + Tile.X] == 0) ? 0.f : weight;
	}
	return 0.f;
}

simulated function BuildVisibilityMask()
{
	local TMPawn pawn;
	local TMFOWRevealActor revealActor;
	local BytePoint Tile;
	local array<BytePoint> Tiles;

	foreach Map.DynamicActors(class'TMPawn', pawn)
	{
		if ( (pawn.m_allyId == AllyIndex || (AllyIndex == class'TMGameInfo'.const.SPECTATOR_ALLY_ID && pawn.m_allyId != -1)) && class'UDKRTSPawn'.static.IsValidPawn(pawn) )
		{
			Tile = Map.GetMapTileFromLocation(pawn.Location);
			Tiles = Map.GetVisibleTilesAround(Tile, pawn.sightRadiusTiles, false);

			RevealMapTiles(Tiles, pawn);
			Tiles.Length = 0;
		}
	}

	foreach mRevealActors(revealActor)
	{
		if (revealActor.bApplyFogOfWar && ( revealActor.allyId == AllyIndex || revealActor.allyId == -2 || AllyIndex == class'TMGameInfo'.const.SPECTATOR_ALLY_ID ) )
		{
			Tiles = revealActor.getCachedTiles();
			if ( Tiles.Length == 0 )
			{
				Tile = Map.GetMapTileFromLocation(revealActor.Location);
				Tiles = Map.GetVisibleTilesAround(Tile, revealActor.sightRadiusTiles, false, revealActor.uninterruptibleSight);
				revealActor.setCachedTiles(Tiles);
			}

			RevealMapTilesRevealActor(Tiles, revealActor);
			Tiles.Length = 0;
		}
	}
}

/**
 * Updates this visibility mask, re-computing the vision for the team this mask
 * belongs to.
 */
simulated function Update()
{
	ClearVisibilityMask();
	
	BuildVisibilityMask();

	isReady = true;
}

DefaultProperties
{
	isReady = false;
}
