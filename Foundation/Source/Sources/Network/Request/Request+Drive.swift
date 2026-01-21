//
//  Request+Drive.swift
//
//
//  Created by Lakr Aream on 2023/1/11.
//

import Foundation
import NetworkModule

public extension Network {
    func requestForDriveFiles(folderId: String? = nil, sinceId: String? = nil, untilId: String? = nil, typeRegex type: String? = nil, limit: Int? = 50) -> [NMDriveFile] {
        var request = prepareRequest(for: .drive_files)
        if let folderId { injectBodyForPost(for: &request, with: ["folderId": folderId]) }
        if let sinceId { injectBodyForPost(for: &request, with: ["sinceId": sinceId]) }
        if let untilId { injectBodyForPost(for: &request, with: ["untilId": untilId]) }
        if let type { injectBodyForPost(for: &request, with: ["type": type]) }
        if let limit { injectBodyForPost(for: &request, with: ["limit": limit]) }

        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }

        return decodeRequest(with: responseData) ?? []
    }

    func requestDriveFileCreate(asset: URL, setTask: (URLSessionDataTask) -> Void, setProgress: @escaping (Double) -> Void) -> NMDriveFile? {
        guard asset.isFileURL else {
            assertionFailure("\(#function) only supports file url")
            return nil
        }
        var fileData: Data
        do {
            fileData = try Data(contentsOf: asset)
        } catch {
            errorMessage.send(error.localizedDescription)
            return nil
        }

        var request = prepareRequest(for: .drive_files_create)

        let boundaryKey = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundaryKey)", forHTTPHeaderField: "Content-Type")

        let body: Data = {
            var builder = Data()
            builder.append(MultipartFormDataBoundaryGenerator.boundaryData(boundaryType: .initial, boundaryKey: boundaryKey))
            builder.append(#"Content-Disposition: form-data; name="i""#)
            builder.append(MultipartFormDataBoundaryGenerator.EncodingCharacters.crlf)
            builder.append(MultipartFormDataBoundaryGenerator.EncodingCharacters.crlf)
            builder.append(credential)

            builder.append(MultipartFormDataBoundaryGenerator.boundaryData(boundaryType: .encapsulated, boundaryKey: boundaryKey))
            builder.append(#"Content-Disposition: form-data; name="file"; filename="blob""#)
            builder.append(MultipartFormDataBoundaryGenerator.EncodingCharacters.crlf)
            builder.append(MultipartFormDataBoundaryGenerator.EncodingCharacters.crlf)
            builder.append(fileData)

            builder.append(MultipartFormDataBoundaryGenerator.boundaryData(boundaryType: .encapsulated, boundaryKey: boundaryKey))
            builder.append(#"Content-Disposition: form-data; name="name""#)
            builder.append(MultipartFormDataBoundaryGenerator.EncodingCharacters.crlf)
            builder.append(MultipartFormDataBoundaryGenerator.EncodingCharacters.crlf)
            builder.append(asset.lastPathComponent)

            builder.append(MultipartFormDataBoundaryGenerator.boundaryData(boundaryType: .final, boundaryKey: boundaryKey))
            return builder
        }()

        request.httpBody = body
        request.timeoutInterval *= 2

        let sendProgressDelegate = URLSendProgressDelegate { progress in
            setProgress(progress.fractionCompleted)
        }
        let session = URLSession(
            configuration: .ephemeral,
            delegate: sendProgressDelegate,
            delegateQueue: nil,
        )
        var responseData: Data?
        makeRequest(with: request, with: session, setTask: setTask) { data in
            responseData = data
        }

        return decodeRequest(with: responseData)
    }

    func requestDriveFileUpdate(fileId: String, folderId: String? = nil, name: String? = nil, isSensitive: Bool? = nil, comment: String? = nil) -> NMDriveFile? {
        var request = prepareRequest(for: .drive_files_update)
        injectBodyForPost(for: &request, with: ["fileId": fileId])
        if let folderId { injectBodyForPost(for: &request, with: ["folderId": folderId]) }
        if let name { injectBodyForPost(for: &request, with: ["name": name]) }
        if let isSensitive { injectBodyForPost(for: &request, with: ["isSensitive": isSensitive]) }
        if let comment { injectBodyForPost(for: &request, with: ["comment": comment]) }

        var responseData: Data?
        makeRequest(with: request) { data in
            responseData = data
        }

        return decodeRequest(with: responseData)
    }
}
