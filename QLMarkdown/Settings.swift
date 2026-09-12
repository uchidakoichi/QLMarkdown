//
//  Settings.swift
//  QLMarkdown
//
//  Created by Sbarex on 13/12/20.
//

import Foundation
import OSLog

enum CMARK_Error: Error {
    case parser_create
    case parser_parse
}

enum Appearance: Int, Codable {
    case undefined
    case light
    case dark
    
    var name: String {
        switch self {
        case .undefined:
            return "auto"
        case .light:
            return "light"
        case .dark:
            return "dark"
        }
    }
}

enum JSExtension: Codable {
    enum CodingKeys: String, CodingKey {
        case state
        case url
    }
    
    case disabled
    case embed(url: URL?)
    case link(url: URL?)
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let state = try container.decode(Int.self, forKey: .state)
        if state == 0 {
            self = .disabled
        } else {
            let url = try container.decode(URL?.self, forKey: .url)
            if state == 1 {
                self = .embed(url: url)
            } else {
                self = .link(url: url)
            }
        }
    }
    
    init?(from dict: [String: Any]) {
        guard let state = dict[Self.CodingKeys.state.rawValue] as? Int else {
            return nil
        }
        if state == 0 {
            self = .disabled
        } else {
            let url: URL?
            if dict.keys.contains(Self.CodingKeys.url.rawValue), let s = dict[Self.CodingKeys.url.rawValue] as? String, let u = URL(string: s) {
                url = u
            } else {
                url = nil
            }
            if state == 1 {
                self = .embed(url: url)
            } else {
                self = .link(url: url)
            }
        }
    }
    
    func toDict() -> [String: Any] {
        switch self {
        case .disabled:
            return [Self.CodingKeys.state.rawValue: 0]
        case .embed(let url):
            var r: [String: Any] = [Self.CodingKeys.state.rawValue: 1]
            if let url {
                r[Self.CodingKeys.url.rawValue] = url.absoluteString
            }
            return r
        case .link(let url):
            var r: [String: Any] = [Self.CodingKeys.state.rawValue: 2]
            if let url {
                r[Self.CodingKeys.url.rawValue] = url.absoluteString
            }
            return r
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .disabled:
            try container.encode(0, forKey: .state)
        case .embed(let url):
            try container.encode(1, forKey: .state)
            try container.encode(url, forKey: .url)
        case .link(let url):
            try container.encode(2, forKey: .state)
            try container.encode(url, forKey: .url)
        }
    }
    
    var isEnabled: Bool {
        return !self.isDisabled
    }
    
    var isDisabled: Bool {
        switch self {
        case .disabled:
            return true
        default:
            return false
        }
    }
    
    func getMode() -> (embed: Bool, url: URL?)?
    {
        switch self {
        case .disabled:
            return nil
        case .embed(let url):
            return (embed: true, url: url)
        case .link(let url):
            return (embed: false, url: url)
        }
    }
    
    /**
     * Sanitize the settings
     * - parameters:
     *   - cacheUrl: Path (local file or web uRL) of the library, from the cache folder or the main bundle.
     *   - cdnUrl: Web url from download the library. Tipically from a CDN service.
     *   - allowLinkFile: `true` allows you to link the library even if it is a local file and not a web URL.
     *
     * You can embed only exists local file. 
     */
    public mutating func sanitize(cacheUrl: URL?, cdnUrl: URL, allowLinkFile: Bool = false) {
        switch self {
        case .disabled:
            break
        case .link(let url):
            if let url = url ?? cacheUrl, allowLinkFile || !url.isFileURL {
                // Without `allowLinkFile`, only web url can be linked.
                // For link do not test if the file exists.
                self = .link(url: url)
            } else {
                // Link the CDN url.
                self = .link(url: cdnUrl)
            }
        case .embed(let url):
            if let url = url ?? cacheUrl {
                if url.isFileURL && FileManager.default.fileExists(atPath: url.path) {
                    // Only exists file can be embed.
                    self = .embed(url: url)
                } else if !url.isFileURL {
                    // Link a web url.
                    self = .link(url: cacheUrl)
                } else {
                    // Link the CDN url.
                    self = .link(url: cdnUrl)
                }
            } else {
                // Link the CDN url.
                self = .link(url: cdnUrl)
            }
        }
    }
    
    /**
     * Get the code to link/embed the JS library.
     * - parameters:
     *  - extraTagLink: Extra code to put in the `<script>` tag when the library is linked.
     *  - extraTagEmbed: Extra code to put in the `<script>` tag when the library is embedded.
     *
     * **Call `sanitize` before invokint this function.**
     */
    func getScriptCode(extraTagLink: String = "", extraTagEmbed: String = "") -> String {
        switch self {
        case .disabled:
            return ""
        case .link(let url):
            guard let url else {
                return ""
            }
            return "<script type='text/javascript' \(extraTagLink) src='\(url.absoluteString)'></script>\n"
        case .embed(let url):
            guard let url else {
                return ""
            }
            if let code = try? String(contentsOfFile: url.path, encoding: .utf8) {
                // Embed the libraty inline
                return "<script type='text/javascript' \(extraTagEmbed)>\n\(code)\n</script>\n"
            }
            return Self.link(url: url).getScriptCode(extraTagLink: extraTagLink, extraTagEmbed: extraTagEmbed)
        }
    }
}

enum YamlMode: Int, Codable {
    case disabled = 0
    case allFiles = 1
    case onlyRmd = 2
}

