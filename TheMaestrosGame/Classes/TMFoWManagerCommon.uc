class TMFoWManagerCommon extends Actor;

/** The number of seconds between two updates of the visibility mask of a player. */
`if(`isdefined(debug))
	const VISIBILITY_UPDATE_INTERVAL = 0.2f;
`else
	const VISIBILITY_UPDATE_INTERVAL = 0.2f;
`endif

var bool enabled;

/** The map this manager renders the fog of war on. */
var TMFOWMapInfoActor Map;

/** The mask that tells where this player/team has vision. */
var TMFOWVisibilityMask VisibilityMask;

/** The index of the team the player/team rendering the fog of war belongs to. */
var int AllyIndex;

var DruHashMap VisiblePawnsById;  /** ONLY EXISTS ON SERVER - pawn by int map containing all pawns visible to players using this fowManager */

/** The textures used as opacity parameters for the fog volumes. */
var array<ScriptedTexture> FogOfWarTextures;
var array<ScriptedTexture> MinimapFogOfWarTextures;

/** The textures that indicate "no vision" for each particular height level. */
var array<ScriptedTexture> FogOfWarBaseTextures;
var array<ScriptedTexture> MinimapFogOfWarBaseTextures;

/** The color that indicates "no vision" on a fog of war texture. */
var LinearColor ClearColor;
var LinearColor MinimapClearColor;
var LinearColor MinimapVisibleColor;
var array<FogVolumeConstantDensityInfo> FogOfWarVolumes;

/**
 * Initializes this fog of war manager, creating a new visibility mask 
 * and setting up all fog of war volumes.
 * 
 * @param TheMap
 *      the map the manager should render the fog of war on
 * @param TheAllyIndex
 *      the index of the team the player rendering the fog of war belongs to,
 *      in case the PRI has not been replicated yet
 */
function Initialize(TMFOWMapInfoActor TheMap, int TheAllyIndex)
{
	local array<BytePoint> permanentTiles;

	Map = TheMap;
	AllyIndex = TheAllyIndex;

	VisibilityMask = new class'TMFOWVisibilityMask';
	VisibilityMask.Initialize(Map, AllyIndex);
	permanentTiles = Map.GetPermanentVisibleTiles();
	VisibilityMask.PermanentHideMapTiles(permanentTiles);

	if (IsFoWManagerForAClientPlayer())
	{
		SetupFogOfWarVolumes();
	}

	if (!IsFoWManagerForAClientPlayer())
	{
		VisiblePawnsById = class'DruHashMap'.static.Create(256);
	}
	
	EnableFoW();

	if (IsFoWManagerForAClientPlayer())
	{
		SetTimer(VISIBILITY_UPDATE_INTERVAL, true, 'UpdateMinimapTextures');
		SetTimer(VISIBILITY_UPDATE_INTERVAL, true, 'UpdateTextures');
	}
}

static function float GetFoWUpdateInterval()
{
	return VISIBILITY_UPDATE_INTERVAL;
}

function BytePoint GetMapTileFromLocation(Vector LocationToTranslate)
{
	return Map.GetMapTileFromLocation(LocationToTranslate);
}

function SetFoWVolumesDensityEnabled(bool bEnabled)
{
	local int index;

	for (index = 0; index < FogOfWarVolumes.Length; index++)
	{
		FogOfWarVolumes[index].DensityComponent.SetEnabled(bEnabled);
		`log("Cleared "@FogOfWarVolumes[index].Name);
	}
}

function FoWShow()
{
	SetFoWVolumesDensityEnabled(true);
}

function FoWHide()
{
	SetFoWVolumesDensityEnabled(false);
}

function ScriptedTexture GetMinimapFogOfWarTexture()
{
	return MinimapFogOfWarTextures[0];
}

function int GetAllyID()
{
	return AllyIndex;
}

function UpdateTextures()
{
	FogOfWarTextures[0].bNeedsUpdate = true;
	//FogOfWarBaseTextures[0].bNeedsUpdate = true;
}

function UpdateMinimapTextures()
{
	if(MinimapFogOfWarTextures.Length < 0 || MinimapFogOfWarBaseTextures.Length < 0)
	{
		return;
	}
	MinimapFogOfWarTextures[0].bNeedsUpdate = true;
	MinimapFogOfWarBaseTextures[0].bNeedsUpdate = true;
}

function EnableFoW()
{
	if (!enabled)
	{
		SetTimer(VISIBILITY_UPDATE_INTERVAL, true, 'UpdateVisibility');
		enabled = true;
	}
}

function DisableFoW()
{
	if ( enabled )
	{
		`log("FoW Disabled");
		ClearTimer('UpdateVisibility');
		ShowAllPawns();
		enabled = false;
	}
}

