import Foundation
import MediaPlayer
import Combine

protocol MusicService {
    var currentTrack: Track? { get }
    var playbackState: PlaybackState { get }
    var isAuthorized: Bool { get }
    
    func requestAuthorization() async
    func play()
    func pause()
    func skipToNextItem()
    func skipToPreviousItem()
}

struct Track {
    let id: String
    let title: String
    let artist: String
    let albumTitle: String?
    let artwork: MPMediaItemArtwork?
    let playbackDuration: TimeInterval
    let source: MusicSource
}

enum MusicSource {
    case appleMusic
    case spotify
    // Add more sources as needed
}

enum PlaybackState {
    case playing
    case paused
    case stopped
}

@MainActor
class MusicManager: NSObject, ObservableObject {
    @Published var currentTrack: Track?
    @Published var playbackState: PlaybackState = .stopped
    @Published var isAuthorized = false
    
    private let appleMusicService: AppleMusicService
    // private let spotifyService: SpotifyService // Future implementation
    private var currentService: MusicService
    
    override init() {
        self.appleMusicService = AppleMusicService()
        self.currentService = appleMusicService
        super.init()
        checkAuthorization()
    }
    
    func requestAuthorization() async {
        await currentService.requestAuthorization()
    }
    
    private func checkAuthorization() {
        isAuthorized = currentService.isAuthorized
    }
    
    // MARK: - Playback Control
    
    func play() {
        guard isAuthorized else { return }
        currentService.play()
    }
    
    func pause() {
        guard isAuthorized else { return }
        currentService.pause()
    }
    
    func skipToNextItem() {
        guard isAuthorized else { return }
        currentService.skipToNextItem()
    }
    
    func skipToPreviousItem() {
        guard isAuthorized else { return }
        currentService.skipToPreviousItem()
    }
    
    // MARK: - Music Selection
    
    func showMusicPicker() {
        guard isAuthorized else { return }
        
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = true
        picker.showsCloudItems = true
        
        // Note: The presentation of the picker needs to be handled by the view layer
        // We'll add a delegate to handle the selection
    }
    
    // MARK: - Track Information
    
    func getCurrentTrackInfo() -> (title: String, artist: String, artwork: MPMediaItemArtwork?)? {
        guard isAuthorized, let track = currentTrack else { return nil }
        return (
            title: track.title,
            artist: track.artist,
            artwork: track.artwork
        )
    }
}

// MARK: - Apple Music Service Implementation
class AppleMusicService: NSObject, MusicService {
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var nowPlayingObserver: NSObjectProtocol?
    private var playbackStateObserver: NSObjectProtocol?
    
    var currentTrack: Track? {
        guard let item = musicPlayer.nowPlayingItem else { return nil }
        return Track(
            id: item.persistentID.description,
            title: item.title ?? "Unknown Title",
            artist: item.artist ?? "Unknown Artist",
            albumTitle: item.albumTitle,
            artwork: item.artwork,
            playbackDuration: item.playbackDuration,
            source: .appleMusic
        )
    }
    
    var playbackState: PlaybackState {
        switch musicPlayer.playbackState {
        case .playing:
            return .playing
        case .paused:
            return .paused
        case .stopped, .interrupted, .seekingForward, .seekingBackward:
            return .stopped
        @unknown default:
            return .stopped
        }
    }
    
    var isAuthorized: Bool {
        MPMediaLibrary.authorizationStatus() == .authorized
    }
    
    override init() {
        super.init()
        setupNotificationObservers()
    }
    
    deinit {
        if let observer = nowPlayingObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = playbackStateObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func requestAuthorization() async {
        let status = await MPMediaLibrary.requestAuthorization()
        if status == .authorized {
            setupNotificationObservers()
        }
    }
    
    private func setupNotificationObservers() {
        nowPlayingObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlayingItem()
        }
        
        playbackStateObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updatePlaybackState()
        }
        
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    private func updateNowPlayingItem() {
        // Handle updates through the currentTrack property
    }
    
    private func updatePlaybackState() {
        // Handle updates through the playbackState property
    }
    
    func play() {
        musicPlayer.play()
    }
    
    func pause() {
        musicPlayer.pause()
    }
    
    func skipToNextItem() {
        musicPlayer.skipToNextItem()
    }
    
    func skipToPreviousItem() {
        musicPlayer.skipToPreviousItem()
    }
}

// Example of how a Spotify service would be implemented:
/*
class SpotifyService: MusicService {
    // Implement Spotify SDK integration here
}
*/ 

