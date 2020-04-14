class TMDecal extends DecalActorMovable ;

/** Half the initial width and height of the texture of this decal. */
var float InitialRadius;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}

simulated function SetPositionAndRotation(Vector pos, Rotator rot)
{
	Decal.Location = pos;
}

DefaultProperties
{
	bNoDelete=false
	Begin Object Name=NewDecalComponent
		NearPlane=-300.0f
		Width=150
		Height=150
		bNoClip=true
		DecalMaterial=DecalMaterial'TM_VineCrawler.VineDecal'
	End Object
	Decal=NewDecalComponent
	Components.Add(NewDecalComponent)



}