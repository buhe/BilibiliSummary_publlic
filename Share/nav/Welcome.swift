//
//  Welcome.swift
//  Share
//
//  Created by 顾艳华 on 2023/7/14.
//

import SwiftUI

struct Welcome: View {
    let next: () -> Void
    @AppStorage(wrappedValue: 10, "html_tryout", store: UserDefaults.shared) var tryout: Int
    var body: some View {
        VStack {
            Text("欢迎来到哔哩哔哩 AI 总结")
                .font(.title)
                .bold()
                .padding()
            VStack(alignment: .leading){
                Text("""
利用先进的AI技术提供简洁准确的哔哩哔哩的视频摘要，帮助您轻松提取关键见解。

""")
                Text("你有 \(tryout) 次试用!")
                    
            }.padding()
            Button{
                next()
            }label: {
                Text("继续")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(.top, 100)
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        Welcome{}
    }
}
