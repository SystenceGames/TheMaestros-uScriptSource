interface TMFOWManager;

function Initialize(TMFOWMapInfoActor TheMap, int TheAllyIndex);

function DisableFoW();

function EnableFoW();

function HideAPawn(TMPawn pawn);

function ShowAPawn(TMPawn pawn);

function bool IsLocationVisible(Vector loc);

function bool IsPawnHidden(TMPawn pawn);

function RemoveFromVisiblePawns(int pawnId);

function FoWShow();

function FoWHide();

function ScriptedTexture GetMinimapFogOfWarTexture();

function BytePoint GetMapTileFromLocation(Vector LocationToTranslate);

function int GetAllyID();

function int GetNumberOfTilesXY();

function AddRevealActor(TMFOWRevealActor revealActor);

function RemoveRevealActor(TMFOWRevealActor revealActor);