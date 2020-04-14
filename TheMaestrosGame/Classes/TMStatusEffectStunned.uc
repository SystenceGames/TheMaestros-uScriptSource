class TMStatusEffectStunned extends TMStatusEffect;

function Begin()
{
	local TMAnimationFE fe;

	if( !m_owner.bCanBeDamaged )
	{
		return;
	}

	// Stop movement
	m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE( m_owner.pawnId,"C_Stop_Move" ) );

	// Stop any animations from playing
	fe = new () class'TMAnimationFE';
	fe.m_commandType = "Idle";
	fe.m_pawnId = m_owner.pawnId;
	m_owner.SendFastEvent(fe);

	// Cancel any ability casting
	m_owner.ReceiveFastEvent( class'TMFastEvent'.static.createGenericFE( m_owner.pawnId, "C_Stop_Ability" ) );

	m_owner.UpdateUnitState( TMPS_STUNNED );
	m_owner.bStunned = true;
	super.Begin();
}

function TMComponent makeCopy(TMPawn newowner) {
	local TMStatusEffectStunned newcomp;
	newcomp= new () class'TMStatusEffectStunned' (self);
	newcomp.m_owner=newowner;
	newcomp.m_bIsActive = m_bIsActive;
	newcomp.m_fDuration = m_fDuration;
	newcomp.m_fDurationRemaing = m_fDurationRemaing;
	return newcomp;
}

function End()
{
	m_owner.UpdateUnitState( TMPS_IDLE );
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

	super.UpdateComponent( dt );
}

DefaultProperties
{
}
