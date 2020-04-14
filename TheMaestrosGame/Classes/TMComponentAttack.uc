/* TMComponentAttack
	The component we put on units in order to do their simple attack.
	We support instant damage attacks and projectile based attacks.

	To give a unit an attack, add a "DoDamage" or "SpawnProjectile" animation callback.

	Can change damage values in unit JSONs
*/

class TMComponentAttack extends TMComponent
	DependsOn(TMFOWSightInfo);


enum AttackState
{
	AS_MOVING_TO_TARGET, AS_NOTHING
};
var AttackState m_State;


/* ATTACK COMPONENT IMPROVEMENTS:
	-simulate everything on the client
	-don't time the animation, check if we're still in range of our target after every attack instead (should have same outcome)
*/


///// ON THE CHOPPING BLOCK /////
/* Saved movement and timing animation stuff
	We only use these to calculate how long an attack animation lasts. If we are going to switch to
	checking range after every successful attack, we don't really need to save this anymore*/
var float m_rateOfFire;
var float m_attackAnimationTimeLeft;//used if we want to issue a follow command
var float m_idleDuration;
var TMMoveFe m_cachedMoveFE;

/* We might be able to remove this with above stuff, not certain */
var TMPawn m_cachedPawn;

/* We might not need this client thing anymore */
var TMPawn m_clientTarget;
///// END CHOPPING BLOCK /////

var int m_iDamage;
var int m_iRange;
var int m_NeutralDamageBonus; 	// extra damage we do to neutrals
var TMPawn m_Target;
var bool m_AttackMove;
var bool m_bAttackMoveIsActive;
var bool m_fireAndForget;
var int m_fireAndForgetDistance;
var bool mIsAoE;
var int mAoERadius;
var float mAoEPercentDamage;
var float m_timeTillCanAttackFromMove;
var TMAttackFE m_cachedFastEvent; //we will use this to see if we got an attack command while we were waiting to attack again
var bool mCanAttack;

// VFX stuff
var ParticleSystem m_onHitParticle;
var int mOnHitParticleScale;
var bool m_bBeamParticle;

// Projectile variables
var float m_projectileSpeed;
var ParticleSystem m_projectileParticle;
var ParticleSystem m_tracerParticle;


var bool TEMP_bPrintLogMessages; 	// delete this later. It will be useful for now

