class TMComponentVineCrawlerWall extends TMComponent;

const SPAWNED_WALL = "C_SPAWNED_WALL";

var float   mDuration;
var bool    mIsDead;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	mDuration = json.GetFloatValue( "duration" );
	m_Owner = parent;
}

simulated function TMComponent makeCopy(TMPawn newowner)
{
	local TMComponentVineCrawlerWall newcomp;
	newcomp = new() class'TMComponentVineCrawlerWall' (self);
	newcomp.m_owner = newowner;
	return newcomp;
}

function ReceiveFastEvent(TMFastEvent fe)
{
	if( fe.commandType == SPAWNED_WALL )
	{
		m_owner.SetTimer( mDuration, false, 'DestroyWall', self );
	}

	super.ReceiveFastEvent(fe);
}

function DestroyWall()
{
	mIsDead = true;
	m_owner.SetCollision( false, false );
	m_owner.Died( m_owner.m_TMPC, class'DamageType', m_owner.Location );
}

function UpdateComponent( float dt )
{
	if ( m_owner.Health <= 0 && !mIsDead )
	{
		DestroyWall();
	}
}

DefaultProperties
{
}
