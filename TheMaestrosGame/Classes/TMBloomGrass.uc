class TMBloomGrass extends StaticMeshActor;

var bool m_bIsActive;

DefaultProperties
{
	m_bIsActive = true;

	Begin Object class=StaticMeshComponent name=theMesh
		StaticMesh=StaticMesh'Plants.SacredArena.Grass_patch_big'
		//StaticMesh'TM_Sniper.temp_mine'
		//StaticMesh'mastermat_kstanley_05092013.Materials.Grass_patch_Small'
		//StaticMesh'mastermat_kstanley_05092013.Materials.Grass_patch_Med'
		//StaticMesh'mastermat_kstanley_05092013.Materials.Grass_patch_big'
	
	End Object
		Components.Add(theMesh)
		bStatic = false
		bNoDelete = false
		bMovable = true
}
