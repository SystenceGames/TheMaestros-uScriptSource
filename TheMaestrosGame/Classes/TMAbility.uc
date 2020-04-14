/* TMAbility
 * Abilities are components attached to a TMPawn.
 * 
 * Abilities go through 3 stages.
 *  1) Start => this is where we begin playing the unit's ability animation
 *  2) Cast  => when the ability's affect is actually fired. An ability can be interrupted before this point.
 *                  Cast will be triggered by an animation callback. The animation needs an "AC_CastAbility" script callback.
 *  3) End   => this will clean up the ability and allow the unit to be controlled again.
 *                  End is also triggered by an animation callback. The animation needs an "AC_EndAbility" script callback.

 	REQUIREMENTS:
 	Animation: 2 script callbacks
 		-"AC_CastAbility" on ability fire
 		-"AC_EndAbility" for ability finished
 		NOTE: if the ability doesn't have an animation set mHasNoAnimation to true
 */

class TMAbility extends TMComponent;

const ABILITY_COMMAND_TYPE = "C_Ability";
const CLEANUP_COMMAND_TYPE = "C_Cleanup";
const ABILITY_STOP_COMMAND_TYPE = "C_Stop_Ability";
const STOP_MOVING = "C_Stop_Move";          // TODO: shouldn't this be located somewhere else?
const ANIMATION_SPAWN_ABILITY_PROJECTILE = "C_SpawnAbilityProjectile";  // REMOVING (it's in TMProjectileAbility)
const CAST_ABILITY_COMMAND = "C_CastAbility";
const END_ABILITY_COMMAND = "C_EndAbility";
const ABILITY_PHASE_COMMAND = "C_AbilityPhase";

enum AbilityState   // Do we actually need states? Trying to remove these
{
	AS_IDLE,
	AS_MOVING_TO_TARGET,
	AS_PLAYING_ANIMATION,
	AS_CASTING,
	AS_COOLDOWN
};
var AbilityState m_AbilityState;

var AbilityIndicatorStyle m_AbilityIndicatorStyle;
var string m_sAbilityName;

var float mCooldown;        // -> m_Cooldown
var float m_fTimeInState;   // REMOVING

var int m_iRange;       // -> m_Range
var TMPawn m_Target;    // REMOVING
var Vector m_TargetLocation;
var Vector m_CastingStartLocation; 	// The location this pawn was when the ability command was sent from the server
var float m_AnimationRate; 	// How fast the animation plays

var bool mIsInstantCast;    // Instant cast abilities don't need to be aimed    // -> m_IsTargetless or m_IsTargetCast and use !
var bool mIsRangeless;      // Rangeless abilities can be cast out of range     // -> something better

var bool mIsPlayerAbility; 	// player-selected ability, like "Ghost"
var bool mHasNoAnimation; 	// abilities are cast by their animation. Turn this on if ability doesn't have animation

var float mAnimationDurationFallback; 	// the amount of time we will wait before we decide an animation failed and we should just fire the ability

// Debug Display variables  // Should these be here???
var float mDebugTickFrequency;
var float mDebugDuration;

var TMAbilityHelper m_AbilityHelper;


// Timer variables to handle the ability projectile animation not playing
var float mSpawnAbilityProjectileTime;  // maybe combine this or move to different system that allow fallback for animation or projectile failing

var bool TEMP_dontStop; 	// addicted to the shindig. Remove this BS. Make it so the stop command never get called anyway


