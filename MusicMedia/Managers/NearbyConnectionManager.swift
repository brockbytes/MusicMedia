import Foundation
import MultipeerConnectivity
import Combine

@MainActor
class NearbyConnectionManager: NSObject, ObservableObject {
    // Published properties for UI updates
    @Published private(set) var nearbyUsers: [String: Song] = [:] // deviceID: Song
    @Published private(set) var connectedPeers: [MCPeerID] = []
    
    // MultipeerConnectivity properties
    private let serviceType = "music-media"
    private let myPeerId: MCPeerID
    private var session: MCSession
    private var serviceAdvertiser: MCNearbyServiceAdvertiser
    private var serviceBrowser: MCNearbyServiceBrowser
    
    // Current song to share
    private var currentSong: Song?
    
    private var reconnectionTimer: Timer?
    private var isInBackground = false
    private var isReconnecting = false
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    private var heartbeatTimer: Timer?
    private let heartbeatInterval: TimeInterval = 1.0
    private var lastHeartbeatTime: Date = Date()
    private let connectionTimeout: TimeInterval = 10.0
    private var peerLastSuccessfulSendTimes: [MCPeerID: Date] = [:]
    
    private let maxReconnectionAttempts = 3
    private var reconnectionAttempts: [MCPeerID: Int] = [:]
    
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif
    
