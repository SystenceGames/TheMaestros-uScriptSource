class TMLocalMessage extends LocalMessage;



static function color GetConsoleColor( PlayerReplicationInfo RelatedPRI_1 )
{
	local TMPlayerReplicationInfo tmpri;
	
	tmpri = TMPlayerReplicationInfo(RelatedPRI_1);

	if (tmpri != None)
	{
		return class'TMColorPalette'.static.GetTeamColorRGB(tmpri.allyId, tmpri.mTeamColorIndex);
	}
	else {
		return Default.DrawColor;
	}
}

DefaultProperties
{
	Lifetime=8	
}
