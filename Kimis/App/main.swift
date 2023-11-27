//
//  main.swift
//  Kimis
//
//  Created by Lakr Aream on 2022/11/14.
//

import UIKit

@_exported import Source
@_exported import SwifterSwift

let bundleIdentifier = Bundle.main.bundleIdentifier!
let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

print("[*] Core Boot Started")
print("    \(bundleIdentifier)")
print("    \(appVersion)")

private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)
let documentsDirectory = availableDirectories[0]
    .appendingPathComponent(bundleIdentifier)

try? FileManager.default.createDirectory(
    at: documentsDirectory,
    withIntermediateDirectories: true,
    attributes: nil
)

print("Document Dir: \(documentsDirectory.path)")

let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)
try? FileManager.default.removeItem(at: temporaryDirectory)
try? FileManager.default.createDirectory(
    at: documentsDirectory,
    withIntermediateDirectories: true,
    attributes: nil
)

print("Temp Dir: \(temporaryDirectory.path)")

AppDelegate.setupIDNADecoder()
_ = Account.shared

_ = UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
