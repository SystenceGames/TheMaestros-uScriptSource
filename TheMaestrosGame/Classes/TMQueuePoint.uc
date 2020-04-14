class TMQueuePoint extends Actor
	placeable;


DefaultProperties
{
	bNoDelete=true

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_Actor'
		HiddenGame=TRUE
		AlwaysLoadOnClient=FALSE
		AlwaysLoadOnServer=FALSE
		SpriteCategoryName="Info"
	End Object
	Components.Add(Sprite)
}