enum EmojiMode: Int, Codable {
    case disabled = 0
    case font = 1
    case images = 2
}

enum StrikethroughMode: Int, Codable {
    case disabled = 0
    case single = 1
    case double = 2
}

/// Color scheme applied to the Markdown elements of the rendered document.
enum MarkdownColorScheme: Int, Codable {
    /// Keep the colors defined by the current style.
    case `default` = 0
    /// Terminal like colors: each Markdown element (heading, emphasis, inline code, link, …)
    /// gets its own ANSI inspired color.
    case terminal = 1
}

enum OverrideMode: Int {
    case never = 0
    case always = 1
    case onlyOlder = 2
}

extension NSNotification.Name {
    public static let QLMarkdownSettingsUpdated: NSNotification.Name = NSNotification.Name("org.sbarex.qlmarkdown-settings-changed")
}

// MARK: -
class Settings: Codable {
    enum CodingKeys: String, CodingKey {
        case appearance
        case autoLinkExtension
        case checkboxExtension
        case headsExtension
        case hightlightExtension
        case inlineImageExtension
        case mathExtension
        case mermaidExtension
        case mentionExtension
        case subExtension
        case supExtension
        case tableExtension
        case tagFilterExtension
        case taskListExtension
        case yamlExtension
        case emojiExtension
        case strikethroughExtension
        case syntaxHighlightExtension
        case syntaxWordWrapOption
        case syntaxLineNumbersOption
        case syntaxTabsOption
        case footnotesOption
        case hardBreakOption
        case noSoftBreakOption
        case unsafeHTMLOption
        case smartQuotesOption
        case validateUTFOption
        case baseFontSize
        case baseFontFamily
        case syntaxFontFamily
        case syntaxFontSize
        case baseFontWeight
        case baseFontItalic
        case syntaxFontWeight
        case syntaxFontItalic
        case colorScheme
        case customCSS
        case customCSSCode
        case customCSSCodeFetched
        case customCSSOverride
        case openInlineLink
        case renderAsCode
        case qlWindowWidth
        case qlWindowHeight
        case debug
    }

    // MARK: - Static properties and methods
    
    /// Shared App Groups name.
    static let appGroup = "group.org.sbarex.qlmarkdown"
    
    /// Shared instance of the Settings.
    static let shared = {
        return Settings.settingsFromSharedFile() ?? Settings()
    }()
    
    static let factorySettings = Settings(noInitFromDefault: true)
    
    /// URL of the Application Bundle.
    static var appBundleUrl: URL?
    
    /**
     * Get the Bundle with the resources.
     * For the host app return the main Bundle. For the appex return the bundle of the hosting app.
     */
    static func getResourceBundle() -> Bundle {
        if let url = Settings.appBundleUrl, let appBundle = Bundle(url: url) {
            return appBundle
        } else if let url = Settings.appBundleUrl?.appendingPathComponent("Contents/Resources"), let appBundle = Bundle(url: url) {
            return appBundle
        } else if Bundle.main.bundlePath.hasSuffix(".appex") {
            // this is an app extension
            let url = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()

            if let appBundle = Bundle(url: url) {
                return appBundle
            } else if let appBundle = Bundle(identifier: "org.sbarex.QLMarkdown") {
                return appBundle
            }
            // To access the main bundle, the extension must not be sandboxed (or must have a security exception entitlement to access the entire disk).
            os_log(
                "Unable to open the main application bundle from %{public}@",
                log: OSLog.quickLookExtension,
                type: .error,
                url.path
            )
            if let appBundle = Bundle(url: Bundle.main.bundleURL.appendingPathComponent("Contents/Resources")) {
                return appBundle
            } else if let appBundle = Bundle(url: Bundle.main.bundleURL) {
                return appBundle
            }
        }
        
        return Bundle.main
    }
    
    static var isLightAppearance: Bool {
        get {
            return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light" == "Light"
        }
    }
    
    /// Home folder of the user, resolved outside of any sandbox container.
    ///
    /// `NSHomeDirectory()` returns the container of the process when it is sandboxed, but the app
    /// and its extensions must agree on a single location for the shared files, so the real home
    /// folder is read from the passwd database.
    static var realHomeUrl: URL {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }
    
    /// Preferences file shared by the app and its extensions.
    ///
    /// This is the file `UserDefaults(suiteName:)` writes for a not sandboxed process. The
    /// extensions are sandboxed and would be redirected to their own container, so they read this
    /// file directly (their sandbox grants a read only exception on the whole file system).
    static var sharedPreferencesUrl: URL {
        return Self.realHomeUrl
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingPathComponent("\(Self.appGroup).plist")
    }
    
    /// URL of the Application Support folder shared by the app and its extensions.
    ///
    /// The App Group container is deliberately not used: on recent macOS versions
    /// `~/Library/Group Containers` is TCC protected and `containerURL(forSecurityApplicationGroupIdentifier:)`
    /// is rejected unless the code signature carries the team identifier the group belongs to
    /// (`containermanagerd`: "Group containers identifiers should be prefixed by requestor's team ID").
    /// A build signed with any other identity is therefore asked for consent at every single launch.
    /// A plain Application Support folder is reachable by every target without any prompt.
    class var applicationSupportUrl: URL? {
        return Self.realHomeUrl
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("QLMarkdown")
    }
    
