//
//  NetworkManager.swift
//  PinningPOC
//
//  Created by Jamie Chu on 9/8/20.
//  Copyright © 2020 Jamie Chu. All rights reserved.
//

import Foundation

protocol PinningPreferences {
    var pinningOption: PinningOption { get }
    var policy: SecPolicy { get }
}

struct PinningPreferencesImpl: PinningPreferences {
    let pinningOption: PinningOption
    let policy: SecPolicy
}

final class NetworkManager {
    private let session: URLSession
    private let policy: SecPolicy
    
    // MARK: - Init
    
    init(options: PinningPreferences) {
        
        self.session = URLSession(
            configuration: .default,
            delegate: PinningSessionDelegate(pinningOption: options.pinningOption, policy: options.policy),
            delegateQueue: nil
        )
        self.policy = options.policy
    }

    // MARK: - Public API
    
    // NOTE: - the pokemon name does not matter. The pokeapi API will not issue a challenge if you search for the same string multiple times, so we will randomize it each search

    func fetchRandomPokemon(completion: @escaping ((Data)->Void)) {
        
        let pokemonName = randomString(length: 9)
        
        session.dataTask(with: URL(string: "https://pokeapi.co/api/v2/pokemon/\(pokemonName)")!) {
            (data, response, error) in
            guard let data = data else { return }
            completion(data)
        }.resume()
    }
}

enum PinningOption {
    case certificate
    case publicKey
}

final class PinningSessionDelegate: NSObject, URLSessionDelegate {
    
    private let pinningOption: PinningOption
    private let policy: SecPolicy
    private let locallyStoredCertificates: [SecCertificate]
        
    init(pinningOption: PinningOption = .certificate, policy: SecPolicy) {
        self.pinningOption = pinningOption
        self.policy = policy
        
        let localCertificateLocations: [(String, String)] = [
            ("CloudflareIncECCCA-3", "crt"),
            ("myPinningCert","cer"),
            ("sni.cloudflaressl.com","cer"), // this is used
        ]
        
        self.locallyStoredCertificates = Self.getCertificatesWith(localCertificateLocations)
    }
    
    // MARK: - URLSessionDelegate
    
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        var disposition: URLSession.AuthChallengeDisposition = .cancelAuthenticationChallenge
        var credential: URLCredential?
        
        // this method shall always call completion
        defer { completionHandler(disposition, credential) }
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust, let serverTrust = challenge.protectionSpace.serverTrust else {
            print("-=- pinning failed")
            return
        }
        
        guard self.validate(trust: serverTrust, with: policy), let certificateProvidedByServer = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            print("-=- pinning failed")
            return
        }
        
        // All of the magic happens here: based on a pinning option, we would use different strategies to verify (via cert or public key)
        switch pinningOption {
        case .certificate:
            if locallyStoredCertificates.contains(certificateProvidedByServer) {
                disposition = .useCredential
                credential = URLCredential(trust: serverTrust)
                print("-=- pinning passed")
            }
        case .publicKey:
            if let serverPublicKey = publicKey(for: certificateProvidedByServer, policy: policy), localPublicKeys.contains(serverPublicKey) {
                disposition = .useCredential
                credential = URLCredential(trust: serverTrust)
                print("-=- pinning passed")
            }
        }
        
    }
    
    // MARK: - Helpers
    
    typealias CertificateLocation = (resource: String, extension: String)
    
    private static func getCertificatesWith(_ certificateLocations: [CertificateLocation]) -> [SecCertificate] {
        
        func createCert(resource: String, ext: String) -> SecCertificate? {
            guard
                let url = Bundle.main.url(forResource: resource, withExtension: ext),
                let certificate = try? Data(contentsOf: url) as CFData,
                let cert = SecCertificateCreateWithData(nil, certificate)
                else { return nil }
            return cert
        }
        
        return certificateLocations.compactMap(createCert)
    }
    
    private func validate(trust: SecTrust, with policy: SecPolicy) -> Bool {
        let status = SecTrustSetPolicies(trust, policy)
        guard status == errSecSuccess else { return false }
        
        return SecTrustEvaluateWithError(trust, nil)
    }
    
    private func publicKey(for certificate: SecCertificate, policy: SecPolicy) -> SecKey? {
        var publicKey: SecKey?
        
        var trust: SecTrust?
        let trustCreationStatus = SecTrustCreateWithCertificates(certificate, policy, &trust)
        
        if let trust = trust, trustCreationStatus == errSecSuccess {
            publicKey = SecTrustCopyPublicKey(trust)
        }
        
        return publicKey
    }
    
    private var localPublicKeys: [SecKey] {
        locallyStoredCertificates.compactMap { publicKey(for: $0, policy: policy) }
    }
}


// MARK: - Attribution: https://www.thetopsites.net/article/50700813.shtml

func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}
