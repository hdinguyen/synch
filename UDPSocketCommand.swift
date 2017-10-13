//
//  UDPSocketCommand.swift
//  Socket
//
//  Created by Nguyen Huynh on 10/10/17.
//  Copyright © 2017 Nguyen Huynh. All rights reserved.
//

import UIKit
import CocoaAsyncSocket
import ObjectMapper

typealias dataReceiveClosure = (_ data:Data, _ fromAddress:String) -> Void

class UDPSocketCommand: NSObject, GCDAsyncUdpSocketDelegate {
    private var socket:GCDAsyncUdpSocket?
    private var port:UInt16 = 3001
    public var receiveHandler = [dataReceiveClosure]()
    
    static let sharedInstance: UDPSocketCommand = {
        let instance = UDPSocketCommand()
        // setup code
        return instance
    }()
    
    override init() {
        super.init()
        socket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .userInteractive))
        socket?.setIPv6Enabled(false)
        socket?.setIPv4Enabled(true)
    }
    
    func start(port: UInt16) {
        self.port = port
        do {
            try socket?.enableBroadcast(true)
            try socket?.bind(toPort: self.port)
            try socket?.beginReceiving()
        } catch {
            print("Initialize UDPBroadcast fail")
        }
    }
    
    func stop() {
        self.socket?.close()
    }
    
    func broadcastData(data: Data) {
        broadcastData(data: data, -1, 0)
    }
    
    func broadcastJSONData(jsonObject:Any) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
            self.broadcastData(data: jsonData)
        } catch let myJSONError {
            print(myJSONError)
        }
    }
    
    func subcribeReceiver(receiver: @escaping dataReceiveClosure) -> Int {
        self.receiveHandler.append(receiver)
        return self.receiveHandler.endIndex
    }
    
    func broadcastData(data: Data, _ timeout:TimeInterval, _ tag:Int) {
        socket?.send(data, toHost: "255.255.255.255", port: self.port, withTimeout: timeout, tag: tag)
    }
    
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        for receiver in receiveHandler {
            receiver(data, GCDAsyncSocket.host(fromAddress: address)!)
        }
    }
}

