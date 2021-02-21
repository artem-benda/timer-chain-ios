//
//  EditTimerViewController.swift
//  TimerChain
//
//  Created by Artem Benda on 19.02.2021.
//

import UIKit

class EditTimerViewController: UIViewController {
    
    var chain: Chain!
    var mode: Mode!
    
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    public enum Mode {
        case new(withName: String)
        case edit(_ timer: Timer)
    }

}
