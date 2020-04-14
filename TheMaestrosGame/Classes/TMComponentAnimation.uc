class TMComponentAnimation extends TMComponent;

var AnimTree loadedAnimTree;
var AnimSet loadedAnimSet;

var AnimNodeBlendList m_MainStates;
var AnimNodeBlendList m_MovementState;

var AnimNodeBlendList m_DeathState;
var AnimNodeBlendList m_AttackingState;

var AnimNodeBlendList m_multiDeath;
var AnimNodeBlendList m_multiAttack;
var AnimNodeBlendList m_multiWalk;
var AnimNodeBlendList m_multiAbility;

var AnimNodePlayCustomAnim m_attack1;
var AnimNodePlayCustomAnim m_attack2;
var AnimNodePlayCustomAnim m_attack3;
var AnimNodePlayCustomAnim m_attack4;

var AnimNodeBlendList m_currentMainState;

const MOVEMENT_STATE_INDEX = 0;
const ATTACK_STATE_INDEX = 1;

const MOVEMENT_WALK_STATE_INDEX = 1;
const MOVEMENT_DEATH_STATE_INDEX = 2;

const ATTACK_ABILITY_STATE_INDEX = 1;

var float m_standardBlendTime;
var int m_currentChildIndex;
var string animTreeName;
var string animSetName;
var bool m_bDead;

function SetUpComponent(JsonObject json,TMPawn parent)
{
	animTreeName = json.GetStringValue("AT");
	animSetName = json.GetStringValue("AS");
	m_currentChildIndex =  -1;
	m_bDead = false;

	loadedAnimTree = AnimTree(DynamicLoadObject(animTreeName,class'AnimTree'));
	loadedAnimSet = AnimSet(DynamicLoadObject(AnimSetName,class'AnimSet'));
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMComponentAnimation newcomp;

	self.m_owner=newowner;
	newcomp= new () class'TMComponentAnimation' (self);

	newcomp.loadedAnimTree = self.loadedAnimTree;
	newcomp.m_owner.Mesh.SetAnimTreeTemplate(newcomp.loadedAnimTree);

	newcomp.loadedAnimSet = self.loadedAnimSet;
	newcomp.m_owner.Mesh.AnimSets.AddItem(newcomp.loadedAnimSet);

	newcomp.m_owner.AnimTreeUpdated(m_owner.Mesh);
	newcomp.m_owner.ForceUpdateComponents(true,false);
	newcomp.m_bDead = false;
	newcomp.SetUpAnimationNodes();
	newcomp.m_standardBlendTime = 0.1f;
	return newcomp;
}

function RemoveServerParticleNotifies()
{
	local int i,j;
	local name becausewefuckinghaveto;
	if(m_owner != none)
	{
	 	for(i =0; i < m_owner.Mesh.AnimSets[0].Sequences.Length; i++)
		{
			for(j=0;j <  m_owner.Mesh.AnimSets[0].Sequences[i].Notifies.Length; j++)
			{
				 if (  m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j].Notify == none)
					  continue;

				if( ( m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j].Notify.IsA('AnimNotify_Trails') || m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j].Notify.IsA('AnimNotify_PlayParticleEffect') ) && m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer )
				{
					m_owner.Mesh.AnimSets[0].Sequences[i].Notifies.RemoveItem( m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j] );
					j= 0;
				}

				if( m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j].Notify.IsA('AnimNotify_Script'))
				{
					becausewefuckinghaveto = AnimNotify_Script(m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j].Notify).NotifyName;
					if(becausewefuckinghaveto == 'DoDamage' || becausewefuckinghaveto == 'SpawnProjectile')
					{
						
						m_owner.m_Unit.m_attackInfo.animationDuration =  m_owner.Mesh.AnimSets[0].Sequences[i].SequenceLength;
						m_owner.m_Unit.m_attackInfo.attackTimeNotification = m_owner.Mesh.AnimSets[0].Sequences[i].Notifies[j].Time;   
					}		
				}
			}
		}
	}
}

