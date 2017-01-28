package;

import openfl.display.Sprite;

/**
 * Just a simple tool that takes a Zip File, and replace the MP3 files it encountered to WAV files.
 * Then you can save that zip file.
 */
class MainOpenFL extends Sprite
{
  var program:ZipMP3toZipWAV;

  // Init
	public function new()
  {
		super();

		program = new ZipMP3toZipWAV();
	}
}