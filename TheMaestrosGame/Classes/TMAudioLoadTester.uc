/*  TMAudioLoadTester
 *  Used to overload the audio manager by spamming pings in the middle of the map. Used for testing purposes.
 * 	Spawn this actor to use it
 */
class TMAudioLoadTester extends Actor;

var AudioManager mAudioManager;


function StartTest( AudioManager inAudioManager, int inNumberOfSounds, float inDuration )
{
	mAudioManager = inAudioManager;

	SetTimer(inDuration / inNumberOfSounds, true, 'PlaySoundLoop', self);
	SetTimer(inDuration, false, 'StopPlaying', self);
}

function PlaySoundLoop()
{
	mAudioManager.requestPlaySFX(SoundCue'SFX_Notification.Notification_Alert_Cue');
}

function StopPlaying()
{
	ClearTimer('PlaySoundLoop', self);
	self.Destroy();
}
