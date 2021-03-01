//
//  AudioTemplatesViewController.swift
//  TimerChain
//
//  Created by Artem Benda on 19.02.2021.
//

import UIKit

class AudioTemplatesViewController: UIViewController, DataViewController {
    
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func handleAddAudioTemplate(_ sender: Any) {
        let mode = RecordAudioViewController.RecordAudioMode.newTemplate
        performSegue(withIdentifier: "audioTemplateSegue", sender: mode)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "audioTemplateSegue":
            let viewController = segue.destination as! RecordAudioViewController
            viewController.mode = sender as? RecordAudioViewController.RecordAudioMode
            viewController.dataController = dataController
        default:
            break
        }
    }
}
