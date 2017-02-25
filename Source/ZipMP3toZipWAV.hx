package;

import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.io.BytesOutput;

import file.load.FileLoad;
import file.save.FileSave;

import zip.Zip;
import zip.ZipReader;
import zip.ZipWriter;
import zip.ZipEntry;

import statistics.TraceTimer;
import statistics.Stats;

// Flash
import flash.Lib;
import flash.media.Sound;
import flash.events.Event;
import flash.utils.ByteArray;

using StringTools;

typedef WAVEntry = {
  var data:Bytes;
  var name:String;
};

typedef XMLEntry = {
  var data:String;
  var name:String;
};

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

  // Create new ZIP
  var writer = new ZipWriter();
  var date = new Date(1988, 11, 2, 12, 45, 0); // Easter egg on NOTE font file
  
  // Zip entries
  var mp3s:Array<ZipEntry> = [];
  var samples:Array<ZipEntry> = [];
  var others:Array<ZipEntry> = [];
  
  var samplesDecoded:Array<XMLEntry> = [];
  var mp3sDecoded:Array<WAVEntry> = [];
  
  var zip:ZipReader;
  
  var zipDone = false;
  var samplesDone = false;
  
  var saved:Bool = false;
  
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
        
        // Parse ZIP
        zip = new ZipReader(bytes);
        
        // Parse 1 per frame
        Lib.current.stage.addEventListener( Event.ENTER_FRAME, enterFrameHandler, false, 0, true );
      },
      error: function(error)
      {
        trace("Error:", error);
      }
    });
  }
  
  // Save to WAV Bytes (16bits)
  public function toWAV( floats:ByteArray )
  {
    var channels = 2;
    var sampleRate = 44100;
    var length = Std.int(floats.length / (4 * 2));
    
    var bitsPerSample = 16;
    var byteRate = Std.int(channels * sampleRate * bitsPerSample / 8);
    var blockAlign = Std.int(channels * bitsPerSample / 8);
    var dataLength = length * channels * 2;

    var output = new BytesOutput();
    output.bigEndian = false;
    output.writeString("RIFF");
    output.writeInt32(36 + dataLength);
    output.writeString("WAVEfmt ");
    output.writeInt32(16);
    output.writeUInt16(1);
    output.writeUInt16(channels);
    output.writeInt32(sampleRate);
    output.writeInt32(byteRate);
    output.writeUInt16(blockAlign);
    output.writeUInt16(bitsPerSample);
    output.writeString("data");
    output.writeInt32(dataLength);
    
    // Read Samples one after another (testing actual float conversion also)
    var n = length * channels, ival:Int;
    floats.position = 0;
    for ( i in 0...n )
    {
      output.writeInt16( Std.int(floats.readFloat() * 32767) );
    }
    
    return output.getBytes();
  }
  
  // Enter Frame
  function enterFrameHandler(e:Event)
  {
    if ( !zipDone )
    {
      var entry:ZipEntry, i:Int = 0;
      
      while ( (i++ < 150) && ((entry = zip.getNextEntry()) != null) )
      {
        // Check if MP3
        if ( entry.fileName.toLowerCase().endsWith(".mp3") )
        {
          mp3s.push(entry);
          
          trace("MP3 Entry added", entry.fileName);
        }
        else if ( entry.fileName.toLowerCase().startsWith("samples/") )
        {
          samples.push(entry);
          
          trace("Sample Entry added", entry.fileName);
        }
        else
        {
          others.push(entry);
          
          trace("Other Entry added", entry.fileName);
        }
      }
      
      if ( entry == null )
      {
        zipDone = true;
        
        trace("Zip Done!", mp3s.length, "mp3s", samples.length, "samples", others.length, "others");
      }
    }
    else if ( !samplesDone )
    {
      for ( entry in samples )
      {
        samplesDecoded.push(
        {
          name: entry.fileName, 
          data: Zip.getString(entry).replace(".mp3", ".ogg")
        });
      }
      
      samplesDone = true;
      
      trace(samples.length, "Samples parsed");
    }
    else if ( mp3s.length > 0 )
    {
      var entry = mp3s.pop();
      var bytes = Zip.getBytes(entry);
      
      var sound:Sound = new Sound();
      sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
      
      var decoded = new ByteArray();
      sound.extract(decoded, 10000000000); // Just a big enough number
      
      // Create WAV file
      var wav = toWAV(decoded);// Bytes.ofData(decoded));
      
      // Add to array
      mp3sDecoded.push(
      {
        name: entry.fileName.replace(".mp3", "_mp3_.wav"),
        data: wav
      });
      
      trace("Decoded!", decoded.length);
    }
    else if ( samplesDecoded.length > 0 )
    {
      var xml = samplesDecoded.pop();
      writer.addString(xml.data, xml.name, true, date);
      
      trace("Zipped", xml.name);
    }
    else if ( mp3sDecoded.length > 0 )
    {
      var wav = mp3sDecoded.pop();
      writer.addBytes(wav.data, wav.name, false, date);
      
      trace("Zipped", wav.name);
    }
    else if ( !saved )
    {
      saved = true;
      
      // Write back entries
      for ( entry in others.iterator() )
      {
        writer.addEntry(entry);
      }
      
      FileSave.saveClickBytes(writer.finalize(), "mp32wav.zip");
      
      trace("Convert done!");
    }
  }
}