class TMAnimationFE extends Object implements(TMFastEventInterface);;

var string m_commandType;
enum AnimTypeFE {ATTACK,MOVE};
var int m_pawnID;
var AnimTypeFE m_animType;
var int m_animationIndex;
var float m_blendTime;
var bool m_bLooping;
var float m_rate;
var float m_startTime;

static function TMAnimationFE create(int pawnID, 
									AnimTypeFE animType, 
									int animationIndex, 
									float blendTime, 
									bool looping, 
									float rate, 
									float startTime,
									optional string command)
{
	local TMAnimationFE result;
	result = new () class'TMAnimationFE';
	result.m_pawnID = pawnID;
	result.m_commandType = command;
	result.m_animType = animType;
	result.m_animationIndex = animationIndex;
	result.m_blendTime = blendTime;
	result.m_bLooping = looping;
	result.m_rate = rate;
	result.m_startTime = startTime;
	return result;
}

function TMFastEvent toFastEvent()
{
	local TMFastEvent fe;

	fe = new () class'TMFastEvent';
	fe.pawnId = m_pawnID;
	fe.commandType = m_commandType;
	fe.int1 = m_animType;
	fe.floats.A = m_animationIndex;
	fe.floats.B = m_blendTime;
	fe.floats.C = m_rate;
	fe.floats.D = m_startTime;
	fe.bool1 = m_bLooping;

	return fe;
}

static function TMAnimationFE fromFastEvent(TMFastEvent fe)
{
	local TMAnimationFE animFe;

	animFe = new () class'TMAnimationFE';
	animFe.m_pawnID = fe.pawnId;
	if(fe.int1 == 0)
	{
		animFe.m_animType = MOVE;
	}
	else
	{
		animFe.m_animType = ATTACK;
	}
	animFe.m_commandType = fe.commandType;
	animFe.m_animationIndex = fe.floats.A;
	animFe.m_blendTime = fe.floats.B;
	animFe.m_rate = fe.floats.C;
	animFe.m_startTime = fe.floats.D;
	animFe.m_bLooping = fe.bool1;
	return animFe;
}




DefaultProperties
{
}