event Tick(float dt)
{
	super.Tick(dt);
	if(Map != none)
	{
		if(Map.preprocRow < Map.NumberOfTilesXY)
		{
			Map.InitializeFOWRow();
		}
	}
}

function int GetNumberOfTilesXY()
{
	return Map.NumberOfTilesXY;
}

/** Prepares all fog of war volumes for rendering. */
function SetupFogOfWarVolumes()
{
	local FogVolumeConstantDensityInfo FogOfWarVolume;
	local int VolumeCount;
	local int i;

	// prepare the opacity textures for the fog volumes
	FogOfWarTextures[0] = ScriptedTexture(class'ScriptedTexture'.static.Create(Map.NumberOfTilesXY, Map.NumberOfTilesXY,, ClearColor));
	FogOfWarTextures[0].Render = RenderFogOfWarTexture0;

	MinimapFogOfWarTextures[0] = ScriptedTexture(class'ScriptedTexture'.static.Create(Map.NumberOfTilesXY, Map.NumberOfTilesXY,, MinimapClearColor));
	MinimapFogOfWarTextures[0].Render = RenderMinimapFogOfWarTexture0;


	FogOfWarBaseTextures[0] = ScriptedTexture(class'ScriptedTexture'.static.Create(Map.NumberOfTilesXY, Map.NumberOfTilesXY,, ClearColor));
	FogOfWarBaseTextures[0].Render = RenderFogOfWarBaseTexture0;
	FogOfWarBaseTextures[0].bNeedsUpdate = true;

	// TODO: Does not scale well with current minimap picture. Disable for now.
	// Also sort of looks wrong in general.
	MinimapFogOfWarBaseTextures[0] = ScriptedTexture(class'ScriptedTexture'.static.Create(Map.NumberOfTilesXY, Map.NumberOfTilesXY,, MinimapClearColor));
	//MinimapFogOfWarBaseTextures[0].Render = RenderMinimapFogOfWarBaseTexture0;

	// find all fog of war volumes and initialize them
	foreach AllActors(class'FogVolumeConstantDensityInfo', FogOfWarVolume)
	{
		if (FogOfWarVolume.DensityComponent.FogMaterial == Material'FX_FogOfWar.M_FX_FogOfWar_Grey')
		{
			FogOfWarVolumes.AddItem(FogOfWarVolume);
		}
	}

	// sort the volumes by the z-coordinate of their locations
	FogOfWarVolumes.Sort(SortFogOfWarVolumes);

	VolumeCount = Min(FogOfWarVolumes.Length, FogOfWarTextures.Length);

	`log("Found "$FogOfWarVolumes.Length$" fog of war volumes and "$FogOfWarTextures.Length$" height levels.");
	`log("Initializing "$VolumeCount$" fog of war volumes...");

	for (i = 0; i < VolumeCount; i++)
	{
		SetupFogOfWarVolume(FogOfWarVolumes[i], FogOfWarTextures[i]);
	}
}

/** The delegate used for sorting the fog volumes by the z-coordinate of their locations. */
delegate int SortFogOfWarVolumes(FogVolumeConstantDensityInfo A, FogVolumeConstantDensityInfo B)
{
	return int(B.Location.Z - A.Location.Z);
}

/**
 * Sets up the passed fog of war volume by creating a new material instance
 * constant for it which uses the passed texture as opacity input.
 * 
 * @param FogOfWarVolume
 *      the volume to be set up
 * @param FogOfWarTexture
 *      the texture to be used as opacity input for the material
 */
