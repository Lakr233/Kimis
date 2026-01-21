//
//  DriveFile.swift
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
    func checkApi_DriveFile() {
        var checkId = UUID().uuidString
        dispatchAndWait {
            let url = temp
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("jpeg")
            try? FileManager.default.removeItem(at: url)
            XCTAssert(FileManager.default.fileExists(atPath: url.path) == false)
            try? jpegImgData.write(to: url, options: .atomic)
            XCTAssert(FileManager.default.fileExists(atPath: url.path))
            let item = source.network.requestDriveFileCreate(
                asset: url,
                setTask: { _ in },
                setProgress: { _ in },
            )
            guard let item else {
                XCTFail("failed to create drive file")
                return
            }
            checkId = item.id
            unwrapOrFail(item.userId == source.receipt.accountId)
            XCTAssert(!item.url.isEmpty)
            XCTAssert(item.isSensitive == false)
            XCTAssert(!item.id.isEmpty)
            unwrapOrFail(item.properties) { pro in
                unwrapOrFail(pro.height) { XCTAssert($0 > 0) }
                unwrapOrFail(pro.width) { XCTAssert($0 > 0) }
            }
            unwrapOrFail(item.size) { XCTAssert($0 > 0) }

            let uploadAgain = source.network.requestDriveFileCreate(
                asset: url,
                setTask: { _ in },
                setProgress: { _ in },
            )
            XCTAssert(uploadAgain?.id == item.id)

            let updatedFile = source.network.requestDriveFileUpdate(
                fileId: item.id,
                folderId: nil,
                name: "123456.jpg",
                isSensitive: true,
                comment: "comment",
            )
            guard let updatedFile else {
                XCTFail("failed to update drive file")
                return
            }
            XCTAssert(updatedFile.id == item.id)
            XCTAssert(updatedFile.comment == "comment")
            XCTAssert(updatedFile.name == "123456.jpg")
            XCTAssert(updatedFile.isSensitive == true)
            unwrapOrFail(updatedFile.userId == source.receipt.accountId)
            XCTAssert(!updatedFile.url.isEmpty)
            unwrapOrFail(updatedFile.properties) { pro in
                unwrapOrFail(pro.height) { XCTAssert($0 > 0) }
                unwrapOrFail(pro.width) { XCTAssert($0 > 0) }
            }
            unwrapOrFail(updatedFile.size) { XCTAssert($0 > 0) }

            let updatedFile2 = source.network.requestDriveFileUpdate(
                fileId: item.id,
                folderId: nil,
                name: "654321.jpg",
                isSensitive: false,
                comment: "tnemmoc",
            )
            guard let updatedFile2 else {
                XCTFail("failed to update drive file")
                return
            }
            XCTAssert(updatedFile2.id == item.id)
            XCTAssert(updatedFile2.comment == "tnemmoc")
            XCTAssert(updatedFile2.name == "654321.jpg")
            XCTAssert(updatedFile2.isSensitive == false)
            unwrapOrFail(updatedFile2.userId == source.receipt.accountId)
            XCTAssert(!updatedFile2.url.isEmpty)
            unwrapOrFail(updatedFile2.properties) { pro in
                unwrapOrFail(pro.height) { XCTAssert($0 > 0) }
                unwrapOrFail(pro.width) { XCTAssert($0 > 0) }
            }
            unwrapOrFail(updatedFile2.size) { XCTAssert($0 > 0) }
        }
        dispatchAndWait {
            let list = source.network.requestForDriveFiles()
            unwrapOrFail(list)
            XCTAssert(!list.isEmpty)
            XCTAssert(list.map(\.id).contains(checkId))
        }
    }
}

private let jpegImgData = Data(base64Encoded: "/9j/4AAQSkZJRgABAQAAkACQAAD/4QCMRXhpZgAATU0AKgAAAAgABQESAAMAAAABAAEAAAEaAAUAAAABAAAASgEbAAUAAAABAAAAUgEoAAMAAAABAAIAAIdpAAQAAAABAAAAWgAAAAAAAACQAAAAAQAAAJAAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAAB6gAwAEAAAAAQAAABoAAAAA/+0AOFBob3Rvc2hvcCAzLjAAOEJJTQQEAAAAAAAAOEJJTQQlAAAAAAAQ1B2M2Y8AsgTpgAmY7PhCfv/AABEIABoAHgMBIgACEQEDEQH/xAAfAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgv/xAC1EAACAQMDAgQDBQUEBAAAAX0BAgMABBEFEiExQQYTUWEHInEUMoGRoQgjQrHBFVLR8CQzYnKCCQoWFxgZGiUmJygpKjQ1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4eLj5OXm5+jp6vHy8/T19vf4+fr/xAAfAQADAQEBAQEBAQEBAAAAAAAAAQIDBAUGBwgJCgv/xAC1EQACAQIEBAMEBwUEBAABAncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/2wBDABwcHBwcHDAcHDBEMDAwRFxEREREXHRcXFxcXHSMdHR0dHR0jIyMjIyMjIyoqKioqKjExMTExNzc3Nzc3Nzc3Nz/2wBDASIkJDg0OGA0NGDmnICc5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ubm5ub/3QAEAAL/2gAMAwEAAhEDEQA/ANQkDk0gYE4707rVKVXj5Xp29qmTtqXCKloWJWKDeO3UU9WDAMOhqk1wHiKt1qS1YlSvpUqacrIuVNqN2f/Q0HMi/MnPtUBuhjBWrlQTKpXJAzWc7rVM2p2bs0ZpOTkDFWrd9hII61LAq9cCp2APWs4Q+1c2qVPs2P/Z")!
