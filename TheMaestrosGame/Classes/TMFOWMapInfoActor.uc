class TMFOWMapInfoActor extends Actor
placeable
DependsOn(TMFOWSightInfo);

/** The texture to be used as minimap. */
var() Texture2D MinimapTexture;

/** The box describing the map extents. */
var() const editconst DrawBoxComponent MapExtentsComponent;

/** The box describing the camera bounds. */
var() const editconst DrawBoxComponent CameraBounds;

/** The total number of different rounds in the artifact cycle. */
var() const int ArtifactCycleRoundsTotal;

/** The number of tiles of the map in x- and y-direction. */
var() int NumberOfTilesXY;

/** The width or height of this map, whichever is higher, in UU. */
var float MapDimUU;

/** The tile size in uu. */
var float TileSizeUU;

/** The height levels of the map tiles. */
var array<byte> TileHeights;

/** The height levels available on map. */
var array<float> HeightLevels;

/** The center locations of all map tiles in world space. */
var array<Vector> TileCenterLocations;

/** The suggested number of players per team. */
var int SuggestedPlayersPerTeam[2];


var TMFOWSightInfo sightInfo;
var int preprocRow;

var array<byte> tilesType;

var array<int> tileSightIndicesRetrievedThisTick;

/** The human-readable size of this map. */
var enum EMapSize
{
	SIZE_Small,
	SIZE_Medium,
	SIZE_Large,
	SIZE_Unknown
} MapSize;

/** Human-readable description of a small map size. */
var localized string MapSizeSmall;

/** Human-readable description of a medium map size. */
var localized string MapSizeMedium;

/** Human-readable description of a large map size. */
var localized string MapSizeLarge;

/** Human-readable description of an unknown map size. */
var localized string MapSizeUnknown;

/** How much to scale pawn's Line of Sight on this map */
var float sightScale;


/** Initializes this map info actor, computing the size and height of all tiles. */
simulated function Initialize()
{
	local int i;
	local int x;
	local int y;
	local int h;

	local TMFOWHeightLevel HeightLevelActor;

	local Vector TileLocation;

	local Vector TraceStart;
	local Vector TraceEnd;

	local Vector TraceHitNormal;

	local BytePoint Tile;

	// compute the size of all tiles
	MapDimUU = FMax(MapExtentsComponent.BoxExtent.X, MapExtentsComponent.BoxExtent.Y) * 2;
	TileSizeUU = MapDimUU / NumberOfTilesXY;

	// get all height levels
	`log("Collecting height levels...");

	sightInfo = new class'TMFOWSightInfo';
	sightInfo.tileSights.Length = NumberOfTilesXY * NumberOfTilesXY;
	sightInfo.tilesType.Length = (NumberOfTilesXY + 1) * (NumberOfTilesXY + 1);

	sightScale = NumberOfTilesXY/float(64);
	sightScale *= 5000.f / MapExtentsComponent.BoxExtent.X;

	for (i = 0; i < tilesType.Length; i++)
	{
		sightInfo.tilesType[i] = 0;
	}

	sightInfo.height = 0;
	sightInfo.range = int(class'TMGameInfo'.default.mLineOfSightRangeForPawns * sightScale);

	foreach AllActors(class'TMFOWHeightLevel', HeightLevelActor)
	{
		HeightLevels.AddItem(HeightLevelActor.Location.Z);
	}

	HeightLevels.Sort(SortHeightLevels);

	for (i = 0; i < HeightLevels.Length; i++)
	{
		`log("Height level "$(i + 1)$" starts at z = "$HeightLevels[i]);
	}

	// trace the height level for each map tile
	TileHeights.Length = (NumberOfTilesXY + 1) * (NumberOfTilesXY + 1);
	TileCenterLocations.Length = NumberOfTilesXY * NumberOfTilesXY;

	for (y = 0; y < NumberOfTilesXY; y++)
	{
		for (x = 0; x < NumberOfTilesXY; x++)
		{
			Tile.X = x;
			Tile.Y = y;
			// translate the tile coordinate into world space
			TileLocation.X = (float(x) / float(NumberOfTilesXY) - 0.5f) * MapDimUU + Location.X;
			TileLocation.Y = (float(y) / float(NumberOfTilesXY) - 0.5f) * MapDimUU + Location.Y;

			// trace the height of the map tile in world space
			TraceStart = TileLocation;
			TraceStart.Z = 1000;

			TraceEnd = TileLocation;
			TraceEnd.Z = -1000;

			Trace(TileLocation, TraceHitNormal, TraceEnd, TraceStart, false);

			// remember tile center location
			TileCenterLocations[y * NumberOfTilesXY + x] = TileLocation;

			// check if tile is bush
			if(WorldInfo.FindEnvironmentVolume(GetMapLocationFromTile( Tile )) != none)
			{
				AddBushTile( Tile );
			}

			// translate the tile's height from world space into a height level
			for (h = 0; h < HeightLevels.Length; h++)
			{
				if (TileLocation.Z >= HeightLevels[h])
				{
					TileHeights[y * NumberOfTilesXY + x] = h + 1;
				}
			}
		}
		
	}

	// prepare human-readable suggested players and size of this map
	//FindSuggestedPlayers();
	preprocRow = 0;

	LoadFoWPreprocessFile();	

	FindMapSize();
}