    /**
     * URL of the folder for the style sheets.
     * * SeeAlso
     * Settings.applicationSupportUrl
     */
    static var stylesFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("styles")
    }
    
    /**
     * URL of the folder for the js cached files.
     * * SeeAlso
     * Settings.applicationSupportUrl
     */
    static var jsFolder: URL? {
        return Settings.applicationSupportUrl?.appendingPathComponent("js")
    }
    
    /**
     * Init the settins from the shared App Groups.
     */
    static func settingsFromSharedFile() -> Settings? {
        var settings: Settings? = nil
        
        // Read the shared preferences file directly: a sandboxed extension asking
        // `UserDefaults(suiteName:)` for this domain would be redirected to its own container.
        if let dict = NSDictionary(contentsOf: Self.sharedPreferencesUrl) as? [String: Any], !dict.isEmpty {
            settings = Settings(defaults: dict)
        } else if let defaults = UserDefaults(suiteName: Self.appGroup) {
            settings = Settings(fromUserDefaults: defaults)
        }
        guard let settings else {
            return nil
        }
        
        settings.customCSSFetched = true
        settings.customCSSCode = nil
        
        if let url = settings.customCSS, url.lastPathComponent != "-" {
            do {
                let css = try String(contentsOf: url, encoding: .utf8)
                settings.customCSSCode = css
            } catch {
                os_log(
                    "Unable to fetch the CSS file %{public}@: %{public}@",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    url.path,
                    error.localizedDescription
                )
                settings.customCSSFetched = false
            }
            
            if let css = try? String(contentsOf: url, encoding: .utf8) {
                settings.customCSSCode = css
            } else {
                os_log(
                    "Unable to fetch the CSS file %{public}@!",
                    log: OSLog.quickLookExtension,
                    type: .error,
                    url.path
                )
                settings.customCSSFetched = false
            }
        } else {
            settings.customCSSCode = ""
        }
        
        return settings
    }
    
    // MARK: - Instance properties and methods
    
    var appearance: Appearance = .dark
    var autoLinkExtension: Bool = true
    var checkboxExtension: Bool = false
    var headsExtension: Bool = true
    var highlightExtension: Bool = true
    var inlineImageExtension: Bool = true
    var mathExtension: JSExtension = .link(url: nil)
    var mermaidExtension: JSExtension = .link(url: nil)
    var mentionExtension: Bool = true
    var subExtension: Bool = true
    var supExtension: Bool = true
    var tableExtension: Bool = true
    var tagFilterExtension: Bool = true
    var taskListExtension: Bool = true
    var yamlExtension: YamlMode = .onlyRmd
    var emojiExtension: EmojiMode = .font
    var strikethroughExtension: StrikethroughMode = .disabled
    var syntaxHighlightExtension: Bool = true
    var syntaxWordWrapOption: Int = 0
    var syntaxLineNumbersOption: Bool = false
    var syntaxTabsOption: Int = 4

    var footnotesOption: Bool = false
    var hardBreakOption: Bool = true
    var noSoftBreakOption: Bool = false
    /// Let the raw HTML of the Markdown source through.
    ///
    /// Required for `<img>` tags to be rendered at all: cmark replaces every raw HTML node with
    /// `<!-- raw HTML omitted -->` when it is disabled. The `tagFilterExtension` still strips the
    /// dangerous tags (`script`, `iframe`, `style`, …).
    var unsafeHTMLOption: Bool = true
    var smartQuotesOption: Bool = true
    var validateUTFOption: Bool = false
    
    var baseFontSize: CGFloat = 16
    /// Font family used to render the document body. Empty means the font defined by the current style.
    var baseFontFamily: String = "PlemolJP Console NF"
    /// Font family used to render code blocks and inline code. Empty means the font defined by the current style.
    var syntaxFontFamily: String = "PlemolJP Console NF"
    /// Font size (pt) used to render code blocks. Zero means the size defined by the current style.
    var syntaxFontSize: CGFloat = 18
    /// CSS weight (100…900) of the document font. Zero means the weight defined by the current style.
    var baseFontWeight: Int = 200
    /// Render the document text with the italic face of `baseFontFamily`.
    var baseFontItalic: Bool = false
    /// CSS weight (100…900) of the code font. Zero means the weight defined by the current style.
    var syntaxFontWeight: Int = 200
    /// Render the code with the italic face of `syntaxFontFamily`.
    var syntaxFontItalic: Bool = false
    /// Color scheme applied to the Markdown elements.
    var colorScheme: MarkdownColorScheme = .terminal
    var customCSS: URL? {
        didSet {
            customCSSFetched = false
            customCSSCode = nil
        }
    }
    var customCSSFetched: Bool = false
    var customCSSCode: String?
    var customCSSOverride: Bool = false
    
    var openInlineLink: Bool = false
    var renderAsCode: Bool = false

    /// Quick Look window width.
    var qlWindowWidth: Int? = 1000
    /// Quick Look window height.
    var qlWindowHeight: Int? = 5000
    /// Quick Look window size.
    var qlWindowSize: CGSize {
        if let w = qlWindowWidth, w > 0, let h = qlWindowHeight, h > 0 {
            return CGSize(width: CGFloat(w), height: CGFloat(h))
        } else {
            return CGSize(width: 0, height: 0)
        }
    }
    
    /// Show the informative message on the footer.
    
    /// Show debug infomations.
    var debug: Bool = false
    
    lazy fileprivate(set) var resourceBundle: Bundle = {
        return Self.getResourceBundle()
    }()
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.appearance = try container.decode(Appearance.self, forKey: .appearance)
        self.tableExtension = try container.decode(Bool.self, forKey: .tableExtension)
        self.autoLinkExtension = try container.decode(Bool.self, forKey:.autoLinkExtension)
        self.tagFilterExtension = try container.decode(Bool.self, forKey: .tagFilterExtension)
        self.taskListExtension = try container.decode(Bool.self, forKey: .taskListExtension)
        
        self.yamlExtension = try container.decode(YamlMode.self, forKey: .yamlExtension)
    
        self.strikethroughExtension = try container.decode(StrikethroughMode.self, forKey:.strikethroughExtension)
        
        self.mathExtension = try container.decode(JSExtension.self, forKey:.mathExtension)
        self.mermaidExtension = try container.decode(JSExtension.self, forKey:.mermaidExtension)
        
        self.mentionExtension = try container.decode(Bool.self, forKey:.mentionExtension)
        self.checkboxExtension = try container.decode(Bool.self, forKey:.checkboxExtension)
        self.headsExtension = try container.decode(Bool.self, forKey:.headsExtension)
        self.highlightExtension = try container.decode(Bool.self, forKey: .hightlightExtension)
       
        self.syntaxHighlightExtension = try container.decode(Bool.self, forKey: .syntaxHighlightExtension)
        self.syntaxWordWrapOption = try container.decode(Int.self, forKey: .syntaxWordWrapOption)
        self.syntaxLineNumbersOption = try container.decode(Bool.self, forKey: .syntaxLineNumbersOption)
        self.syntaxTabsOption = try container.decode(Int.self, forKey: .syntaxTabsOption)
        
        self.subExtension = try container.decode(Bool.self, forKey:.subExtension)
        self.supExtension = try container.decode(Bool.self, forKey:.supExtension)
        
        self.emojiExtension = try container.decode(EmojiMode.self, forKey:.emojiExtension)
        
        self.inlineImageExtension = try container.decode(Bool.self, forKey:.inlineImageExtension)
        
        self.hardBreakOption = try container.decode(Bool.self, forKey: .hardBreakOption)
        self.noSoftBreakOption = try container.decode(Bool.self, forKey: .noSoftBreakOption)
        self.unsafeHTMLOption = try container.decode(Bool.self, forKey: .unsafeHTMLOption)
        self.validateUTFOption = try container.decode(Bool.self, forKey: .validateUTFOption)
        self.smartQuotesOption = try container.decode(Bool.self, forKey: .smartQuotesOption)
        self.footnotesOption = try container.decode(Bool.self, forKey: .footnotesOption)
        
        self.baseFontSize = try container.decode(CGFloat.self, forKey: .baseFontSize)
        self.baseFontFamily = try container.decodeIfPresent(String.self, forKey: .baseFontFamily) ?? ""
        self.syntaxFontFamily = try container.decodeIfPresent(String.self, forKey: .syntaxFontFamily) ?? ""
        self.syntaxFontSize = try container.decodeIfPresent(CGFloat.self, forKey: .syntaxFontSize) ?? 0
        self.baseFontWeight = try container.decodeIfPresent(Int.self, forKey: .baseFontWeight) ?? 0
        self.baseFontItalic = try container.decodeIfPresent(Bool.self, forKey: .baseFontItalic) ?? false
        self.syntaxFontWeight = try container.decodeIfPresent(Int.self, forKey: .syntaxFontWeight) ?? 0
        self.syntaxFontItalic = try container.decodeIfPresent(Bool.self, forKey: .syntaxFontItalic) ?? false
        self.colorScheme = try container.decodeIfPresent(MarkdownColorScheme.self, forKey: .colorScheme) ?? .default
        self.customCSS = try container.decode(URL?.self, forKey: .customCSS)
        self.customCSSFetched = try container.decode(Bool.self, forKey: .customCSSCodeFetched)
        self.customCSSCode = try container.decode(String?.self, forKey: .customCSSCode)
        self.customCSSOverride = try container.decode(Bool.self, forKey: .customCSSOverride)
        
        self.debug = try container.decode(Bool.self, forKey: .debug)
        
        self.openInlineLink = try container.decode(Bool.self, forKey: .openInlineLink)
        self.renderAsCode = try container.decode(Bool.self, forKey: .renderAsCode)

        self.qlWindowWidth = try container.decode(Int?.self, forKey: .qlWindowWidth)
        self.qlWindowHeight = try container.decode(Int?.self, forKey: .qlWindowHeight)
    }
    
    init() { }
    
    init(defaults defaultsDomain: [String: Any]) {
        self.update(from: defaultsDomain)
    }
    
    convenience init(fromUserDefaults defaults: UserDefaults) {
        self.init()
        update(from: defaults.dictionaryRepresentation())
    }
    
    private init(noInitFromDefault: Bool = false) {
        if !noInitFromDefault {
            self.initFromDefaults()
        }
    }

    deinit {
        stopMonitorChange()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(self.appearance, forKey: .appearance)
        try container.encode(self.tableExtension, forKey: .tableExtension)
        try container.encode(self.autoLinkExtension, forKey: .autoLinkExtension)
        try container.encode(self.tagFilterExtension, forKey: .tagFilterExtension)
        try container.encode(self.taskListExtension, forKey: .taskListExtension)
    
        try container.encode(self.yamlExtension, forKey: .yamlExtension)
    
        try container.encode(self.strikethroughExtension, forKey: .strikethroughExtension)
        
        try container.encode(self.mathExtension, forKey: .mathExtension)
        try container.encode(self.mermaidExtension, forKey: .mermaidExtension)
        
        try container.encode(self.mentionExtension, forKey: .mentionExtension)
        try container.encode(self.checkboxExtension, forKey: .checkboxExtension)
        try container.encode(self.headsExtension, forKey: .headsExtension)
        try container.encode(self.highlightExtension, forKey: .hightlightExtension)
        
        try container.encode(self.syntaxHighlightExtension, forKey: .syntaxHighlightExtension)
        try container.encode(self.syntaxWordWrapOption, forKey: .syntaxWordWrapOption)
        try container.encode(self.syntaxLineNumbersOption, forKey: .syntaxLineNumbersOption)
        try container.encode(self.syntaxTabsOption, forKey: .syntaxTabsOption)
        
        try container.encode(self.subExtension, forKey: .subExtension)
        try container.encode(self.supExtension, forKey: .supExtension)
        
        try container.encode(self.emojiExtension, forKey: .emojiExtension)
        
        try container.encode(self.inlineImageExtension, forKey: .inlineImageExtension)
    
        try container.encode(self.hardBreakOption, forKey: .hardBreakOption)
        try container.encode(self.noSoftBreakOption, forKey: .noSoftBreakOption)
        try container.encode(self.unsafeHTMLOption, forKey: .unsafeHTMLOption)
        try container.encode(self.validateUTFOption, forKey: .validateUTFOption)
        try container.encode(self.smartQuotesOption, forKey: .smartQuotesOption)
        try container.encode(self.footnotesOption, forKey: .footnotesOption)
        
        try container.encode(self.baseFontSize, forKey: .baseFontSize)
        try container.encode(self.baseFontFamily, forKey: .baseFontFamily)
        try container.encode(self.syntaxFontFamily, forKey: .syntaxFontFamily)
        try container.encode(self.syntaxFontSize, forKey: .syntaxFontSize)
        try container.encode(self.baseFontWeight, forKey: .baseFontWeight)
        try container.encode(self.baseFontItalic, forKey: .baseFontItalic)
        try container.encode(self.syntaxFontWeight, forKey: .syntaxFontWeight)
        try container.encode(self.syntaxFontItalic, forKey: .syntaxFontItalic)
        try container.encode(self.colorScheme, forKey: .colorScheme)
        try container.encode(self.customCSS, forKey: .customCSS)
        try container.encode(self.customCSSCode, forKey: .customCSSCode)
        try container.encode(self.customCSSFetched, forKey: .customCSSCodeFetched)
        try container.encode(self.customCSSOverride, forKey: .customCSSOverride)
        
        try container.encode(self.debug, forKey: .debug)
    
        try container.encode(self.openInlineLink, forKey: .openInlineLink)
        try container.encode(self.renderAsCode, forKey: .renderAsCode)

        try container.encode(self.qlWindowWidth, forKey: .qlWindowWidth)
        try container.encode(self.qlWindowHeight, forKey: .qlWindowHeight)
    }
    
    func initFromDefaults() {
        if let s = Settings.settingsFromSharedFile() {
            update(from: s)
        }
    }
    
    private(set) var isMonitoring = false
    /**
     * Monitors settings changes by other processes.
     */
    func startMonitorChange() {
        guard !isMonitoring else {
            return
        }
        isMonitoring = true
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.handleSettingsChanged(_:)), name: .QLMarkdownSettingsUpdated, object: nil)
    }
    /**
     * Suspend the settings changes monitor.
     */
    func stopMonitorChange() {
        if isMonitoring {
            DistributedNotificationCenter.default().removeObserver(self)
            isMonitoring = false
        }
    }
    
    /**
     * Reloads settings after they have been changed by another process.
     */
    @objc func handleSettingsChanged(_ notification: NSNotification) {
        // print("settings changed")
        self.initFromDefaults()
    }
    
    /**
     * Update settings based on other settings provided.
     */
    func update(from s: Settings) {
        self.appearance = s.appearance
        
        self.tableExtension = s.tableExtension
        self.autoLinkExtension = s.autoLinkExtension
        self.tagFilterExtension = s.tagFilterExtension
        self.taskListExtension = s.taskListExtension
        
        self.yamlExtension = s.yamlExtension
        
        self.strikethroughExtension = s.strikethroughExtension
        
        self.mathExtension = s.mathExtension
        self.mermaidExtension = s.mermaidExtension
        self.mentionExtension = s.mentionExtension
        self.checkboxExtension = s.checkboxExtension
        self.headsExtension = s.headsExtension
        
        self.highlightExtension = s.highlightExtension
        
        self.syntaxHighlightExtension = s.syntaxHighlightExtension
        self.syntaxWordWrapOption = s.syntaxWordWrapOption
        self.syntaxLineNumbersOption = s.syntaxLineNumbersOption
        self.syntaxTabsOption = s.syntaxTabsOption
        
        self.subExtension = s.subExtension
        self.supExtension = s.supExtension
        
        self.emojiExtension = s.emojiExtension
        
        self.inlineImageExtension = s.inlineImageExtension
        
        self.hardBreakOption = s.hardBreakOption
        self.noSoftBreakOption = s.noSoftBreakOption
        self.unsafeHTMLOption = s.unsafeHTMLOption
        self.validateUTFOption = s.validateUTFOption
        self.smartQuotesOption = s.smartQuotesOption
        self.footnotesOption = s.footnotesOption
        
        self.baseFontSize = s.baseFontSize
        self.baseFontFamily = s.baseFontFamily
        self.syntaxFontFamily = s.syntaxFontFamily
        self.syntaxFontSize = s.syntaxFontSize
        self.baseFontWeight = s.baseFontWeight
        self.baseFontItalic = s.baseFontItalic
        self.syntaxFontWeight = s.syntaxFontWeight
        self.syntaxFontItalic = s.syntaxFontItalic
        self.colorScheme = s.colorScheme
        self.customCSS = s.customCSS
        self.customCSSCode = s.customCSSCode
        self.customCSSFetched = s.customCSSFetched
        self.customCSSOverride = s.customCSSOverride
        
        self.debug = s.debug
        
        self.openInlineLink = s.openInlineLink
        
        self.renderAsCode = s.renderAsCode
        
        self.qlWindowWidth = s.qlWindowWidth
        self.qlWindowHeight = s.qlWindowHeight
    }
    
    /**
     * Update settings based on other settings provided from a UserDefaults dictionary.
     */
    func update(from defaultsDomain: [String: Any]) {
        if let n = defaultsDomain[Self.CodingKeys.appearance.rawValue] as? Int, let state = Appearance(rawValue: n) {
            appearance = state
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.tableExtension.rawValue] as? Bool {
            tableExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.autoLinkExtension.rawValue] as? Bool {
            autoLinkExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.tagFilterExtension.rawValue] as? Bool {
            tagFilterExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.taskListExtension.rawValue] as? Bool {
            taskListExtension = ext
        }
        if let n = defaultsDomain[Self.CodingKeys.yamlExtension.rawValue] as? Int, let ext = YamlMode(rawValue: n) {
            yamlExtension = ext
        }
        
        if let n = defaultsDomain[Self.CodingKeys.strikethroughExtension.rawValue] as? Int, let ext = StrikethroughMode(rawValue: n) {
            strikethroughExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.mathExtension.rawValue] as? [String: Any] {
            mathExtension = JSExtension(from: ext) ?? .disabled
        }
        if let ext = defaultsDomain[Self.CodingKeys.mermaidExtension.rawValue] as? [String: Any] {
            mermaidExtension = JSExtension(from: ext) ?? .disabled
        }
        if let ext = defaultsDomain[Self.CodingKeys.mentionExtension.rawValue] as? Bool {
            mentionExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.checkboxExtension.rawValue] as? Bool {
            checkboxExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.headsExtension.rawValue] as? Bool {
            headsExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.hightlightExtension.rawValue] as? Bool {
            highlightExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.syntaxHighlightExtension.rawValue] as? Bool {
            syntaxHighlightExtension = ext
        }
        
        if let characters = defaultsDomain[Self.CodingKeys.syntaxWordWrapOption.rawValue] as? Int {
            syntaxWordWrapOption = characters
        }
        if let state = defaultsDomain[Self.CodingKeys.syntaxLineNumbersOption.rawValue] as? Bool {
            syntaxLineNumbersOption = state
        }
        if let n = defaultsDomain[Self.CodingKeys.syntaxTabsOption.rawValue] as? Int {
            syntaxTabsOption = n
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.subExtension.rawValue] as? Bool {
            subExtension = ext
        }
        if let ext = defaultsDomain[Self.CodingKeys.subExtension.rawValue] as? Bool {
            supExtension = ext
        }
        
        if let n = defaultsDomain[Self.CodingKeys.emojiExtension.rawValue] as? Int, let ext = EmojiMode(rawValue: n) {
            emojiExtension = ext
        }
        
        if let ext = defaultsDomain[Self.CodingKeys.inlineImageExtension.rawValue] as? Bool {
            inlineImageExtension = ext
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.hardBreakOption.rawValue] as? Bool {
            hardBreakOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.noSoftBreakOption.rawValue] as? Bool {
            noSoftBreakOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.unsafeHTMLOption.rawValue] as? Bool {
            unsafeHTMLOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.validateUTFOption.rawValue] as? Bool {
            validateUTFOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.smartQuotesOption.rawValue] as? Bool {
            smartQuotesOption = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.footnotesOption.rawValue] as? Bool {
            footnotesOption = opt
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.baseFontSize.rawValue] as? CGFloat {
            baseFontSize = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.baseFontFamily.rawValue] as? String {
            baseFontFamily = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.syntaxFontFamily.rawValue] as? String {
            syntaxFontFamily = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.syntaxFontSize.rawValue] as? CGFloat {
            syntaxFontSize = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.baseFontWeight.rawValue] as? Int {
            baseFontWeight = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.baseFontItalic.rawValue] as? Bool {
            baseFontItalic = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.syntaxFontWeight.rawValue] as? Int {
            syntaxFontWeight = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.syntaxFontItalic.rawValue] as? Bool {
            syntaxFontItalic = opt
        }
        if let n = defaultsDomain[Self.CodingKeys.colorScheme.rawValue] as? Int, let scheme = MarkdownColorScheme(rawValue: n) {
            colorScheme = scheme
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.customCSS.rawValue] as? String, !opt.isEmpty {
            if !opt.hasPrefix("/"), let path = Settings.stylesFolder{
                customCSS = path.appendingPathComponent(opt)
            } else {
                customCSS = URL(fileURLWithPath: opt)
            }
        }
        if let opt = defaultsDomain[Self.CodingKeys.customCSSOverride.rawValue] as? Bool {
            customCSSOverride = opt
        }
        
        
        if let opt = defaultsDomain[Self.CodingKeys.debug.rawValue] as? Bool {
            debug = opt
        }
        
        if let opt = defaultsDomain[Self.CodingKeys.openInlineLink.rawValue] as? Bool {
            openInlineLink = opt
        }
        if let opt = defaultsDomain[Self.CodingKeys.renderAsCode.rawValue] as? Bool {
            renderAsCode = opt
        }
        // Only override the default when the key is stored: an absent key must keep the factory
        // value, a stored zero means "auto".
        if let opt = defaultsDomain[Self.CodingKeys.qlWindowWidth.rawValue] as? Int {
            qlWindowWidth = opt > 0 ? opt : nil
        }
        if let opt = defaultsDomain[Self.CodingKeys.qlWindowHeight.rawValue] as? Int {
            qlWindowHeight = opt > 0 ? opt : nil
        }

        sanitize()
    }
    
    /**
     * Reset the settings to the factory values.
     */
    func resetToFactory() {
        let s = Settings()
        update(from: s)
    }
    
    func sanitize(allowLinkFile: Bool = false) {
        var messages: [String] = []
        sanitize(allowLinkFile: allowLinkFile, messages: &messages)
        messages.forEach({ print($0) })
    }
    
    /**
     * Sanitize the settings.
     * - parameters:
     *   - allowLinkFile: allow to link local file for the JSExtension properties
     *   - messages: Filled with a list of error messages.
     */
    func sanitize(allowLinkFile: Bool = false, messages: inout [String]) {
        messages = []
        
        if baseFontSize < 0 {
            self.baseFontSize = 0
        }
        if syntaxFontSize < 0 {
            self.syntaxFontSize = 0
        }
        if baseFontWeight < 0 || baseFontWeight > 1000 {
            self.baseFontWeight = 0
        }
        if syntaxFontWeight < 0 || syntaxFontWeight > 1000 {
            self.syntaxFontWeight = 0
        }
        self.baseFontFamily = self.baseFontFamily.trimmingCharacters(in: .whitespacesAndNewlines)
        self.syntaxFontFamily = self.syntaxFontFamily.trimmingCharacters(in: .whitespacesAndNewlines)
        
        self.mathExtension.sanitize(cacheUrl: mathJaxFileUrl, cdnUrl: Self.mathJaxWebUrl, allowLinkFile: allowLinkFile)
        self.mermaidExtension.sanitize(cacheUrl: mermaidFileUrl, cdnUrl: Self.mermaidWebUrl, allowLinkFile: allowLinkFile)
        
        if self.subExtension && self.strikethroughExtension == .single {
            messages.append("The Sub extension is incompatibile with the Strikethrough extension when recognize a single tile (~).")
        }
        
        if self.supExtension && self.footnotesOption {
            messages.append("The Sup extension can cause corrupted output when the Footnotes option is set.")
        }
    }
    
    /**
     * Get the contents of a file insie dhe Reource Bundle.
     *  - parameters:
     *    - name: Name of the resource.
     *    - ext: Extension of the resource
     */
    func getBundleContents(forResource name: String, ofType ext: String) -> String? {
        if let p = self.resourceBundle.path(forResource: name, ofType: ext), let data = FileManager.default.contents(atPath: p), let s = String(data: data, encoding: .utf8) {
            return s
        } else {
            return nil
        }
    }
    
    /**
     * Get the custom CSS code
     */
    func getCustomCSSCode() -> String? {
        guard let url = self.customCSS, url.lastPathComponent != "-" else {
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }
    
    /**
     * Install the dependencies files.
     *
     * This function create the support folders and copy from the bundle, if available, the mermaid and mathjax libraries.
     * Then copy the support files of highlight.
     */
    func installDependencies(override: OverrideMode = .never) {
        try? installDep(forResource: "mermaid.min", withExtension: "js", to: Self.mermaidCacheFileUrl, overwrite: override)
        try? installDep(forResource: "tex-mml-chtml", withExtension: "js", to: Self.mathJaxCacheFileUrl, overwrite: override)
        
        try? installDep(forResource: "highlight", withExtension: nil, to: Settings.syntaxHighlightSupportCacheUrl, overwrite: override)
    }
    
    private func installDep(forResource name: String, withExtension ext: String?, to destination: URL?, overwrite: OverrideMode) throws {
        guard let source = self.resourceBundle.url(forResource: name, withExtension: ext) else {
            os_log(
                "Unable to store cache the file/folder %{public}s: source is missing on the app bundle!",
                log: OSLog.quickLookExtension,
                type: .error,
                "\(name)\(ext != nil ? "." + ext! : "")"
            )
            return
        }
        
        do {
            try installDep(from: source, to: destination, overwrite: overwrite)
        } catch {
            os_log(
                "Unable to store cache the file/folder %{public}s to %{public}s: %{public}s!",
                log: OSLog.quickLookExtension,
                type: .error,
                "\(name)\(ext != nil ? "." + ext! : "")",
                destination?.path ?? "N/D",
                error.localizedDescription
            )
            throw error
        }
    }
    
    private func installDep(from source: URL?, to destination: URL?, overwrite: OverrideMode) throws {
        guard let source, let destination else {
            return
        }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        
        let exists = fileManager.fileExists(atPath: destination.path, isDirectory: &isDirectory)
        guard overwrite != .never || !exists else {
            return
        }
        guard overwrite != .always else {
            if exists {
                // Remove original file/folder
                try fileManager.removeItem(at: destination)
            }
            let folder = destination.deletingLastPathComponent()
            
            if !fileManager.fileExists(atPath: folder.path) {
                // Create the destination folder
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            }
            
            try fileManager.copyItem(atPath: source.path, toPath: destination.path)
            return
        }
        
        if isDirectory.boolValue {
            if !fileManager.fileExists(atPath: destination.path) {
                // Create the destination folder
                try fileManager.createDirectory(
                    at: destination,
                    withIntermediateDirectories: true
                )
            }
            
            let contents = try fileManager.contentsOfDirectory(
                at: source,
                includingPropertiesForKeys: nil
            )
            
            for item in contents {
                let target = destination.appendingPathComponent(
                    item.lastPathComponent
                )
                
                try installDep(
                    from: item,
                    to: target,
                    overwrite: overwrite
                )
            }
        } else {
            if exists && overwrite == .onlyOlder {
                let srcValues = try source.resourceValues(
                    forKeys: [.contentModificationDateKey]
                )
                
                let dstValues = try destination.resourceValues(
                    forKeys: [.contentModificationDateKey]
                )
                
                let srcDate = srcValues.contentModificationDate ?? .distantPast
                let dstDate = dstValues.contentModificationDate ?? .distantPast
                
                guard srcDate > dstDate else {
                    // The destination file is newer than the original.
                    return
                }
            }
            
            if exists {
                try fileManager.removeItem(at: destination)
            }
            let folder = destination.deletingLastPathComponent()
            
            if !fileManager.fileExists(atPath: folder.path) {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
            }
            
            try fileManager.copyItem(atPath: source.path, toPath: destination.path)
        }
    }
    
    /**
     * Download and cache a fiile from web.
     * - parameters:
     *   - source: Source url.
     *   - destination: Destination path
     *   - reply: Action to perform after the download.
     */
    static func fetchCacheFile(from source: URL, to destination: URL, withReply reply: ((Bool) -> Void)?) {
        let cacheFolderUrl = destination.deletingLastPathComponent()
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: cacheFolderUrl.path) {
            do {
                try FileManager.default.createDirectory(at: cacheFolderUrl, withIntermediateDirectories: true, attributes: nil)
            } catch {
                reply?(false)
                return
            }
        }
        
        let task = URLSession.shared.downloadTask(with: source) { tempURL, response, error in
            if let error = error {
                print("Unable to fetch \(source.absoluteString):", error)
                os_log("Unable to fetch %{public}s", log: OSLog.rendering, type: .error, source.absoluteString)
                reply?(false)
                return
            }
            
            guard let tempURL = tempURL else {
                print("No file downloaded")
                os_log("No file downloaded from %{public}s", log: OSLog.rendering, type: .error, source.absoluteString)
                reply?(false)
                return
            }
            
            do {
                // Rimuove se esiste già
                if fileManager.fileExists(atPath: destination.path) {
                    try fileManager.removeItem(at: destination)
                }
                
                // Sposta il file temporaneo
                try fileManager.moveItem(at: tempURL, to: destination)
                
                // print("File seved in:", mermaidCacheFileUrl)
                reply?(true)
            } catch {
                print("Error storing file on \(destination.path):", error)
                os_log("Error storing mermaid file on %{public}s: %{public}s", log: OSLog.rendering, type: .error, destination.path, error.localizedDescription)
                reply?(false)
            }
        }
        
        task.resume()
    }
    
}