function SetUpAnimationNodes()
{
	local float rate;
	m_MainStates = AnimNodeBlendList(m_owner.Mesh.FindAnimNode('MainStates'));
	
	if(m_MainStates != none)
	{
		m_MainStates.SetActiveChild(0,1);
		m_MovementState = AnimNodeBlendList(m_MainStates.FindAnimNode('MovementState'));
		m_multiDeath = AnimNodeBlendList(m_MainStates.FindAnimNode('MultiDeath'));
		m_multiWalk = AnimNodeBlendList(m_MainStates.FindAnimNode('MultiWalk'));
		m_multiAbility = AnimNodeBlendList(m_MainStates.FindAnimNode('MultiAbility'));
		//
		m_AttackingState = AnimNodeBlendList(m_MainStates.FindAnimNode('AttackingState'));

		if(m_AttackingState != none)
		{
			m_attack1 = AnimNodePlayCustomAnim(m_AttackingState.FindAnimNode('attack1'));
			if(m_attack1 != none)
			{
				m_attack1.SetActorAnimEndNotification(true);
			}

			m_attack2 = AnimNodePlayCustomAnim(m_AttackingState.FindAnimNode('attack2'));
			if(m_attack2 != none)
			{
				m_attack2.SetActorAnimEndNotification(true);
			}

			m_attack3 = AnimNodePlayCustomAnim(m_AttackingState.FindAnimNode('attack3'));
			if(m_attack3 != none)
			{
				m_attack3.SetActorAnimEndNotification(true);
			}

			m_attack4 = AnimNodePlayCustomAnim(m_AttackingState.FindAnimNode('attack4'));
			if(m_attack4 != none)
			{
				m_attack4.SetActorAnimEndNotification(true);
			}
		}

		m_multiAttack = AnimNodeBlendList(m_MainStates.FindAnimNode('MultiAttack'));
		///this is temp to get an idle animation in
		if(m_MovementState != none)
		{
			rate = 1.0f;
			if(m_owner != none)
			{
				if(m_owner.m_Unit.m_UnitName == "VineCrawler_Wall")
				{
					rate = 0.12f;
				}
			}
			m_MovementState.SetActiveChild(0,1);
			m_MovementState.PlayAnim(false,rate,0);
		}
		
	}
	if(m_owner != none && m_MainStates != none)
	{
		//if(m_owner.m_TMPC.WorldInfo.NetMode == NM_DedicatedServer)
		//{
			RemoveServerParticleNotifies();
		//}
	}
}

function bool TrySetActiveState(AnimNodeBlendList mainState, int childIndex, float blendTime)
{
	if (mainState != m_currentMainState)
	{
		m_currentMainState = mainState; 
		if (mainState == m_AttackingState)
		{
			m_MainStates.SetActiveChild(ATTACK_STATE_INDEX, m_standardBlendTime);
		}
		else if (mainState == m_MovementState)
		{
			m_MainStates.SetActiveChild(MOVEMENT_STATE_INDEX, m_standardBlendTime);
		}
		m_currentChildIndex = -1;
	}

	if (m_currentChildIndex != childIndex)
	{
		m_currentChildIndex = childIndex;
		mainState.SetActiveChild(childIndex, blendTime);
		return true;
	}

	return false;
}

function float GetBlendTimeToUseAttack(float blendTime)
{
	if (m_multiAttack == none)
	{
		 return blendTime;
	}

	return m_standardBlendTime;
}

function PlayAttackAnim(int childIndex, float blendTime, bool looping, float rate, float startTime, optional float duration)
{
	local int range;

	if(m_AttackingState == none)
	{
		`warn("Trying to play attack anim without an attacking state anim node");
		return;
	}

	if (!TrySetActiveState(m_AttackingState, childIndex, GetBlendTimeToUseAttack(blendTime)))
	{
		return;
	}

	if(m_multiAttack == none)
	{
		m_attack1.PlayCustomAnimByDuration('attack01', duration, -1, -1, looping, true);
	}
	else
	{
		range = RandRange(0, m_multiAttack.Children.Length);
		m_multiAttack.SetActiveChild(range, blendTime);
		if(range == 0)
		{
			m_attack1.PlayCustomAnimByDuration('attack01', duration, blendTime,, looping,);
		}
		else if(range == 1)
		{
			m_attack2.PlayCustomAnimByDuration('attack02', duration, blendTime,, looping,);
		}
		else if(range == 2)
		{
			m_attack3.PlayCustomAnimByDuration('attack03', duration, blendTime,, looping,);
		}
		else if(range == 3)
		{
			m_attack4.PlayCustomAnimByDuration('attack04', duration, blendTime,, looping,);
		}
	}
}

function float GetBlendTimeToUseMovement(int childIndex, float blendTime)
{
	if(childIndex == MOVEMENT_WALK_STATE_INDEX && m_multiWalk != none)
	{
		return m_standardBlendTime;
	}
	else if(childIndex == MOVEMENT_DEATH_STATE_INDEX && m_multiDeath != none)
	{
		return m_standardBlendTime;
	}
	else
	{
		return blendTime;
	}
}

function PlayMovementAnim(int childIndex, float blendTime, bool looping, float rate, float startTime)
{
	local int range;

	if (m_MovementState == none)
	{
		`warn("Trying to movement animation without an movement state anim node");    
		return;
	}

	if (!TrySetActiveState(m_MovementState, childIndex, GetBlendTimeToUseMovement(childIndex, blendTime)))
	{
		return;
	}

	if(childIndex == MOVEMENT_WALK_STATE_INDEX && m_multiWalk != none)
	{
		range = RandRange(0,m_multiWalk.Children.Length);
		m_multiWalk.SetActiveChild(range,blendTime);
		m_multiWalk.PlayAnim(looping, rate, startTime);
	}
	else if(childIndex == MOVEMENT_DEATH_STATE_INDEX && m_multiDeath != none)
	{
		range = RandRange(0,m_multiDeath.Children.Length);
		m_multiDeath.SetActiveChild(range,blendTime);
		m_multiDeath.PlayAnim(looping, rate, startTime);
	}
	else
	{
		m_MovementState.PlayAnim(looping, rate, startTime);
	}
}