function SetupFogOfWarVolume(FogVolumeConstantDensityInfo FogOfWarVolume, ScriptedTexture FogOfWarTexture/*,  ScriptedTexture PermanentFogOfWarTexture*/)
{
	local MaterialInstanceConstant FogOfWarMatInst;

	FogOfWarMatInst = new(None) Class'MaterialInstanceConstant';
	FogOfWarMatInst.SetParent(FogOfWarVolume.DensityComponent.FogMaterial);
	FogOfWarMatInst.SetTextureParameterValue('FogOfWarTexture', FogOfWarTexture);
	//FogOfWarMatInst.SetTextureParameterValue('PermanentFOWTexture', PermanentFogOfWarTexture);
	FogOfWarVolume.DensityComponent.FogMaterial = FogOfWarMatInst;
	FogOfWarVolume.DensityComponent.ForceUpdate(false);
}

/** The render delegate used to render the opacity texture of the lowest fog of war volume. */
function RenderFogOfWarTexture0(Canvas Canvas)
{
	RenderFogOfWarTexture(Canvas, 0);
}

function RenderMinimapFogOfWarTexture0(Canvas Canvas)
{
	RenderMinimapFogOfWarTexture(Canvas, 0);
}

/**
 * Renders a fog of war texture to the passed canvas indicating vision
 * on the passed height level.
 * 
 * On a given height level h, tiles belonging to all other height levels
 * are considered "visible" in order to prevent strange artifacts like
 * overlapping additive fog or fog inside of closed static meshes.
 * 
 * @param Canvas
 *      the canvas to render the fog of war texture to
 * @param HeightLevel
 *      the height level to render the fog of war texture of
 */
function RenderFogOfWarTexture(Canvas Canvas, int HeightLevel)
{
	// the fog of war texture is automatically cleared to black ("no vision")
	local BytePoint tile;
	
	FogOfWarTextures[0].bNeedsUpdate = false;

	Canvas.SetDrawColor(255, 255, 255, 255);
	Canvas.DrawTexture(FogOfWarBaseTextures[HeightLevel], 1.0f);

	foreach VisibilityMask.VisibleTiles(tile)
	{
		Canvas.SetPos(Map.NumberOfTilesXY - Tile.X, Tile.Y);
		Canvas.DrawRect(1, 1);
	}
}

function RenderMinimapFogOfWarTexture(Canvas Canvas, int HeightLevel)
{
	// the fog of war texture is automatically cleared to black ("no vision")

	local BytePoint tile;

	MinimapFogOfWarTextures[HeightLevel].bNeedsUpdate = false;

	// TODO: Does not scale well with current minimap picture. Disable for now.
	// Also sort of looks wrong in general.
	Canvas.SetDrawColor(255, 255, 255, 255);
	//Canvas.DrawTexture(FogOfWarBaseTextures[HeightLevel], 1.0f);

	

	// If FoW is enabled light up visible areas
	if( enabled )
	{
		foreach self.VisibilityMask.VisibleTiles(tile)
		{
			Canvas.SetPos(Tile.X, Tile.Y);
			Canvas.DrawRect(1, 1);
		}
	}
	else 	// if we're disabled light up everything
	{
		Canvas.SetPos(0, 0);
		Canvas.DrawRect(Canvas.SizeX, Canvas.SizeY);
	}
}


/** 
 * The render delegate used to render the base of the opacity texture of the lowest fog of war volume.
 * See RenderFogOfWarTexture(Canvas, int) for further information.
 */
function RenderFogOfWarBaseTexture0(Canvas Canvas)
{
	RenderFogOfWarBaseTexture(Canvas, 0);
}

function RenderMinimapFogOfWarBaseTexture0(Canvas Canvas)
{
	RenderMinimapFogOfWarBaseTexture(Canvas, 0);
}

/** 
 * Renders the base of the opacity texture of the a fog of war volume.
 * See RenderFogOfWarTexture(Canvas, int) for further information.
 */
