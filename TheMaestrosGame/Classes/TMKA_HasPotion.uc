class TMKA_HasPotion extends SequenceAction;

var string inUnitName;
var bool outVal;

event Activated()
{
	local TMPotionStack tempStack;
	local array<TMPotionStack> potions;

	outVal = false;

	
	potions = TMGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_TMPlayerController.m_Potions;
	foreach potions( tempStack )
	{
		if( tempStack.m_UnitType == inUnitName &&
			tempStack.m_Count > 0 )
		{
			outVal = true;
			OutputLinks[0].bHasImpulse = TRUE;
			return;
		}
	}
}

defaultproperties
{
	ObjName="HasPotion"
	ObjCategory="TheMaestros"

	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="potion unit name", PropertyName=inUnitName)
	VariableLinks(1) = (ExpectedType=class'SeqVar_Bool', LinkDesc="Does player have?", bWriteable = true, PropertyName=outVal)
}