function PlayAbilityAnim(int multiAbilityChildIndex, float blendTime, bool looping, float rate, float startTime)
{
	if (m_AttackingState == none)
	{
		`warn("Trying to play attack anim without an attacking state anim node");
	}

	if (m_multiAbility != none)
	{
		// MultiAbilities will have the multiability node called multiple times. Let him through
		TrySetActiveState(m_AttackingState, ATTACK_ABILITY_STATE_INDEX, blendTime);
	}
	else if(!TrySetActiveState(m_AttackingState, ATTACK_ABILITY_STATE_INDEX, blendTime))
	{
		return;
	}

	if(m_multiAbility != none)
	{
		m_multiAbility.SetActiveChild(multiAbilityChildIndex, blendTime);
		m_multiAbility.PlayAnim(false,rate,startTime);
	}
	else
	{
		m_AttackingState.PlayAnim(false,rate,startTime);
	}
}

simulated function PauseAnimation()
{
	m_MainStates.StopAnim();
}

simulated function UnPauseAnimattion()
{
	local TMFastEvent fe;
	fe = new () class'TMFastEvent';
	fe.commandType = "Idle";
	ReceiveFastEvent(fe);
}

simulated function ReceiveFastEvent(TMFastEvent fe)
{
	local TMAnimationFE animationFE;

	if(!m_bDead )
	{
		if(fe.commandType == "Attack")
		{
			PlayAttackAnim(0,0.1f,fe.bool1,1,0,fe.floats.C);
		}
		else if(fe.commandType == "Ability")
		{
			animationFE = class'TMAnimationFE'.static.fromFastEvent( fe ); 	// create the animation FE here since others don't seem to need it
			PlayAbilityAnim( fe.floats.A, 0.1f, false, animationFE.m_rate, 0 );
		}
		else if(fe.commandType == "Idle" )
		{
			//throwing this in here because for some reason in 1v1
			//it calls a idle animation, but not in standalone, quick and dirty fix
			if(m_owner.m_currentState != TMPS_ABILITY)
			{
				PlayMovementAnim(0,0.1f,false,1 * m_owner.m_Unit.m_Data.animRatio,0);
			}
		}
		else if(fe.commandType == "Move_Anim")
		{
			PlayMovementAnim(1,0.1f,true,1 * m_owner.m_Unit.m_Data.animRatio,0);
		}
		else if(fe.commandType == "dead")
		{
			m_bdead = true;
			PlayMovementAnim(2,0.1f,false,1 * m_owner.m_Unit.m_Data.animRatio,0);
		}
		else if(fe.commandType == "C_Stop")
		{
			if(m_owner.m_currentState != TMPS_JUGGERNAUT)
			{
				PlayMovementAnim(0,0.1f,false,1 * m_owner.m_Unit.m_Data.animRatio,0);
			}
		}
		else if(fe.commandType == "C_SpawnFinished" && m_owner.m_Unit.m_UnitName == "DoughBoy")
		{
			PlayMovementAnim(3,0.1f,false,1 * m_owner.m_Unit.m_Data.animRatio,0);
		}
		else if(fe.commandType == "Pause_Animation")
		{
			PauseAnimation();
		}
		else if(fe.commandType == "UnPause_Animation")
		{   
			UnPauseAnimattion();
		}
		else if(fe.commandType == "Animation")
		{
			PlayMovementAnim(fe.int1 ,0.1f,false,1 * m_owner.m_Unit.m_Data.animRatio,0);
		}
	
	}

}


// NEW Functions! Taylor is adding this functions here, moved from the ability class
//  It makes sense to me that the animation class should have these function, but
//  let me know if it shouldn't.
simulated function PlayIdleAnimation()
{
	local TMAnimationFe animation;
	animation = new () class'TMAnimationFe';
	animation.m_commandType = "Idle";
	animation.m_pawnID = m_owner.pawnId;
	animation.m_animationIndex = 1;
	m_owner.ReceiveFastEvent(animation.toFastEvent());
}

simulated function PlayAbilityAnimation( float inRate = 1, int inIndex = 1 )
{
	local TMAnimationFe animation;
	animation = new () class'TMAnimationFe';
	animation.m_commandType = "Ability";
	animation.m_pawnID = m_owner.pawnId;
	animation.m_animationIndex = inIndex;
	animation.m_rate = inRate;
	m_owner.ReceiveFastEvent(animation.toFastEvent());
}

simulated function PlayMovementAnimation()
{
	local TMAnimationFe animation;
	animation = new () class'TMAnimationFe';
	animation.m_commandType = "Move_Anim";
	animation.m_pawnID = m_owner.pawnId;
	animation.m_animationIndex = 1;
	m_owner.ReceiveFastEvent(animation.toFastEvent());
}
