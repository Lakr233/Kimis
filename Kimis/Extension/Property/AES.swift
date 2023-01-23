//
//  AES.swift
//  PTFoundation
//
//  Created by Lakr Aream on 12/15/20.
//

import CommonCrypto
import Foundation
import KeychainAccess

private let mainKeyID = "wiki.qaq.crypto.MainCrypto"

public struct AES {
    private let key: Data
    private let iv: Data

    public static let shared: AES = {
        if let aes = loadFromKeychain() {
            return aes
        }

        print("[Keychain]")
        print("  > Failed to communicate with keychain, fallback to static encryption key.")
        print("  > Check your application signature.")

        guard let fallbackAES = AES(
            key: "00393F5A-BB66-4671-A925-480F288BB48F",
            iv: "079B10D5-E1AD-4BD4-BC27-7D85F9634B6A"
        ) else {
            fatalError()
        }
        print("  > Using full static key.")
        return fallbackAES
    }()

    private static func loadFromKeychain() -> AES? {
        let keychain = Keychain()
        var retry = 3
        var key: String?
        repeat {
            defer { retry -= 1 }
            do {
                try setupKey(usingKeychain: keychain, &key)
            } catch {
                continue
            }
        } while retry > 0
        guard let key else {
            NSLog("Failed to load crypto keys for crypto engine")
            return nil
        }
        guard let aes = AES(key: key, iv: key) else {
            NSLog("Failed to initialize crypto engine")
            return nil
        }
        return aes
    }

    private static func setupKey(usingKeychain keychain: Keychain, _ key: inout String?) throws {
        let main = try keychain.getString(mainKeyID)
        if let main, main.count > 2 {
            key = main
        } else {
            try keychain.remove(mainKeyID)
            let new = UUID().uuidString
            key = new
            try keychain
                .label("Main Crypto Key")
                .comment("\(Bundle.main.bundleIdentifier ?? "Unknown") requires a main crypto key to access your encrypted data on disk.")
                .set(new, key: mainKeyID)
        }
    }

    internal init?(key initKey: String, iv initIV: String) {
        if initKey.count < kCCKeySizeAES128 || initIV.count < kCCBlockSizeAES128 {
            return nil
        }
        var initKey = initKey
        while initKey.count < 32 {
            initKey += initKey
        }
        while initKey.count > 32 {
            initKey.removeLast()
        }
        guard initKey.count == kCCKeySizeAES128 || initKey.count == kCCKeySizeAES256,
              let keyData = initKey.data(using: .utf8)
        else {
            return nil
        }
        var initIV = initIV
        while initIV.count < kCCBlockSizeAES128 {
            initIV += initIV
        }
        while initIV.count > kCCBlockSizeAES128 {
            initIV.removeLast()
        }
        guard initIV.count == kCCBlockSizeAES128, let ivData = initIV.data(using: .utf8) else {
            print("Error \(#file) \(#line): Failed to set an initial vector.")
            return nil
        }
        key = keyData
        iv = ivData
    }

    // MARK: - API

    public func encrypt(data: Data) -> Data? {
        crypt(data: data, option: CCOperation(kCCEncrypt))
    }

    public func decrypt(data: Data) -> Data? {
        crypt(data: data, option: CCOperation(kCCDecrypt))
    }

    // MARK: - INTERNAL

    private func crypt(data: Data?, option: CCOperation) -> Data? {
        guard let data else { return nil }

        let cryptLength = data.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLength)

        let keyLength = key.count
        let options = CCOptions(kCCOptionPKCS7Padding)

        var bytesLength = Int(0)

        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            data.withUnsafeBytes { dataBytes in
                iv.withUnsafeBytes { ivBytes in
                    key.withUnsafeBytes { keyBytes in
                        CCCrypt(option, CCAlgorithm(kCCAlgorithmAES), options, keyBytes.baseAddress, keyLength, ivBytes.baseAddress, dataBytes.baseAddress, data.count, cryptBytes.baseAddress, cryptLength, &bytesLength)
                    }
                }
            }
        }

        guard UInt32(status) == UInt32(kCCSuccess) else {
            print("Error: Failed to crypt data. Status \(status)")
            return nil
        }

        cryptData.removeSubrange(bytesLength ..< cryptData.count)
        return cryptData
    }
}
