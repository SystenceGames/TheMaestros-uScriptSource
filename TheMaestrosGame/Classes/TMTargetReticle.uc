/*  TMTargetReticle
 *  A target reticle that can be set to follow FoW rules

 Right now this is used only for ability projectiles. We might want to use this for all ability targets.
 */
class TMTargetReticle extends TMFOWActor;

var StaticMeshComponent m_MeshComponent;
var bool m_IsDestroyed;


static function TMTargetReticle Create( Vector inLocation, Rotator inRotation, int inRadius, TMPlayerController inTMPC, int inAllyID, int inTeamColorIndex )
{
    local TMTargetReticle object;
    object = inTMPC.Spawn( class'TMTargetReticle',,, inLocation, inRotation );
    object.SetupFoWActor( inTMPC, inAllyID );
    object.SetupMesh( inRadius, inTeamColorIndex );

    // Be hidden until start is called
    object.SetIsHidden( true );
    
    return object;
}

function SetupMesh( int inRadius, int inTeamColorIndex )
{
    local MaterialInstanceConstant material;

    // Set the mesh
    m_MeshComponent.SetStaticMesh( StaticMesh'SelectionCircles.Meshes.FlatCircle' );
    m_MeshComponent.SetMaterial( 0, Material'SelectionCircles.Materials.TargetMat' );
    m_MeshComponent.SetScale( class'TMHelper'.static.GetScaleFromRadius( inRadius ) );

    // Set the color
    material = new(None) Class'MaterialInstanceConstant';
    material.SetParent( m_MeshComponent.GetMaterial(0) );
    material.SetScalarParameterValue( 'HueShift', class'TMColorPalette'.static.GetTeamColorHSV( m_AllyID, inTeamColorIndex ).X );
    m_MeshComponent.SetMaterial( 0, material );
}

/* SetHidden()
    AbilityActors need to implement SetHidden() for FoW to work.
*/
simulated function SetIsHidden( bool inIsHidden )
{
    if (m_IsDestroyed)
    {
        self.SetHidden(true);
        return;
    }

    self.SetHidden( inIsHidden );
}

simulated function Cleanup()
{
    m_IsDestroyed = true;
    SetIsHidden(true);
    DetachComponent(m_MeshComponent);
}

DefaultProperties
{
    m_ShowTeamThroughFoW = true;

    Begin Object Class=StaticMeshComponent Name=TargetMeshComponent
        CollideActors=false
        CastShadow=false
    End Object
    m_MeshComponent=TargetMeshComponent
    Components.Add( TargetMeshComponent );
}
