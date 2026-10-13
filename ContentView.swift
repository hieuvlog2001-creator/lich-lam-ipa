import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var model = WebViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.48, blue: 0.34),
                                    Color(red: 0.04, green: 0.32, blue: 0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 40, height: 40)
                .shadow(color: Color(red: 0.04, green: 0.32, blue: 0.25).opacity(0.18), radius: 5, y: 3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppConfig.appName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.08, green: 0.20, blue: 0.16))
                    HStack(spacing: 5) {
                        Circle()
                            .fill(model.isLoading ? Color.orange : Color(red: 0.08, green: 0.61, blue: 0.42))
                            .frame(width: 6, height: 6)
                        Text(model.isLoading ? "Đang cập nhật lịch" : "Lịch nhân sự")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(red: 0.39, green: 0.48, blue: 0.44))
                    }
                }

                Spacer(minLength: 8)

                Button {
                    model.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 0.07, green: 0.40, blue: 0.30))
                        .frame(width: 40, height: 40)
                        .background(Color(red: 0.91, green: 0.96, blue: 0.93))
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color(red: 0.82, green: 0.90, blue: 0.85), lineWidth: 0.8)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Tải lại lịch")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 10)
            .background(
                LinearGradient(
                    colors: [Color.white, Color(red: 0.97, green: 0.99, blue: 0.98)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(red: 0.88, green: 0.92, blue: 0.89))
                    .frame(height: 0.7)
            }

            if model.isLoading {
                ProgressView(value: model.progress)
                    .tint(Color(red: 0.07, green: 0.42, blue: 0.31))
            }

            WebView(webView: model.webView)
                .background(Color(red: 0.95, green: 0.97, blue: 0.96))
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

        // Chỉ tinh chỉnh cách trình bày trong app iOS; website và dữ liệu gốc không bị sửa.
        let mobileScheduleScript = """
        (function () {
          if (window.__lichLamIOSCompactInstalled) return;
          window.__lichLamIOSCompactInstalled = true;

          const css = `
            @media screen {
              body { background: #f3f7f5 !important; }
              .schedule-table {
                width: 100% !important;
                min-width: 0 !important;
                table-layout: fixed !important;
                border-collapse: separate !important;
                border-spacing: 0 !important;
                font-size: 13px !important;
              }
              .schedule-table th,
              .schedule-table td {
                box-sizing: border-box !important;
                padding: 10px 8px !important;
                overflow-wrap: anywhere !important;
                vertical-align: middle !important;
              }
              .schedule-table th:nth-child(1),
              .schedule-table td:nth-child(1) { width: 13% !important; text-align: center !important; }
              .schedule-table th:nth-child(2),
              .schedule-table td:nth-child(2) { width: 52% !important; }
              .schedule-table th:nth-child(3),
              .schedule-table td:nth-child(3),
              .schedule-table th:nth-child(5),
              .schedule-table td:nth-child(5) { display: none !important; }
              .schedule-table th:nth-child(4),
              .schedule-table td:nth-child(4) { width: 35% !important; }
              .schedule-table thead th {
                position: sticky !important;
                top: 0 !important;
                z-index: 3 !important;
                background: #e8f3ed !important;
                color: #155b45 !important;
                font-size: 11px !important;
                font-weight: 800 !important;
                line-height: 1.25 !important;
              }
              .schedule-table .shift-group-row td { padding: 9px 10px !important; }
              .schedule-table .shift-group-label { display: flex !important; align-items: center !important; gap: 7px !important; }
              .schedule-table .shift-group-count { margin-left: auto !important; font-size: 11px !important; white-space: nowrap !important; }
              .schedule-table .staff-name { font-size: 13px !important; line-height: 1.3 !important; font-weight: 800 !important; color: #16362c !important; }
              .schedule-table .staff-dept { margin-top: 3px !important; font-size: 11px !important; line-height: 1.25 !important; color: #0c8061 !important; font-weight: 600 !important; }
              .schedule-table .shift-badge { display: inline-flex !important; align-items: center !important; justify-content: center !important; min-width: 38px !important; border-radius: 9px !important; padding: 6px 7px !important; font-size: 13px !important; font-weight: 800 !important; white-space: nowrap !important; }
              .schedule-table .ios-shift-caption { display: block !important; margin-top: 4px !important; font-size: 10px !important; line-height: 1.15 !important; color: #657a71 !important; font-weight: 600 !important; text-align: center !important; white-space: normal !important; }
              .schedule-table .ios-shift-wrap { display: flex !important; flex-direction: column !important; align-items: center !important; justify-content: center !important; }
              #departments { overflow-x: hidden !important; }
              .schedule-table tr.staff-row td { height: auto !important; }
              .schedule-table tr.staff-row:nth-child(even) td { background-color: #fbfdfc; }
            }
          `;
          const style = document.createElement('style');
          style.id = 'lich-lam-ios-compact-style';
          style.textContent = css;
          (document.head || document.documentElement).appendChild(style);

          function shiftCaption(code) {
            const c = (code || '').trim().toUpperCase();
            if (/^M\\d*/.test(c)) return 'Ca sáng';
            if (/^A\\d*/.test(c)) return 'Ca chiều';
            if (/^N\\d*/.test(c)) return 'Ca đêm';
            if (c === 'OFF') return 'Ngày nghỉ';
            if (c === 'CL') return 'Nghỉ bù lễ';
            if (c === 'AL') return 'Nghỉ phép năm';
            if (c === 'PH') return 'Lễ tết';
            if (c === 'ARR') return 'Check-In';
            if (c === 'DEP') return 'Check-out';
            if (c === 'OCC') return 'Tổng công suất';
            return '';
          }

          function compactTable() {
            const table = document.querySelector('#departments table.schedule-table');
            if (!table) return;
            const headers = table.querySelectorAll('thead th');
            if (headers.length >= 5) {
              headers[2].setAttribute('aria-hidden', 'true');
              headers[4].setAttribute('aria-hidden', 'true');
            }
            table.querySelectorAll('tr.shift-group-row td').forEach(td => { td.colSpan = 3; });
            table.querySelectorAll('tr.staff-row').forEach(row => {
              const cells = row.children;
              if (cells.length >= 5) {
                // Bảng nguồn: STT | Họ và tên | Vị trí | Ca làm | Trạng thái.
                // CSS ẩn Vị trí và Trạng thái để app chỉ còn 3 cột.
                const shiftCell = cells[3];
                const badge = shiftCell && shiftCell.querySelector('.shift-badge');
                if (badge && !badge.dataset.iosEnhanced) {
                  badge.dataset.iosEnhanced = '1';
                  const wrap = document.createElement('div');
                  wrap.className = 'ios-shift-wrap';
                  badge.parentNode.insertBefore(wrap, badge);
                  wrap.appendChild(badge);
                  const caption = document.createElement('span');
                  caption.className = 'ios-shift-caption';
                  caption.textContent = shiftCaption(badge.textContent);
                  wrap.appendChild(caption);
                }
              }
            });
          }

          const install = () => {
            const root = document.getElementById('departments');
            if (!root) { setTimeout(install, 250); return; }
            compactTable();
            const observer = new MutationObserver(() => compactTable());
            observer.observe(root, { childList: true, subtree: true });
            document.addEventListener('change', () => setTimeout(compactTable, 100), true);
          };
          if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', install);
          else install();
        })();
        """
        let userScript = WKUserScript(source: mobileScheduleScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)

        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init()
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = UIColor(red: 0.95, green: 0.97, blue: 0.96, alpha: 1)
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
