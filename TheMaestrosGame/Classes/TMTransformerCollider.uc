
class TMTransformerCollider extends UDKRTSTransformerCollider;

var CylinderComponent m_CollisionCylinder;
var TMTransformer m_Transformer;


function SetUpCollider(TMTransformer transformer)
{
	m_Transformer = transformer;
}

event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	if(Other.IsA('TMPawn'))
	{
		// m_Transformer.PawnTouchedCollider(TMPawn(Other));
	}
}


DefaultProperties
{
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionHeight=250
		CollisionRadius=25
		bDrawBoundingBox=true
		bDrawNonColliding=true
		HiddenGame=false
		CollideActors=true
	End Object
	m_CollisionCylinder=CollisionCylinder
	Components.Add(CollisionCylinder)

	CollisionType=COLLIDE_TouchAll
	bCollideActors=true
	bAlwaysRelevant=true
}