function SetUpComponent(JsonObject json, TMPawn parent)
{
	local int isAoE;

	if (m_owner != none)    // This will be set later
	{
		m_owner = parent;
	}
	m_iDamage = json.GetIntValue("damage");
	m_iRange = json.GetIntValue("range");
	m_rateOfFire =  json.GetIntValue("attackSpeed");
	m_rateOfFire = m_rateOfFire / 100;
	m_projectileSpeed = json.GetIntValue("projSpeed");
	m_NeutralDamageBonus = json.GetIntValue("addDamage");
	m_fireAndForgetDistance = json.GetIntValue("projDistance");
	m_idleDuration = -69;
	mAoERadius = json.GetIntValue("aoeRadius");
	mAoEPercentDamage = json.GetFloatValue("aoePercentDamage")/100;
	isAoE = json.GetIntValue("isAoE");

	mCanAttack = true;

	if( isAoE == 1 )
	{
		mIsAoE = true;
	}


	if( json.HasKey("forget"))
	{
		m_fireAndForget = true;	
	}
	else
	{
		m_fireAndForget = false;
	}
	
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentAttack newcomp;
	newcomp= new () class'TMComponentAttack' (self);
	newcomp.m_owner=newowner;
	newcomp.m_iDamage = m_iDamage;
	newcomp.m_iRange = m_iRange;
	newcomp.m_rateOfFire = m_rateOfFire;
	newcomp.m_bAttackMoveIsActive = false;
	newcomp.m_State = AS_NOTHING;
	newcomp.m_projectileSpeed = m_projectileSpeed;
	newcomp.m_onHitParticle = m_onHitParticle;
	newcomp.m_NeutralDamageBonus = m_NeutralDamageBonus;
	newcomp.m_fireAndForget = m_fireAndForget;
	newcomp.m_idleDuration = m_idleDuration;
	newcomp.m_fireAndForgetDistance = m_fireAndForgetDistance;


	// Taylor TODO: maybe make a ParticleSystem assignment class? Can retrieve and assign this stuff
	newcomp.m_onHitParticle = ParticleSystem'VFX_Leo.Particles.vfx_DoughBoy_Hit_Small_Red';
	
	if(newowner.m_Unit.m_unitName == "Conductor")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Conductor.Particles.P_Conductor_Projectile';
		newcomp.m_onHitParticle = ParticleSystem'VFX_Leo.Particles.vfx_DoughBoy_Hit_Small_Blue';
	}
	else if(newowner.m_Unit.m_unitName == "Oiler")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Projectile_FlameGoo';
		newcomp.m_onHitParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Default_Hit';
	}
	else if(newowner.m_Unit.m_unitName == "Rosie" || newowner.m_Unit.m_unitName == "CrippledRosie" || newowner.m_Unit.m_unitName == "FortniteRosie")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Sniper.Particles.P_Sniper_APProjectile';
	}
	else if(newowner.m_Unit.m_unitName == "Slender" || newowner.m_Unit.m_unitname == "Tower")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Slender.Particles.P_Slender_Projectile';
	}
	else if( newowner.m_Unit.m_unitName == "RoboMeister" )
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Sniper.Particles.P_Sniper_APProjectile';
		newcomp.m_onHitParticle =  ParticleSystem'VFX_Robomeister.Particles.P_Robomeister_on_hit';
		newcomp.mOnHitParticleScale = 15;
	}
	else if(newowner.m_Unit.m_UnitName == "Salvator" || newowner.m_Unit.m_UnitName == "Salvator_Assassin")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Salvator.Particles.vfx_acid';
		newcomp.m_onHitParticle= ParticleSystem'VFX_Salvator.Particles.vfx_salvator_onhit';
	}
	else if ( newowner.m_Unit.m_UnitName == "Disruptor")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonBall_Red';
		newcomp.m_onHitParticle = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonBall_onhit_Red';
	}
	else if(newowner.m_Unit.m_UnitName == "Turtle")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Turtle.Particles.P_Turtle_Rock';
		newcomp.m_onHitParticle = ParticleSystem'VFX_Turtle.Particles.vfx_turtle_egg_impact';
	}
	else if(newowner.m_Unit.m_UnitName == "Regenerator")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Regenerator.Particles.P_Regernator_Projectile';
	}
	else if(newowner.m_Unit.m_UnitName == "VineCrawler")
	{
		newcomp.m_bBeamParticle = true;
		newcomp.m_tracerParticle = ParticleSystem'VFX_VineCrawler.Particles.P_Vinecrawler_projectile';
	}
    else if(newowner.m_Unit.m_UnitName == "Regenerator")
	{
		newcomp.m_projectileParticle =ParticleSystem'VFX_Turtle.Particles.P_Turtle_Rock';
	}
	else if(newowner.m_Unit.m_UnitName == "HiveLord")
	{
		newcomp.m_projectileParticle =ParticleSystem'VFX_Turtle.Particles.P_Turtle_Rock';
	}
	else if(newowner.m_Unit.m_UnitName == "Grappler")
	{
		newcomp.m_projectileParticle = ParticleSystem'VFX_Regenerator.Particles.P_Regernator_Projectile';
		newcomp.m_onHitParticle = ParticleSystem'VFX_Oiler.Particles.vfx_Oiler_Muzzle_Special';
	}
	else if(newowner.m_Unit.m_UnitName == "RamBamQueen")
	{
		newcomp.m_projectileParticle = ParticleSystem'TM_Cocoon.RBQ_AutoAttack_PS';
		newcomp.m_onHitParticle = ParticleSystem'VFX_Leo.Particles.vfx_DoughBoy_Hit_Small_Blue';
		newcomp.mOnHitParticleScale = 2;
	}

	return newcomp;
}

//need to wait for the disruptor since it is team based
function InitDisruptorParticles()
{
	
	 if(m_owner.WorldInfo.NetMode != NM_DedicatedServer)
	 {
		if( TMPlayerReplicationInfo( m_owner.OwnerReplicationInfo ).allyId == 0)
		{
			m_projectileParticle = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonBall_Blue';
			m_onHitParticle = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonBall_onhit_Blue';
		}
		else
		{
			m_projectileParticle = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonBall_Red';
			m_onHitParticle = ParticleSystem'VFX_Disruptor.Effects.PS_PoisonBall_onhit_Red';
		}
	 }
}


