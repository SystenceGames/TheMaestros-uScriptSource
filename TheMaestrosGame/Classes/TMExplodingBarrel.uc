class TMExplodingBarrel extends Pawn;

var () float BarrelHealth;
var () float BlastRadius;


simulated event PostBeginPlay()
{
	
}


simulated function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{


}

simulated event Tick(float dt)
{



}



DefaultProperties
{
	Begin Object  Name=CollisionCylinder
	CollisionRadius=30
	CollisionHeight=50
	AlwaysLoadOnClient=True
	AlwaysLoadOnServer=True
	BlockNonZeroExtent=true
	BlockZeroExtent=true
	BlockActors=true
	CollideActors=true
	End Object
	CylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)


	Begin Object Class=StaticMeshComponent Name=MeshComp
		StaticMesh=StaticMesh'TM_Transformer.StaticMeshes.TempTransformer'
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
	End Object
	Components.Add(MeshComp)
}
