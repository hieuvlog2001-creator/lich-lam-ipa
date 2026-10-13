import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var model = WebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Button {
                    model.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 38, height: 38)
                }
                .disabled(!model.canGoBack)
                .opacity(model.canGoBack ? 1 : 0.35)

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppConfig.appName)
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.07, green: 0.24, blue: 0.19))
                    Text(model.status)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    model.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 38, height: 38)
                }

                Button {
                    model.goHome()
                } label: {
                    Image(systemName: "house")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 38, height: 38)
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color(red: 0.07, green: 0.42, blue: 0.31))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.white)

            if model.isLoading {
                ProgressView(value: model.progress)
                    .tint(Color(red: 0.07, green: 0.42, blue: 0.31))
            }

            WebView(webView: model.webView)
                .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.white)
        .onAppear { model.loadIfNeeded() }
    }
}

final class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView
    @Published var isLoading = false
    @Published var progress = 0.0
    @Published var canGoBack = false
    @Published var status = "Đang kết nối…"
    private var observation: NSKeyValueObservation?
    private var didLoad = false

    override init() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] view, _ in
            DispatchQueue.main.async { self?.progress = view.estimatedProgress }
        }
    }

    func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true
        goHome()
    }

    func goHome() {
        webView.load(URLRequest(url: AppConfig.websiteURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30))
    }

    func reload() { webView.reload() }
    func goBack() { if webView.canGoBack { webView.goBack() } }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = true
            self.status = "Đang tải trang…"
            self.canGoBack = webView.canGoBack
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.status = webView.url?.host ?? "Đã kết nối"
            self.canGoBack = webView.canGoBack
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handle(error)
    }

    private func handle(_ error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.status = "Không kết nối được — nhấn tải lại"
            self.canGoBack = self.webView.canGoBack
        }
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
