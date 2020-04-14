/* TMHelper
 * 
 * Sometimes there's a function that doesn't belong anywhere. Rather than hide bad or reused code
 *	all over our project and in our systems, let's just put it here. This isn't the best solution,
 *	but this will allow for the easiest transition for some sort of static or helper class in the
 *	future. The goal is to eliminate odd reused functions that don't really have a place.
 */
class TMHelper extends Object;


/* GetScaleFromRadius()
	Converts a worldspace-radius into UDK VFX scale units using
	the magic number "2.0f / 97.0f".

	I'm not really sure where this number came from, but we
	use it EVERYWHERE! Anytime there is something relating to 
	abilities or VFX, this little bastard somehow appears.

	Regardless of how dumb this seems to be, we need this
	magic scalar number to create properly scaled VFX that
	looks good.
*/
static function float GetScaleFromRadius( int inRadius )
{
	return 2.0f / 97.0f * inRadius;
}
