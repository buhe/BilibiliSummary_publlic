//
//  ShareViewController.swift
//  ShareExt
//
//  Created by 顾艳华 on 2023/7/3.
//

import UIKit
import Social
import SwiftUI
import LangChain
import AsyncHTTPClient
import Foundation
import NIOPosix
import StoreKit
import CoreData

enum Cause {
    case NoSubtitle
    case Expired
    case Success
    case NotYoutube
}
struct VideoInfo {
    let title: String
    let summarize: String
    let description: String
    let thumbnail: String
    let url: String
    let successed: Bool
    let cause: Cause
    let id: String
}
@available(iOSApplicationExtension, unavailable)
class ShareViewController: UIViewController {
    var requested = false
    let persistenceController = PersistenceController.shared
    @AppStorage(wrappedValue: NSLocale.preferredLanguages.first!, "lang", store: UserDefaults.shared) var lang: String
    
    @AppStorage(wrappedValue: 10, "bili_tryout", store: UserDefaults.shared) var tryout: Int
//    let userDefaults = UserDefaults(suiteName: suiteName)
//    let semaphore = DispatchSemaphore(value: 0)
    var hasTry = false

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        print("lang: \(userDefaults?.object(forKey: "lang") ?? "")")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sui = SwiftUIView(close: {
            self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
        })
        // Do any additional setup after loading the view.
        let vc  = UIHostingController(rootView: sui)
        self.addChild(vc)
        self.view.addSubview(vc.view)
        vc.didMove(toParent: self)

        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.heightAnchor.constraint(equalTo: self.view.heightAnchor).isActive = true
        vc.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        vc.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
        vc.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        vc.view.backgroundColor = UIColor.clear
    
       
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if checkSubscriptionStatus() {
            for item in extensionContext!.inputItems as! [NSExtensionItem] {
                if let attachments = item.attachments {
                    for itemProvider in attachments {
                        if itemProvider.hasItemConformingToTypeIdentifier("public.plain-text") {
                            itemProvider.loadItem(forTypeIdentifier: "public.plain-text", options: nil, completionHandler: { (item, error) in
                                print("public.plain-text: \(item as! String)")
                            })
                        }
                                                  
                        
                        //
                        if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
                            itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (item, error) in
                                let url = item as! NSURL
                                if url.absoluteString!.contains("m.bilibili.com") {
                                    // do nothing
                                } else
                                // parse https://b23.tv/zbZADXc bilibili app
                                if url.absoluteString!.contains("b23"){
                                    if !self.requested {
                                        self.requested = true
                                        Task {
                                            await self.parseURL(url:  await BilibiliClient.getLongUrl(short: url.absoluteString!)!, callback: {
                                                await self.sum(video_id: $0)
                                            })
                                        }
                                    }
                                } else if url.absoluteString!.contains("www.bilibili.com") {
                                    // parse https://www.bilibili.com/video/BV1um4y1j7Sh/?spm_id_from=333.1007.tianma.1-1-1.click&vd_source=3823c0f6bad6220be4274277d1feb738 brower
                                    if !self.requested {
                                        self.requested = true
                                        Task {
                                            await self.parseURL(url:url.absoluteString!, callback: {
                                                await self.sum(video_id: $0)
                                            })
                                        }
                                    }
                                } else {
                                    let payload = VideoInfo(title: "", summarize: "", description: "", thumbnail: "", url: "", successed: false, cause: .NotYoutube, id: "")
                                    NotificationCenter.default.post(name: Notification.Name("Summarize"), object: payload)
                                }
                            })
                        }
                        
                        
                    }
                }
            }
        }
        else {
            let payload = VideoInfo(title: "", summarize: "", description: "", thumbnail: "", url: "", successed: false, cause: .Expired, id: "")
            NotificationCenter.default.post(name: Notification.Name("Summarize"), object: payload)
        }
    }
    func parseURL(url: String, callback: (_ id: String) async -> Void) async {
        let c = URLComponents(string: url)
        if var id = c?.path.replacingOccurrences(of: "/video/", with: "") {
            id = id.replacingOccurrences(of: "/", with: "")
            await callback(id)
        }
    }