function ReceiveFastEvent(TMFastEvent fe)
{
	if( self.IsAuthority() )
	{
		if (fe.commandType == "C_DoDamage" && m_owner.NotInteruptingCommand())
		{
			HandleDoDamageFE();
		}
		else if(fe.commandType == class'TMCommands'.default.MOVE || fe.commandType == class'TMCommands'.default.AI_MOVE)
		{
			HandleMoveFE( class'TMMoveFE'.static.fromFastEvent(fe) );
		}
		else if (fe.commandType == "C_Stop" || fe.commandType == "C_Stop_Attack")
		{
			HandleStopFE();
		}
	}
	else
	{
		/* Taylor 5/3/18 update:
			This block includes any stuff we need to simulate on the client. Ideally we'd simulate every fast event,
			but it's not worth doing the work for the ENTIRE state of this component.
		*/

		if(fe.commandType == "C_DoDamage")
		{
			DoPassiveAbility();
		}
		// If we get a move command and it's an attack move, make sure the client tells the movement animation to play
		else if(fe.commandType == class'TMCommands'.default.MOVE || fe.commandType == class'TMCommands'.default.AI_MOVE)
		{
			if(class'TMMoveFE'.static.fromFastEvent(fe).m_AttackMove == true)
			{
				// Wow, why would we do this? Because the client pawns don't know about the move command.
				m_owner.GetAnimationComponent().PlayMovementAnimation();
			}
		}
	}

	if(fe.commandType == class'TMCommands'.default.ATTACK && m_owner.NotInteruptingCommand())
	{
		HandleAttackFE(class'TMAttackFe'.static.fromFastEvent(fe));
	}
	//want this to be executed on the client as well
	else if(fe.commandType == "C_SpawnProjectile" && m_owner.NotInteruptingCommand())
	{
		SpawnProjectile( fe );
	}
	else if( fe.commandType == "C_StopAttack")
	{
		print("Fast event stop atatck");
		StopAttack();
	}
}

function StopAttack()
{
	print("STOP ATTACK");
	SetAttackState(AS_NOTHING);
	m_target = none;
	m_cachedPawn = none;
	m_cachedFastEvent = none;
	m_cachedMoveFE = none;
	m_attackAnimationTimeLeft = 0;
	m_owner.ClearAllTimers(self);
}

// TODO: delete this function later. For now let's keep it so I can switch everything to authority
function bool IsAuthority()
{
	return m_owner.IsAuthority();
}

//if we got issued a move command and it is an attack move, we then 
// will want to check for damage while walking around
function HandleMoveFE( TMMoveFE moveFE )
{
	local TMAttackFE fe;
	if(m_owner.NotInteruptingCommand())
	{
		m_bAttackMoveIsActive = moveFE.m_AttackMove;
		
		//we just got a move command from the player, need to get rid of any target and revert the state to nothing
		// unless it is an attack move, then we do not want to get ride of any already engaged targets
		if( moveFE.commandType == class'TMCommands'.default.MOVE && !m_bAttackMoveIsActive)
		{
			if( m_Target != none)
			{
				fe = new class'TMAttackFE'();
				fe.commandType = "AttackerDisengaged";

				fe.pawnId = m_Target.pawnId;
				fe.targetId = m_owner.pawnId;
				m_owner.SendFastEvent( fe );
			}
			
			print("HANDLEMOVE FE STOP ATTACK");
			StopAttack();
		}
	}
}

function HandleStopFE()
{
	print("Handle STOP FE Stop attack");
	StopAttack();

	// Why is m_bAttackMoveIsActive false for this but not StopAttack?
	m_bAttackMoveIsActive = false;
}

function HandleAttackFE(TMAttackFE atkFE)
{
	// Ignore attack commands for a target we're already attacking
	if(m_target != none)
	{
		if(m_target.pawnId ==  atkFE.targetId)
		{   
			return;
		}
	}

	if(!self.IsAuthority())
	{
		m_target = m_owner.m_TMPC.GetPawnByID( atkFE.targetId );
		return;
	}

	if( self.m_timeTillCanAttackFromMove > 0)
	{
		m_cachedPawn = m_owner.m_TMPC.GetPawnByID( atkFE.targetId );
		m_cachedFastEvent = atkFE; //may not need to cache this shit?
		m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, class'TMCommands'.default.STOP_MOVE ) );
		if(m_cachedPawn != none)
		{
			if(!IsInRange(m_cachedPawn,m_iRange) )
			{
				if( !IsTargetInsight(m_cachedPawn) )
				{   
					SendMoveToLocation( m_cachedPawn);
				}
				else
				{
					SendFollowTarget(m_cachedPawn);
				}
				return;
			}
		}
		
		
		DoIdleAnimation();
		
		
		return;
	}

	m_target = m_owner.m_TMPC.GetPawnByID( atkFE.targetId );
	if( m_Target == none && !self.m_AttackMove)
	{
		CommandFinished();
		return;
	}


	if(m_cachedPawn != none)
	{
		if(m_cachedPawn.pawnId == m_target.pawnId)
		{
			m_cachedPawn = none;
		}
	}


	DoAttackCommand();
}

