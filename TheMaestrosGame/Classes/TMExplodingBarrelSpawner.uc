class TMExplodingBarrelSpawner extends Pawn
	placeable
	hidecategories(Collision);

var TMExplodingBarrel m_barrel;


function bool IsAuthority()
{
	return ((WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer || WorldInfo.NetMode == NM_Standalone));
}


simulated event PostBeginPlay()
{
	if( IsAuthority() )
	{
		m_barrel = Spawn(class'TMExplodingBarrel',,,Location);
	}
}



DefaultProperties
{
	bCollideWhenPlacing=true
	bCollideActors=false
}
