package;

/**
 * Just a simple tool that takes a Zip File, and replace the MP3 files it encountered to WAV files.
 * Then you can save that zip file.
 */
class Main
{
  var program:ZipMP3toZipWAV;

  public function new()
  {
    program = new ZipMP3toZipWAV();
  }

  static function main()
  {
    new Main();
  }
}