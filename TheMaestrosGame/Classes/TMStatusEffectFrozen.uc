class TMStatusEffectFrozen extends TMStatusEffect;

/* TMStatusEffectFrozen
 * This is a timer-less status effect. It is required to be removed
 *	by the pawn who applied the effect. While this status effect is
 *	active, the unit will receive no updates.
 */

function TMComponent makeCopy(TMPawn newowner)
{
	local TMStatusEffectFrozen newcomp;
	newcomp= new () class'TMStatusEffectFrozen' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	return newcomp;
}

// Block stacking, since we won't use that for the Frozen SE. In future can keep a count of how many times it was applied and do a self remove from compArray later
function StackStatusEffect(TMStatusEffectFE seFE)
{
}


function Begin()
{
	if( !m_owner.bCanBeDamaged )
	{
		return;
	}

	// Stop movement
	m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE( m_owner.pawnId,"C_Stop_Move" ) );

	// Cancel any ability casting
	m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE( m_owner.pawnId, "C_Stop_Ability" ) );

	m_owner.UpdateUnitState( TMPS_STUNNED );
	m_owner.bFrozen = true;
	super.Begin();
}

function End()
{
	m_owner.UpdateUnitState( TMPS_IDLE );
	m_owner.bFrozen = false;
	m_owner.bStunned = false;
	super.End();
}

simulated function UpdateComponent( float dt )
{
	// Enforce state variables when active
	if ( m_bIsActive )
	{
		m_owner.UpdateUnitState( TMPS_STUNNED );
		m_owner.bStunned = true;
	}
}


DefaultProperties
{
}
