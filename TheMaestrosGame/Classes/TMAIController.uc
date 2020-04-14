class TMAIController extends UDKRTSAIController;

var float m_timeSinceLastAttack;
// this takes care of unit's AI's reaction when attacked
function NotifyTakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	//if (TMPawn(DamageCauser) != None)
	//{
		//Retaliate(/*DamageCauser*/);
	//}
}

/**
 * Renders Some AIController State info on the HUD
 */
simulated function RenderDebugState(UDKRTSHUD HUD)
{
	local Vector V;
	local string Text;
	local float XL, YL;

	// Display the AI states
	if (HUD.ShouldDisplayDebug('AIStates'))
	{
		V = Pawn.Location + Pawn.CylinderComponent.CollisionHeight * Vect(0.f, 0.f, 1.f);
		V = HUD.Canvas.Project(V);		
		HUD.Canvas.Font = class'Engine'.static.GetTinyFont();

		// Render the state debug
		Text = String(GetStateName())@"-"@StateLabel;
		HUD.Canvas.TextSize(Text, XL, YL);
		HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y - (YL * 3.f), Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

		HUD.Canvas.TextSize("Previous state - "$CachedPreviousStateName, XL, YL);
		HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y - (YL * 2.f), "Previous state - "$CachedPreviousStateName, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);

		// Render the enemy debug text
		if (EnemyTargetInterface != None && EnemyTargetInterface.IsValidTarget())
		{
			Text = "Target = "$EnemyTargetInterface.GetActor();
			HUD.Canvas.TextSize(Text, XL, YL);
			HUD.DrawBorderedText(HUD, V.X - (XL * 0.5f), V.Y - YL, Text, class'HUD'.default.WhiteColor, class'UDKRTSPalette'.default.BlackColor);
		}
	}

	// Display the AI focus
	if (HUD.ShouldDisplayDebug('AIFocus'))
	{
		HUD.Draw3DLine(Pawn.Location, FocusSpot, class'HUD'.default.GreenColor);
	}
}

function Retaliate(/*Actor target*/)
{
	/*
	local TMAttackFE lAttackFE;
	local TMPawn lControllerPawn;

	lControllerPawn = TMPawn(Pawn);
	
	// If this controller has a pawn AND the player is not controlling this pawn AND this pawn is alive AND this pawn is not stunned
	if(lControllerPawn != none && lControllerPawn.m_currentState == TMPS_IDLE && lControllerPawn.Health > 0 && !lControllerPawn.bStunned)
	{
		if(mTarget == none)
		{
			if(lControllerPawn.Role == ROLE_Authority)
			{
				lAttackFE = class'TMAttackFE'.static.create(mTarget, lControllerPawn.pawnId);
				lControllerPawn.SendFastEvent(lAttackFE);
			}
		}
	}
	*/
}

function Tick(float dt)
{
	//mTarget = FindClosestTarget();   // Find the potential retaliate target
	super.Tick(dt);
	
	/*
	if(mTarget != none && mTarget.Health <= 0)
	{
		mTarget = none;
	}
	*/

	
}

defaultproperties
{
	//bUsingPathLanes=true // may this will help us some day - dru
	//LaneOffset=50
}