simulated function LoadFoWPreprocessFile()
{
	local TMFOWSightInfo loadedSightInfo;

	loadedSightInfo = new () class'TMFOWSightInfo';

	if(!class'Engine'.static.BasicLoadObject( loadedSightInfo, GetFOWMapInfoName(), false, 1))
	{
		`warn("Fog of war preprocess file not found");
		return;
	}

	if (loadedSightInfo.range != sightInfo.range)
	{
		`warn("Fog of war preprocess file had inappropriate range (Line of Sight).  Not using Fog of War preprocess file.");
		return;
	}

	sightInfo = loadedSightInfo;
	preprocRow = NumberOfTilesXY+1;
}

simulated function InitialRePreProcess()
{
	preprocRow = 0;
}

simulated function InitializeFOWRow()
{
	local int x, y;
	local float percent;
	local TMFOWTileSight tileSight;
	local BytePoint center;

	y = preprocRow;

	for (x = 0; x < NumberOfTilesXY; x++)
	{
		center.X = x;
		center.Y = y;
		tileSight.tile = center;
			
		tileSight.inSightTiles = GetVisibleTilesAround(center, sightInfo.range, true);

		SetTileSight( tileSight, y * NumberOfTilesXY + x);
	}

	percent = float(preprocRow)/NumberOfTilesXY;
	percent *= 100.f;
	`log("Initializing Fog of War "@percent@"%");
	preprocRow++;

	if(preprocRow == NumberOfTilesXY)
	{
		`log("Fog of War Initialization complete");
		if (!class'Engine'.static.BasicSaveObject( sightInfo, GetFOWMapInfoName(), false, 1))
		{
			`warn("Failed to save off file "$GetFOWMapInfoName()$" File name may already exist.");
		}
		else
		{
			`log("Fog of War preprocess saved off to file.");
		}
	}
}

simulated function string GetFOWMapInfoName()
{
	return "FogOfWar/"$WorldInfo.GetMapInfo().GetPackageName()$"."$NumberOfTilesXY$"."$sightInfo.range$".fow";
}

simulated function SetTileSight(TMFOWTileSight tileSight, int index)
{
	sightInfo.tileSights[index] = tileSight;
}

/** The delegate used for sorting the height level array. */
delegate int SortHeightLevels(float A, float B)
{
	return int(B - A);
}

/** 
 *  Translates a given location in world coordinates to tile coordinates.
 *  
 *  @param LocationToTranslate
 *      the location to translate
 */
