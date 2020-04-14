/* TMSniperMine
	A mine that explodes when an enemy gets too close to it.
	Has an initial arming time.
*/
class TMSniperMine extends TMAbilityActor;

var StaticMeshComponent m_MineMesh;

var int 	m_Damage;
var float 	m_Duration;
var float 	m_ActivationTime;
var float 	m_FlashLightFrequency;
var int 	m_ExplosionRadius;

var bool m_IsActive;
var bool m_HasBeenHit;

var MaterialInstanceConstant m_Material;

var ParticleSystem m_ExplosionParticleSystem;


static function TMSniperMine Create( TMAbilityHelper inAbilityHelper, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, Vector inSpawnLocation, Rotator inSpawnRotation, float inDuration, float inRadius, int inDamage, float inMineDelay )
{
	local TMSniperMine object;
	object = inTMPC.Spawn( class'TMSniperMine',,, inSpawnLocation, inSpawnRotation );
	object.Setup( inAbilityHelper, inTMPC, inAllyID, inPlayerID, inTeamColorIndex, 40 ); // NOTE: need to hand-code the radius since we have a different collision radius than explosion radius

	object.m_Damage = inDamage;
	object.m_Duration = inDuration;
	object.m_ActivationTime = inMineDelay;
	object.m_ExplosionRadius = inRadius;
	object.SetupMesh();

	// Be hidden until start is called
	object.m_MineMesh.SetHidden( true );
	
	return object;
}

function Start()
{
	m_MineMesh.SetHidden( false );

	m_TMPC.SetTimer( m_ActivationTime, false, 'SetMineActive', self );

	super.Start();
}

function Stop()
{
	ExplodeMine();

	super.Stop();
}

function SetupMesh()
{
	local Vector hsvColor;

	hsvColor = class'TMColorPalette'.static.GetTeamColorHSV( m_AllyID, m_TeamColorIndex );
    m_Material = new(None) Class'MaterialInstanceConstant';
    m_Material.SetParent( m_MineMesh.GetMaterial(0) );
    m_Material.SetScalarParameterValue( 'HueShift', hsvColor.X );
    m_Material.SetScalarParameterValue( 'SaturationScale', hsvColor.Y );
    m_Material.SetScalarParameterValue( 'ValueScale', hsvColor.Z );
    TurnLightOff();
    m_MineMesh.SetMaterial( 0, m_Material );
}

function SetMineActive()
{
	// Check every enemy to see if we're already colliding with one
	local TMPawn tempPawn;
	local array< TMPawn > pawnList;

	// Check if any enemies are in range to slow
	pawnList = m_TMPC.GetTMPawnList();
	foreach pawnList( tempPawn )
	{
		// If is an enemy AND is in range
		if( !m_TMPC.IsPawnOnSameTeam( tempPawn ) &&
			tempPawn.IsInRange2D( location, tempPawn.Location, 100 ) ) 	// hacky that we need to hardcode it, but we can't use a number since it's in defaultprop
		{
			// We're colliding with someone! Blow up
			ExplodeMine();

			// We don't need to activate the mine anymore
			return;
		}
	}

	// Start mine loop
	FlashLight();
	m_TMPC.SetTimer( m_Duration, false, 'ExplodeMine', self );
	m_TMPC.SetTimer( m_FlashLightFrequency, true, 'FlashLight', self );

	m_IsActive = true;
}

function FlashLight()
{
	TurnLightOn();
	m_TMPC.SetTimer( m_FlashLightFrequency/2, false, 'TurnLightOff', self );
}

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	if( TMPawn( other ) != none )
	{
		HandleCollision( TMPawn( other ) );
	}
}

simulated function HandleCollision( TMPawn otherPawn )
{
	if( !m_IsActive || m_HasBeenHit || otherPawn.IsGameObjective() )
	{
		return;
	}

	// Check if we hit a bad guy
	if( TMPlayerReplicationInfo( otherPawn.OwnerReplicationInfo ).allyId != m_AllyID )
	{
		ExplodeMine();
	}
}

function ExplodeMine()
{
	local TMPawn tempPawn;
	local array< TMPawn > pawnList;

	// Check if any enemies are in range to damage
	pawnList = m_TMPC.GetTMPawnList();
	foreach pawnList( tempPawn )
	{
		// If is an enemy AND is in range
		if( !m_TMPC.IsPawnOnSameTeam( tempPawn ) &&
			tempPawn.IsInRange2D( location, tempPawn.Location, m_ExplosionRadius ) )
		{
			m_AbilityHelper.DoDamageToTarget( m_Damage, tempPawn );
		}
	}

	m_TMPC.m_ParticleSystemFactory.CreateWithScale( m_ExplosionParticleSystem, m_AllyID, m_TeamColorIndex, location, 1.5f );
	SetHidden( true );

	m_HasBeenHit = true;
	m_TMPC.ClearTimer( 'FlashRedLight', self );
	m_TMPC.ClearTimer( 'ExplodeMine', self );

	// Remove self from TMPC list
	m_TMPC.m_SniperMines.RemoveItem( self );
	self.Destroy();
}

// Helper to change the material emissive value
function TurnLightOn() {
	m_Material.SetScalarParameterValue( 'EmissiveAmount', 1 );
}
function TurnLightOff() {
	m_Material.SetScalarParameterValue( 'EmissiveAmount', 0 );
}

DefaultProperties
{
	m_ShowTeamThroughFoW = true;

	m_FlashLightFrequency = 0.75;

	m_ExplosionParticleSystem = ParticleSystem'VFX_Sniper.Particles.P_Mine_Explosion';

	bCollideActors=true;
	bBlockActors=false
	bStatic = false
	bNoDelete = false
	bMovable = true


	Begin Object class=StaticMeshComponent name=theMesh
		StaticMesh = StaticMesh'TM_Sniper.Aimbot_Mine_LP';
		Scale = 3;
	End Object

	m_MineMesh = theMesh;
	Components.Add( theMesh )

    
    Begin Object Class=CylinderComponent Name=CylinderComp
        CollisionRadius=32
        CollisionHeight=48
        CollideActors=true
        BlockActors=false
    End Object
    
    Components.Add( CylinderComp )
    CollisionComponent=CylinderComp    
}
