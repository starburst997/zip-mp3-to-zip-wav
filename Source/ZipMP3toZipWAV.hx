package;

import file.load.Loaders;
import file.load.FileLoad;
import file.save.FileSave;

import statistics.TraceTimer;
import statistics.Stats;

/**
 * Just a simple tool that takes a Zip File, and replace the MP3 files it encountered to WAV files.
 * Then you can save that zip file.
 */
class ZipMP3toZipWAV
{
  // List of files
  public static inline var PATH:String = "./assets/notes/";
  public static inline var NOTE00:String = PATH + "NOTE00.note";
  public static inline var NOTE01:String = PATH + "NOTE01.note";

  // Stats
  var stats = new Stats();

  // Load ZIP
  public function new()
  {
    trace("Launch");

    TraceTimer.activate();

    loadZip( NOTE00 );
  }

  // Load a zip and process it
  function loadZip( url:String )
  {
    FileLoad.loadBytes(
    {
      url: url,
      complete: function(bytes)
      {
        trace("Download complete", bytes.length);
      },
      error: function(error)
      {
        trace("Error:", error);
      }
    });
  }
}