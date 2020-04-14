class TMStatusEffectKnockback extends TMStatusEffectStunned;

function TMComponent makeCopy(TMPawn newowner)
{
	local TMStatusEffectKnockback newcomp;
	newcomp= new () class'TMStatusEffectKnockback' (self);
	newcomp.m_owner=newowner;
	return newcomp;
}

function Begin()
{
	if( !m_owner.bCanBeDamaged )
	{
		return;
	}

	m_owner.SetCollision( false ); // so you don't bounce on pawns

	super.Begin();
}

simulated function UpdateComponent( float dt )
{
	if ( m_bIsActive && IsZero( m_owner.Velocity ) )
	{
		End();
	}
	else
	{
		super.UpdateComponent( dt );
	}
}

function End()
{
	m_owner.SetCollision( true );

	super.End();
}