function RenderFogOfWarBaseTexture(Canvas Canvas, int HeightLevel)
{
	// the fog of war texture is automatically cleared to black
	
	local int x;
	local int y;
	local int index;
	local BytePoint Tile;
	
	Canvas.SetDrawColor(0, 0, 0, 255);
	FogOfWarBaseTextures[HeightLevel].bNeedsUpdate = false;

	for (y = 0; y < Map.NumberOfTilesXY + 1; y++)
	{
		for (x = 0; x < Map.NumberOfTilesXY + 1; x++)
		{
			// mark all tiles on other height levels as visible
			if (Map.GetTileHeightAt(x, y) != HeightLevel || x == Map.NumberOfTilesXY || y == Map.NumberOfTilesXY || x == 0 || y == 0 )
			{
				Canvas.SetPos(Map.NumberOfTilesXY - x, y);
				Canvas.DrawRect(1, 1);
			}
		}
	}

	Canvas.SetDrawColor(255, 255, 255, 255);
	
	foreach VisibilityMask.PermanentTilesToHide(Tile)
	{
		Canvas.SetPos(Map.NumberOfTilesXY - Tile.X, Tile.Y);
		Map.sightInfo.tilesType[Tile.Y * Map.NumberOfTilesXY + Tile.X] = 2;
		Canvas.DrawRect(1, 1);
		
		//hacky fix for fow borders/bridges
		if(Tile.X < Map.NumberOfTilesXY / 10.f || Tile.Y < Map.NumberOfTilesXY / 10.f || Tile.X > Map.NumberOfTilesXY * 9 / 10.f || Tile.Y > Map.NumberOfTilesXY * 9 / 10.f) 
		{
			index = Tile.Y * Map.NumberOfTilesXY + (Tile.X + 1);
			if(index >= 0 && index < Map.sightInfo.tilesType.Length - 1)
			{
				Map.sightInfo.tilesType[index] = 2;
			}
			Canvas.SetPos(Map.NumberOfTilesXY - Tile.X + 1, Tile.Y);
			Canvas.DrawRect(1, 1);

			index = Tile.Y * Map.NumberOfTilesXY + (Tile.X - 1);
			if(index >= 0 && index < Map.sightInfo.tilesType.Length - 1)
			{
				Map.sightInfo.tilesType[index] = 2;
			}
			Canvas.SetPos(Map.NumberOfTilesXY - Tile.X - 1, Tile.Y);
			Canvas.DrawRect(1, 1);

			index = (Tile.Y + 1) * Map.NumberOfTilesXY + Tile.X;
			if(index >= 0 && index < Map.sightInfo.tilesType.Length - 1)
			{
				Map.sightInfo.tilesType[index] = 2;
			}
			Canvas.SetPos(Map.NumberOfTilesXY - Tile.X, Tile.Y + 1);
			Canvas.DrawRect(1, 1);

			index = (Tile.Y - 1) * Map.NumberOfTilesXY + Tile.X;
			if(index >= 0 && index < Map.sightInfo.tilesType.Length - 1)
			{
				Map.sightInfo.tilesType[index] = 2;
			}
			Canvas.SetPos(Map.NumberOfTilesXY - Tile.X, Tile.Y - 1);
			Canvas.DrawRect(1, 1);
		}
	}
}

function RenderMinimapFogOfWarBaseTexture(Canvas Canvas, int HeightLevel)
{
	// the fog of war texture is automatically cleared to black
	local int x;
	local int y;
	local BytePoint Tile;
	local Texture2D minimapTexture;

	minimapTexture = class'UDKRTSMapInfo'.static.GetMinimapTexture();

	if(minimapTexture != none)
	{
		Canvas.SetDrawColor(255, 255, 255, 255);
		Canvas.DrawTexture(minimapTexture, 1);
	}
	else
	{
		MinimapFogOfWarBaseTextures[0].bNeedsUpdate = true;
	}

	Canvas.SetDrawColor(255, 255, 255, 255);

	// mark all tiles on other height levels as visible
	for (y = 0; y < Map.NumberOfTilesXY; y++)
	{
		for (x = 0; x < Map.NumberOfTilesXY; x++)
		{
			if (Map.GetTileHeightAt(x, y) != HeightLevel)
			{
				Canvas.SetPos(x, y);
				Canvas.DrawRect(1, 1);
			}
		}
	}

	Canvas.SetDrawColor(255, 255, 255, 255);
	
	foreach VisibilityMask.PermanentTilesToHide(Tile)
	{
		Canvas.SetPos(Tile.X, Tile.Y);
		Canvas.DrawRect(1, 1);
	}
}