simulated function BytePoint GetMapTileFromLocation(Vector LocationToTranslate)
{
	local BytePoint Tile;
	local Vector NormalizedOffsetFromCenter;

	// compute the offset of the passed location from the map center and normalize to [-0.5 .. +0.5]
	NormalizedOffsetFromCenter.X = (LocationToTranslate.X - Location.X) / MapDimUU;
	NormalizedOffsetFromCenter.Y = (LocationToTranslate.Y - Location.Y) / MapDimUU;

	// transform the normalized coordinates to [0..1] and compute the tile coordinates
	Tile.X = byte((NormalizedOffsetFromCenter.X + 0.5) * NumberOfTilesXY);
	Tile.Y = byte((NormalizedOffsetFromCenter.Y + 0.5) * NumberOfTilesXY);

	//Tile.X = Tile.X < 0 ? 0 : Tile.X;
	//Tile.Y = Tile.Y < 0 ? 0 : Tile.Y;
	//Tile.X = Tile.X >= NumberOfTilesXY ? NumberOfTilesXY - 1 : Tile.X;
	//Tile.Y = Tile.Y >= NumberOfTilesXY ? NumberOfTilesXY - 1 : Tile.Y;

	return Tile;
}

/** 
 *  Translates a given location in tile coordinates to world coordinates.
 *  
 *  @param Tile
 *      the tile to translate
 */
simulated function Vector GetMapLocationFromTile(BytePoint Tile)
{
	local Vector MapLocation;

	MapLocation = TileCenterLocations[ Tile.y * NumberOfTilesXY + Tile.x ];

	if(GetTileHeightAt(Tile.X, Tile.Y) < HeightLevels.Length) 
	{
		MapLocation.Z = HeightLevels[GetTileHeightAt(Tile.X, Tile.Y)];
	}
	else
	{
		MapLocation.Z = HeightLevels[0];
	}

	return MapLocation;
}

/** 
 *  Returns the center of a given map tile in world space.
 *  
 *  @param x
 *      the x-coordinate of the tile to get the center location of
 *  @param y
 *      the y-coordinate of the tile to get the center location of
 */
simulated function Vector GetCenterOfMapTile(int x, int y)
{
	return TileCenterLocations[y * NumberOfTilesXY + x];
}


simulated function array<BytePoint> GetPermanentVisibleTiles()
{
	local BytePoint tile;
	local array<BytePoint> tiles;
	local int x,y;

	local Vector TraceHitLocation;
	local Vector TraceHitNormal;

	local Vector TraceStart;
	local Vector TraceEnd;
	local Actor hitActor;

	for (y = 0; y < NumberOfTilesXY; y++)
	{
		for (x = 0; x < NumberOfTilesXY; x++)
		{
			tile.X = x;
			tile.Y = y;

			TraceStart = GetMapLocationFromTile( tile );
			TraceEnd = TraceStart;
			TraceEnd.Z -= 100;
			hitActor = Trace(TraceHitLocation, TraceHitNormal, TraceEnd, TraceStart, false,,, TRACEFLAG_Bullet);
			//hitAnything = FastTrace(TraceEnd, TraceStart,, true);
			//foreach TraceActors(class'WorldInfo', hitActor, TraceHitLocation, TraceHitNormal, TraceEnd, TraceStart)

			if(hitActor == None )    // if there's line of sight to th tile
			{
				hitActor = Trace(TraceHitLocation, TraceHitNormal, TraceEnd, TraceStart, true,,, TRACEFLAG_PhysicsVolumes);
				if(TMPhysicsVolume(hitActor) == None)
				{
					tiles.AddItem(tile);
				}
			}
		}
	}

	return tiles;
}


/**
 * Computes a list of tiles that represent a circle with the specified radius regardless of line-of-sight
 * around the given center tile. All returned tiles are on the same height
 * level as the specified center tile, or below.
 * 
 * @param Center
 *      the tile that is the center of the computed circle
 * @param Radius
 *      the radius of the circle
 * @return
 *      a circle of tiles around the given center
 */
simulated function array<BytePoint> GetAllTilesAround(BytePoint Center, int Radius, bool forceUpdate)
{
	local array<BytePoint> Tiles;
	local BytePoint Tile;
	local int i;
	local int j;
	local int x;
	local int y;

	local byte CenterHeight;

	// get the height level of the circle's center tile
	CenterHeight = GetTileHeight(Center);

	// XXX VERY simple circle algorithm
	for (j = - Radius; j < Radius; j++)
	{
		for (i = - Radius; i < Radius; i++)
		{
			x = Center.X + i;
			y = Center.Y + j;

			// check if within circle
			if (x >= 0 && y >= 0 && x < NumberOfTilesXY && y < NumberOfTilesXY && (i * i + j * j < Radius * Radius))
			{
				// check tile height
				if (GetTileHeightAt(x, y) <= CenterHeight)
				{
					Tile.X = x;
					Tile.Y = y;
					Tiles.AddItem(Tile);
				}
			}
		}
	}
	return Tiles;
}


