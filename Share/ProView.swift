//
//  ProView.swift
//  FinanceDashboard
//
//  Created by 顾艳华 on 2023/1/22.
//

import SwiftUI
import SwiftUIX
import StoreKit

struct ProView: View {
    let title: String = "哔哩哔哩视频总结"
  
    @ObservedObject var viewModel: IAPViewModel = IAPViewModel.shared
    
    @ObservedObject var iap: IAPManager = IAPManager.shared
    
    @State var text = ""
    
    let close: () -> Void
    
    init(scheme: Bool,  close: @escaping () -> Void){
        if scheme {
            SKPaymentQueue.default().add(IAPManager.shared)
            IAPManager.shared.getProducts()
            text = "您的试用次数已经用完了。"
        }
        self.close = close
    }
    var body: some View {
        if viewModel.loading {
            ActivityIndicator()
        } else {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title)
                    .bold()
                    .padding()
                
                HStack{
                    Image(systemName: "infinity")
                    VStack(alignment: .leading){
                        Text("无限制摘要")
                            .bold()
                        Text("总结《哔哩哔哩》视频内容，没有时长或次数限制。")
                    }
                }
                .padding()
                HStack{
                    Image(systemName: "square.and.arrow.up.fill").padding(.trailing, 8)
                    VStack(alignment: .leading){
                        Text("分享摘要")
                            .bold()
                        Text("分享摘要和原始视频的链接。")
                    }
                }
                .padding()
                Text("""
包括无限次数的摘要，无限的字符，自定义设置和分享。
订阅自动续订每个月18元，直到您取消。
""")
                .padding()
                Text(text)
                    .padding()
                    .bold()
                    .italic()
                
                Text("EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
                    .padding(.horizontal)
                Text("隐私策略: https://github.com/buhe/HtmlSummary/blob/main/PrivacyPolicy.md")
                    .padding(.horizontal)
                HStack{
                    Button{
                        IAPViewModel.shared.loading = true
                        IAPManager.shared.buy(product: IAPManager.shared.products.first!)
                        
                    }label: {
                        Text("订阅")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(iap.products.isEmpty)
                    .padding(.horizontal)
                    Button{
                        IAPViewModel.shared.loading = true
                        IAPManager.shared.restore()
                    }label: {
                        Text("恢复")
                    }
                }
                Spacer()
            }
            .padding(.top, 100)
        }
    }
}

struct ProView_Previews: PreviewProvider {
    static var previews: some View {
        ProView(scheme: true){}
    }
}
