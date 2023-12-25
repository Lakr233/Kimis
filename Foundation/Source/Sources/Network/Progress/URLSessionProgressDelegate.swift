//
//  URLSessionProgressDelegate.swift
//
//
//  Created by Lakr Aream on 2023/1/11.
//

import Foundation

class URLSendProgressDelegate: NSObject, URLSessionTaskDelegate {
    let sendProgress: (Progress) -> Void

    init(send: @escaping ((Progress) -> Void)) {
        sendProgress = send
        super.init()
    }

    func urlSession(_: URLSession, task _: URLSessionTask, didSendBodyData _: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progres = Progress(totalUnitCount: totalBytesExpectedToSend)
        progres.completedUnitCount = totalBytesSent
//        print(bytesSent, totalBytesSent, totalBytesExpectedToSend)
        sendProgress(progres)
    }
}
