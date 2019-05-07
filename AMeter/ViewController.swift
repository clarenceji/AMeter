//
//  ViewController.swift
//  AMeter
//
//  Created by Clarence Ji on 5/7/19.
//  Copyright © 2019 Clarence Ji. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var peakLabel: UILabel!
    @IBOutlet weak var averageProgression: UIProgressView!
    @IBOutlet weak var peakProgression: UIProgressView!
    @IBOutlet weak var sensitivityLabel: UILabel!

    private let recordSettings: [String : Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 48_000,
        AVLinearPCMBitDepthKey: 16,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false
    ]
    
    var audioSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder?
    var meterUpdateTimer: Timer!
    
    var sliderValue: Float = 1.5
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        audioSession = AVAudioSession.sharedInstance()
        setupAudioSession()
        setupMeterUpdates()
        startRecording()
        
    }
    
    private func setupAudioSession() {
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true, options: [])
        } catch {
            fatalError()
        }
        
    }
    
    private func startRecording() {
        
        if audioRecorder == nil {
            
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let outputPath = documentDirectory.appendingPathComponent("dummy.wav", isDirectory: false)
            
            do {
                audioRecorder = try AVAudioRecorder(url: outputPath, settings: recordSettings)
                audioRecorder!.delegate = self
            } catch {
                fatalError("[PNg AVFoundation] Cannot instantiate new AVAudioRecorder")
            }
            
        }
        
        audioRecorder?.prepareToRecord()
        audioRecorder?.record()
        audioRecorder?.isMeteringEnabled = true
        
    }
    
    private func setupMeterUpdates() {
        
        let meterSamplingInterval: TimeInterval = 0.05
        meterUpdateTimer = Timer.scheduledTimer(timeInterval: meterSamplingInterval, target: self, selector: #selector(updateVolumeReading), userInfo: nil, repeats: true)
        
    }
    
    @objc private func updateVolumeReading() {
        
        guard let recorder = audioRecorder else { return }
        
        recorder.updateMeters()
        
        DispatchQueue.main.async {
            
            let averagePower = recorder.averagePower(forChannel: 0)
            let peakPower = recorder.peakPower(forChannel: 0)
            
            // Sensitivity can be changed by changing the base.
            let linearAveragePower = pow(self.sliderValue, averagePower / 20)
            let linearPeakPower = pow(self.sliderValue, peakPower / 20)
            
            self.averageLabel.text = "\(linearAveragePower)"
            self.peakLabel.text = "\(linearPeakPower)"
            
            self.averageProgression.progress = linearAveragePower
            self.peakProgression.progress = linearPeakPower
            
        }
        
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.sliderValue = sender.value
        sensitivityLabel.text = "\(sender.value)"
    }
    
}

extension ViewController: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
    }
    
}
