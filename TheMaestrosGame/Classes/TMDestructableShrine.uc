class TMDestructableShrine extends ApexDestructibleActorSpawnable;

simulated event PostBeginPlay() 
{
	local TMPlayerController iterTMPC;

	super.PostBeginPlay();

	foreach LocalPlayerControllers(class'TMPlayerController', iterTMPC)
	{
		iterTMPC.mDestructableShrine = self;
	}
}

simulated function SetTimerToExpire()
{
	self.SetTimer(10,false,'KillDisBitch');
}

simulated function KillDisBitch()
{   
	self.Destroy();
}

defaultproperties
{
	// Network
	RemoteRole=ROLE_SimulatedProxy
	NetPriority=+00002.000000
	bUpdateSimulatedPosition=true
	bAlwaysRelevant=true
	bHidden=true
	bCollideActors=false

    //thank you Spoof!
    Begin Object name=DestructibleComponent0
        //change to your asset, look up entire path of your APEX by going into UDK
        //right click on your APEX and get the full name, copy into your code

       // Asset = ApexDestructibleAsset'Nexus.ShrineFractured'
	//	Asset = ApexDestructibleAsset'Nexus.ShrineFractured2'; //this one is bigger
		Asset = ApexDestructibleAsset'Nexus.Shrine2xV2'
        //sets collison/colliding on fracture pieces of Apex mesh
        //I looked this up in Engine/ActorFactoryApexDestructible.uc 
       //and added "RB" to front of "CollideWithChannels"
	RBChannel=RBCC_EffectPhysics
	RBCollideWithChannels={(
           Default=TRUE,
           BlockingVolume=TRUE,
           GameplayPhysics=TRUE,
           EffectPhysics=TRUE
        )}
    End Object		
}

