class Util extends Object;

var int MILLIS_IN_SECOND;
var int SECONDS_IN_MINUTE;
var int MINUTES_IN_HOUR;
var int HOURS_IN_DAY;
var int DAYS_IN_MONTH;

var Util instance;

static function int GetMillies()
{
	/*local int year, month, dow, day, hour, min, sec, ms;
	local int millies;
	instance.GetSystemTime(year, month, dow, day, hour, min, sec, ms);
	millies = ((((month * DAYS_IN_MONTH + day) * HOURS_IN_DAY + hour) * MINUTES_IN_HOUR + min ) * SECONDS_IN_MINUTE + sec ) * MILLIS_IN_SECOND + ms;*/

	return 0;
}

function Initialize(){
	instance = self;
}

DefaultProperties
{
	MILLIS_IN_SECOND = 1000
	SECONDS_IN_MINUTE = 60
	MINUTES_IN_HOUR = 60
	HOURS_IN_DAY = 24
	DAYS_IN_MONTH = 30
}
