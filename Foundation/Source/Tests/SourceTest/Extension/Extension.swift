//
//  File.swift
//
//
//  Created by QAQ on 2023/3/1.
//

import Foundation
import XCTest

func dispatchAndWait(_ block: @escaping () throws -> Void) {
    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
        do {
            try block()
        } catch {
            XCTFail(error.localizedDescription)
        }
        sem.signal()
    }
    sem.wait()
}

func requestAndWait(url: String, allowFailure: Bool = false, data: Data? = nil, method: String = "GET", result: @escaping (Data?) -> Void) {
    guard let url = URL(string: url) else {
        XCTFail("failed to create URL with string \(url)")
        result(nil)
        return
    }
    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.global().async {
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 10
        )
        request.httpMethod = method
        if let data {
            request.httpBody = data
            if (try? JSONSerialization.jsonObject(with: data)) != nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        URLSession.shared.dataTask(with: request) { data, _, error in
            defer { sem.signal() }
            if let err = error?.localizedDescription {
                let message = "[i] networking failed on \(url) with \(err)"
                if allowFailure {
                    print(message)
                } else {
                    XCTFail(message)
                }
            }
            result(data)
        }.resume()
    }
    sem.wait()
}

func unwrapOrFail<T>(_ input: T?, execute: ((T) -> Void)? = nil) {
    guard let input else {
        XCTFail("failed with nil")
        return
    }
    if let execute { execute(input) }
}
