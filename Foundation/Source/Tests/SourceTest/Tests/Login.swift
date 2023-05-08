//
//  Login.swift
//
//
//  Created by QAQ on 2023/3/1.
//

import Foundation
import Module
import Network
import Source
import XCTest

extension SourceTest {
    static func loginToTestServer(host: String, port: Int, secured: Bool, username: String, password: String, store: URL) -> Source? {
        let scheme = secured ? "https" : "http"
        let challenge: LoginChallenge
        var permission: [String] = []

        do {
            guard let challengePrefab = LoginChallenge(host: host) else {
                XCTFail("invalid challenge")
                return nil
            }
            guard var loginComps = URLComponents(url: challengePrefab.requestURL, resolvingAgainstBaseURL: false) else {
                XCTFail("invalid url")
                return nil
            }
            loginComps.scheme = scheme
            loginComps.host = host
            loginComps.port = port
            guard let loginUrl = loginComps.url else {
                XCTFail("invalid url")
                return nil
            }

            for item in loginComps.queryItems ?? [] {
                if item.name == "permission" {
                    permission = item.value?.components(separatedBy: ",") ?? []
                    break
                }
            }

            guard let origCheckUrl = challengePrefab.requestRecipeCheck.url,
                  var checkComps = URLComponents(url: origCheckUrl, resolvingAgainstBaseURL: false)
            else {
                XCTFail("invalid url")
                return nil
            }
            checkComps.scheme = scheme
            checkComps.host = host
            checkComps.port = port
            guard let checkUrl = checkComps.url else {
                XCTFail("invalid url")
                return nil
            }
            var checkRequest = URLRequest(url: checkUrl)
            checkRequest.httpMethod = "POST"

            challenge = LoginChallenge(
                requestHost: challengePrefab.requestHost,
                requestURL: loginUrl,
                requestSession: challengePrefab.requestSession,
                requestRecipeCheck: checkRequest
            )
        }

        print("[+] prepared login challenge at \(challenge.requestURL)")

        var firstToken: String?
        do {
            guard let payload = try? JSONSerialization.data(withJSONObject: [
                "username": username,
                "password": password,
            ]) else {
                XCTFail("unable to create data")
                return nil
            }
            requestAndWait(
                url: "\(scheme)://\(host):\(port)/api/signin",
                allowFailure: false,
                data: payload,
                method: "POST"
            ) { data in
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let seed = json["i"] as? String
                else {
                    return
                }
                firstToken = seed
            }
        }
        guard let firstToken else {
            XCTFail("failed to login")
            return nil
        }
        print("[+] acquired preflight token: \(firstToken)")

        do {
            guard let payload = try? JSONSerialization.data(withJSONObject: [
                "session": challenge.requestSession,
                "permission": permission,
                "i": firstToken,
            ] as [String: Any]) else {
                XCTFail("unable to create data")
                return nil
            }
            requestAndWait(
                url: "\(scheme)://\(host):\(port)/api/miauth/gen-token",
                allowFailure: false,
                data: payload,
                method: "POST"
            ) { _ in }
        }

        print("[+] token request posted, checking answer...")

        var receipt: LoginChallengeReceipt?
        dispatchAndWait {
            if let ans = challenge.check() { receipt = ans }
        }
        guard let receipt else {
            XCTFail("failed to acquire receipt from miauth")
            return nil
        }
        return Source(
            withLoginChallengeRecipe: receipt,
            baseEndpoint: URL(string: "\(scheme)://\(host):\(port)")!,
            storageLocation: store
        )
    }
}