//init
function SetUpComponent(JsonObject json, TMPawn parent)
{
	m_owner = parent;
	m_sAbilityName = json.GetStringValue("abilityName");
	m_iRange = json.GetIntValue("range");
	m_AnimationRate = json.GetFloatValue( "animationSpeed" );
	if( m_AnimationRate == 0 )
	{
		m_AnimationRate = 1;
	}

	// Our custom game modes might want to tweak these ability cast times
	if( json.HasKey("animationDurationFallback") )
	{
		mAnimationDurationFallback = json.GetFloatValue("animationDurationFallback");
	}

	// TODO: moving this functionality OUT OF HERE. Waiting for ability indicator rewrite
	if( m_AbilityIndicatorStyle == AIS_UNSET )
	{
		m_AbilityIndicatorStyle = class'TMAbilityIndicator'.static.GetAbilityIndicatorStyle( json.GetStringValue("indicator") );
	}

	mCooldown = json.GetFloatValue("cooldown");
	m_fTimeInState = 0;
	m_AbilityState = AS_IDLE;
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMAbility newcomp;
	newcomp= new () class'TMAbility'(self);
	newcomp.m_owner=newowner;
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function SetupAbilityHelper()
{
	m_AbilityHelper = new class'TMAbilityHelper'();
	m_AbilityHelper.Setup( m_Owner.m_TMPC, m_Owner.m_AllyID );
}

function ReceiveFastEvent(TMFastEvent fe)
{
	if(fe.commandType == ABILITY_COMMAND_TYPE)
	{
		HandleAbilityFE(class'TMAbilityFe'.static.fromFastEvent(fe));
	}
	else if (fe.commandType == "C_Stop" || fe.commandType == "C_Stop_Attack")
	{
		HandleStopFE();
	}
	else if ( fe.commandType == CLEANUP_COMMAND_TYPE )
	{
		Cleanup();
	}
	else if ( fe.commandType == ABILITY_STOP_COMMAND_TYPE || fe.commandType == "C_Move" )
	{
		StopAbility();
	}
	else if( fe.commandType == CAST_ABILITY_COMMAND && m_AbilityState == AS_PLAYING_ANIMATION )
	{
		m_owner.ClearTimer( 'OnAnimationCallbackFailed', self );
		CastAbility();
	}
	else if( fe.commandType == END_ABILITY_COMMAND && m_AbilityState == AS_COOLDOWN )
	{
		// The ability animation just finished
		EndAbilityAnimation();
	}
	else if( fe.commandType == ABILITY_PHASE_COMMAND )
	{
		StartAbilityPhase(class'TMAbilityPhaseFE'.static.fromFastEvent(fe));
	}
	
	super.ReceiveFastEvent(fe);
}

function HandleStopFE()
{
	if (m_AbilityState == AS_MOVING_TO_TARGET)
	{
		m_Target = none;
		m_TargetLocation = vect(0,0,0);
		m_AbilityState = AS_IDLE;
	}
}

function Cleanup() 	// called when the unit is killed
{
	m_owner.ClearAllTimers( self );
}

function StopAbility()
{
	if (m_AbilityState == AS_MOVING_TO_TARGET)
	{
		m_Target = none;
		m_TargetLocation = vect(0,0,0);
		m_AbilityState = AS_IDLE;
	}
}

function HandleAbilityFE(TMAbilityFe abFE)
{
	if (abFE.ability == m_sAbilityName)
	{
		m_Target = m_owner.m_TMPC.GetPawnByID(abFE.targetId);
		m_TargetLocation = abFE.abilityLocation;
		m_CastingStartLocation = abFE.castingPawnLocation;
		
		HandleAbility();
	}
}

function TODOIntegrate_DoAbilityAnimation()
{
	m_owner.GetAnimationComponent().PlayAbilityAnimation();
}

function PlayAbilityAnimation()
{
	m_owner.GetAnimationComponent().PlayAbilityAnimation( m_AnimationRate );
}

function HandleAbility()
{
	if( IsOnCooldown() )
	{
		return; 	// don't cast the ability
	}
	
	// Make sure the ability cast location is possible
	if( !IsLocationCastable( m_TargetLocation ) )
	{
		return; 	// don't cast the ability
	}

	if (mIsInstantCast || mIsRangeless ||  IsInRange(m_owner.Location, m_TargetLocation, m_iRange) )
	{
		m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, "C_StopAttack" ) );
		StartAbility();
	}
	else
	{
		//only the serve should be sending a move location
		m_AbilityState = AS_MOVING_TO_TARGET;
		if( m_owner.IsAuthority() )
		{
			MoveToTargetLocation();
		}
	}
}


function MoveToTargetLocation()
{
	local TMMoveFE fe;
	m_owner.UpdateUnitState( TMPS_ABILITY );
	fe = class'TMMoveFE'.static.create(m_TargetLocation,false,m_owner.pawnId );
	fe.destination = m_TargetLocation;
	m_owner.SendFastEvent( fe );
}

function StartAbility()
{
	if( !TEMP_dontStop )
	{
		m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE( m_owner.pawnId, STOP_MOVING ) );   // TODO: move this call somewhere else. It feels weird to have it here
	}

	m_fTimeInState = 0;
	m_owner.m_bIsAbilityReady = false;


	if( mHasNoAnimation )
	{
		CastAbility();
		return;
	}

	m_owner.UpdateUnitState( TMPS_JUGGERNAUT ); // juggernaut makes it so you can't do any other commands
													// We should update TMPS_Ability so that it also does this.
													// we often use juggernaut in abilities just to achieve this
	m_AbilityState = AS_PLAYING_ANIMATION;

	// Start the ability animation. We will actually cast the ability once we get the CastAbility callback from this animation
	m_owner.SetTimer( mAnimationDurationFallback, false, 'OnAnimationCallbackFailed', self );    // keep track of the animation
	PlayAbilityAnimation();
}

function CastAbility()
{
	EndAbility();
}

