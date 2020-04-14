class TMPlayerAIController extends TMAIController;

var float mSummonRadiusSq;
var array<int> m_AttackingPawns;
var int m_neutralPawnID;

var bool 	mIsAttacking;

var TMAIAbilityStrategy mAIAbilityStrategy;
var float 	mChanceToCastAbility;

event PostBeginPlay()
{
	super.PostBeginPlay();
//	SetTimer(1/30,true,'LookToEngageEnemies',);
	m_timeSinceLastAttack = 0;
}



function NotifyTakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local array<UDKRTSPawn> similarPawns;
	if (TMPawn(DamageCauser) != None)
	{
		m_timeSinceLastAttack = 0;
		//will also cause the pawn to attack if they are in an idle state
		if( TMPawn(Pawn).m_currentState == TMPS_IDLE && Vsize(DamageCauser.Location - Pawn.Location) < TMPawn(Pawn).m_Unit.m_fEngageRange)
		{
			similarPawns.AddItem( UDKRTSPawn(Pawn) );
			TMPawn(Pawn).HandleCommand(C_Attack,false,,TMPawn(DamageCauser), similarPawns, false);
		}
		//SummonHelp( TMPawn(Pawn), TMPawn(DamageCauser));
	
		/*
		for(i=0; i < m_AttackingPawns.Length; i++)
		{
			if( m_AttackingPawns[i] == TMPawn(DamageCauser).pawnId )
			{
				break;
			}
		}
		if( i == m_AttackingPawns.Length )
		{
			m_AttackingPawns.AddItem( TMPawn(DamageCauser).pawnId );
		}
		*/
	}
	
	super.NotifyTakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}


function AttackerDisengaged(int pawnID)
{
	local TMPawn pw;
//	local array<UDKRTSPawn> similarPawns;
	
	if(m_AttackingPawns.Length != 0)
	{
		m_AttackingPawns.RemoveItem( pawnID );
		while( pw == none && m_AttackingPawns.Length != 0)
		{
			pw = TMPawn(Pawn).m_TMPC.GetPawnByID( m_AttackingPawns[0] );
			if(pw == none)
			{
				m_AttackingPawns.Remove(0,1);
			}
		}
		/*
		if( pw != none)
		{
			similarPawns.AddItem( TMPawn(Pawn));
			TMPawn(Pawn).HandleCommand(C_ATTACK,false,,pw,similarPawns,false);
		}	
		*/
	}
}
// attacked pawn is the one who just recieved damage
// attacking pawn is the one who did the damage


function bool IsAuthority()
{
	return ((TMPawn(Pawn).m_TMPC.WorldInfo.NetMode == NM_DedicatedServer || TMPawn(Pawn).m_TMPC.WorldInfo.NetMode == NM_ListenServer || TMPawn(Pawn).m_TMPC.WorldInfo.NetMode == NM_Standalone));
}

function LookToEngageEnemies()
{
	local TMPawn myPawn, foundPawn;
	local array<UDKRTSPawn> similarPawns;
	if(Pawn != none)
	{
		myPawn = TMPawn(Pawn);
		//we had to put not hidden here because when the unit first spawns it will be hidden
		//animation will not play if they are hidden, so we will wait till they are not hidden and are idle to check if we can
		//do our agro
		if(myPawn.m_currentState == TMPS_IDLE && !myPawn.bHidden)
		{
			foreach myPawn.OverlappingActors(class'TMPawn',foundPawn, myPawn.m_Unit.m_agroRange,, true)
			{
				if (TMPlayerReplicationInfo(foundPawn.OwnerReplicationInfo).allyId != TMPlayerReplicationInfo(myPawn.OwnerReplicationInfo).allyId && foundPawn.Health > 0 && !foundPawn.IsPawnNeutral(foundPawn))
				{
					similarPawns.AddItem(myPawn);
					myPawn.HandleCommand(C_ATTACK,false,,foundPawn,similarPawns,false);
					return;
				}
			}
		}
	}
}

function SetAttackingState( bool inIsAttacking )
{
	mIsAttacking = inIsAttacking;
}

function SetupAIAbilityStrategy(float inChanceToCastAbility)
{
	// This hack shouldn't exist. We need a way to initialize AIControllers on bots or have a separate AIController for them
	if( mAIAbilityStrategy == none )
	{
		mChanceToCastAbility = inChanceToCastAbility;
		mAIAbilityStrategy = class'TMAIAbilityStrategyFactory'.static.CreateAIAbilityStrategy( TMPawn(self.Pawn) );
	}
}

function Tick(float dt)
{
	//magic number, but nothing will have more than this to start health regen
	if( m_timeSinceLastAttack <= 100)
	{
		m_timeSinceLastAttack += dt;
	}

	//prvent float overflow if someone just sits forever, it is possible, unlikely, but still possible


	if( mIsAttacking )
	{
		if( Rand( 100 / mChanceToCastAbility ) == 0 ) 	// Taylor TODO: make this randomness be checked on a timer
		{
			mAIAbilityStrategy.TryToCastAbility();
		}
	}
	
	super.Tick(dt);
}

DefaultProperties
{
	mChanceToCastAbility = 1f; 	// out of 100%
	mSummonRadiusSq = 360000;
}
