import SwiftUI
import MusicKit

struct CurrentSongView: View {
    let song: Song
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 16) {
                // Album Artwork - larger than the nearby items
                if let artworkURL = song.artworkURL {
                    AsyncImage(url: artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: min(geometry.size.width * 0.3, 120), height: min(geometry.size.width * 0.3, 120))
                    .cornerRadius(8)
                } else {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: min(geometry.size.width * 0.3, 120), height: min(geometry.size.width * 0.3, 120))
                        .cornerRadius(8)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        )
                }
                
                // Song Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(song.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(song.artist)
                        .font(.body)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .layoutPriority(1)
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .frame(height: 140)
    }
}

struct NearbyListItemView: View {
    let song: Song
    
    var body: some View {
        HStack(spacing: 12) {
            if let artworkURL = song.artworkURL {
                AsyncImage(url: artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .foregroundColor(.gray.opacity(0.3))
                }
                .frame(idealWidth: 50, maxWidth: 50, idealHeight: 50, maxHeight: 50)
                .cornerRadius(4)
            } else {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(idealWidth: 50, maxWidth: 50, idealHeight: 50, maxHeight: 50)
                    .cornerRadius(4)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
} 