// Let's change this from a "send" fastevent to receive. Will be possible once clients are simulating everything
function DoIdleAnimation()
{
	local TMAnimationFE fe;
	fe = new () class'TMAnimationFE';
	fe.m_commandType = "Idle";
	fe.m_pawnId = m_owner.pawnId;
	m_owner.SendFastEvent(fe);
}

/** Ideally just a helper, has some hacks for neutrals though */
function bool IsPawnHidden(TMPawn pawn)
{
	if (m_owner.IsPawnNeutral(m_owner))
	{
		return false;
	}

	return m_owner.m_Controller.GetFoWManager().IsPawnHidden( pawn );
}

function DoAttackCommand()
{
	if (m_owner.Health <= 0 || m_Target == m_owner || !mCanAttack )
	{
		return;
	}

	if (m_Target.Health <= 0 || IsPawnHidden(m_target))
	{
		if( FindNewTarget() == none)
		{
			CommandFinished();
			return;
		}
	}

	else if(!IsInRange(m_Target,m_iRange) )
	{
		if( !IsTargetInsight(m_target) )
		{   
			SendMoveToLocation( m_target);
		}
		else
		{
			SendFollowTarget(m_target);
		}
	}
	else
	{
		if(IsInRange(m_Target,m_iRange))
		{
			m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, class'TMCommands'.default.STOP_MOVE ) );
			DoAttackAnimation();
		}
	}
}

function FireCachedFastEvent()
{
	if( m_cachedMoveFE != none)
	{
		m_owner.ReceiveFastEvent( m_cachedMoveFE.toFastEvent() );
		m_owner.SendFastEvent( m_cachedMoveFE );
		SetAttackState( AS_MOVING_TO_TARGET );
	}
	
}

function SendFollowTarget(TMPawn target)
{
	// Instead of checking animation time, we should just see if the attack has happened once. The animation will only matter on our first attack
	if(self.m_attackAnimationTimeLeft > 0)
	{
		m_cachedFastEvent = none;
		m_cachedPawn = none;
		m_cachedMoveFE =  class'TMMoveFe'.static.create(target.Location , false, m_owner.pawnId ,, target, true, m_bAttackMoveIsActive, false );
		m_owner.SetTimer(m_attackAnimationTimeLeft,false,'FireCachedFastEvent',self);
	}
	else 	// This case is always the case if the animation has looped once
	{
		m_cachedFastEvent = none;
		m_cachedPawn = none;
		SetAttackState( AS_MOVING_TO_TARGET );
		m_owner.ReceiveFastEvent( class'TMMoveFe'.static.create(target.Location , false, m_owner.pawnId ,, target, true, m_bAttackMoveIsActive, false ).toFastEvent() );
		m_owner.SendFastEvent( class'TMMoveFe'.static.create(target.Location , false, m_owner.pawnId ,, target, true, m_bAttackMoveIsActive, false ) );
	}
	
}

function SendMoveToLocation(TMPawn target)
{
	local TMFastEvent fe;

	if(self.m_attackAnimationTimeLeft > 0)
	{
		m_cachedMoveFE = class'TMMoveFE'.static.create(m_target.Location,false,m_owner.pawnId,,,,false,false);
		m_owner.SetTimer(m_attackAnimationTimeLeft,false,'FireCachedFastEvent',self);
		print("Animation time left: " $ m_attackAnimationTimeLeft);
	}
	else
	{
		SetAttackState( AS_MOVING_TO_TARGET );
		fe = class'TMMoveFE'.static.create(m_target.Location,false,m_owner.pawnId,,,,false,false).toFastEvent();
		fe.position2 = m_target.Location;
		m_owner.ReceiveFastEvent( fe );
	}
}



function SetAttackState( AttackState newState )
{
	print("Changing attack state to " $ newState);
	m_state = newState;
}


function CommandFinished()
{
	print("COMMAND FINISHED");
	m_Target = none;
	SetAttackState( AS_NOTHING );
	//need to tell move to continue moving if it was an attack move
	if( m_bAttackMoveIsActive )
	{       
		m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, class'TMCommands'.default.RESUME_ATTACK_MOVE ) );
	}
	else
	{
		m_owner.UpdateUnitState( TMPS_IDLE );
		m_Owner.CommandQueueDo();
	}
}

function bool IsTargetInsight(TMPawn possibleTarget)
{
	local Actor a;
	local Vector hitLoc,
				 hitNorm;
				

	foreach m_owner.TraceActors(class'Actor',a,hitLoc,hitNorm,possibleTarget.Location,m_owner.Location)
	{
		if(a.IsA('BlockingVolume') || (a.IsA('StaticMeshActor') &&  a.bCanStepUpOn ))
		{
			return false;
		}
	}
	
	return true;
}

