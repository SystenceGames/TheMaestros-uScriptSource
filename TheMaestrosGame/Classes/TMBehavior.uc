interface TMBehavior;

function InitBehavior(TMTeamAIController teamAIController, TMBehaviorHelper behaviorHelper);

function int GetImportance();

function string GetName();

function FinishTask(int importance);

function Update(float dt);

function bool ShouldKeepArmyCentered();

function NotifyMoveComplete( Vector inLocation ); /* Notifcation called by TMTeamAIController */

function string GetDebugBehaviorStatus(); 	// used to show debug strings over the bots to observe behavior

DefaultProperties
{
}
