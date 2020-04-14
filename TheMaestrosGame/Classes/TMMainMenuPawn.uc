class TMMainMenuPawn extends Pawn;


function SetupUnitAs(string unitName)
{
	local AnimNodeBlendList movement;
	if( unitName == "Rosie")
	{
		SetupRosie();
	}
	else if( unitName == "RoboMeister")
	{
		SetupRoboMeister();
	}
	else if( unitName == "TinkerMeister")
	{
		SetupTinkerMeister();
	}
	else if( unitName == "Random")
	{
		SetUpRandomUnit();
	}
	else if( unitname == "Salvator")
	{
		SetupSalvator();
	}
	else if( unitname == "RamBamQueen")
	{
		SetupRamBamQueen();
	}
	else if( unitname == "HiveLord")
	{
		SetupHiveLord();
	}
	else
	{
		`log("bad name for menu commanders");
	}

	if(unitName == "Salvator" || unitName == "RamBamQueen")
	{
		movement = AnimNodeBlendList(Mesh.FindAnimNode('Idle'));
		movement.SetActiveChild(0,0);
		movement.PlayAnim(true,1,0);
		AnimTreeUpdated(Mesh);
		ForceUpdateComponents(true,false);
		return;
	}

	// Gets rid of 'Accessed None: Movement' for QuestionMark.
	if(unitName != "Random") {
		movement = AnimNodeBlendList(Mesh.FindAnimNode('MovementState'));
		movement.SetActiveChild(0,0);
		movement.PlayAnim(true,1,0);
		AnimTreeUpdated(Mesh);
		ForceUpdateComponents(true,false);
	}
}


function SetUpRandomUnit()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'TM_QuestionMark.TM_QuestionMark' );
}

function SetupRosie()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'TM_Rosie.Rosie');
	Mesh.SetAnimTreeTemplate( AnimTree'TM_Rosie.TM_RosieAnimTree');
	Mesh.AnimSets.AddItem( AnimSet'TM_Rosie.Rosie_AnimSet');
}


function SetupTinkerMeister()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'tm_tinkermeister.TinkerMeister');
	Mesh.SetAnimTreeTemplate( AnimTree'tm_tinkermeister.TM_TinkerMeisterAnimTree' );
	Mesh.AnimSets.AddItem( AnimSet'tm_tinkermeister.TinkerMeister_AnimSet');
}


function SetupRoboMeister()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'TM_Robomeister.Robomeister');
	Mesh.SetAnimTreeTemplate( AnimTree'TM_Robomeister.TM_RobomeisterAnimTree');
	Mesh.AnimSets.AddItem( AnimSet'TM_Robomeister.Robomeister_AnimSet');
}

function SetupSalvator()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'TM_Salvator.Salvator');
	Mesh.SetAnimTreeTemplate( AnimTree'TM_Salvator.TM_SalvatorMainMenuAnimTree');
	Mesh.AnimSets.AddItem( AnimSet'TM_Salvator.Salvator_AnimSet');
}

function SetupRamBamQueen()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'TM_RambamQueen.RambamQueen');
	Mesh.SetAnimTreeTemplate( AnimTree'TM_RambamQueen.TM_RambamQueenMainMenuAnimTree');
	Mesh.AnimSets.AddItem( AnimSet'TM_RambamQueen.RambamQueen_AnimSet');
}

function SetupHiveLord()
{
	Mesh.SetSkeletalMesh( SkeletalMesh'TM_HiveLord.HiveLord');
	Mesh.SetAnimTreeTemplate( AnimTree'TM_HiveLord.TM_HiveLordAnimTree');
	Mesh.AnimSets.AddItem( AnimSet'TM_HiveLord.HiveLord_AnimSet');
}

DefaultProperties
{
	Begin Object Class=SkeletalMeshComponent Name=UnitSkele
		SkeletalMesh=SkeletalMesh'TM_DoughBoy.DoughBoy'
	End Object
	Mesh=UnitSkele
	Components.Add(UnitSkele)
}
