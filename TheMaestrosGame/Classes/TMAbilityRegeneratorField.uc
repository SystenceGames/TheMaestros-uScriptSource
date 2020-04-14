class TMAbilityRegeneratorField extends TMAbility;

struct RegeneratorTriangle
{
	var TMAbilityRegeneratorField field1, field2, field3;
};

var array<TMAbilityRegeneratorField> mLinkedRegenerators;   // regenerators I form a link with
var array<RegeneratorTriangle> mRegeneratorTriangles;       // regenerators I actually form a triangle with


// NEW VARIABLES
var int mRadius;


function SetUpComponent(JsonObject json, TMPawn parent)
{
	super.SetUpComponent( json, parent );
	mRadius = json.GetIntValue( "radius" );
	mIsInstantCast = true;
}

function TMComponent makeCopy(TMPawn newowner)
{
	local TMAbilityRegeneratorField newcomp;
	newcomp= new () class'TMAbilityRegeneratorField'(self);
	newcomp.m_owner=newowner;
	newcomp.mIsInstantCast = true;
	return newcomp;
}

function CastAbility()
{
	// OLD AREA ABILITY
	/*
	m_AbilityState = AS_CASTING;
	m_fTimeInState = 0;
	m_owner.m_bIsAbilityReady = false;
	m_owner.UpdateUnitState( TMPS_JUGGERNAUT );

	FindRegeneratorLinks();
	FindRegeneratorTriangles();
	HealUnits();

	m_owner.SetTimer(m_fDurationCast, false, 'Deactivate', self);
	*/

	HealAreaAroundMe();
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale( ParticleSystem'VFX_Regenerator.Particles.P_Heal_ability', m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner.Location, 2.0f );
	
	super.CastAbility();
}

function HealAreaAroundMe()
{
	local TMPawn tempPawn;
	local array< TMPawn > pawns;
	pawns = m_owner.m_TMPC.GetTMPawnList();
	foreach pawns( tempPawn )
	{
		if( tempPawn.IsPointInRange2D( m_owner.Location, mRadius ) )
		{
			if( TMPlayerReplicationInfo( tempPawn.OwnerReplicationInfo ).allyId == TMPlayerReplicationInfo( m_owner.OwnerReplicationInfo ).allyId )
			{
				// The TMPawn is on my team, heal him
				tempPawn.m_Unit.SendStatusEffect( SE_REGENERATOR_HEAL );
			}
		}
	}
}

function Deactivate()
{
	m_owner.m_TMPC.m_aRegenerators.RemoveItem(self);
	mLinkedRegenerators.Remove(0, mLinkedRegenerators.Length);
	mRegeneratorTriangles.Remove(0, mRegeneratorTriangles.Length);

	m_owner.UpdateUnitState( TMPS_IDLE );
	super.BeginCooldown();
}

function FindRegeneratorLinks()
{
	local int i;

	// Add myself to the list of conductor who want to cast shock
	m_owner.m_TMPC.m_aRegenerators.AddItem(self);

	for (i = 0; i < m_owner.m_TMPC.m_aRegenerators.Length; i++)
	{
		if (m_owner.m_TMPC.m_aRegenerators[i] != self)
		{
			if (IsInRange(m_owner.Location, m_owner.m_TMPC.m_aRegenerators[i].m_owner.Location, m_iRange))
			{
				mLinkedRegenerators.AddItem(m_owner.m_TMPC.m_aRegenerators[i]);
			}
		}
	}
}

/**
 * Go through each linked regenerator and see if I'm neighbors with any of his neighbors.
 * If we both share the same neighbor we form a triangle.
 */
function FindRegeneratorTriangles()
{
	local RegeneratorTriangle triangle;
	local TMAbilityRegeneratorField regenField;
	local TMAbilityRegeneratorField neighbor;

	foreach mLinkedRegenerators(regenField)
	{
		foreach regenField.mLinkedRegenerators(neighbor)
		{
			if (mLinkedRegenerators.Find(neighbor) != INDEX_NONE)
			{
				triangle.field1 = self;
				triangle.field2 = regenField;
				triangle.field3 = neighbor;

				mRegeneratorTriangles.AddItem(triangle);
			}
		}
	}
	`log("Have this many tris: "@mRegeneratorTriangles.Length);
}

function HealUnits()
{
	// Used for collision reference
	// http://www.blackpawn.com/texts/pointinpoly/default.html
	local vector v0, v1, v2;
	local float dot00, dot01, dot02, dot11, dot12;
	local float invDenom;
	local float u, v;
	local RegeneratorTriangle tri;
	local array< TMPawn > pawnList;
	local TMPawn tempPawn;

	pawnList = m_owner.m_TMPC.GetTMPawnList();

	// Do VFX
	m_owner.m_TMPC.m_ParticleSystemFactory.CreateWithScale( ParticleSystem'VFX_Regenerator.Particles.P_Heal_ability', m_owner.m_allyId, m_owner.GetTeamColorIndex(), m_owner.Location, 2.0f );

	foreach mRegeneratorTriangles( tri )
	{	
		foreach pawnList( tempPawn )
		{
			if ( TMPlayerReplicationInfo(tempPawn.OwnerReplicationInfo).allyId == TMPlayerReplicationInfo(m_owner.OwnerReplicationInfo).allyId &&
				tempPawn.m_Unit.m_UnitName != "Regenerator" && tempPawn.m_Unit.m_UnitName != "TEST" )
			{
				// Compute vectors
				v0 = tri.field3.m_owner.Location - tri.field1.m_owner.Location;
				v1 = tri.field2.m_owner.Location - tri.field1.m_owner.Location;
				v2 = tempPawn.Location - tri.field1.m_owner.Location;

				// Compute dot products
				dot00 = v0 dot v0;
				dot01 = v0 dot v1;
				dot02 = v0 dot v2;
				dot11 = v1 dot v1;
				dot12 = v1 dot v2;

				// Compute barycentric coordinates
				invDenom = 1 / ( dot00 * dot11 - dot01 * dot01 );
				u = ( dot11 * dot02 - dot01 * dot12 ) * invDenom;
				v = ( dot00 * dot12 - dot01 * dot02 ) * invDenom;

				// Check if the point is in the triangle
				if ( ( u >= 0 ) && ( v >= 0 ) && ( ( u + v ) < 1 ) )
				{
					tempPawn.m_Unit.SendStatusEffect( SE_REGENERATOR_HEAL );
				}
			}
		}
	}
}

function UpdateComponent(float dt)
{
	local RegeneratorTriangle tri;
	foreach mRegeneratorTriangles( tri )
	{
		m_owner.GetActor().DrawDebugLine(m_owner.Location, tri.field2.m_owner.Location, 0, 153, 0);
		m_owner.GetActor().DrawDebugLine(m_owner.Location, tri.field3.m_owner.Location, 0, 153, 0);
	}

	// CHECK FOR COLLISIONS: IN FUTURE WILL NOT DO IT HERE
	//http://www.blackpawn.com/texts/pointinpoly/default.html
	/*
	if (collide)
	{
		pawn.addStatusEffect(HEAL)
		tempPawn.m_Unit.SendStatusEffect( SE_POISON );
	}
	*/

	super.UpdateComponent(dt);
}

DefaultProperties
{
	mIsInstantCast = true;
	TEMP_dontStop = true;
}
