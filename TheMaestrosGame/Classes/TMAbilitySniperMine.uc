/* TMAbilitySniperMine
	The SniperMine ability fires 4 TMSniperMines to a target location.

	This ability is slightly unusual because it holds a reference to the TMAbilityObjects
	it creates, in this case an array of TMSniperMines. Abilities are NOT supposed to hold
	references to their ability objects, and if not careful will cause bugs and unwanted behavior.
	If the sniper were to die before his ability animation finished, an invisible sniper mine
	actor would be sitting in the game doing nothing. To fix this potential leak, in Cleanup()
	we destroy any TMSniperMines that we haven't fired. Cleanup() is called if this unit dies.
*/
class TMAbilitySniperMine extends TMProjectileAbility;

var int 	m_Damage;
var float 	m_Duration;
var float 	m_MineDelay;
var int 	m_MineSpreadDistance;

var array<TMSniperMine> m_SniperMinesToFire; 	// we ONLY hold these to hand off to FireAbilityProjectile()


function SetUpComponent( JsonObject inJSON, TMPawn inParent )
{
	super.SetUpComponent( inJSON, inParent );
	
	m_Damage 				= inJSON.GetIntValue( "damage" );
	m_DamageRadius 			= inJSON.GetIntValue( "explosionRadius" );
	m_Duration 				= inJSON.GetFloatValue( "duration" );
	m_MineDelay 			= inJSON.GetFloatValue( "armTime" );
	m_MineSpreadDistance 	= inJSON.GetIntValue( "mineSpreadDistance" );
}

// We need to create our ability objects early and add them to the player controller,
// that way another Sniper won't cast his mines on the same location I'm attempting to
function StartAbility()
{
	local Vector targetLocation;

	targetLocation = m_TargetLocation;
	targetLocation.x -= m_MineSpreadDistance;
	targetLocation.y -= m_MineSpreadDistance;
	CreateMine( targetLocation );

	targetLocation.x += m_MineSpreadDistance*2;
	CreateMine( targetLocation );

	targetLocation.y += m_MineSpreadDistance*2;
	CreateMine( targetLocation );

	targetLocation.x -= m_MineSpreadDistance*2;
	CreateMine( targetLocation );

	super.StartAbility();
}

function CreateMine( Vector inLocation )
{
	local TMSniperMine mine;
	local Rotator rot;
	mine = class'TMSniperMine'.static.Create(
		m_AbilityHelper,
		m_owner.m_TMPC,
		m_owner.m_allyId,
		m_owner.m_owningPlayerId,
		m_owner.GetTeamColorIndex(),
		inLocation,
		rot,
		m_Duration,
		m_DamageRadius,
		m_Damage,
		m_MineDelay );

	// Add this to the list of sniper mines
	m_owner.m_TMPC.m_SniperMines.AddItem( mine );
	m_SniperMinesToFire.AddItem( mine );
}

// This is called if the unit dies. Destroy any sniper mines we didn't fire.
function Cleanup()
{
	local TMSniperMine mine;

	foreach m_SniperMinesToFire( mine )
	{
		m_owner.m_TMPC.m_SniperMines.RemoveItem( mine );
		mine.Stop();
	}

	super.Cleanup();
}

function CastAbility()
{
	local TMSniperMine mine;

	foreach m_SniperMinesToFire( mine )
	{
		FireAbilityProjectile( mine );
	}
	
	// I don't need a reference to the sniper mines anymore, they are independent
	m_SniperMinesToFire.Remove( 0, m_SniperMinesToFire.Length );

	super.CastAbility();
}

/* IsLocationCastable( Vector inLocation )
	Make sure that no other sniper mines occupy the same space I need for my sniper
	mines. We can't cast the ability if there is another mine in the way.
*/
function bool IsLocationCastable( Vector inLocation )
{
	local float leftBound, rightBound, lowerBound, upperBound;
	local float mineDistance; 	// the distance we can place a new mine away from old ones
	local TMSniperMine mine;

	// Make the place distance a little larger that the spread
	mineDistance = m_MineSpreadDistance * 1.5;

	// Find the bounds that my mines would occupy
	leftBound = inLocation.x - mineDistance;
	rightBound = inLocation.x + mineDistance;
	lowerBound = inLocation.y - mineDistance;
	upperBound = inLocation.y + mineDistance;

	// If any mine is already in my space, I can't cast
	foreach m_owner.m_TMPC.m_SniperMines( mine )
	{
		if( mine.location.x > leftBound &&
			mine.location.x < rightBound &&
			mine.location.y > lowerBound &&
			mine.location.y < upperBound )
		{
			return false;
		}
	}

	return super.IsLocationCastable( inLocation );
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilitySniperMine newcomp;
	newcomp= new () class'TMAbilitySniperMine'(self);
	newcomp.m_owner = newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

DefaultProperties
{
	m_AbilityIndicatorStyle = AIS_MINES;

	m_ProjectileParticle = ParticleSystem'VFX_Sniper.Particles.P_Sniper_Mine_Projectile';
	m_OnProjectileHitParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Default_Hit';
}
