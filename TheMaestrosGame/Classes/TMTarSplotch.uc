/* TMTarSplotch
 * 
 * Slows enemies who touch the tar. The tar can be set on fire to do AoE damage.
 *
 * You can create a flaming or non-flaming tarsplotch. If you are creating a flaming
 * 	tarsplotch you must have a previous tarsplotch that you're replacing.
 */
class TMTarSplotch extends TMAbilityObject;

var float   			m_Duration;
var float   			m_Radius;
var float   			m_CheckFrequency;
var int 				m_FireDamage;
var bool 				m_IsOnFire;


static function TMTarSplotch Create( TMAbilityHelper inAbilityHelper, TMPlayerController inTMPC, int inAllyID, int inPlayerID, int inTeamColorIndex, Vector inLocation, float inDuration, float inRadius, float inCheckFrequency, int inFireDamage, bool inIsOnFire = false )
{
	local TMTarSplotch object;
	object = new class'TMTarSplotch'();
	object.Setup( inAbilityHelper, inTMPC, inAllyID, inPlayerID, inTeamColorIndex, inLocation, inRadius );
	object.m_Duration 		= inDuration;
	object.m_Radius 		= inRadius;
	object.m_CheckFrequency	= inCheckFrequency;
	object.m_FireDamage 	= inFireDamage;
	object.m_IsOnFire 		= inIsOnFire;
	return object;
}

function Start()
{
	SetupVFX();

	Update();
	m_TMPC.SetTimer( m_CheckFrequency, true, 'Update', self );
	m_TMPC.SetTimer( m_Duration, false, 'Stop', self );

	super.Start();
}

function Stop()
{
	// Clean up my timers
	m_TMPC.ClearTimer( 'Update', self );

	// Remove self from TMPC list
	m_TMPC.m_TarSplotches.RemoveItem( self );

	super.Stop();
}

function Update()
{
	local TMPawn tempPawn;
	local array< TMPawn > pawnList;

	// Check if any enemies are in range to slow
	pawnList = m_TMPC.GetTMPawnList();
	foreach pawnList( tempPawn )
	{
		// If is an enemy AND is in range
		if( !m_TMPC.IsPawnOnSameTeam( tempPawn ) &&
			!tempPawn.IsGameObjective() &&
			tempPawn.IsInRange2D( m_Location, tempPawn.Location, m_Radius ) )
		{
			// Deal damage to the pawn so that the pawn aggros us. If the tar is on fire we can deal non-zero damage
			if( m_IsOnFire ) {
				m_AbilityHelper.DoDamageToTarget( m_FireDamage, tempPawn );
			} else {
				m_AbilityHelper.DoDamageToTarget( 0, tempPawn ); 	// get aggro
			}

			// Slow the pawn
			tempPawn.m_Unit.SendStatusEffect( SE_OILER_SLOW );
		}
	}
}

simulated function SetupVFX()
{
	local ParticleSystem tarSplotchPS;
	local float psScale;
	local Vector tarSpawnLocation, fireSpawnLocation;

	// Assign the properly colored partclesystem based on my team's color
	if( class'TMColorPalette'.static.IsBlueTeam( m_AllyID ) ) {
		tarSplotchPS = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_AOE_Splat_Blue';
	}
	else if( class'TMColorPalette'.static.IsRedTeam( m_AllyID ) ) {
		tarSplotchPS = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_AOE_Splat_Red';
	}
	else {
		`warn( "TMTarSplotch::SetupVFX() didn't have Blue or Red team!" );
		tarSplotchPS = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_AOE_Splat_Red';
	}

	// Set the spawn location of the tar
	tarSpawnLocation = m_Location;
	if( m_IsOnFire )
	{
		tarSpawnLocation.z += 1;	// if this is the flaming tar splotch, raise it slightly so that it won't clip the previous tar splotch
	}

	// Create the particle system
	psScale = 1.15 * class'TMHelper'.static.GetScaleFromRadius( m_Radius ); 	// make the oil be 15% larger since there
																				// is a lot of empty space around the VFX
	m_TMPC.m_ParticleSystemFactory.CreateWithScale( tarSplotchPS, m_AllyID, m_TeamColorIndex, tarSpawnLocation, psScale, m_Duration );

	if( m_IsOnFire )
	{
		// Create the fire particlesystem
		fireSpawnLocation = m_Location;
		fireSpawnLocation.z -= 50; 	// lower the fire a little so that it actually looks like the tar is on fire
		psScale = 0.4 * class'TMHelper'.static.GetScaleFromRadius( m_Radius ); 	// 50% of the size of tar

		m_TMPC.m_ParticleSystemFactory.CreateWithScale( ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_SplatFire', m_AllyID, m_TeamColorIndex, fireSpawnLocation, psScale, m_Duration );
	}
}

function bool CanIgnite()
{
	return !m_IsOnFire;
}

function Ignite()
{
	// We are now considered "on fire" however nothing immediately happens.
	// A new flaming tarsplotch is being fired which will take my place.
	m_IsOnFire = true;
}