/** Tells the visibility of this player it needs to re-compute the vision. */
function UpdateVisibility()
{
	//local ScriptedTexture FogOfWarTexture;
	VisibilityMask.Update();

	// reveal and hide units as appropriate
	if (!IsFoWManagerForAClientPlayer())
	{
		VisiblePawnsById = class'DruHashMap'.static.Create(256);		
	}
	ApplyFogOfWar();
}

function AddRevealActor(TMFOWRevealActor revealActor)
{
	VisibilityMask.mRevealActors.AddItem(revealActor);
}

function RemoveRevealActor(TMFOWRevealActor revealActor)
{
	VisibilityMask.mRevealActors.RemoveItem(revealActor);
}

function bool IsLocationVisible(Vector loc)
{
	local BytePoint fowLocation;

	if( !enabled )
	{
		return true;
	}

	if(VisibilityMask != none && VisibilityMask.isReady && Map != None && VisibilityMask != None)
	{
		fowLocation = Map.GetMapTileFromLocation(loc);
		return !VisibilityMask.IsMapTileHidden(fowLocation);
	}
	
	return true;
}

/** Applies the visibility mask of this player/team, hiding and revealing enemy units. */
function ApplyFogOfWar()
{
	local BytePoint Tile;
	local TMPawn pawn;

	foreach DynamicActors(class'TMPawn', pawn)
	{
		if ( (AllyIndex == -3 && pawn.m_allyId != -1) || pawn.m_allyId == AllyIndex)
		{
			ShowAPawn(pawn);
		}
		else
		{
			Tile = Map.GetMapTileFromLocation(pawn.Location);

			if (VisibilityMask.IsMapTileHidden(Tile))
			{
				HideAPawn(pawn);
			}
			else
			{
				ShowAPawn(pawn);
			}
		}		
	}
}

function bool IsPawnHidden(TMPawn pawn)
{
	if (IsFoWManagerForAClientPlayer())
	{
		return pawn.bHidden;
	}
	
	if ( VisiblePawnsById.GetByIntKey(pawn.pawnId) == None )
	{
		return true;
	}

	return false;
}

function bool IsFoWManagerForAClientPlayer() 
{
	return (WorldInfo.NetMode != NM_DedicatedServer) && (AllyIndex == TMPlayerController(GetALocalPlayerController()).m_allyId);
}

function ShowAPawn(TMPawn pawn)
{
	if (IsFoWManagerForAClientPlayer())
	{
		pawn.Show();
	}
	else
	{
		AddToVisiblePawns(pawn);
	}
}

function HideAPawn(TMPawn pawn)
{
	if (IsFoWManagerForAClientPlayer())
	{
		pawn.Hide();
	}
	else
	{
		RemoveFromVisiblePawns(pawn.pawnId);
	}
}

/** This function should only be called on the server */
function RemoveFromVisiblePawns(int pawnId)
{
	VisiblePawnsById.RemoveByIntKey(pawnId);
}

/** This function should only be called on the server */
function AddToVisiblePawns(TMPawn pawn)
{
	VisiblePawnsById.PutByIntKey(pawn.pawnId, pawn);
}

function ShowAllPawns()
{
	local TMPawn pawn;

	foreach DynamicActors(class'TMPawn', pawn)
	{
		ShowAPawn(pawn);
	}
}

DefaultProperties
{
	ClearColor=(R=0,G=0,B=0,A=255)
	MinimapClearColor=(R=0,G=0,B=0,A=255)
	MinimapVisibleColor=(R=255,G=255,B=255,A=255)
}
