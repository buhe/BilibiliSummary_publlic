//
//  Setting.swift
//  Share
//
//  Created by 顾艳华 on 2023/7/5.
//

import SwiftUI

struct Setting: View {
    
    static let shared = Setting()
    
    @State private var showingIAP = false
//    @AppStorage(wrappedValue: false, "iap") var iap: Bool
    // @AppStorage(wrappedValue: NSLocale.preferredLanguages.first!, "lang", store: UserDefaults.shared) var lang: String
    
//    @State var lang: String
    @AppStorage(wrappedValue: 10, "bili_tryout", store: UserDefaults.shared) var tryout: Int
    
//    init() {
//        if UserDefaults.shared.string(forKey: "lang_html") == nil {
//            UserDefaults.shared.set("en", forKey: "lang_html")
//        }
//        lang = UserDefaults.shared.string(forKey: "lang_html")!
////        print(lang)
//    }
    var body: some View {
        Form {
            HStack{
                Text("版本")
                Spacer()
                Text(Bundle.main.releaseVersionNumber!)
            }
            HStack{
                Text("许可证")
                Spacer()
                Text("GPLv3")
            }
            HStack {
                Text("试用次数")
                Spacer()
                Text("\(tryout)")
            }
            Button{
                if let url = URL(string: "itms-apps://itunes.apple.com/app/6455595076?action=write-review") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("喜欢")
            }
            Section {
                Button{
                   showingIAP = true
                } label: {
                    
                    Text("订阅")
                    
                }
            }
        }
        .sheet(isPresented: $showingIAP){
            ProView(scheme: false){
                showingIAP = false
            }
        }
    }
}