// MARK: - Mermaid support
extension Settings {
    /// Url from which to download the mermaid library.
    static let mermaidWebUrl = URL(string: "https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js")!
    
    /// Local file with the mermaid library.
    static var mermaidCacheFileUrl: URL? {
        return Self.jsFolder?.appendingPathComponent("mermaid.min.js")
    }
    
    /// Location of the mermaid library. Can be from the file cache or from the bundle.
    var mermaidFileUrl: URL? {
        return Self.mermaidCacheFileUrl ?? self.resourceBundle.url(forResource: "mermaid.min", withExtension: "js")
    }
}

// MARK: - MathJax
extension Settings {
    /// Url from which to download the mermaid library.
    static let mathJaxWebUrl = URL(string: "https://cdn.jsdelivr.net/npm/mathjax/es5/tex-mml-chtml.js")!
    
    /// Cache of the mermaid library.
    static var mathJaxCacheFileUrl: URL? {
        return Self.jsFolder?.appendingPathComponent("tex-mml-chtml.js")
    }
    
    /// Location of the mermaid library. Can be from the file cache or from the bundle.
    var mathJaxFileUrl: URL? {
        return Self.mathJaxCacheFileUrl ?? self.resourceBundle.url(forResource: "tex-mml-chtml", withExtension: "js")
    }
}

// MARK: - Syntax highlight
extension Settings {
    /// Url from which to download the `highlight` support files.
    static var syntaxHighlightSupportCacheUrl: URL? {
        return Self.applicationSupportUrl?.appendingPathComponent("highlight")
    }
    
    /// Get the path of folder with `highlight` support files.
    func getHighlightSupportPath() -> String? {
        if let cache = Self.syntaxHighlightSupportCacheUrl, FileManager.default.fileExists(atPath: cache.path) {
            return cache.path
        }
        
        return self.resourceBundle.url(forResource: "highlight", withExtension: "")?.path
    }
}
