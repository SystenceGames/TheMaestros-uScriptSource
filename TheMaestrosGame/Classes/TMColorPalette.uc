class TMColorPalette extends Object;


enum TeamColors {
	Red,
	Green,
	Blue,
};


// Other Colors
var const Color GrayRGB;
var const Vector GrayHSV;

var const Color BlackTransparentRGBA;

var const Color GoldColorRGB;

var const Color WhiteRGB;
var const Vector WhiteHSV;

var const Color GreenRGB;
var const Vector GreenHSV;

var const Color RedRGB;
var const Vector RedHSV;

// Team Colors
var const Color TeamRedRGB;
var const Vector TeamRedHSV;

var const Color TeamDarkRedRGB;
var const Vector TeamDarkRedHSV;

var const Color TeamPinkRGB;
var const Vector TeamPinkHSV;

var const Color TeamBlueRGB;
var const Vector TeamBlueHSV;

var const Color TeamTealRGB;
var const Vector TeamTealHSV;

var const Color TeamCyanRGB;
var const Vector TeamCyanHSV;

static function Color GetTeamColorRGB(int allyId, int teamColorIndex)
{
	if (allyId == -1 || allyId == -3)
	{
			return class'TMColorPalette'.default.GrayRGB;
	}
	else if (allyId == 0)
	{
		switch (teamColorIndex)
		{
		case 0:
			return class'TMColorPalette'.default.TeamTealRGB;
		case 1:
			return class'TMColorPalette'.default.TeamBlueRGB;
		case 2:
			return class'TMColorPalette'.default.TeamCyanRGB;
		}
	}
	else // allyId == 1
	{
		switch (teamColorIndex)
		{
		case 0:
			return class'TMColorPalette'.default.TeamRedRGB;
		case 1:
			return class'TMColorPalette'.default.TeamDarkRedRGB;
		case 2:
			return class'TMColorPalette'.default.TeamPinkRGB;
		}
	}
	`warn("Unable to assign team color RGB");
	return MakeColor(100,0,0,255);
}

static function Vector GetTeamColorHSV(int allyId, int teamColorIndex)
{
	// NOTE: I'm not really sure what the color -1,-1,-1 actually is, but it seems to make the tutorial work. It must be a red color
	local Vector nullColor;
	nullColor.X = -1;
	nullColor.Y = -1;
	nullColor.Z = -1;

	if (allyId == -1)
	{
		return nullColor;
	}
	else if (allyId == 0)
	{
		switch (teamColorIndex)
		{
		case 0:
			return class'TMColorPalette'.default.TeamTealHSV;
		case 1:
			return class'TMColorPalette'.default.TeamBlueHSV;
		case 2:
			return class'TMColorPalette'.default.TeamCyanHSV;
		}
	}
	else // allyId == 1
	{
		switch (teamColorIndex)
		{
		case 0:
			return class'TMColorPalette'.default.TeamRedHSV;
		case 1:
			return class'TMColorPalette'.default.TeamDarkRedHSV;
		case 2:
			return class'TMColorPalette'.default.TeamPinkHSV;
		}
	}
	`warn("Unable to assign team color HSV");
	return class'TMColorPalette'.default.WhiteHSV;
}

static function TeamColors GetTeamColor( int inAllyID )
{
	if( inAllyID == 0 )
	{
		return TeamColors.Blue;
	}
	if( inAllyID == 1 )
	{
		return TeamColors.Red;
	}
	
	`warn( "TMColorPalette::GetTeamColor() didn't get a vaild team color. Returning blue." );
	return TeamColors.Blue;
}

static function bool IsBlueTeam( int inAllyID )
{
	return GetTeamColor( inAllyID ) == Blue;
}

static function bool IsRedTeam( int inAllyID )
{
	return GetTeamColor( inAllyID ) == Red;
}

DefaultProperties
{
	GrayRGB=(R=127,G=127,B=127,A=255)
	GrayHSV=(X=0,Y=0,Z=0.5)

	WhiteRGB=(R=255,G=255,B=255,A=255)
	WhiteHSV=(X=0,Y=0,Z=1)

	GreenRGB=(R=0,G=255,B=0,A=255)
	GreenHSV=(X=120,Y=-1,Z=-1)

	RedRGB=(R=255,G=0,B=0,A=255)
	RedHSV=(X=0,Y=-1,Z=-1)

	// Team Colors
	TeamRedRGB=(R=150,G=0,B=0,A=255)
	TeamRedHSV=(X=0,Y=-1,Z=0.45)

	TeamDarkRedRGB=(R=80,G=0,B=0,A=255)
	TeamDarkRedHSV=(X=0,Y=-1,Z=0.13)

	TeamPinkRGB=(R=220,G=0,B=81,A=255)
	TeamPinkHSV=(X=345,Y=-1,Z=0.75)

	TeamTealRGB=(R=0,G=120,B=170,A=255)
	TeamTealHSV=(X=200,Y=-1,Z=0.3)

	TeamBlueRGB=(R=0,G=0,B=255,A=255)
	TeamBlueHSV=(X=240,Y=-1,Z=-1)

	BlackTransparentRGBA=(R=0,G=0,B=0,A=128)
	GoldColorRGB=(R=155,G=104,B=70,A=255)

	TeamCyanRGB=(R=0,G=95,B=78,A=255)
	TeamCyanHSV=(X=170,Y=-1,Z=0.7)
}