/**
 * Computes a list of tiles that represent a circle with the specified radius
 * around the given center tile. All returned tiles are on the same height
 * level as the specified center tile, or below.
 * 
 * @param Center
 *      the tile that is the center of the computed circle
 * @param Radius
 *      the radius of the circle
 * @return
 *      a circle of tiles around the given center
 */
simulated function array<BytePoint> GetVisibleTilesAround(BytePoint Center, int Radius, bool forceUpdate, bool uninterruptible = false)
{
	local array<BytePoint> Tiles;
	local BytePoint Tile;
	local int i;
	local int j;
	local int x;
	local int y;

	local byte CenterHeight;
	local int index;
	local TMFOWTileSight tileSight;
	

	local Vector TraceHitLocation;
	local Vector TraceHitNormal;

	local Vector TraceStart;
	local Vector TraceEnd;
	local Actor hitActor;

	local EnvironmentVolume ev1, ev2;
	local TMFOWTileSight emptyTileSight;
	emptyTileSight.tile.X = 255; // for the compiler

	index = Center.Y * NumberOfTilesXY + Center.X;
	
	if (Center.X < 0 || Center.Y < 0 || Center.X >= NumberOfTilesXY || Center.Y >= NumberOfTilesXY)
	{
		//`warn("GetVisibleTilesAround() was passed a tile that was out of bounds X:"$Center.X$" Y:"$Center.Y);
		return Tiles;
	}

	if( !uninterruptible && forceUpdate == false && sightInfo.tileSights[index] != emptyTileSight && Radius == sightInfo.range)
	{
		if (sightInfo.tileSights[index].retrievedThisTick == 1)
		{
			//`log("already retrieved this tile, giving you nothing", true, 'dru');
			return Tiles;
		}
		sightInfo.tileSights[index].retrievedThisTick = 1;
		tileSightIndicesRetrievedThisTick.AddItem(index);
		return sightInfo.tileSights[index].inSightTiles;
	}
	//else
	//{
	//	`log("X "$Center.X$" Y "$Center.Y$" R "$Radius$" wasn't cached", true, 'dru');
	//}

	// get the height level of the circle's center tile
	CenterHeight = GetTileHeight(Center);
	TraceStart = GetMapLocationFromTile( Center );

	// XXX VERY simple circle algorithm
	for (j = - Radius; j < Radius; j++)
	{
		for (i = - Radius; i < Radius; i++)
		{
			x = Center.X + i;
			y = Center.Y + j;

			if (x >= 0 && y >= 0 && x < NumberOfTilesXY && y < NumberOfTilesXY && (i * i + j * j < Radius * Radius)) // Dru TODO: is this extra circle check actually necessary?
			{
				// check tile height
				if (GetTileHeightAt(x, y) <= CenterHeight)
				{
					
					Tile.X = x;
					Tile.Y = y;
					if(uninterruptible)
					{
						Tiles.AddItem(Tile);
						continue;
					}
					TraceEnd = GetMapLocationFromTile( Tile );
					
					hitActor = Trace(TraceHitLocation, TraceHitNormal, TraceEnd, TraceStart, false,,, TRACEFLAG_Blocking | TRACEFLAG_PhysicsVolumes);
					//hitAnything = FastTrace(TraceEnd, TraceStart,, true);
					//foreach TraceActors(class'WorldInfo', hitActor, TraceHitLocation, TraceHitNormal, TraceEnd, TraceStart)

					if(hitActor == None || TMPhysicsVolume(hitActor) != None)    // if there's line of sight to th tile
					{
						Tiles.AddItem(Tile);
					}
					else
					{
						
						ev1 = WorldInfo.FindEnvironmentVolume(TraceStart);
						ev2 = WorldInfo.FindEnvironmentVolume(TraceEnd);

						if(ev1 != none && ev1==ev2)
						{
							Tiles.AddItem(Tile);
						}
						else if(ev1!= none && ev2 == none)
						{
							hitActor = Trace(TraceHitLocation, TraceHitNormal, TraceEnd, TraceStart, false,,, TRACEFLAG_Blocking);
							if(hitActor == None)    // if there's line of sight to th tile
							{
								Tiles.AddItem(Tile);
							}
						}
					}
				}
			}
		}
	}

	tileSight.tile = Center;
	tileSight.inSightTiles = Tiles;
	
	sightInfo.tileSights[index] = tileSight;
	
	return Tiles;
}


