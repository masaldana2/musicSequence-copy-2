//
//  ViewController.swift
//  musicSequence
//
//  Created by Miguel Saldana on 6/13/16.
//  Copyright © 2016 Miguel Saldana. All rights reserved.
//

import UIKit
import AudioToolbox

class ViewController: UIViewController {
    var gen = SoundGenerator()
 

    
    override func viewDidLoad() {
        super.viewDidLoad()
        var musicSequence:MusicSequence? = nil
        
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr){
            print("\(#line)bad status \(status) creating sequence")
        }
        print(status)
        
        //add a track
        var track:MusicTrack? = nil
        status = MusicSequenceNewTrack(musicSequence!, &track)
        print(status)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
        }
        
        //now make some nores and put them on the track
        var beat = MusicTimeStamp(1.0)
        for i:UInt8 in 60...72{
            var mess = MIDINoteMessage(channel: 0,
                                       note: i,
                                       velocity:  64,
                                       releaseVelocity: 0,
                                       duration: 1.0)
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            print(mess)
            if status != OSStatus(noErr) {
                print("error creating midi note event \(status)")
            }
            beat += 1
        }
   
        var musicPlayer:MusicPlayer? = nil
         status = NewMusicPlayer(&musicPlayer)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating player")
        }
        status = MusicPlayerSetSequence(musicPlayer!, musicSequence)
        if status != OSStatus(noErr) {
            print("setting sequence \(status)")
        }
        status = MusicPlayerPreroll(musicPlayer!)
        if status != OSStatus(noErr) {
            print("prerolling player \(status)")
        }

        //
     
        
     
        
    }
    @IBOutlet var loopSlider: UISlider!

    @IBAction func loopSliderChange(sender: AnyObject) {
        
        print("slider vlaue \(loopSlider.value)")
        gen.setTrackLoopDuration(duration: loopSlider.value)
    }
    @IBAction func play(sender: UIButton) {
        gen.play()
    }
    @IBAction func playNoteOn(sender: AnyObject) {
        gen.playNoteOn(noteNum: 60, velocity: 100)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

