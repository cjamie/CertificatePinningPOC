//
//  ViewController.swift
//  PinningPOC
//
//  Created by Jamie Chu on 9/7/20.
//  Copyright © 2020 Jamie Chu. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("-=- vdl")
        URLSession.shared.dataTask(with: .init(url: URL(string: "http://pokeapi.co/api/v2/pokemon/ditto")!)) { (data, respone, error) in
            print("-=-")
        }.resume()
    }

    
    private func getCertificates() -> [SecCertificate] {
        let url = Bundle.main.url(forResource: "google", withExtension: "cer")
        return []
    }

}

//openssl s_client -connect <url>:443 </dev/null | openssl x509 -outform DER -out <filename>.der
