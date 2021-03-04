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
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    @IBAction func playRecording(_ sender: Any) {
        
    }
    
    @IBAction func clearRecording(_ sender: Any) {
        
    }
    
    @IBAction func saveChanges(_ sender: Any) {
        
    }
    
    // Disable or enable buttons depending on recording state
    func configureUI() {
        
    }
    
    // MARK: AV Audio Recording Delegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let data = FileManager.default.contents(atPath: recorder.url.absoluteString)!
            audioState = .recorded(data: data)
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
        case .editTemplate:
            templateNameTextField.isHidden = false
            saveAsTempateStackView.isHidden = true
        case .editTimer:
            templateNameTextField.isHidden = true
            saveAsTempateStackView.isHidden = false
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
        case playing(data: Data)
        case recorded(data: Data)
    }
}


