import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var model = WebViewModel()

    var body: some View {
        VStack(spacing: 0) {
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
              .ios-theme-controls { display:flex; gap:8px; align-items:center; justify-content:flex-end; margin-left:12px; }
              .ios-theme-controls button { border:0; border-radius:12px; padding:9px 12px; font-size:13px; font-weight:800; color:#ffffff; background:rgba(255,255,255,.18); box-shadow:inset 0 0 0 1px rgba(255,255,255,.2); }
              html.ios-dark, html.ios-dark body { background:#101a17 !important; color:#e6f0eb !important; }
              html.ios-dark body { color:#e6f0eb !important; }
              html.ios-dark body * { border-color:#2c443a !important; }
              html.ios-dark h1, html.ios-dark h2, html.ios-dark h3, html.ios-dark p, html.ios-dark label, html.ios-dark span, html.ios-dark div { color:#e6f0eb; }
              html.ios-dark .schedule-table { background:#172520 !important; }
              html.ios-dark .schedule-table th { background:#18382d !important; color:#d7f5e7 !important; }
              html.ios-dark .schedule-table td, html.ios-dark .schedule-table tr.staff-row td { background:#172520 !important; border-color:#2c443a !important; color:#e6f0eb !important; }
              html.ios-dark .schedule-table .staff-name { color:#f0fff7 !important; }
              html.ios-dark .schedule-table .staff-dept, html.ios-dark .schedule-table .ios-shift-caption { color:#85d9b7 !important; }
              html.ios-dark input, html.ios-dark select, html.ios-dark textarea { background:#172520 !important; color:#e6f0eb !important; border-color:#355448 !important; }
              html.ios-dark button, html.ios-dark .card, html.ios-dark .stat-card, html.ios-dark .summary-card { background:#172520 !important; color:#e6f0eb !important; border-color:#2c443a !important; }
              html.ios-dark .ios-theme-controls button { background:#246b53 !important; color:#ffffff !important; border-color:#4d8d74 !important; }
              html.ios-dark #departments > * { color:#e6f0eb !important; }
            }
          `;
          const style = document.createElement('style');
          style.id = 'lich-lam-ios-compact-style';
          style.textContent = css;
          (document.head || document.documentElement).appendChild(style);

          function normalizeDarkPalette() {
            if (!document.documentElement.classList.contains('ios-dark')) return;
            const isLight = (color) => {
              const m = (color || '').match(/rgba?\((\d+)[,\s]+(\d+)[,\s]+(\d+)/i);
              return !!m && Number(m[1]) > 235 && Number(m[2]) > 235 && Number(m[3]) > 235;
            };
            const isPale = (color) => {
              const m = (color || '').match(/rgba?\((\d+)[,\s]+(\d+)[,\s]+(\d+)/i);
              if (!m) return false;
              const r=Number(m[1]), g=Number(m[2]), b=Number(m[3]);
              return r > 205 && g > 215 && b > 205;
            };
            document.querySelectorAll('body *').forEach(el => {
              if (el.closest('.ios-theme-controls')) return;
              const tag = el.tagName;
              if (tag === 'SCRIPT' || tag === 'STYLE' || tag === 'OPTION') return;
              const cs = getComputedStyle(el);
              // Only recolor opaque, near-white surfaces, preserving shift badge colors.
              if (!el.classList.contains('shift-badge') &&
                  !el.classList.contains('ios-shift-caption') &&
                  isLight(cs.backgroundColor)) {
                el.style.setProperty('background-color', '#172520', 'important');
                if (cs.borderTopWidth !== '0px') el.style.setProperty('border-color', '#2c443a', 'important');
              }
              if (isPale(cs.color) && !el.classList.contains('shift-badge')) {
                el.style.setProperty('color', '#e6f0eb', 'important');
              }
            });
          }

          function installBannerControls() {
            normalizeDarkPalette();
            const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
            let node;
            while ((node = walker.nextNode())) {
              if ((node.nodeValue || '').includes('Dữ liệu sẵn sàng')) {
                const host = node.parentElement;
                if (!host || host.dataset.iosControlsInstalled) continue;
                host.dataset.iosControlsInstalled = '1';
                node.nodeValue = node.nodeValue.replace('Dữ liệu sẵn sàng', '');
                const controls = document.createElement('div');
                controls.className = 'ios-theme-controls';
                const reload = document.createElement('button');
                reload.type = 'button'; reload.textContent = '↻ Làm mới';
                reload.addEventListener('click', () => location.reload());
                const theme = document.createElement('button');
                theme.type = 'button';
                const updateThemeLabel = () => { theme.textContent = document.documentElement.classList.contains('ios-dark') ? '☀ Sáng' : '☾ Tối'; };
                theme.addEventListener('click', () => {
                  const dark = document.documentElement.classList.toggle('ios-dark');
                  try { localStorage.setItem('lichLamIOSTheme', dark ? 'dark' : 'light'); } catch(e) {}
                  updateThemeLabel();
                });
                try { if (localStorage.getItem('lichLamIOSTheme') === 'dark') document.documentElement.classList.add('ios-dark'); } catch(e) {}
                updateThemeLabel(); controls.appendChild(reload); controls.appendChild(theme);
                host.appendChild(controls);
                host.style.display = 'flex'; host.style.alignItems = 'center'; host.style.justifyContent = 'space-between'; host.style.gap = '10px';
              }
            }
          }
          function removeVisibleScriptText() {
            // Phòng trường hợp trang web vô tình render mã JavaScript thành nội dung văn bản.
            const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
            const badMarkers = ['const $=id=>document.getElementById', 'function shiftColor(', 'dayColumns.push(', 'function render(){ if(!dayColumns.length)'];
            const remove = [];
            let textNode;
            while ((textNode = walker.nextNode())) {
              const value = textNode.nodeValue || '';
              if (value.length > 500 && badMarkers.some(marker => value.includes(marker))) {
                const parent = textNode.parentElement;
                if (parent) remove.push(parent.closest('pre, code, script, .script-output, .code-output') || parent);
              }
            }
            [...new Set(remove)].forEach(el => {
              if (el && !el.closest('script, style')) el.remove();
            });
          }

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
            removeVisibleScriptText();
            compactTable();
            installBannerControls();
            const observer = new MutationObserver(() => { removeVisibleScriptText(); compactTable(); installBannerControls(); });
            observer.observe(document.body, { childList: true, subtree: true, characterData: true });
            setInterval(normalizeDarkPalette, 1000);
            document.addEventListener('change', () => setTimeout(() => { compactTable(); installBannerControls(); }, 100), true);
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