/**
 * Add bush tile to list
 * @param Tile 
 *      The bush tile
 */
simulated function AddBushTile(BytePoint tile)
{
	sightInfo.tilesType[tile.Y * NumberOfTilesXY + tile.X] = 1;
}

/**
 * Returns if a tile is under bush
 * @param Tile 
 *      Target tile
 */
simulated function bool IsBushTile(BytePoint tile)
{
	return sightInfo.tilesType[tile.Y * NumberOfTilesXY + tile.X] == 1;
}


/**
 * Returns if a tile is a permanent visible tile
 * @param Tile 
 *      Target tile
 */
simulated function bool IsPermanentTile(BytePoint tile)
{
	return sightInfo.tilesType[tile.Y * NumberOfTilesXY + tile.X] == 2;
}

/**
 * Returns the height level of the tile at the specified location in tile-space.
 * 
 * @param X
 *      the x-coordinate of the tile to get the height level of
 * @param Y
 *      the y-coordinate of the tile to get the height level of
 */
simulated function byte GetTileHeightAt(int X, int Y)
{
	return TileHeights[Y * NumberOfTilesXY + X];
}

/**
 * Returns the height level of the specified tile.
 * 
 * @param Tile
 *      the tile to get the height level of
 */
simulated function byte GetTileHeight(BytePoint Tile)
{
	local int index;

	index = Tile.Y * NumberOfTilesXY + Tile.X;

	index = index < 0 ? 0 : index;

	return index < TileHeights.Length ? TileHeights[index] : byte(0);
}

/**
 * Returns the height level of the tile at the specified location in world-space.
 * 
 * @param LocationToTranslate
 *      the location of the tile to get the height level of
 */
simulated function byte GetTileHeightFromLocation(Vector LocationToTranslate)
{
	return GetTileHeight(GetMapTileFromLocation(LocationToTranslate));
}

/**
 * Returns the extents of map.
 * 
 * Why simulated? Why, why, why, just why? ^^
 */
simulated function Vector GetMapSize()
{
	return MapExtentsComponent.BoxExtent;
}

/** Finds a human-readable description of the size of this map. */
simulated function FindMapSize()
{
	if (MapDimUU < 10000.0f)
	{
		MapSize = SIZE_Small;
	}
	else if (MapDimUU < 20000.0f)
	{
		MapSize = SIZE_Medium;
	}
	else
	{
		MapSize = SIZE_Large;
	}
}

/** Returns the human-readable description of the size of this map. */
simulated function string GetHumanReadableMapSize()
{
	switch (MapSize)
	{
		case SIZE_Small:
			return MapSizeSmall;
		case SIZE_Medium:
			return MapSizeMedium;
		case SIZE_Large:
			return MapSizeLarge;
		case SIZE_Unknown:
			return MapSizeUnknown;
	}
}


DefaultProperties
{
	Begin Object Class=DrawBoxComponent Name=DrawBox0
		BoxColor=(R=0,G=255,B=0,A=255)
		BoxExtent=(X=1024, Y=1024, Z=0)
	End Object
	MapExtentsComponent=DrawBox0
	Components.Add(DrawBox0)

	Begin Object Class=DrawBoxComponent Name=DrawBox1
		BoxColor=(R=0,G=0,B=255,A=255)
		BoxExtent=(X=1024, Y=1024, Z=0)
	End Object
	CameraBounds=DrawBox1
	Components.Add(DrawBox1)

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Flag1'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
	End Object
	Components.Add(Sprite)

	bNoDelete=true
	bStatic=true

	NumberOfTilesXY=64

	MapSize=SIZE_Unknown
}