/*
This function tries to find a new target. If there is a target, it issues an attack command on that target
I don't like how this function works. It seems like we should have 2 functions.
*/
function TMPawn FindNewTarget()
{
	local TMPawn closestPawn;
	local float cachedClosestLocation;
	local array<TMPawn> TMPawnList;
	local array<UDKRTSPawn> similarIssuedPawns;
	local int i;

	if(!self.IsAuthority() )
	{
		return none;
	}

	cachedClosestLocation = 0;

	TMPawnList = m_owner.m_TMPC.GetTMPawnList();
	for(i = 0; i < TMPawnList.Length; ++i)
	{
		if(Vsize(TMPawnList[i].Location - m_owner.Location) < m_owner.m_Unit.m_agroRange)
		{
			if(closestPawn == none && TMPlayerReplicationInfo(TMPawnList[i].OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId && TMPawnList[i].Health > 0 && !IsPawnHidden(TMPawnList[i]))
			{
				closestPawn = TMPawnList[i];
				cachedClosestLocation = VSize(m_owner.Location - closestPawn.Location);
			}
			else
			{
				if(TMPlayerReplicationInfo(TMPawnList[i].OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId && TMPawnList[i].Health > 0 && !IsPawnHidden(TMPawnList[i]))
				{
					if(m_owner.IsPawnNeutral( closestPawn ))
					{
						if(!m_owner.IsPawnNeutral( TMPawnList[i]))
						{
							closestPawn = TMPawnList[i];
							cachedClosestLocation = VSize(m_owner.Location - closestPawn.Location);
						}
						else if(cachedClosestLocation > VSize(m_owner.Location - TMPawnList[i].Location ) )
						{
							closestPawn = TMPawnList[i];
							cachedClosestLocation = VSize(m_owner.Location - closestPawn.Location);
						}
					}
					else if(!m_owner.IsPawnNeutral( TMPawnList[i]))
					{
						if(cachedClosestLocation > VSize(m_owner.Location - TMPawnList[i].Location ) )
						{
							closestPawn = TMPawnList[i];
							cachedClosestLocation = VSize(m_owner.Location - closestPawn.Location);
						}
					}
				}
			}
		}
	}
	
	//no need to spam a none
	if(self.m_Target == none && closestPawn== none)
	{
		return none;
	}
	similarIssuedPawns.AddItem( m_owner);
	m_owner.SendAttackCommand(closestPawn,similarIssuedPawns, false,self.m_AttackMove);
	return closestPawn;
}

//// Dru TODO: static creational & move to calling location?
function DoAttackAnimation()
{
	// Send an animation fast event to the animation component
	local TMAnimationFe animation;

	if( !mCanAttack )
	{
		return;
	}

	print("DO ATTACK ANIMATION.");

	m_owner.UpdateUnitState( TMPS_ATTACK );
	animation = new () class'TMAnimationFe';
	animation.m_commandType = "Attack";
	animation.m_pawnID = m_owner.pawnId;
	animation.m_rate = m_rateOfFire;
	animation.m_bLooping = true;
	
	m_owner.SendFastEvent(animation);
	
	m_attackAnimationTimeLeft = m_rateOfFire;
	
	CalculateIdleDuration();
}

 function CalculateIdleDuration()
{
	local float ratio;
	if(m_idleDuration == -69)
	{
		ratio = m_rateOfFire / m_owner.m_Unit.m_attackInfo.animationDuration;
		m_idleDuration = ratio * m_owner.m_Unit.m_attackInfo.attackTimeNotification; //this will give us when the 
		m_idleDuration = m_rateOfFire - m_idleDuration; //this will give us the duration we need from the last damage to begin attacking again
	}
}

function bool IsInRange(TMPawn otherPawn, int range)
{
	local float distance;

	distance = VSize2D(m_owner.Location - otherPawn.Location);
	distance -= m_owner.GetCollisionRadius();
	distance -= otherPawn.GetCollisionRadius();

	return (distance < range);
}


//function to update whatever you need
simulated  function UpdateComponent(float dt)
{
	local Rotator DesiredRotation;
	local array<UDKRTSPawn> similar;
	//local TMPawn pawn;
	Local TMAttackFe fe;
	//we still want to update in the case we are doing an attack move, if we are


	
	if(!self.IsAuthority())
	{
		return;
	}


	if(m_State == AS_MOVING_TO_TARGET && m_cachedPawn != none)
	{
		if(IsInRange(m_cachedPawn,m_iRange))
		{
			m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, class'TMCommands'.default.STOP_MOVE ) );
			DoIdleAnimation();
			SetAttackState(AS_Nothing);
			print("UPDATE COMPONENT AS_NOTHING");
		}
	}

	

	if(m_attackAnimationTimeLeft > 0)
	{
		m_attackAnimationTimeLeft -=dt;
	}

	if(m_timeTillCanAttackFromMove > 0)
	{
		m_timeTillCanAttackFromMove -= dt;
	}
	else if( m_cachedFastEvent != none)
	{
		HandleAttackFE( m_cachedFastEvent );
		m_cachedFastEvent = none;
	}


	if(m_cachedPawn != none && m_cachedPawn.Health > 0)
	{
		DesiredRotation = Rotator(m_cachedPawn.Location - m_owner.Location);
		DesiredRotation.Pitch = 0;
		DesiredRotation.Roll = 0;
		if(m_owner.Rotation != DesiredRotation)
		{
			m_owner.FaceRotation(RLerp( m_owner.Rotation,DesiredRotation, FClamp(m_owner.TurnSpeed * dt, 0.01f, 1.f),true), dt);
		}
	}
	//if the pawn we were waiting on just died, we should find another
	else if(m_cachedPawn != none && m_cachedPawn.Health <= 0)
	{
		if( FindNewTarget() == none && !self.m_AttackMove)
		{
			CommandFinished();
			return;
		}
	}

	if( (m_owner == none ||  m_target == none  ) && !m_bAttackMoveIsActive)
	{
		return;
	}

	if(m_owner.Health <= 0 )
	{

		m_Target = none;
		return;
	}

	///this should NOOTTTT BE CHECKIGN EVERY FRAME, not efficient, every other
	if( m_bAttackMoveIsActive && m_target == none && m_cachedFastEvent == none)
	{
		FindNewTarget();
	}

	
	
	if(m_Target != none)
	{
		if(m_cachedPawn == none && m_Target.Health > 0)
		{
			DesiredRotation = Rotator(m_Target.Location - m_owner.Location);
			DesiredRotation.Pitch = 0;
			DesiredRotation.Roll = 0;
			if(m_owner.Rotation != DesiredRotation)
			{
				m_owner.FaceRotation(RLerp( m_owner.Rotation,DesiredRotation, FClamp(m_owner.TurnSpeed * dt, 0.01f, 1.f),true), dt);
			}
		}

		if( IsPawnHidden(m_target) )
		{
			similar.AddItem( m_target);
			m_owner.HandleCommand(C_Move,true,m_target.Location,,similar);
			m_target = none;
			return;
		}

		if(m_state == AS_MOVING_TO_TARGET )
		{
			if(m_target.Health <= 0)
			{
				if( FindNewTarget() == none && !self.m_AttackMove)
				{
					CommandFinished();
					return;
				}
				return;
			}


			if(IsInRange(m_Target,m_iRange) && IsTargetInsight(m_target))
			{
				m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE(m_owner.pawnID, class'TMCommands'.default.STOP_MOVE ) );
				if( m_timeTillCanAttackFromMove > 0 )
				{
					fe = new() class'TMAttackFe';
					fe.targetId = m_Target.pawnId;
					fe.m_AttackMove = false;
					m_cachedFastEvent = fe;
					DoIdleAnimation();
				}
				else
				{
					DoAttackAnimation();
				}
				SetAttackState( AS_NOTHING );
			}
		}
		//dontttt really like how this checks every frame may want to do it every other frame?
		else if(!IsInRange(m_Target,m_iRange) && m_state != AS_MOVING_TO_TARGET ) /*|| IsPawnHidden(m_Target)*/
		{
			if( !IsTargetInsight(m_target) )
			{   
				SendMoveToLocation( m_target);
			}
			else
			{
				SendFollowTarget(m_target);
			}
		}
	}
	
}


