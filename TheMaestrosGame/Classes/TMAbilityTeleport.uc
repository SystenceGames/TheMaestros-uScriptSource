class TMAbilityTeleport extends TMAbility;

var float m_airTime;
var int m_iDamage;
var int m_iDamageRadius;
var float m_velocityDown;
var float m_velocityUp;
var bool m_isFalling;

var TMAbilityTargetPainter mAbilityTargetPainter;


// Taylor: delete this later when we're done with the skybreaker.
function print(string message)
{
	`log("TMAbilityTeleport: " $ message);
}


function SetUpComponent(JsonObject json, TMPawn parent) {
	m_airTime = json.GetFloatValue("airTime");
	m_iDamage = json.GetIntValue("damage");
	m_iDamageRadius = json.GetIntValue("damageRadius");
	m_velocityDown = json.GetFloatValue("VelocityDown");
	m_velocityUp = json.GetFloatValue("VelocityUp");

	super.SetUpComponent(json,parent);
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMAbilityTeleport newcomp;
	newcomp= new () class'TMAbilityTeleport'(self);
	newcomp.m_owner=newowner;
	newowner.mbDontDeselectOnCommandActive = true; 	// Taylor: let's try removing this entirely
	newcomp.SetupAbilityHelper();
	return newcomp;
}

function ReceiveFastEvent(TMFastEvent fe)
{
	// All we do is check if we've just landed from our ability
	if(fe.commandType == "Landed" && m_isFalling == true)
	{
		Phase4();
	}

	super.ReceiveFastEvent(fe);
}

function Cleanup()
{
	m_owner.bBlockActors = true;
	RemoveTargetPaint();
	super.Cleanup();
}

function StartAbility()
{
	// Set the ability target painter
	mAbilityTargetPainter = new class'TMAbilityTargetPainter'();
	mAbilityTargetPainter.SetupAbilityTargetPainter( m_owner, m_TargetLocation, m_iDamageRadius );

	super.StartAbility();
}

function CastAbility()
{
	Phase1();
}

function StartAbilityPhase(TMAbilityPhaseFE inAbilityPhaseFE)
{
	local int phaseNumber;
	phaseNumber = inAbilityPhaseFE.abilityPhase;

	if( phaseNumber == 2 ) {
		Phase2();
	}
	// Phase3 is triggered by a timer
	// Phase4 isn't triggered through animation, it's an actual check on if the pawn has landed
	else if( phaseNumber == 5 ) {
		Phase5();
	}
	else if( phaseNumber == 6 ) {
		Phase6();
	}
	else {
		print("Got unexpected ability phase " $ phaseNumber);
	}
}

// override TMAbility's PlayAbilityAnimation. Abilities default to child 1 for animation index, but for some reason skybreaker starts at 0 index
function PlayAbilityAnimation()
{
	m_owner.GetAnimationComponent().PlayAbilityAnimation( m_AnimationRate, 0 );
}

// Play our ability animation for the given index. Skybreaker has 5 ability animations.
function PlayAnimation(int inAnimationIndex, float animationRate=m_AnimationRate)
{
	m_owner.GetAnimationComponent().PlayAbilityAnimation( animationRate, inAnimationIndex );
}

function Phase1() 	// launch into the sky
{
	local Vector vel;

	print("Phase 1.");
	vel.Z = self.m_velocityUp;
	m_owner.SetPhysics(PHYS_Falling);
	m_owner.Velocity += vel;
	m_owner.bBlockActors = false;
}

function Phase2() 	// play vertical animation
{
	print("Start phase 2!");
	PlayAnimation(1);

	m_owner.SetTimer(m_airTime, false, nameof(Phase3), self);
}

function Phase3() 	// teleport to proper location and begin falling. This occurs after the timer elapses
{
	local vector tempVec, zeroVec;

	print("Phase 3 drop it like it's hot!");

	zeroVec.X = 0;
	zeroVec.Y = 0;
	zeroVec.Z = 0;
	m_owner.Velocity = zeroVec; 	// Taylor: maybe set velocity to falling down?
	tempVec.Z = m_owner.Location.Z;
	tempVec.X = m_TargetLocation.X;
	tempVec.Y = m_TargetLocation.Y;
	m_owner.SetLocation(tempVec);
	m_isFalling = true;

	PlayAnimation(2);
}

function Phase4() 	// Hit and do damage
{
	print("Phase 4");
	m_isFalling = false;
	RemoveTargetPaint();
	m_AbilityHelper.DoDamageInRadius( m_iDamage, m_iDamageRadius, m_owner.Location );
	PlayAnimation(3);
}

function Phase5() 	// Get up
{
	print("Phase 5");
	PlayAnimation(4, 2.0f); 	// play the getup animation more quickly
}

function Phase6()
{
	print("Phase 6 -- Ability finished.");
	m_owner.bBlockActors = true;

	RemoveTargetPaint(); 	// it should already be removed, but do it once more to be safe
	EndAbility();
}

function RemoveTargetPaint()
{
	if( mAbilityTargetPainter != none )
	{
		mAbilityTargetPainter.Cleanup();
	}
}

DefaultProperties
{
	mAnimationDurationFallback = 10f; 	// lower this later, we want to see if any callbacks fail for skybreaker
}