//
//  ViewController.swift
//  PinningPOC
//
//  Created by Jamie Chu on 9/7/20.
//  Copyright © 2020 Jamie Chu. All rights reserved.
//

// MARK: - Attribution: - https://medium.com/better-programming/how-to-implement-ssl-pinning-in-swift-7c4e8f6ee821

import UIKit

final class ViewController: UIViewController {

    
    private let networkManager = NetworkManager(
        options: PinningPreferencesImpl(pinningOption: .publicKey, policy: SecPolicyCreateBasicX509())
    )
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        networkManager.fetchRandomPokemon { _ in }
    }

}

// NOTE: - These are sample terminal commands you can run to download your certs. Alternatively, you can download these directly from chrome. Make sure to embed it to your Xcode project afterwards. 

//openssl s_client -connect <url>:443 </dev/null | openssl x509 -outform DER -out <filename>.der
//openssl s_client -connect sni.cloudflaressl.com:443 </dev/null | openssl x509 -outform DER -out secondPoke.der
//openssl s_client -connect google.com:443 </dev/null | openssl x509 -outform DER -out myPinningCert.cer


//openssl s_client -connect sni.cloudflaressl.com:443 </dev/null | openssl x509 -outform DER -out myPoke1.cer

//sni.cloudflaressl.com