function SpawnProjectile(TMFastEvent fe)
{
	
	local TMProjectile proj;
	local Vector socketLoc;
	local rotator socketRot;
	local TMAttackFE attackFE, afe;
	local TMPawn targetPawn;

	/* Taylor Update 4/3/18
		I believe the infinite range bug is happening because 'SendFollowTarget()' could fail.
		If SendFollowTarget's move command fails, the pawn will remain in the attack animation.
		If the attack animation is playing, he will continuously keep dealing damage and not stop
			since SendFollowTarget() is failing.

		If SendFollowTarget() fails, then AS_MOVING_TO_TARGET will be our current state. Right now
			just print out log messages if we think infinite range bug is happening. Next time we
			see the infinite range bug, if this is spamming then we have a potential solution.
	*/
	if( m_State == AS_MOVING_TO_TARGET )
	{
		SendFollowTarget(m_Target);
		return;
	}
	print("SPAWN PROJ");

	attackFE = class'TMAttackFE'.static.fromFastEvent( fe );
	targetPawn = m_owner.m_TMPC.GetPawnByID( attackFE.targetId );

	if((targetPawn == none ||targetPawn.Health <= 0)  && self.IsAuthority() )
	{   
		if( FindNewTarget() == none && !self.m_AttackMove)
		{
			CommandFinished();
			return;
		}
		return;
	}
	
	if( m_projectileParticle != none && targetPawn != none)
	{
		
		m_owner.Mesh.GetSocketWorldLocationAndRotation('ProjectileSpawn',socketLoc,socketRot,);

		proj = m_owner.Spawn(class'TMProjectile',,,socketLoc,m_owner.Rotation,,);
		if(self.IsAuthority())
		{
			afe = new() class'TMAttackFe';
			afe.targetId = m_Target.pawnId;
			afe.m_AttackMove = false;
			m_cachedFastEvent = afe;
		}
		if( proj != none )
		{
			proj.SetOnHitParticle( m_onHitParticle, mOnHitParticleScale );
			m_timeTillCanAttackFromMove = m_idleDuration; //time till we can attack again if we move
			if( !m_fireAndForget)
			{
			
				if(targetPawn.IsPawnNeutral(targetPawn))
				{
					proj.FireProjectile(targetPawn ,m_owner ,m_projectileParticle , m_projectileSpeed, (m_iDamage + m_NeutralDamageBonus) * m_owner.m_Unit.m_fDamagePercentIncrease,,, mIsAoE, mAoERadius, mAoEPercentDamage);
					if(targetPawn.Health - (m_iDamage + m_NeutralDamageBonus ) <= 0 && self.IsAuthority())
					{
						if( FindNewTarget() == none  && !self.m_AttackMove)
						{
							CommandFinished();
							return;
						}
						return;
					}
				}
				else
				{
					proj.FireProjectile(targetPawn ,m_owner ,m_projectileParticle , m_projectileSpeed,m_iDamage * m_owner.m_Unit.m_fDamagePercentIncrease,,, mIsAoE, mAoERadius, mAoEPercentDamage);
					if(targetPawn.Health - m_iDamage  <= 0 && self.IsAuthority())
					{
						if( FindNewTarget() == none  && !self.m_AttackMove)
						{
							CommandFinished();
							return;
						}
						return;
					}
				}
			}
			else
			{
				if(targetPawn.IsPawnNeutral(targetPawn))
				{
					proj.FireProjectile(targetPawn ,m_owner ,m_projectileParticle , m_projectileSpeed, (m_iDamage + m_NeutralDamageBonus) * m_owner.m_Unit.m_fDamagePercentIncrease ,m_fireAndForget, m_fireAndForgetDistance,mIsAoE, mAoERadius, mAoEPercentDamage);
				}
				else
				{
					proj.FireProjectile(targetPawn ,m_owner ,m_projectileParticle , m_projectileSpeed, m_iDamage * m_owner.m_Unit.m_fDamagePercentIncrease,m_fireAndForget,m_fireAndForgetDistance, mIsAoE, mAoERadius, mAoEPercentDamage);
				}
			}
		}
		if(!IsInRange(targetPawn,m_iRange) && self.IsAuthority() && targetPawn.Health > 0 )
		{   
			SendFollowTarget( targetPawn );
		}	
	}
	
}


