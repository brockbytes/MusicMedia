import Foundation
import MediaPlayer
import Combine

class MusicManager: NSObject, ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var playbackProgress: Double = 0
    
    private let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    
    override init() {
        super.init()
        setupNotificationObservers()
        setupPlaybackTimer()
        updateNowPlaying()
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        timer?.invalidate()
    }
    
    private func setupNotificationObservers() {
        let playbackStateObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerPlaybackStateDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackStateChange()
        }
        
        let nowPlayingObserver = NotificationCenter.default.addObserver(
            forName: .MPMusicPlayerControllerNowPlayingItemDidChange,
            object: musicPlayer,
            queue: .main
        ) { [weak self] _ in
            self?.updateNowPlaying()
        }
        
        observers = [playbackStateObserver, nowPlayingObserver]
        musicPlayer.beginGeneratingPlaybackNotifications()
    }
    
    private func setupPlaybackTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }
    
    private func handlePlaybackStateChange() {
        isPlaying = musicPlayer.playbackState == .playing
    }
    
    private func updateNowPlaying() {
        guard let mediaItem = musicPlayer.nowPlayingItem else {
            currentSong = nil
            return
        }
        currentSong = Song(from: mediaItem)
    }
    
    private func updatePlaybackProgress() {
        guard isPlaying,
              let duration = currentSong?.playbackDuration,
              duration > 0 else {
            return
        }
        
        playbackProgress = musicPlayer.currentPlaybackTime / duration
    }
    
    // MARK: - Public Methods
    
    func requestMusicAuthorization() async -> Bool {
        let status = await MPMediaLibrary.requestAuthorization()
        return status == .authorized
    }
    
    func showMediaPicker() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        
        let picker = MPMediaPickerController(mediaTypes: .music)
        picker.allowsPickingMultipleItems = true
        picker.showsCloudItems = true
        picker.prompt = "Select songs to play"
        picker.delegate = self
        
        rootViewController.present(picker, animated: true)
    }
    
    func play() {
        musicPlayer.play()
    }
    
    func pause() {
        musicPlayer.pause()
    }
    
    func skipToNext() {
        musicPlayer.skipToNextItem()
    }
    
    func skipToPrevious() {
        musicPlayer.skipToPreviousItem()
    }
}

// MARK: - MPMediaPickerControllerDelegate
extension MusicManager: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        musicPlayer.setQueue(with: mediaItemCollection)
        musicPlayer.play()
        mediaPicker.dismiss(animated: true)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true)
    }
} 
