//
//  RecordAudioViewController.swift
//  TimerChain
//
//  Created by Artem Benda on 19.02.2021.
//

import UIKit
import AVFoundation

class RecordAudioViewController: UIViewController, AVAudioRecorderDelegate, DataViewController {
    
    var mode: RecordAudioMode!
    var dataController: DataController!

    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioState: AudioState!

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var saveButton: UIButton!
    
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var templateNameTextField: UITextField!
    @IBOutlet weak var saveAsTempateStackView: UIStackView!
    @IBOutlet weak var saveAsTemplateSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUIInitial()
        configureUI()
    }
    
    private func setupPlayer(data: Data) -> Bool {
        do {
            try audioPlayer = AVAudioPlayer(data: data)
            audioPlayer.delegate = self
            return true
        } catch {
            print("Could not initialize player with provided binary data")
            return false
        }
    }

    @IBAction func recordAudio(_ sender: Any) {
        audioState = .recording
        configureUI()
        
        let dirPath = NSTemporaryDirectory() //NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "audioInstruction.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)

        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    @IBAction func stopRecording(_ sender: Any) {
        switch audioState {
        case .recording:
            audioState = .stoppedRecording
            configureUI()
            audioRecorder.stop()
            let audioSession = AVAudioSession.sharedInstance()
            try! audioSession.setActive(false)
        case .playing(let data):
            audioState = .ready(data: data)
            stopAudio()
            configureUI()
        default:
            break
        }
    }
    
    @IBAction func playRecording(_ sender: Any) {
        playSound()
    }
    
    @IBAction func clearRecording(_ sender: Any) {
        audioState = .notRecorded
        configureUI()
    }
    
    @IBAction func saveChanges(_ sender: Any) {
        
    }
    
    // Disable or enable buttons depending on recording state
    func configureUI() {
        switch audioState {
        case .notRecorded:
            recordingLabel.text = "No Recording"
            recordButton.isEnabled = true
            playButton.isEnabled = false
            stopButton.isEnabled = false
            clearButton.isEnabled = false
        case .playing:
            recordingLabel.text = "Playing audio..."
            recordButton.isEnabled = false
            playButton.isEnabled = false
            stopButton.isEnabled = true
            clearButton.isEnabled = false
        case .ready:
            let duration = audioPlayer.duration.rounded().description
            recordingLabel.text = "Recording duration: \(duration)"
            recordButton.isEnabled = false
            playButton.isEnabled = true
            stopButton.isEnabled = false
            clearButton.isEnabled = true
        case .stoppedRecording:
            recordingLabel.text = "Processing Recording..."
            recordButton.isEnabled = false
            playButton.isEnabled = false
            stopButton.isEnabled = false
            clearButton.isEnabled = false
        case .recording:
            recordingLabel.text = "Recording..."
            recordButton.isEnabled = false
            playButton.isEnabled = false
            stopButton.isEnabled = true
            clearButton.isEnabled = false
        default:
            break
        }
    }
    
    // MARK: AV Audio Recording Delegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let data = FileManager.default.contents(atPath: recorder.url.absoluteString)!
            if setupPlayer(data: data) {
                audioState = .ready(data: data)
            } else {
                audioState = .notRecorded
            }
        } else {
            print("Recording was not successfull")
            audioState = .notRecorded
        }
        configureUI()
    }
    
    private func configureUIInitial() {
        switch mode {
        case .newTemplate:
            templateNameTextField.isHidden = false
            saveAsTempateStackView.isHidden = true
            audioState = .notRecorded
        case .editTemplate(let template):
            templateNameTextField.isHidden = false
            saveAsTempateStackView.isHidden = true
            if let data = template.audioData {
                audioState = .ready(data: data)
            } else {
                audioState = .notRecorded
            }
        case .editTimer(let timer):
            templateNameTextField.isHidden = true
            saveAsTempateStackView.isHidden = false
            if let data = timer.audioActionDescription?.audioData {
                audioState = .ready(data: data)
            } else {
                audioState = .notRecorded
            }
        default:
            print("No mode selected")
            break
        }
    }
    
    public enum RecordAudioMode {
        case newTemplate
        case editTemplate(_ template: AudioRecordingTemplate)
        case editTimer(_ timer: Timer)
    }
    
    enum AudioState {
        case notRecorded
        case recording
        case stoppedRecording
        case playing(data: Data)
        case ready(data: Data)
    }
}

extension RecordAudioViewController: AVAudioPlayerDelegate {
    
    // MARK: Audio Functions
    
    func playSound() {
        switch audioState {
        case .ready(let data):
            do {
                if audioPlayer == nil, data != audioPlayer.data {
                    let isSuccess = setupPlayer(data: data)
                    guard isSuccess == true else { return }
                }
                audioState = .playing(data: data)
                configureUI()
                audioPlayer.play()
            }
        default:
            break
        }
    }
    
    func stopAudio() {
        switch audioState {
        case .playing(let data):
            audioPlayer?.stop()
            audioState = .ready(data: data)
            configureUI()
        default:
            break
        }
    }
    
    // MARK AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Playback finished")
        stopAudio()
    }
}
