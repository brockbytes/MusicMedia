import Foundation
import MediaPlayer
import CoreLocation
import UserNotifications
import AVFoundation
import UIKit
import CoreBluetooth

enum PermissionType: String, CaseIterable {
    case music = "Media & Apple Music"
    case location = "Location"
    case notifications = "Notifications"
    case microphone = "Microphone"
    case backgroundRefresh = "Background App Refresh"
    case siri = "Siri & Search"
    case bluetooth = "Bluetooth"
    case localNetwork = "Local Network"
}

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@MainActor
class PermissionsManager: NSObject, ObservableObject, CLLocationManagerDelegate, CBCentralManagerDelegate {
    @Published private(set) var permissionStatuses: [PermissionType: PermissionStatus] = [:]
    
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private var bluetoothManager: CBCentralManager?
    
    override init() {
        super.init()
        locationManager.delegate = self
        bluetoothManager = CBCentralManager(delegate: self, queue: nil)
        updateAllPermissionStatuses()
    }
    
    // MARK: - Permission Status Updates
    
    func updateAllPermissionStatuses() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.updateMusicPermissionStatus() }
                group.addTask { await self.updateLocationPermissionStatus() }
                group.addTask { await self.updateNotificationPermissionStatus() }
                group.addTask { await self.updateMicrophonePermissionStatus() }
                group.addTask { await self.updateSiriPermissionStatus() }
                group.addTask { await self.updateBackgroundRefreshStatus() }
                group.addTask { await self.updateBluetoothStatus() }
                group.addTask { await self.updateLocalNetworkStatus() }
            }
        }
    }
    
    private func updateMusicPermissionStatus() async {
        let status = MPMediaLibrary.authorizationStatus()
        await MainActor.run {
            permissionStatuses[.music] = convertMPMediaLibraryAuthorizationStatus(status)
        }
    }
    
    private func updateLocationPermissionStatus() async {
        let status = locationManager.authorizationStatus
        await MainActor.run {
            permissionStatuses[.location] = convertCLAuthorizationStatus(status)
        }
    }
    
    private func updateNotificationPermissionStatus() async {
        let settings = await notificationCenter.notificationSettings()
        await MainActor.run {
            permissionStatuses[.notifications] = convertUNAuthorizationStatus(settings.authorizationStatus)
        }
    }
    
    private func updateMicrophonePermissionStatus() async {
        let status = AVAudioSession.sharedInstance().recordPermission
        await MainActor.run {
            permissionStatuses[.microphone] = convertAVPermission(status)
        }
    }
    
    private func updateSiriPermissionStatus() async {
        // Siri permissions are handled through Info.plist and system settings
        await MainActor.run {
            permissionStatuses[.siri] = .notDetermined
        }
    }
    
    private func updateBackgroundRefreshStatus() async {
        let status = UIApplication.shared.backgroundRefreshStatus
        await MainActor.run {
            permissionStatuses[.backgroundRefresh] = convertUIBackgroundRefreshStatus(status)
        }
    }
    
    private func updateBluetoothStatus() async {
        guard let manager = bluetoothManager else { return }
        await MainActor.run {
            permissionStatuses[.bluetooth] = convertCBManagerState(manager.state)
        }
    }
    
    private func updateLocalNetworkStatus() async {
        // Local network permissions are handled through Info.plist
        // and are requested when the feature is first used
        await MainActor.run {
            permissionStatuses[.localNetwork] = .notDetermined
        }
    }
    
    // MARK: - Permission Requests
    
    /// Request music library access. Call this when user tries to access music features.
    func requestMusicPermissionIfNeeded() async -> Bool {
        let status = MPMediaLibrary.authorizationStatus()
        if status == .notDetermined {
            let newStatus = await MPMediaLibrary.requestAuthorization()
            await updateMusicPermissionStatus()
            return newStatus == .authorized
        }
        return status == .authorized
    }
    
    /// Request location access. Call this when user accesses nearby features.
    func requestLocationPermissionIfNeeded() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    /// Request notification permissions. Call this during onboarding or when needed.
    func requestNotificationPermissionIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            } catch {
                print("Error requesting notification permission: \(error)")
                return false
            }
        }
        return settings.authorizationStatus == .authorized
    }
    
    /// Request microphone access. Call this when user tries to use audio features.
    func requestMicrophonePermissionIfNeeded() async -> Bool {
        let status = AVAudioSession.sharedInstance().recordPermission
        if status == .undetermined {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        return status == .granted
    }
    
    /// Request permission for a specific type
    func requestPermission(_ type: PermissionType) async {
        switch type {
        case .music:
            _ = await requestMusicPermissionIfNeeded()
        case .location:
            requestLocationPermissionIfNeeded()
        case .notifications:
            _ = await requestNotificationPermissionIfNeeded()
        case .microphone:
            _ = await requestMicrophonePermissionIfNeeded()
        case .backgroundRefresh:
            // Background refresh permission is not managed by this manager
            break
        case .siri:
            // Siri permission is not managed by this manager
            break
        case .bluetooth:
            // Bluetooth permission is not managed by this manager
            break
        case .localNetwork:
            // Local network permission is not managed by this manager
            break
        }
        await updateAllPermissionStatuses()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            permissionStatuses[.location] = convertCLAuthorizationStatus(manager.authorizationStatus)
        }
    }
    
    // MARK: - CBCentralManagerDelegate
    
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            permissionStatuses[.bluetooth] = convertCBManagerState(central.state)
        }
    }
    
    // MARK: - Helper Functions
    
    private func convertMPMediaLibraryAuthorizationStatus(_ status: MPMediaLibraryAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }
    
    private func convertCLAuthorizationStatus(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorizedWhenInUse, .authorizedAlways: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }
    
    private func convertUNAuthorizationStatus(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .authorized, .provisional, .ephemeral: return .authorized
        case .denied: return .denied
        @unknown default: return .denied
        }
    }
    
    private func convertAVPermission(_ status: AVAudioSession.RecordPermission) -> PermissionStatus {
        switch status {
        case .undetermined: return .notDetermined
        case .granted: return .authorized
        case .denied: return .denied
        @unknown default: return .denied
        }
    }
    
    private func convertINAuthorizationStatus(_ status: Int) -> PermissionStatus {
        // Since we're not actively managing Siri permissions, we'll return notDetermined
        return .notDetermined
    }
    
    private func convertUIBackgroundRefreshStatus(_ status: UIBackgroundRefreshStatus) -> PermissionStatus {
        switch status {
        case .available: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }
    
    private func convertCBManagerState(_ state: CBManagerState) -> PermissionStatus {
        switch state {
        case .unknown, .resetting:
            return .notDetermined
        case .unsupported, .unauthorized:
            return .denied
        case .poweredOff:
            return .restricted
        case .poweredOn:
            return .authorized
        @unknown default:
            return .denied
        }
    }
    
    /// Opens the app's settings page
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
} 