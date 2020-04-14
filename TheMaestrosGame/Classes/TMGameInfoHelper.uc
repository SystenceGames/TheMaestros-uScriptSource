/* TMGameInfoHelper
	Provides some useful functions that custom game modes might use, but don't want to clutter our base class with.
*/
class TMGameInfoHelper extends Object;


function bool IsBaseUnit(string unitName)
{
	if(unitName == "DoughBoy")
	{
		return true;
	}

	if(unitName == "RamBam")
	{
		return true;
	}

	return false;
}


function bool IsGameObjectiveUnit(string unitName)
{
	if(unitName == "Nexus")
	{
		return true;
	}

	if(unitName == "Brute")
	{
		return true;
	}

	return false;
}


function bool IsNeutralUnit(string unitName)
{
	if(unitName == "Droplet")
	{
		return true;
	}

	if(unitName == "Slender")
	{
		return true;
	}

	return false;
}