    override init() {
        // Create a unique identifier for this device
        let deviceName = UIDevice.current.name
        #if targetEnvironment(simulator)
        myPeerId = MCPeerID(displayName: "Simulator-\(deviceName)")
        #else
        myPeerId = MCPeerID(displayName: deviceName)
        #endif
        
        print("🔍 Initializing NearbyConnectionManager with peer ID: \(myPeerId.displayName)")
        
        session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .required)
        
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId,
                                                    discoveryInfo: nil,
                                                    serviceType: serviceType)
        
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId,
                                              serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        startServices()
        setupNotifications()
        
        print("✅ NearbyConnectionManager initialized and services started")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppDidEnterBackground),
                                            name: UIApplication.didEnterBackgroundNotification,
                                            object: nil)
        
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(handleAppWillEnterForeground),
                                            name: UIApplication.willEnterForegroundNotification,
                                            object: nil)
    }
    
    @objc private func handleAppDidEnterBackground() {
        Task { @MainActor in
            isInBackground = true
            print("NearbyConnectionManager: App entered background")
            
            backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.endBackgroundTask()
                }
            }
            
            // Keep everything running in background
            startHeartbeat() // Restart heartbeat timer
            
            // Send current song state immediately
            if let currentSong = currentSong {
                updateCurrentSong(currentSong)
            }
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        Task { @MainActor in
            isInBackground = false
            print("NearbyConnectionManager: App will enter foreground")
            
            // End background task if it's running
            await endBackgroundTask()
            
            startServices()
        }
    }
    
    private func endBackgroundTask() async {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
    
    private func startServices() {
        print("🚀 Starting nearby services...")
        print("📡 Starting advertising as: \(myPeerId.displayName)")
        serviceAdvertiser.startAdvertisingPeer()
        
        print("🔍 Starting browsing for peers")
        serviceBrowser.startBrowsingForPeers()
        
        startHeartbeat()
        print("✅ All services started")
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    private func sendHeartbeat() {
        guard !connectedPeers.isEmpty else { return }
        
        let heartbeat = [
            "type": "heartbeat",
            "timestamp": Date().timeIntervalSince1970,
            "deviceName": myPeerId.displayName
        ] as [String: Any]
        
        if let heartbeatData = try? JSONSerialization.data(withJSONObject: heartbeat) {
            for peer in session.connectedPeers {
                do {
                    try session.send(heartbeatData, toPeers: [peer], with: .reliable)
                    updateLastSuccessfulSendTime(for: peer)
                } catch {
                    print("❌ Failed heartbeat to \(peer.displayName): \(error)")
                    handleConnectionFailure()
                }
            }
        }
    }
    
    private func updateLastSuccessfulSendTime(for peer: MCPeerID) {
        peerLastSuccessfulSendTimes[peer] = Date()
    }
    
    private func handleConnectionFailure() {
        let currentTime = Date()
        
        // Check each peer individually
        for (peer, lastSuccessTime) in peerLastSuccessfulSendTimes {
            let timeSinceLastSuccess = currentTime.timeIntervalSince(lastSuccessTime)
            print("⚠️ Time since last successful communication with \(peer.displayName): \(Int(timeSinceLastSuccess))s")
            
            if timeSinceLastSuccess > connectionTimeout {
                print("🔄 Starting recovery for \(peer.displayName)")
                Task { @MainActor in
                    // Try to reconnect to this specific peer
                    try? session.send("ping".data(using: .utf8)!, toPeers: [peer], with: .reliable)
                    
                    print("⏳ Grace period started for \(peer.displayName)")
                    // Wait for grace period
                    try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second grace period
                    
                    // Check if we've had successful communication during grace period
                    if let newLastSuccess = peerLastSuccessfulSendTimes[peer],
                       currentTime.timeIntervalSince(newLastSuccess) > connectionTimeout {
                        print("❌ Grace period expired for \(peer.displayName) - removing peer")
                        connectedPeers.removeAll(where: { $0 == peer })
                        nearbyUsers.removeValue(forKey: peer.displayName)
                        peerLastSuccessfulSendTimes.removeValue(forKey: peer)
                    }
                }
            }
        }
    }
    
    func updateCurrentSong(_ song: Song?) {
        print("🎵 Updating current song: \(song?.title ?? "nil")")
        currentSong = song
        
        // Allow simulator to receive songs but only real devices send song updates
        #if targetEnvironment(simulator)
        print("📱 Running in simulator - will receive songs but not send them")
        #else
        print("📡 Broadcasting song update to \(connectedPeers.count) peers")
        sendSongUpdate()
        #endif
    }
    
    private func sendSongUpdate() {
        guard let songData = try? JSONEncoder().encode(currentSong) else {
            print("❌ Failed to encode song")
            return
        }
        
        for peer in session.connectedPeers {
            do {
                print("📤 Sending song update to peer: \(peer.displayName)")
                try session.send(songData, toPeers: [peer], with: .reliable)
                updateLastSuccessfulSendTime(for: peer)
                print("✅ Successfully sent song update to: \(peer.displayName)")
            } catch {
                print("❌ Failed to send song to \(peer.displayName): \(error)")
                handleConnectionFailure()
            }
        }
    }
    
    private func resetReconnectionAttempts(for peer: MCPeerID) {
        reconnectionAttempts[peer] = 0
    }
    
    private func attemptReconnectionWithPeer(_ peerID: MCPeerID) async {
        // Prevent multiple simultaneous reconnection attempts
        guard !isReconnecting else {
            print("⚠️ Reconnection already in progress, skipping new attempt")
            return
        }
        
        guard let attempts = reconnectionAttempts[peerID], attempts < maxReconnectionAttempts else {
            print("❌ Max reconnection attempts reached for \(peerID.displayName)")
            connectedPeers.removeAll(where: { $0 == peerID })
            nearbyUsers.removeValue(forKey: peerID.displayName)
            peerLastSuccessfulSendTimes.removeValue(forKey: peerID)
            reconnectionAttempts.removeValue(forKey: peerID)
            return
        }
        
        isReconnecting = true
        print("🔄 Reconnection attempt \(attempts + 1)/\(maxReconnectionAttempts) for \(peerID.displayName)")
        reconnectionAttempts[peerID] = attempts + 1
        
        // Don't recreate session, just restart services
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        startServices()
        
        // Wait for potential reconnection
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 second wait
        
        // If still not connected and not at max attempts, try again
        if !session.connectedPeers.contains(peerID) && reconnectionAttempts[peerID] ?? 0 < maxReconnectionAttempts {
            isReconnecting = false
            await attemptReconnectionWithPeer(peerID)
        } else if session.connectedPeers.contains(peerID) {
            print("✅ Successfully reconnected to \(peerID.displayName)")
            resetReconnectionAttempts(for: peerID)
            isReconnecting = false
        } else {
            isReconnecting = false
        }
    }
    
    deinit {
        Task { @MainActor in
            await endBackgroundTask()
            reconnectionTimer?.invalidate()
            heartbeatTimer?.invalidate()
            serviceAdvertiser.stopAdvertisingPeer()
            serviceBrowser.stopBrowsingForPeers()
        }
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - MCSessionDelegate
extension NearbyConnectionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            print("👥 Peer \(peerID.displayName) state changed to: \(state.description)")
            switch state {
            case .connected:
                if !connectedPeers.contains(peerID) {
                    connectedPeers.append(peerID)
                    print("✅ Successfully connected to peer: \(peerID.displayName)")
                    resetReconnectionAttempts(for: peerID)
                    
                    // Only send current song if we're not in simulator
                    #if !targetEnvironment(simulator)
                    if let songData = try? JSONEncoder().encode(currentSong) {
                        print("📤 Sending current song to newly connected peer")
                        try? session.send(songData, toPeers: [peerID], with: .reliable)
                    }
                    #endif
                }
            case .notConnected:
                print("⚠️ Peer disconnected: \(peerID.displayName)")
                if reconnectionAttempts[peerID] == nil {
                    reconnectionAttempts[peerID] = 0
                }
                Task {
                    await attemptReconnectionWithPeer(peerID)
                }
            case .connecting:
                print("🔄 Establishing connection with peer: \(peerID.displayName)")
            @unknown default:
                print("❓ Unknown connection state for peer: \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        Task { @MainActor in
            print("📥 Received data from peer: \(peerID.displayName)")
            
            do {
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   dict["type"] as? String == "heartbeat" {
                    print("💓 Received heartbeat from: \(peerID.displayName)")
                    lastHeartbeatTime = Date()
                    return
                }
                
                let song = try JSONDecoder().decode(Song.self, from: data)
                print("🎵 Received song update from \(peerID.displayName): \(song.title)")
                nearbyUsers[peerID.displayName] = song
                updateLastSuccessfulSendTime(for: peerID)
                print("📊 Current nearby users count: \(nearbyUsers.count)")
                print("🎵 Current nearby songs: \(nearbyUsers.map { "\($0.key): \($0.value.title)" }.joined(separator: ", "))")
            } catch {
                print("❌ Error processing data from \(peerID.displayName): \(error)")
                if let str = String(data: data, encoding: .utf8) {
                    print("📝 Received data as string: \(str)")
                }
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension NearbyConnectionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📨 Received invitation from peer: \(peerID.displayName)")
        invitationHandler(true, session)
        print("✅ Automatically accepted invitation from: \(peerID.displayName)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("❌ Failed to start advertising: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension NearbyConnectionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("✨ Found peer: \(peerID.displayName)")
        print("📨 Sending invitation to peer: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("⚠️ Lost sight of peer: \(peerID.displayName)")
        Task { @MainActor in
            if reconnectionAttempts[peerID] == nil {
                reconnectionAttempts[peerID] = 0
            }
            await attemptReconnectionWithPeer(peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("❌ Failed to start browsing: \(error.localizedDescription)")
    }
}

private extension MCSessionState {
    var description: String {
        switch self {
        case .notConnected: return "Not Connected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        @unknown default: return "Unknown"
        }
    }
} 