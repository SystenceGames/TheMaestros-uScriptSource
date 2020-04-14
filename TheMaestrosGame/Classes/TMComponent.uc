class TMComponent extends Object;

var TMPawn m_owner;

// Component init
function SetUpComponent(JsonObject json, TMPawn parent)
{
	// Implemented in child class
}

// Copies the TM component and assigns it to the new owner
function TMComponent makeCopy(TMPawn newowner)
{
	// Implemented in child class
}

// Called when the owner pawn updates the component
function UpdateComponent(float dt)
{
	// Implemented in child class
}

function ReceiveFastEvent(TMFastEvent event)
{
	// Implemented in child class
}

function HandleStopFE()
{
	// Implemented in child class
}

DefaultProperties
{
}
