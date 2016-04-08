//
//  RecordingViewController.swift
//  PitchPerfect
//
//  Created by Andy Isaacson on 4/7/16.
//  Copyright © 2016 Andy Isaacson. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var stopRecordingButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    
    var audioRecorder:AVAudioRecorder!
    let recordingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0))
    var isRecordingTimerRunning = false
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTimer()
        setRecordingState(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupTimer() {
        dispatch_source_set_event_handler(recordingTimer, updateRecordingUi)
        dispatch_source_set_timer(recordingTimer, DISPATCH_TIME_NOW, 1000, 1000)
    }
    
    func setTimerRunning(willRun: Bool) {
        if (willRun && !isRecordingTimerRunning) {
            dispatch_resume(recordingTimer)
            isRecordingTimerRunning = true
        } else if (!willRun && isRecordingTimerRunning) {
            dispatch_suspend(recordingTimer)
            isRecordingTimerRunning = false
        }
    }

    @IBAction func recordAudio(sender: AnyObject) {
        setRecordingState(true)
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        
        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSessionCategoryPlayAndRecord)
        
        try! audioRecorder = AVAudioRecorder(URL: filePath!, settings: [:])
        audioRecorder.meteringEnabled = true
        audioRecorder.delegate = self
        audioRecorder.prepareToRecord()
        audioRecorder.record()

    }

    @IBAction func stopRecording(sender: AnyObject) {
        setRecordingState(false)
        audioRecorder.stop()
    }
    
    func setRecordingState(isRecording: Bool) {
        recordButton.enabled = !isRecording
        stopRecordingButton.enabled = isRecording
        timeLabel.hidden = !isRecording
        if (isRecording) {
            recordingLabel.text = "Recording in Progress"
        } else {
            recordingLabel.text = "Tap to Record"
        }
        
        setTimerRunning(isRecording)
    }
    
    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if (flag) {
            self.performSegueWithIdentifier("stopRecording", sender: audioRecorder.url)
        } else {
            print("Error saving recording")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "stopRecording") {
            let playSoundsVC = segue.destinationViewController as! PlaySoundsViewController
            let recordedAudioURL = sender as! NSURL
            playSoundsVC.recordedAudioURL = recordedAudioURL
        }
    }
    
    func updateRecordingUi() {
        dispatch_async(dispatch_get_main_queue()) {
            let elapsedTime:NSTimeInterval  = self.audioRecorder.currentTime
            let elapsedMinutes = Int(elapsedTime / 60.0)
            let elapsedSeconds = Int(elapsedTime) % 60
            let elapsedMillis = Int(elapsedTime * 1000.0) % 1000
            self.timeLabel.text = String(format: "%02d:%02d.%03d", elapsedMinutes, elapsedSeconds, elapsedMillis)
        }
    }
}

