//
//  RealtimeManager.swift
//  Mammoth
//
//  Created by Benoit Nolens on 08/11/2023.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Reachability
import UIKit

class RealtimeManager {
    static let shared = RealtimeManager()

    enum CallbackData {
        case notification(Notificationt)
        case error(Error?)
    }

    typealias Callback = (_ data: CallbackData) -> Void

    private var webSocket: URLSessionWebSocketTask?
    private var session: URLSession?
    private let reachability = try? Reachability(hostname: "google.com")
    private var callbacks: [Callback] = []
    private var receivedCallback: ((Result<URLSessionWebSocketTask.Message, Error>) -> Void)?
    private var pingTimer: Timer?

    func prepareForUse() {
        receivedCallback = { [weak self] result in
            guard let self else { return }
            switch result {
            case let .success(message):
                switch message {
                case let .string(text):
                    if let jsonData = text.data(using: .utf8) {
                        do {
                            let event = try JSONDecoder().decode(EventData.self, from: jsonData)
                            if let notification = event.payload {
                                self.callListeners(.notification(notification))
                            }
                        } catch {
                            self.callListeners(.error(error))
                        }
                    }
                default:
                    log.warning("got an unexpected webSocket message; sleeping to prevent a tight loop")
                    sleep(1)
                }
            case let .failure(error):
                log.error("[websocket error]: \(error)")
            }
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive),
                                               name: appDidBecomeActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reachabilityChanged),
                                               name: .reachabilityChanged,
                                               object: nil)

        try? reachability?.startNotifier()
    }

    func connect() throws {
        guard let _ = AccountsManager.shared.currentAccount as? MastodonAcctData else {
            let error = NSError(domain: "RealtimeManager.connect called with no current account", code: 401)
            log.error("\(error)")
            throw error
        }

        let client = AccountsManager.shared.currentAccountClient

        guard let accessToken = client.accessToken else {
            let error = NSError(domain: "RealtimeManager.connect called with no access token", code: 401)
            log.error("\(error)")
            throw error
        }

        // Get the streaming URL, if any specified
        Task {
            let currentInstanceDetails = try await InstanceService.instanceDetails()
            let baseURLString = currentInstanceDetails.configuration?.urls?.streaming ?? "wss://\(client.baseHost)"
            log.debug("Streaming URL: \(baseURLString)")
            DispatchQueue.main.async {
                var request = URLRequest(url: URL(string: "\(baseURLString)/api/v1/streaming?type=subscribe&stream=user:notification&access_token=\(accessToken)")!)
                request.timeoutInterval = 5
                self.session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
                self.webSocket = self.session?.webSocketTask(with: request)
                self.setListener()
                self.webSocket?.resume()

                self.startPinging()
            }
        }
    }

    func disconnect() {
        webSocket?.cancel()
        webSocket = nil
    }

    func onEvent(callback: @escaping Callback) {
        DispatchQueue.main.async {
            self.callbacks.append(callback)
        }
    }

    func clearAllListeners() {
        DispatchQueue.main.async {
            self.callbacks = []
        }
    }

    // MARK: - Internal methods

    private func setListener() {
        if let callback = receivedCallback {
            webSocket?.receive(completionHandler: callback)
        }
    }

    private func callListeners(_ data: CallbackData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for callback in self.callbacks {
                callback(data)
            }
        }
    }

    @objc private func appDidBecomeActive() {
        if let ws = webSocket, [.canceling, .suspended, .completed].contains(ws.state) {
            try? connect()
        } else {
            startPinging()
        }

        setListener()
    }

    @objc private func appWillResignActive() {
        stopPinging()
    }

    @objc private func reachabilityChanged(notification: Notification) {
        let reachability = notification.object as! Reachability

        switch reachability.connection {
        case .wifi, .cellular:
            if let ws = webSocket, [.canceling, .suspended, .completed].contains(ws.state) {
                try? connect()
            }
            setListener()
        case .unavailable:
            disconnect()
        }
    }

    // Ping the server every 10s to keep the connection alive
    private func startPinging() {
        guard pingTimer == nil else { return }
        pingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] timer in
            self?.webSocket?.sendPing { error in
                guard let self else { return }
                if error != nil {
                    if let timer = self.pingTimer, timer.isValid {
                        self.stopPinging()
                        try? self.connect()
                    }
                }
            }
        }
    }

    private func stopPinging() {
        pingTimer?.invalidate()
        pingTimer = nil
    }
}

struct EventData {
    let stream: [String]
    let event: String
    let payload: Notificationt?

    enum CodingKeys: String, CodingKey {
        case stream, event, payload
    }
}

extension EventData: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        stream = try values.decode([String].self, forKey: .stream)
        event = try values.decode(String.self, forKey: .event)

        switch event {
        case "notification":
            let payloadString = try values.decode(String.self, forKey: .payload)
            if let data = payloadString.data(using: .utf8) {
                payload = try JSONDecoder().decode(Notificationt.self, from: data)
            } else {
                log.error("[RealtimeManager] cannot parse payload")
                payload = nil
            }
        default:
            payload = nil
        }
    }
}
