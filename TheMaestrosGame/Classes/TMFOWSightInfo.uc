class TMFOWSightInfo extends Object;

/**
 * Light weight x,y coordinates
 */
struct immutable BytePoint
{
	var byte X, Y;
};

struct TMFOWTileSight
{
	var BytePoint tile;
	var array<BytePoint> inSightTiles;
	var byte retrievedThisTick;

	structdefaultproperties
	{
		tile=(X=255,Y=255)
	}
};

var int height;
var int range;
var array<TMFOWTileSight> tileSights;
var array<byte> tilesType;

DefaultProperties
{
}
