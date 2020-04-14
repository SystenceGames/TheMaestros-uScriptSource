/* TMEventTimer
	System for timing events in our game.

	Example Usage: Timing bots
		Can timestamp when a bot starts farming, finishes farming, starts transforming, etc.

	Allows you to print out a log of all events that were timed with duration.
*/

class TMEventTimer extends Object;


Struct TMTimedEvent
{
	var string 	EventName; 	// name for this event
	var float 	StartTime; 	// global time this event started, in seconds
	var float 	EndTime;	// global time this event finished, in seconds
};
var array<TMTimedEvent> eventsList;

var string eventGroupName;
var bool shouldPrintEvents;


/* Create
	Creates a new TMTimedEvent

	inEventGroupName: the name for the group of events you're timing
*/
static function TMEventTimer Create(string inEventGroupName, bool inShouldPrintEvents=false)
{
	local TMEventTimer eventTimer;

	eventTimer = new class'TMEventTimer'();
	eventTimer.eventGroupName = inEventGroupName;
	eventTimer.shouldPrintEvents = inShouldPrintEvents;
	
	return eventTimer;
}

/* StartEvent
	Creates an event with the given name. Will keep track of it's start time.
*/
function StartEvent(string inEventName)
{
	local TMTimedEvent timedEvent;

	// Make sure there's no current events with that name in progress
	StopEvent(inEventName);

	timedEvent.EventName = inEventName;
	timedEvent.StartTime = Class'WorldInfo'.static.GetWorldInfo().TimeSeconds;
	timedEvent.EndTime = -1;

	eventsList.AddItem(timedEvent);

	PrintEvents();
}

/* StopEvent
	Stops the event that you were timing.
*/
function StopEvent(string inEventName)
{
	local TMTimedEvent timedEvent;
	local int i;

	for(i=0; i < eventsList.Length; i++)
	{
		timedEvent = eventsList[i];

		if(timedEvent.EventName == inEventName && timedEvent.EndTime < 0)
		{
			`log("TMTimedEvent: Stopping " $ inEventName);
			eventsList.Remove(i, 1);
			timedEvent.EndTime = Class'WorldInfo'.static.GetWorldInfo().TimeSeconds;
			eventsList.InsertItem(i, timedEvent);
			PrintEvents();
			return;
		}
	}
}

/* PrintEvents
	Prints full event details and a high level events list.
*/
function PrintEvents()
{
	local array<TMTimedEvent> shortenedEventList;
	local TMTimedEvent timedEvent;

	if(self.shouldPrintEvents == false)
	{
		return;
	}

	PrintEventList(eventsList);

	// Also create a shortened list that doesn't have events that look like "sub-events".
	foreach eventsList(timedEvent)
	{
		if( InStr(timedEvent.EventName, ":") == -1 )
		{
			shortenedEventList.AddItem(timedEvent);
		}
	}
	PrintEventList(shortenedEventList);
}


/* PrintEventList
	Prints each event and its duration in event-creation order.
*/
function PrintEventList(array<TMTimedEvent> inEventList)
{
	local TMTimedEvent timedEvent;
	local float duration;
	local string eventMessage;

	`log("========== '" $ eventGroupName $ "' timed events. ==========");
	`log("TIMESTAMP       EVENT       DURATION");

	foreach inEventList(timedEvent)
	{
		eventMessage = " " $ timedEvent.StartTime $ "s    " $ timedEvent.EventName $ "      ";
		duration = timedEvent.EndTime - timedEvent.StartTime;

		if( duration > 0 ) {
			`log(eventMessage $ duration $ "s");
		}
		else {
			`log(eventMessage $ "N/A");
		}
	}

	`log("========== Current time stamp: " $ Class'WorldInfo'.static.GetWorldInfo().TimeSeconds $ " ==========");
}
