//
//  ViewController.swift
//  PullupController
//
//  Created by Даниил Виноградов on 12.04.2021.
//

import UIKit

class ViewController: UIViewController {
    let pullup = TestPullupController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pullup.applyTo(self, in: .halfState, order: 0)
        
    }
    
    @IBAction func expanded(_ sender: Any) {
        pullup.setState(.expanded)
    }
    
    @IBAction func half(_ sender: Any) {
        pullup.setState(.halfState)
    }
    
    @IBAction func collapsed(_ sender: Any) {
        pullup.setState(.collapsed)
    }
    
    @IBAction func hidden(_ sender: Any) {
        pullup.setState(.hidden)
    }
    
}

