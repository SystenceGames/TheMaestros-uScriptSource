class TMGroup extends UDKRTSGroup;

static function TMGroup MakeGroup(array<TMPawn> inPawns, Vector inCenterOfGroup, Vector inDestination, float inStdDeviation)
{
	local TMGroup group;
	group = new () class'TMGroup';

	group.pawns = inPawns;
	group.startingCenterOfGroup = inCenterOfGroup;
	group.destination = inDestination;
	group.stdDeviation = inStdDeviation;

	return group;
}

function HandleGroupedMoveV2(TMFastEvent fe, TMPawn leadPawn )
{
	local UDKRTSPawn f_pawn;
	local Vector offset;

	foreach pawns( f_pawn )
	{
		fe.position1 = self.destination;
		offSet = f_pawn.Location - self.startingCenterOfGroup;
		fe.position1 = destination + offSet;

		// don't trigger a group move for units that are too large - e.g. Brute, it's likely to get stuck on edges.
		if (f_pawn.Mesh.Bounds.SphereRadius > MAX_SPHERE_RADIUS_FOR_GROUPMOVE2)
		{
			fe.ints.A = 0;
			fe.position1 = self.destination + Normal( offSet ) * self.stdDeviation;
			TMPawn(f_pawn).ReceiveFastEvent(fe);
			continue;
		}

		// don't trigger a group move for guys that are too far away, in the future, keep them part of the group and just make sure they know they're in the "out" group
		if (VSize( fe.position1 - self.destination ) > class'UDKRTSPlayerController'.static.calculateMaxStdDevForGroupedMove(self.pawns))
		{
			fe.ints.A = 0;
			fe.position1 = self.destination + Normal( offSet ) * self.stdDeviation;
			TMPawn(f_pawn).ReceiveFastEvent(fe);
			continue;
		}

		/* If you're far from the group, collapse back in, but still try to path with the group */
		if ( VSize( fe.position1 - self.destination ) > self.stdDeviation )
		{
			fe.ints.A = 1;
			f_pawn.MoveGroup = self;

			fe.position1 = self.destination + Normal( offSet ) * self.stdDeviation;
			TMPawn(f_pawn).ReceiveFastEvent(fe);
			continue;
		}
		
		/* do a full v2 group path */
		if (leadPawn != None)
		{
			fe.int1 = leadPawn.pawnId;

			fe.ints.A = 1;
			f_pawn.MoveGroup = self;
			
			TMPawn(f_pawn).ReceiveFastEvent(fe);
		}
	}
}

function HandleGroupedMoveV1(TMFastEvent fe, TMPawn leadPawn )
{
	local UDKRTSPawn f_pawn;
	local Vector offset;

	foreach pawns( f_pawn )
	{
		fe.position1 = self.destination;
		offSet = f_pawn.Location - self.startingCenterOfGroup;
		fe.position1 = destination + offSet;

		/* If you're far from the group, collapse back in */
		if ( VSize( fe.position1 - self.destination ) > self.stdDeviation )
		{
			fe.position1 = self.destination + Normal( offSet ) * self.stdDeviation;
		} else if (leadPawn != None)
		{
			fe.int1 = leadPawn.pawnId;
		}

		TMPawn(f_pawn).ReceiveFastEvent(fe);
	}
}

function DoGroupedMove(TMFastEvent fe )
{
	local UDKRTSAiController leadController;
	local TMPawn leadPawn;
	local array<Vector> outMovePoints;
	local Vector addedVector;
	local Vector crossedVector;
	local Vector shift;
	local int i;
	local Vector lastPosition;
	local bool plusSidePathable;
	local bool minusSidePathable;

	leadPawn = TMPawn(class'UDKRTSPawn'.static.MostCentralPawn(pawns));

	if (leadPawn == None)
	{
		return;
	}

	leadController = UDKRTSAiController(leadPawn.Controller);

	// if it's reachable, move to it using the old system (it was pretty good at that)
	if (leadController.IsPointReachable(destination))
	{
		HandleGroupedMoveV1(fe, leadPawn);
		return;
	}

	// may need to put a for loop here in odd case where leadPawn is in a spot where he can't path
	if (!leadController.GeneratePathTo(destination, leadPawn.GetCollisionRadius(), true))
	{
		// not reachable or pathable - probably not clicking on pathable terrain?
		HandleGroupedMoveV1(fe, leadPawn);
		return;
	}

	// if it's pathable, save off the path, and have everybody use some iteration of it.
	leadController.NavigationHandle.CopyMovePointsFromPathCache(destination, outMovePoints);
	movePoints = outMovePoints;
	unshiftedMovePoints.Length = movePoints.Length;
	for (i = 0; i < unshiftedMovePoints.Length; ++i)
	{
		unshiftedMovePoints[i] = movePoints[i];
	}

	moveVectors.Length = unshiftedMovePoints.Length;
	lastPosition = leadPawn.Location;
	for (i = 0; i < unshiftedMovePoints.Length; ++i)
	{
		moveVectors[i] = unshiftedMovePoints[i] - lastPosition;
		lastPosition = unshiftedMovePoints[i];
	}

	// if you're on a corner, oversteer so that our guys don't get stuck on the edges
	for (i = 1; i < moveVectors.Length; ++i)
	{
		addedVector = moveVectors[i-1] + moveVectors[i];
		crossedVector = addedVector cross vect(0.f,0.f,-1.f);
		shift = Normal(crossedVector) * ( stdDeviation + FMax(leadPawn.GetCollisionRadius(), 0.1f * stdDeviation) );
				
		plusSidePathable = leadController.GeneratePathTo(movePoints[i-1] + shift, leadPawn.GetCollisionRadius(), true);
		minusSidePathable = leadController.GeneratePathTo(movePoints[i-1] - shift, leadPawn.GetCollisionRadius(), true);

		if (plusSidePathable && !minusSidePathable)
		{
			movePoints[i-1] = movePoints[i-1] + shift;
		} 
		else if (!plusSidePathable && minusSidePathable) 
		{
			movePoints[i-1] = movePoints[i-1] - shift;
		}
	}

	/** This looks dumb, but hear me out: UDK pathfinding is terrible.  
	 *  It'll give you two of the same points in a row, no joke. 
	 *  
	 *  I believe this happens when multiple edges converge on the same
	 *  location such that there's a point in space which isn't the same
	 *  but only differs if you have sub-float accuracy, and if you're 
	 *  trying to move through the 2+ edges that this happens to,
	 *  the exact same point is naturally the closest point between 
	 *  those two edges, and so you choose that one. You can't differentiate 
	 *  for grabbing the next location in the MovingToPoint2 state machine,
	 *  and just wait infinitely */
	for (i = movePoints.Length - 1; i > 0; --i)
	{
		if (movePoints[i] == movePoints[i - 1])
		{
			movePoints.Remove(i, 1);
		}
	}

	HandleGroupedMoveV2(fe, leadPawn);
}

DefaultProperties
{
}
