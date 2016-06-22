//
//  soundgenerator.swift
//  musicSequence
//
//  Created by Miguel Saldana on 6/14/16.
//  Copyright © 2016 Miguel Saldana. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreAudio
//import AVFoundation
class SoundGenerator {
    var samplerUnit:AudioUnit? = nil
    var musicPlayer:MusicPlayer? = nil
    var musicSequence:MusicSequence? = nil
    var processingGraph:AUGraph? = nil
    
    init() {
//        self.processingGraph = AUGraph()
//        self.samplerUnit  = AudioUnit()
//        self.musicPlayer = nil
        augraphSetup()
        graphStart()
        loadSF2Preset(preset: 0)
        
        //or loadDLSPreset(0)
        
        self.musicSequence = createMusicSequence()
        self.musicPlayer = createPlayer(musicSequence: musicSequence!)
        
        CAShow(UnsafeMutablePointer<MusicSequence>(self.processingGraph!))
        CAShow(UnsafeMutablePointer<MusicSequence>(musicSequence!))
    }
    func augraphSetup() {
        var status = OSStatus(noErr)
        status = NewAUGraph(&self.processingGraph)
        CheckError(error: status)
        
        //create sampler
        //To create the sampler and add it to the graph, you need to create an AudioComponentDescription.
        var samplerNode = AUNode()
        
        var cd:AudioComponentDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_Sampler),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &cd , &samplerNode)
        CheckError(error: status)
        
        //Create an output node in the same manner.
        
        var ioNode = AUNode()
        
        var ioUnitDescription = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_Output),
            componentSubType: OSType(kAudioUnitSubType_RemoteIO),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0,
            componentFlagsMask: 0)
        status = AUGraphAddNode(self.processingGraph!, &ioUnitDescription, &ioNode)
        CheckError(error: status)
        
        //Now to wire the nodes together and init the AudioUnits. The graph needs to be open, so we do that first.
        //Then I obtain references to the audio units with the function AUGraphNodeInfo.
        status = AUGraphOpen(self.processingGraph!)
        CheckError(error: status)
        
        status = AUGraphNodeInfo(self.processingGraph!, samplerNode, nil, &self.samplerUnit)
        CheckError(error: status)
        
        var ioUnit:AudioUnit? = nil
        status = AUGraphNodeInfo(self.processingGraph!, ioNode, nil, &ioUnit)
        CheckError(error: status)
        
        
        //Now wire them using AUGraphConnectNodeInput.
        let ioUnitOutputElement = AudioUnitElement(0)
        let samplerOutputElement = AudioUnitElement(0)
        status = AUGraphConnectNodeInput(
            self.processingGraph!,
            samplerNode, samplerOutputElement,//source node
            ioNode, ioUnitOutputElement)//destination node
            CheckError(error: status)
    }
    
    
    func graphStart() {
        var status = OSStatus(noErr)
        var outIsInitialized:DarwinBoolean = false
        status = AUGraphIsInitialized(self.processingGraph!, &outIsInitialized)
        print("isinit status is \(status)")
        print("bool is \(outIsInitialized)")
        if outIsInitialized == false{
            status = AUGraphInitialize(self.processingGraph!)
            CheckError(error: status)
        }
        
        var isRunning = DarwinBoolean(false)
        status = AUGraphIsRunning(self.processingGraph!, &isRunning)
        print("running bool is \(isRunning) status \(status)")
        if isRunning == false{
            print("graph is not running, starting now")
            status = AUGraphStart(self.processingGraph!)
            CheckError(error: status)
        }
    }
    
    
    func loadSF2Preset(preset:UInt8)  {
        guard let bankURL = Bundle.main().urlForResource("stab", withExtension: ".wav") else{
            fatalError("\"soundfont not found.")
        }
        var instdata = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(bankURL),
                                               instrumentType: UInt8(kInstrumentType_Audiofile),//kInstrumentType_SF2Preset
                                               bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                               bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                               presetID: preset)
        let status = AudioUnitSetProperty(self.samplerUnit!,
                                          AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument),
                                          AudioUnitScope(kAudioUnitScope_Global), 0,
                                          &instdata,
                                          UInt32(sizeof(AUSamplerInstrumentData)))
        CheckError(error: status)
    }
    var track:MusicTrack? = nil
    
    func createMusicSequence() -> MusicSequence {
        // create the sequence
        var musicSequence:MusicSequence? = nil
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr) {
            print("\(#line) bad status \(status) creating sequence")
            CheckError(error: status)
        }
        
        // add a track
       // var track = MusicTrack()
        status = MusicSequenceNewTrack(musicSequence!, &track)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
            CheckError(error: status)
        }
        
        // now make some notes and put them on the track
        var beat = MusicTimeStamp(1.0)
        for i:UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                                       note: i,
                                       velocity: 64,
                                       releaseVelocity: 0,
                                       duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track!, beat, &mess)
            //putNoteOn(0.0)
            if status != OSStatus(noErr) {
                CheckError(error: status)
            }
            beat += 1
            
        }
        
        loopTrack(musicTrack: track!)
        
        // associate the AUGraph with the sequence.
        MusicSequenceSetAUGraph(musicSequence!, self.processingGraph)
        
        return musicSequence!
    }
    func putNoteOn(beat:Double)  {
        
        var mess2 = MIDINoteMessage(channel: 0,
                                    note: 50,
                                    velocity: 64,
                                    releaseVelocity: 0,
                                    duration: 1.0 )
        var status = MusicTrackNewMIDINoteEvent(track!, 0.0, &mess2)
        if status != OSStatus(noErr) {
            CheckError(error: status)
        }
        print(status)
        print("touches1")
        
       
    }

    func playNoteOn(noteNum:UInt32, velocity:UInt32){
        let noteCommand = UInt32(0x90 | 0)
        var status = OSStatus(noErr)
        status = MusicDeviceMIDIEvent(self.samplerUnit!, noteCommand, noteNum, velocity, 0)
        CheckError(error: status)
        print("noteon status is \(status)")
        var track:MusicTrack? = nil
        var mess = MIDINoteMessage(channel: 0,
                                   note: 50,
                                   velocity: 64,
                                   releaseVelocity: 0,
                                   duration: 1.0 )
        status = MusicTrackNewMIDINoteEvent(track!, 0.0, &mess)
        
        
    }
    
    func createPlayer(musicSequence:MusicSequence) -> MusicPlayer {
        var musicPlayer:MusicPlayer? = nil
        var status = OSStatus(noErr)
        status = NewMusicPlayer(&musicPlayer)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating player")
            CheckError(error: status)
        }
        status = MusicPlayerSetSequence(musicPlayer!, musicSequence)
        if status != OSStatus(noErr) {
            print("setting sequence \(status)")
            CheckError(error: status)
        }
        status = MusicPlayerPreroll(musicPlayer!)
        if status != OSStatus(noErr) {
            print("prerolling player \(status)")
            CheckError(error: status)
        }
        return musicPlayer!
    }
    
    // called fron the button's action
    func play() {
        var status = OSStatus(noErr)
        var playing = DarwinBoolean(false)
        status = MusicPlayerIsPlaying(musicPlayer!, &playing)
        if playing != false {
            print("music player is playing. stopping")
            status = MusicPlayerStop(musicPlayer!)
            if status != OSStatus(noErr) {
                print("Error stopping \(status)")
                CheckError(error: status)
                return
            }
        } else {
            print("music player is not playing.")
        }
        
        status = MusicPlayerSetTime(musicPlayer!, 0)
        if status != OSStatus(noErr) {
            print("setting time \(status)")
            CheckError(error: status)
            return
        }
        
        status = MusicPlayerStart(musicPlayer!)
        if status != OSStatus(noErr) {
            print("Error starting \(status)")
            CheckError(error: status)
            return
        }
    }
    
    func stop() {
        var status = OSStatus(noErr)
        status = MusicPlayerStop(musicPlayer!)
        if status != OSStatus(noErr) {
            print("Error stopping \(status)")
            CheckError(error: status)
            return
        }
    }
    
 
    func CheckError(error:OSStatus) {
        if error == 0 {return}
        
        switch(error) {
        // AudioToolbox
        case kAUGraphErr_NodeNotFound:
            print("Error:kAUGraphErr_NodeNotFound \n");
            
        case kAUGraphErr_OutputNodeErr:
            print( "Error:kAUGraphErr_OutputNodeErr \n");
            
        case kAUGraphErr_InvalidConnection:
            print("Error:kAUGraphErr_InvalidConnection \n");
            
        case kAUGraphErr_CannotDoInCurrentContext:
            print( "Error:kAUGraphErr_CannotDoInCurrentContext \n");
            
        case kAUGraphErr_InvalidAudioUnit:
            print( "Error:kAUGraphErr_InvalidAudioUnit \n");
            
            // Core MIDI constants. Not using them here.
            //    case kMIDIInvalidClient :
            //        println( "kMIDIInvalidClient ");
            //
            //
            //    case kMIDIInvalidPort :
            //        println( "kMIDIInvalidPort ");
            //
            //
            //    case kMIDIWrongEndpointType :
            //        println( "kMIDIWrongEndpointType");
            //
            //
            //    case kMIDINoConnection :
            //        println( "kMIDINoConnection ");
            //
            //
            //    case kMIDIUnknownEndpoint :
            //        println( "kMIDIUnknownEndpoint ");
            //
            //
            //    case kMIDIUnknownProperty :
            //        println( "kMIDIUnknownProperty ");
            //
            //
            //    case kMIDIWrongPropertyType :
            //        println( "kMIDIWrongPropertyType ");
            //
            //
            //    case kMIDINoCurrentSetup :
            //        println( "kMIDINoCurrentSetup ");
            //
            //
            //    case kMIDIMessageSendErr :
            //        println( "kMIDIMessageSendErr ");
            //
            //
            //    case kMIDIServerStartErr :
            //        println( "kMIDIServerStartErr ");
            //
            //
            //    case kMIDISetupFormatErr :
            //        println( "kMIDISetupFormatErr ");
            //
            //
            //    case kMIDIWrongThread :
            //        println( "kMIDIWrongThread ");
            //
            //
            //    case kMIDIObjectNotFound :
            //        println( "kMIDIObjectNotFound ");
            //
            //
            //    case kMIDIIDNotUnique :
            //        println( "kMIDIIDNotUnique ");
            
            
        case kAudioToolboxErr_InvalidSequenceType :
            print( " kAudioToolboxErr_InvalidSequenceType ");
            
        case kAudioToolboxErr_TrackIndexError :
            print( " kAudioToolboxErr_TrackIndexError ");
            
        case kAudioToolboxErr_TrackNotFound :
            print( " kAudioToolboxErr_TrackNotFound ");
            
        case kAudioToolboxErr_EndOfTrack :
            print( " kAudioToolboxErr_EndOfTrack ");
            
        case kAudioToolboxErr_StartOfTrack :
            print( " kAudioToolboxErr_StartOfTrack ");
            
        case kAudioToolboxErr_IllegalTrackDestination	:
            print( " kAudioToolboxErr_IllegalTrackDestination");
            
        case kAudioToolboxErr_NoSequence 		:
            print( " kAudioToolboxErr_NoSequence ");
            
        case kAudioToolboxErr_InvalidEventType		:
            print( " kAudioToolboxErr_InvalidEventType");
            
        case kAudioToolboxErr_InvalidPlayerState	:
            print( " kAudioToolboxErr_InvalidPlayerState");
            
        case kAudioUnitErr_InvalidProperty		:
            print( " kAudioUnitErr_InvalidProperty");
            
        case kAudioUnitErr_InvalidParameter		:
            print( " kAudioUnitErr_InvalidParameter");
            
        case kAudioUnitErr_InvalidElement		:
            print( " kAudioUnitErr_InvalidElement");
            
        case kAudioUnitErr_NoConnection			:
            print( " kAudioUnitErr_NoConnection");
            
        case kAudioUnitErr_FailedInitialization		:
            print( " kAudioUnitErr_FailedInitialization");
            
        case kAudioUnitErr_TooManyFramesToProcess	:
            print( " kAudioUnitErr_TooManyFramesToProcess");
            
        case kAudioUnitErr_InvalidFile			:
            print( " kAudioUnitErr_InvalidFile");
            
        case kAudioUnitErr_FormatNotSupported		:
            print( " kAudioUnitErr_FormatNotSupported");
            
        case kAudioUnitErr_Uninitialized		:
            print( " kAudioUnitErr_Uninitialized");
            
        case kAudioUnitErr_InvalidScope			:
            print( " kAudioUnitErr_InvalidScope");
            
        case kAudioUnitErr_PropertyNotWritable		:
            print( " kAudioUnitErr_PropertyNotWritable");
            
        case kAudioUnitErr_InvalidPropertyValue		:
            print( " kAudioUnitErr_InvalidPropertyValue");
            
        case kAudioUnitErr_PropertyNotInUse		:
            print( " kAudioUnitErr_PropertyNotInUse");
            
        case kAudioUnitErr_Initialized			:
            print( " kAudioUnitErr_Initialized");
            
        case kAudioUnitErr_InvalidOfflineRender		:
            print( " kAudioUnitErr_InvalidOfflineRender");
            
        case kAudioUnitErr_Unauthorized			:
            print( " kAudioUnitErr_Unauthorized");
            
        default:
            print("huh?")
        }
    }
    
    //LOOOOOOOOOOOOPINNG=====================================================================================================================
    //==============================================================================
    //=================================================================
    
    
    func getTrackLength(musicTrack:MusicTrack) -> MusicTimeStamp {
        //The time of the last music event in a music track, plus time required for note fade-outs and so on
        var trackLength = MusicTimeStamp(0)
        var tracklengthSize = UInt32(0)
        let status = MusicTrackGetProperty(musicTrack,
                                           UInt32(kSequenceTrackProperty_TrackLength),
                                           &trackLength,
                                           &tracklengthSize)
        if status != OSStatus(noErr){
            print("Error getting track length \(status)")
            CheckError(error: status)
            return 0
        }
        print("track length is \(trackLength)")
        return trackLength
    }
    
    func loopTrack(musicTrack:MusicTrack) {
        let trackLength = getTrackLength(musicTrack: musicTrack)
        print("Track length is \(trackLength)")
        setTrackLoopDuration(musicTrack: musicTrack, duration: trackLength)
    }
    
    /*
     The default looping behaviour is off (track plays once)
     Looping is set by specifying the length of the loop. It loops from
     (TrackLength - loop length) to Track Length
     If numLoops is set to zero, it will loop forever.
     To turn looping off, you set this with loop length equal to zero.
     */
    
    func setTrackLoopDuration(duration:Float) {
        var track:MusicTrack? = nil
        let status = MusicSequenceGetIndTrack(musicSequence!, 0, &track)
        CheckError(error: status)
        setTrackLoopDuration(musicTrack: track!, duration: MusicTimeStamp(duration))
    }
    
    func setTrackLoopDuration(musicTrack:MusicTrack, duration:MusicTimeStamp) {
        print("loop duration to \(duration)")
        
        //to loop forever, set numberOfLoops to 0. To explicitly turn of looping,secify a loop Duration of 0
        var loopInfo = MusicTrackLoopInfo(loopDuration: duration, numberOfLoops: 0)
        let lisize = UInt32(0)
        let status = MusicTrackSetProperty(musicTrack, UInt32(kSequenceTrackProperty_LoopInfo), &loopInfo, lisize)
        if status != OSStatus(noErr){
            print("Error setting loopinfo on track \(status)")
            CheckError(error: status)
            return
        }
    }
    
    
    
}//end

















