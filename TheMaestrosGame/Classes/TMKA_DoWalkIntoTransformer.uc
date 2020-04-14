class TMKA_DoWalkIntoTransformer extends SequenceAction;

var() string transformerName;

event Activated()
{
	local array<UDKRTSPawn> transformArray;
	local TMPlayerController pc;
	local TMPawn pawnItr;
	local TMTransformer transformerItr;
	pc = TMPlayerController(GetWorldInfo().GetALocalPlayerController());

	foreach pc.AllActors(class'TMPawn', pawnItr)
	{
		if(pawnItr.m_UnitType == "DoughBoy" && pawnItr.OwnerReplicationInfo == pc.PlayerReplicationInfo)
		{
			transformArray.AddItem(pawnItr);
		}
	}

	foreach pc.AllActors(class'TMTransformer', transformerItr)
	{
		if(transformerItr.Name == Name(transformerName))
		{
			break;
		}
	}

	if(transformArray.Length != 0)
	{
		transformArray[0].HandleCommand(C_Transform, false, transformerItr.Location,,transformArray,);
	}
	else
	{
		`log("Shit gone bad", true, 'Lang');
	}
}

DefaultProperties
{
	ObjName="DoWalkIntoTransformer"
	ObjCategory="TheMaestros"

	VariableLinks.Empty
	VariableLinks(0) = (ExpectedType=class'SeqVar_String', LinkDesc="TransformerName", PropertyName=transformerName)
}
