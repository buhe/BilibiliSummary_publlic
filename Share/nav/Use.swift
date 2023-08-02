//
//  Use.swift
//  Share
//
//  Created by 顾艳华 on 2023/7/14.
//

import SwiftUI
import AVKit

struct Use: View {
    let screenWidth = UIScreen.main.bounds.width
    let next: () -> Void
    var player = AVPlayer(url:  Bundle.main.url(forResource: "use", withExtension: "mp4")!)
    var body: some View {
        VStack {
            Text("""
            如何总结哔哩哔哩视频
            """)
                .font(.title)
                .bold()
                .padding()
            Text("""
您可以使用摘要的共享扩展直接从《哔哩哔哩》应用程序打开摘要。
""")
            .padding()
            VideoPlayer(player: player)
                .frame(width: screenWidth / 2, height: screenWidth)
                .padding()
                .onAppear() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                        player.play()
                    })
                    
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
                                          player.seek(to: .zero)
                                          player.play()
                                      }
                }
            Button{
                next()
            }label: {
                Text("完成")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct UsePreviews: PreviewProvider {
    static var previews: some View {
        Use{}
    }
}