//    func parseURL2(url: String, callback: (_ id: String) async -> Void) async {
//        let c = URLComponents(string: url)
//        if let queryItems = c?.queryItems {
//            for item in queryItems {
//                if item.name ==  "v" {
//                    let video_id = item.value!
//                    await callback(video_id)
//                }
//            }
//        }
//    }
    func sum(video_id: String) async {
        let p = """
以下是哔哩哔哩视频的字幕 : %@ , 请总结主要内容, 要求在100个字以内.
"""
        let loader = BilibiliLoader(videoId: video_id)
        let doc = await loader.load()
        if doc.isEmpty {
            let payload = VideoInfo(title: "", summarize: "", description: "", thumbnail: "", url: "", successed: false, cause: .NoSubtitle, id: "")
            NotificationCenter.default.post(name: Notification.Name("Summarize"), object: payload)
        } else {
            let prompt = PromptTemplate(input_variables: ["bilibili"], template: p)
            let request = prompt.format(args: [String(doc.first!.page_content.prefix(2000))])
            let llm = OpenAI()
            let reply = await llm.send(text: request)
            print(reply)
            
            let uuid = UUID()
            let uuidString = uuid.uuidString
            let payload = VideoInfo(title: doc.first!.metadata["title"]!, summarize: reply, description: doc.first!.metadata["desc"]!, thumbnail: doc.first!.metadata["thumbnail"]!, url: "https://www.bilibili.com/video/" + video_id, successed: true, cause: .Success,id: uuidString)
            if hasTry {
                tryout -= 1
                hasTry = false
            }
            NotificationCenter.default.post(name: Notification.Name("Summarize"), object: payload)
        }
    }

    func checkSubscriptionStatus() -> Bool {
        
        let semaphore = DispatchSemaphore(value: 0)
        let request = SKReceiptRefreshRequest()
//        request.delegate = self
        request.start()
        var vaild = true
        #if DEBUG
            print("Debug mode")
            let storeURL = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")
        #else
            print("Release mode")
            let storeURL = URL(string: "https://buy.itunes.apple.com/verifyReceipt")
        #endif
        print("store url: \(storeURL!.absoluteString)")
        
        if let receiptUrl = Bundle.main.appStoreReceiptURL {
            do {
                let receiptData = try Data(contentsOf: receiptUrl)
                let receiptString = receiptData.base64EncodedString(options: [])
                let requestContents = ["receipt-data": receiptString,
                                       "password": "ed573749d76d4651a04a3ce45a589509"]

                let requestData = try JSONSerialization.data(withJSONObject: requestContents,
                                                              options: [])
                
                var request = URLRequest(url: storeURL!)
                request.httpMethod = "POST"
                request.httpBody = requestData

                let session = URLSession.shared
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
                    if let data = data {
                        do {
                            if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                let receiptInfo = jsonResponse["latest_receipt_info"] as? [[String: Any]] {
                                let last = receiptInfo.first!
                                let expires = Int(last["expires_date_ms"] as! String)!
                                let now = Date()
                                
                                let utcMilliseconds = Int(now.timeIntervalSince1970 * 1000)
                                if utcMilliseconds > expires {
                                    // timeout
                                    vaild = false
                                }
                            }
                        } catch {
                            print("Pasre server error: \(error)")
                        }
                    }
                    
                    semaphore.signal()
                })
                task.resume()
            } catch {
                print("Can not load receipt：\(error), user not subscriptio.")
                vaild = false
                semaphore.signal()
            }
            
        } else {
            vaild = false
            semaphore.signal()
        }
        semaphore.wait()
        if !vaild {
            if tryout > 0 {
                hasTry = true
                return true
            } else {
                //
                
                UIApplication.shared.open(URL(string:"sum://")!)
                return false
            }
        } else {
            return true
        }
    }

}
struct SwiftUIView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State var title = "总结中..."
    @State var text = ""
    init(close: @escaping () -> Void) {
        self.close = close
//        NotificationCenter.default.addObserver(forName: NSNotification.Name("Summarize"), object: nil, queue: .main) { msg in
//            
//        }
    }
    let close: () -> Void
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(colorScheme == .light ? .white : .gray)
                .shadow(radius: 10)
            VStack {
                HStack {
                    Spacer()
                    Button {
                        close()
                    } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .font(.title)
                    .padding()
                }
                Text(title)
                    .bold()
                    .font(.title)
                    .padding(.horizontal)
                ScrollView {
                    Text(text)
                        .font(.title2)
                }
                .padding([.bottom,.horizontal])
                Spacer()
            
            }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Summarize"))) { msg in
            let payload = msg.object as! VideoInfo
            if payload.successed {
                text = payload.summarize
                title = payload.title
                addItem(payload: payload)
            } else {
                switch payload.cause {
                    case .NoSubtitle:
                        text = "视频没有字幕，摘要失败。"
                    case .Expired:
                        text = "您已超过试用次数，并且未订阅。"
                    case .NotYoutube:
                        text = "不是《哔哩哔哩》视频链接。"
                    default:
                    // not reachered
                        text = ""
                }
            }
        }
    }
    
    private func addItem(payload: VideoInfo) {
        let viewContext = PersistenceController.shared.container.viewContext
        // 创建一个NSFetchRequest对象来指定查询的实体
        let fetchRequest: NSFetchRequest<Bili> = Bili.fetchRequest()

        // 创建一个NSPredicate对象来定义查询条件
        let predicate = NSPredicate(format: "uuid == %@", payload.id)

        // 将NSPredicate对象赋值给fetchRequest的predicate属性
        fetchRequest.predicate = predicate

        // 指定任何其他所需的排序、限制或排序规则
        // fetchRequest.sortDescriptors = ...

        // 获取需要的ManagedObjectContext对象
//        let context = persistentContainer.viewContext

        do {
            // 执行查询并获取结果
            let results = try viewContext.fetch(fetchRequest)
            
//            // 处理查询结果
//            for result in results {
//                // 打印或对结果进行其他处理
//                print(result)
//            }
            
            if results.isEmpty {
                
                let newItem = Bili(context: viewContext)
                newItem.timestamp = Date()
                newItem.summary = payload.summarize
                newItem.title = payload.title
                newItem.url = payload.url
                newItem.desc = payload.description
                newItem.thumbnail = payload.thumbnail
                newItem.fav = false
                newItem.uuid = payload.id
                do {
                    try viewContext.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
        } catch {
            // 处理错误
            print("Error fetching data: \(error)")
        }
        
        
    }
}
