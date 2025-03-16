import Foundation
import MusicKit
import MediaPlayer
import Combine

@MainActor
class MusicManager: ObservableObject {
    @Published private(set) var currentSong: Song?
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published private(set) var isPlaying: Bool = false
    
    private var timer: Timer?
    private let musicPlayer = SystemMusicPlayer.shared
    private var isSettingUp = false
    let nearbyManager: NearbyConnectionManager
    
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif
    
    init() {
        self.nearbyManager = NearbyConnectionManager()
        Task {
            if !isSimulator {
                await requestMusicAuthorization()
                await setupMusicPlayer()
            } else {
                print("Running in simulator - music playback disabled but nearby connections enabled")
                authorizationStatus = .authorized // Mock authorization for UI testing
            }
        }
    }
    
    private func requestMusicAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status
        print("Music authorization status: \(status)")
    }
    
    private func setupMusicPlayer() async {
        guard !isSettingUp else { return }
        isSettingUp = true
        
        print("Initial player state: \(musicPlayer.state.playbackStatus)")
        startMusicMonitoring()
        isSettingUp = false
    }
    
    private func startMusicMonitoring(interval: TimeInterval = 1.0) {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.checkCurrentSong()
                await self?.updatePlaybackState()
            }
        }
        
        Task {
            await checkCurrentSong()
            await updatePlaybackState()
        }
    }
    
    private func checkCurrentSong() async {
        do {
            let state = musicPlayer.state
            print("Player state: \(state.playbackStatus), Queue status: \(musicPlayer.queue.currentEntry != nil ? "has entry" : "no entry")")
            
            if state.playbackStatus == .playing {
                if let nowPlaying = musicPlayer.queue.currentEntry {
                    print("Current queue entry: \(nowPlaying.title)")
                    
                    // Get artwork using MPMusicPlayerController
                    var artworkURL: URL? = nil
                    if let systemPlayer = MPMusicPlayerController.systemMusicPlayer.nowPlayingItem {
                        if let artwork = systemPlayer.artwork {
                            // Convert UIImage to Data and create a temporary file URL
                            if let imageData = artwork.image(at: CGSize(width: 800, height: 800))?.jpegData(compressionQuality: 1.0) {
                                let tempDir = FileManager.default.temporaryDirectory
                                let fileName = "\(nowPlaying.id).jpg"
                                let fileURL = tempDir.appendingPathComponent(fileName)
                                try? imageData.write(to: fileURL)
                                artworkURL = fileURL
                                print("Created local artwork URL: \(fileURL)")
                            }
                        }
                    }
                    
                    // Create song with artwork
                    let song = Song(
                        id: nowPlaying.id.description,
                        title: nowPlaying.title,
                        artist: extractArtistName(from: nowPlaying.description),
                        albumTitle: MPMusicPlayerController.systemMusicPlayer.nowPlayingItem?.albumTitle ?? "",
                        artworkURL: artworkURL,
                        playbackDate: Date()
                    )
                    
                    // Debug: Print created song details
                    print("Created Song Debug:")
                    print("- Title: \(song.title)")
                    print("- Artist: \(song.artist)")
                    print("- Album: \(song.albumTitle)")
                    print("- Artwork URL: \(artworkURL?.absoluteString ?? "none")")
                    print("- ID: \(song.id)")
                    
                    if currentSong?.id != song.id {
                        print("Updating current song to: \(song.title) by \(song.artist)")
                        currentSong = song
                        nearbyManager.updateCurrentSong(song)
                    }
                } else {
                    print("No current entry in queue")
                    currentSong = nil
                }
            } else {
                print("Player is not in playing state: \(state.playbackStatus)")
                if state.playbackStatus == .stopped || state.playbackStatus == .paused {
                    currentSong = nil
                }
            }
        } catch {
            print("Error checking current song: \(error)")
            currentSong = nil
        }
    }
    
    private func extractArtistName(from description: String) -> String {
        if let artistStart = description.range(of: "artistName: \""),
           let artistEnd = description.range(of: "\"))", range: artistStart.upperBound..<description.endIndex) {
            return String(description[artistStart.upperBound..<artistEnd.lowerBound])
        }
        return ""
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Playback Control Methods
    
    func togglePlayPause() async throws {
        if musicPlayer.state.playbackStatus == .playing {
            try await musicPlayer.pause()
        } else {
            try await musicPlayer.play()
        }
        await updatePlaybackState()
    }
    
    func skipToNext() async throws {
        try await musicPlayer.skipToNextEntry()
        await updatePlaybackState()
    }
    
    func skipToPrevious() async throws {
        try await musicPlayer.skipToPreviousEntry()
        await updatePlaybackState()
    }
    
    private func updatePlaybackState() async {
        isPlaying = musicPlayer.state.playbackStatus == .playing
        await checkCurrentSong()
    }
}