function EndAbility()
{
	BeginCooldown();
	m_owner.UpdateUnitState( TMPS_IDLE );
}

/* EndAbilityAnimation()
	This is called when the ability's animation has finished playing.
	If the unit is still in the idle state, he isn't going to have an
	animation to play. We will tell the unit to play his idle animation.
*/
function EndAbilityAnimation()
{
	if( m_owner.m_currentState == TMPS_IDLE )
	{
		m_owner.GetAnimationComponent().PlayIdleAnimation();
	}
}

/* OnAnimationCallbackFailed
 *  This function is put on a timer whenever the ability is relying on a callback from animation.
 *  Since the new ability system is relying on these callbacks, this function will allow us to see
 *  when an animation has failed. The goal of this function is to keep track of our animation system
 *  and make sure it isn't causing any ability bugs. One bonus of this function is that it will also
 *  recover from the missed animation callback. Ideally, this function should never get called. But
 *  in the unfortunate event that an animation fails, this will make the ability not break.
 */
function OnAnimationCallbackFailed()
{
	DebugMessage( "ERROR: animation never sent a callback!", true );

	if( m_AbilityState == AS_PLAYING_ANIMATION )
	{
		DebugMessage( "Recovering from error by calling 'CastAbility()'", true );
		CastAbility();
	}
}

function BeginIdle()
{
	m_AbilityState = AS_IDLE;
	m_owner.m_bIsAbilityReady = true;
}

function BeginCooldown()
{
	m_AbilityState = AS_COOLDOWN;
	m_owner.m_bIsAbilityReady = false;
	m_fTimeInState = 0;
	m_Target = none;
	m_TargetLocation.X = 0;
	m_TargetLocation.Y = 0;
	m_TargetLocation.Z = 0;
	m_owner.SetTimer(mCooldown, false, 'BeginIdle', self);
}

function CommandFinished()
{
	m_Owner.CommandQueueDo();
}

function UpdateComponent(float dt)
{
	if (m_AbilityState == AS_MOVING_TO_TARGET )
	{
		CheckAbilityRange();
	}
	else if (m_AbilityState == AS_COOLDOWN)
	{
		m_fTimeInState += dt;
	}
}

function CheckAbilityRange()
{
	if (IsInRange(m_owner.Location, m_TargetLocation, m_iRange) )
	{
		StartAbility();
	}
}

/* IsLocationCastable( Vector inLocation )
	This function returns true if the given location is valid for casting.

	Any ability who wants to add special location restrictions to their ability
	should implement this function.
*/
function bool IsLocationCastable( Vector inLocation )
{
	// TODO: return false if there is terrain in the way
	// NOTE: This work is sort of already done by UDKRTSPCHUD::TransformScreenToWorldSpaceOnTerrain() before
	// 	the ability ever invoked

	return true;
}

function bool IsInRange(Vector location1, Vector location2, int range)
{
	local int rangeSq;
	rangeSq = range*range;
	return (VSizeSq2D(location1 - location2) < rangeSq);
}

function RotateToTarget()
{
	local Rotator desiredRotation;
	desiredRotation = Rotator( m_TargetLocation - m_owner.Location );
	desiredRotation.Pitch = 0;
	desiredRotation.Roll = 0;
	m_owner.SetRotation( desiredRotation );
}


///// Debug Data Functions /////
function ShowDebug()
{
	`if(`isdefined(debug))
	m_owner.SetTimer( mDebugTickFrequency, true, 'ShowDebugTick', self );
	m_owner.SetTimer( mDebugDuration, false, 'HideDebug', self );
	`endif
}

function HideDebug()
{
	m_owner.ClearTimer( 'ShowDebugTick', self );
}

// This gets called on every ShowDebug update to display debug data
function ShowDebugTick()
{
	// Abilities need to implement this function to show debug
}

function DebugMessage( string inString, optional bool inIsError )
{
	// We always print errors to the console
	if( inIsError )
	{
		`log( "TMAbility:"@m_sAbilityName@inString );
	}
	else
	// Regular print messages won't be shown in release mode
	{
		`if(`isdefined(debug))
		`log( "TMAbility:"@m_sAbilityName@inString );
		`endif
	}
}

function bool IsOnCooldown()
{
	return m_AbilityState != AS_IDLE;
}

// Implement this function if your ability has more than 1 phase. Currently only the skybreaker has multiple phases.
function StartAbilityPhase(TMAbilityPhaseFE inAbilityPhaseFE) {}

defaultproperties
{
	mAnimationDurationFallback = 1.0f;
	mDebugTickFrequency = 0.01f;
	mDebugDuration = 2.0f;

	m_AbilityIndicatorStyle = AIS_UNSET;
}