function ApplyDamage(TMPawn target)
{
	local int bonusDamage;

	if(m_owner.IsPawnNeutral( target) )
	{
		bonusDamage = m_NeutralDamageBonus;
	}

	target.TakeDamage( (m_iDamage + bonusDamage) * m_owner.m_Unit.m_fDamagePercentIncrease, m_owner.Controller, target.Location, target.Location, class'DamageType',,m_owner);
}

///i don't like how it is not checking if the target is in range, it should be in update, checking if the target is in fact in range
//conrad
function HandleDoDamageFE()
{
	local TMAttackFe fe;

	if(class'UDKRTSPawn'.static.IsValidPawn(m_Target) && m_owner != none && m_projectileParticle == none)
	{
		/* Taylor Update 4/2/18
			I believe the infinite range bug is happening because 'SendFollowTarget()' could fail.
			If SendFollowTarget's move command fails, the pawn will remain in the attack animation.
			If the attack animation is playing, he will continuously keep dealing damage and not stop
				since SendFollowTarget() is failing.

			If SendFollowTarget() fails, then AS_MOVING_TO_TARGET will be our current state. Right now
				just print out log messages if we think infinite range bug is happening. Next time we
				see the infinite range bug, if this is spamming then we have a potential solution.
		*/
		if( m_State == AS_MOVING_TO_TARGET )
		{
			SendFollowTarget(m_Target);
			return;
		}

		ApplyDamage(m_Target);
		DoPassiveAbility();
		m_timeTillCanAttackFromMove = m_idleDuration; //we need to wait this much more time until we can attack again
			
		if (m_Target.Health <= 0)
		{    
			if(  FindNewTarget() == none && !self.m_AttackMove)
			{
				CommandFinished();
				return;
			}
			return;
		}

		if(!IsInRange(m_Target,m_iRange) )
		{   
			SendFollowTarget( m_Target );
			return;
		}	

		fe = new() class'TMAttackFe';
		fe.targetId = m_Target.pawnId;
		fe.m_AttackMove = false;
		m_cachedFastEvent = fe;
		
	}
	//we should try to find another target then
	else if( m_owner != none && m_projectileParticle == none)
	{
		if( FindNewTarget() == none && !self.m_AttackMove)
		{
			CommandFinished();
			return;
		}
	}
}

function DoPassiveAbility()
{
	local TMPAwn tempPawn;
	//if we have a projectile then we have our own on hit
	if(m_owner != none )
	{
		if(m_owner.m_TMPC.WorldInfo.NetMode != NM_DedicatedServer && ( m_Target != none || m_clientTarget != none))
		{
			tempPawn = m_target == none ? m_clientTarget : m_target;
			m_owner.m_TMPC.m_ParticleSystemFactory.Create(m_onHitParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), tempPawn.Location);

			if(!IsPawnHidden(tempPawn))
			{
				//Doughboy on-hit sound
				m_owner.m_TMPC.m_AudioManager.requestPlayEmitterSFX(m_onHitParticle, tempPawn);
			}

			// This is only used by the vinecrawler, which seems messy
			if(self.m_bBeamParticle)
			{
				m_owner.m_TMPC.m_ParticleSystemFactory.CreateBeamWithScale(m_tracerParticle, m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner.Location, tempPawn.Location, 3, 4);
			}
		}
	}
}

/* DoAttack
	Performs an attack. Will spawn a projectile or instantly deal the damage.
	Checks that the target is still in range AFTER dealing the damage.
		This allows our unit to get in range, start an attack, then succeed with
		the attack before having to continue following the target.

	GOAL: Replace SpawnProjectile and DoDamage with this one function, since they
		effectively do the same thing: perform an attack.
*/
function DoAttack(TMFastEvent fe, bool isProjectileAttack)
{
	local TMAttackFe atkFE;

	if(class'UDKRTSPawn'.static.IsValidPawn(m_Target) == false)
	{
		// If our target isn't valid, try to find a new target
		// I don't quite fully understand this conditional, it looks like we try to get a
		// 	target, but if we fail and m_AttackMove is true then we should continue?
		// 	I think that would put us in an attack loop.
		if( FindNewTarget() == none && !self.m_AttackMove)
		{
			CommandFinished();
		}

		// We have nothing to do if our target is invalid
		return;
	}

	// How would "DoAttack" get called if we were moving to our target?
	// 	This bad case happens if the attack animation gets stuck. Investigating elimating this check.
	if( m_State == AS_MOVING_TO_TARGET )
	{
		SendFollowTarget(m_Target);
		return;
	}

	if(isProjectileAttack == false)
	{
		ApplyDamage(m_Target);
		DoPassiveAbility();
		m_timeTillCanAttackFromMove = m_idleDuration; //we need to wait this much more time until we can attack again
	}
	else
	{
		// Spawn Projectile
	}

	// If the target is now dead, do the same odd find new target logic as above
	if (m_Target.Health <= 0)
	{    
		if(  FindNewTarget() == none && !self.m_AttackMove)
		{
			CommandFinished();
		}

		return;
	}

	// If we are no longer in range, send a new follow target command
	if(!IsInRange(m_Target,m_iRange) )
	{   
		SendFollowTarget( m_Target );
		return;
	}

	// Cache an attack command? Not sure why. Need to investigate more.
	atkFE = new() class'TMAttackFe';
	atkFE.targetId = m_Target.pawnId;
	atkFE.m_AttackMove = false;
	m_cachedFastEvent = atkFE;
}

// TEMP print function for Taylor to learn more about the attack component
function print(string inMessage)
{
	if(TEMP_bPrintLogMessages)
	{
		`log("TMComponentAttack: " $ inMessage);
	}
}

DefaultProperties
{
	TEMP_bPrintLogMessages = false;
}
