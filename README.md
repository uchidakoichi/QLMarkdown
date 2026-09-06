<p align="center">
  <img src="assets/img/icon.png" width="150" alt="logo" />
</p>

# QLMarkdown (fork)

[sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) の個人用フォークです。Markdown ファイルの Quick Look プレビュー、設定用の GUI、コマンドラインツール、Shortcut 拡張を提供します。

機能そのものの説明（対応拡張子、Markdown の拡張機能、テーマ、CLI の使い方など）は本家のドキュメントをそのまま残してあります → [README.upstream.md](README.upstream.md)

このファイルには**本家との差分**だけを書いています。

> このアプリケーションは Markdown エディタ／ビューアの代替を目指したものではありません。
> また、本ソフトウェアは無保証で提供されます。

## 本家との違い

### 1. フォントを設定できる

設定画面に **Base font**（本文）と **Code font**（コードブロック・インラインコード）の行を追加しました。ボタンを押すと macOS 標準のフォントパネルが開き、インストール済みの任意のフォントを選べます。

- **ファミリ・サイズに加えてウェイトとイタリックも反映されます。** ウェイトは OpenType の `OS/2` テーブルの `usWeightClass` から取得します。これは定義上 CSS の `font-weight` と同じ尺度なので、パネルで選んだ face がそのまま選び戻されます（`NSFontDescriptor` のウェイト特性は粗く、Thin / ExtraLight / Light が同じ値になるため使っていません）
- 「Reset」でスタイル既定に戻ります
- 生成される CSS は本家同梱の `default.css` の**後**、シンタックスハイライトとユーザーのカスタム CSS の**前**に挿入されます。つまり既定スタイルより優先され、カスタム CSS では上書きできます

> [!NOTE]
> カスタム CSS で `font-family` や `font-weight` を指定していると、そちらが後から適用されるためアプリ側のフォント設定は効きません。

### 2. Markdown 要素ごとのターミナル風配色

設定画面の **Colors** で `Terminal` を選ぶと、Markdown の要素ごとに ANSI 風の色が割り当てられます（One Light / One Dark 系のパレット、ライト・ダーク両対応）。

| 要素 | ライト | ダーク |
|---|---|---|
| `# 見出し1` | `#0184bc` | `#56b6c2` |
| `## 〜 ######` | `#4078f2` | `#61afef` |
| `**強調**` | `#383a42` | `#ffffff` |
| `*斜体*` | `#986801` | `#e5c07b` |
| `` `インラインコード` `` | `#986801` | `#d19a66` |
| `[リンク]()` | `#4078f2` + 下線 | `#61afef` + 下線 |
| `> 引用` | `#50a14f` | `#98c379` |
| リストのマーカー | `#a626a4` | `#c678dd` |
| `~~打ち消し~~` / `---` | グレー | グレー |
| テーブルのヘッダ | `#0184bc` | `#56b6c2` |

コードブロックは対象外で、既存のシンタックスハイライトがそのまま効きます。

### 3. Quick Look から開くファイル以外の情報を排除

- レンダリング結果末尾のフッター（アプリ名・バージョン・著作権表示・寄付リンク）を削除
- 出力 HTML に埋め込まれていた `<!-- File generated with QLMarkdown ... -->` コメントを削除
- **100 ファイルごとに Quick Look 画面へ挿入されていた宣伝ブロック**（アイコン＋閲覧ファイル数＋寄付リンク＋開発者クレジット）と、そのためのレンダリング回数カウンタを削除
- 設定画面ツールバーの寄付ボタン、アプリメニューの項目、About ウィンドウのボタン、CLI が表示していた同様のメッセージを削除
- 上記に伴い不要になった「Show about info」スイッチと `about` 設定も削除

### 4. App Group を使わない

本家は設定と補助ファイルを App Group コンテナ（`~/Library/Group Containers/group.org.sbarex.qlmarkdown`）に置いています。しかし macOS ではこの領域が TCC 保護対象で、**署名に Team ID が無いビルドはアクセスを拒否され、起動のたびに「ほかのアプリからのデータへのアクセス権を求めています」というダイアログが出ます**（許可しても永続化されません）。

```
containermanagerd: [org.sbarex.QLMarkdown] requesting [group.org.sbarex.qlmarkdown]: REJECTED.
Requestor's signature does not allow it to access a TCC-protected group container.
Group containers identifiers should be prefixed by requestor's team ID
```

そこで保存先を変更しました。

| 用途 | 本家 | このフォーク |
|---|---|---|
| テーマ・highlight・js キャッシュ | App Group コンテナ | `~/Library/Application Support/QLMarkdown` |
| 設定 | App Group の preferences | `~/Library/Preferences/group.org.sbarex.qlmarkdown.plist` |

アプリ（非サンドボックス）が `UserDefaults` 経由で書き、サンドボックス下の拡張機能は自分のコンテナへリダイレクトされないよう**このファイルを直接読みます**。パスは `getpwuid` で実ホームを解決するため、サンドボックスの有無に関わらず同じ場所を指します。両方の `.entitlements` から `com.apple.security.application-groups` を削除しています。

### 5. 既定値の変更

配布時の初期値を変更しています（設定ファイルが無いときに使われる値）。

| 設定 | 本家 | このフォーク |
|---|---|---|
| Appearance | Auto | Dark |
| Base font size | 自動 | 16 pt |
| Base / Code font | 未指定 | PlemolJP Console NF ExtraLight (weight 200) |
| Code font size | 自動 | 18 pt |
| Colors | Default | Terminal |
| Footnotes | on | off |
| Hard break | off | on |
| Raw HTML (unsafe) | on | off |
| Strikethrough | single tilde | 無効 |
| Highlight (`==`) | off | on |
| GitHub mention | off | on |
| Sub / Superscript | off | on |
| Preferred Quick Look size | Auto | 固定 1000 × 5000 px |

既定フォントの [PlemolJP Console NF](https://github.com/yuru7/PlemolJP) が入っていない環境では、CSS のフォールバック（本文は `-apple-system`、コードは `ui-monospace` / Menlo）で表示されます。

### 6. 不具合修正

- **フォントパネルでウェイトを選んでも反映されない** — 選択された face からファミリ名しか取り出しておらず、`font-weight` / `font-style` を出力していませんでした
- **フォントパネルの候補がすべてグレーアウトして選べない** — パネルを開く前に `NSViewController` へ `makeFirstResponder` していたため、`acceptsFirstResponder` が `false` の同コントローラは受け取れず、ファーストレスポンダがウィンドウに戻ってレスポンダチェーンから外れ、`NSFontPanel` が `changeFont(_:)` の処理先を見つけられずパネル全体を無効化していました。あわせて `AppDelegate` を `NSFontChanging` に準拠させ、フォーカス位置に依存しないようにしています
- **フォントパネルが画面の隅に開く** — 初回表示時に設定ウィンドウの中央へ配置するようにしました
- **Preferred Quick Look size が復元されない** — `update(from:)` が未保存のキーに対して値を `nil` で上書きしていたため、保存した固定サイズも既定値も反映されませんでした
- 設定のリロード時にフォント関連の設定が UI へ反映されていなかった点を修正

### 7. CLI のオプション追加

```
--base-font-family <font name>   本文のフォントファミリ
--base-font-weight <number>      本文の CSS ウェイト (100…900)
--base-font-italic <on|off>      本文にイタリック face を使う
--code-font-family <font name>   コードのフォントファミリ
--code-font-size <number>        コードのフォントサイズ (pt)
--code-font-weight <number>      コードの CSS ウェイト (100…900)
--code-font-italic <on|off>      コードにイタリック face を使う
--color-scheme <default|terminal> Markdown 要素の配色
```

削除したオプション: `--about`

## ビルド

```sh
git clone https://github.com/uchidakoichi/QLMarkdown.git
cd QLMarkdown
git submodule update --init
```

ビルドには以下が必要です。

```sh
brew install autoconf automake libtool cmake
```

`cmake` は `cmark-gfm` の、`autoconf` / `automake` / `libtool` は `libpcre2` のビルドに使います。

```sh
xcodebuild -scheme QLMarkdown -configuration Release \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -jobs 1 build
```

> [!TIP]
> 外部ビルドツールを使うターゲット（`libpcre2`、`libjpcre2`、`highlight-wrapper`、`cmark-headers`）を並列でビルドすると `Internal inconsistency error: never received target ended message` で失敗することがあります。`-jobs 1` を付けてください。

## インストール

Apple の署名証明書が無い環境では、ビルド成果物をそのままコピーしても **Quick Look 拡張が未署名扱いになり PlugInKit に登録されません**。ad-hoc 署名を内側のバイナリから順に付け直す必要があります。

- アプリ本体はエンタイトルメントなし（非サンドボックス）で署名します。設定と補助ファイルをホームディレクトリ配下に読み書きするためです
- 拡張機能はサンドボックスを維持したまま署名します。サンドボックスが無いと Quick Look 拡張として登録されません

```sh
DERIVED=$(xcodebuild -scheme QLMarkdown -configuration Release -showBuildSettings 2>/dev/null \
  | awk -F' = ' '/ BUILT_PRODUCTS_DIR/ {print $2}')
APP=/Applications/QLMarkdown.app

osascript -e 'tell application "QLMarkdown" to quit' 2>/dev/null
rm -rf "$APP" && ditto "$DERIVED/QLMarkdown.app" "$APP"

sign() { codesign --force --sign - --timestamp=none "$@"; }
sign "$APP/Contents/Frameworks/libswift_Concurrency.dylib"
sign "$APP/Contents/Frameworks/libwrapper_highlight.dylib"
sign "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc"
sign "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc"
sign "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app"
sign "$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
sign "$APP/Contents/PlugIns/Markdown QL Extension.appex/Contents/XPCServices/external-launcher.xpc"
sign --identifier org.sbarex.QLMarkdown.QLExtension \
     --entitlements QLExtension/QLExtension.entitlements \
     "$APP/Contents/PlugIns/Markdown QL Extension.appex"
sign --entitlements QLExtension/QLExtension.entitlements \
     "$APP/Contents/Extensions/QLMarkdown Shortcut Extension.appex"
sign --identifier org.sbarex.QLMarkdown "$APP"

codesign -v --deep --strict "$APP"   # 出力が無ければ OK
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
open -a "$APP"
```

登録されたか確認するには:

```sh
pluginkit -mAvvv | grep -A2 org.sbarex.QLMarkdown
```

`+ org.sbarex.QLMarkdown.QLExtension` と表示されれば有効です。プレビューが出ない場合はシステム設定 →「一般」→「ログイン項目と機能拡張」→「Quick Look」で有効になっているか確認してください。

> [!WARNING]
> **Sparkle の自動アップデートは使わないでください。** 署名が一致せず失敗するか、本家のリリース版で上書きされてこのフォークの変更がすべて失われます。

> [!NOTE]
> ad-hoc 署名は再ビルドのたびに署名 ID が変わります。TCC の許可ダイアログが出た場合は再ビルドが原因です。

## ライセンス・クレジット

本家と同じく [GPLv3](LICENSE.txt) です。

- 本家: [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) — SBAREX
- 使用ライブラリ: [cmark-gfm](https://github.com/github/cmark-gfm), [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php), [PCRE2](https://github.com/PhilipHazel/pcre2), [JPCRE2](https://github.com/jpcre2/jpcre2), [MathJax](https://www.mathjax.org/), [Mermaid](https://mermaid.js.org/), [Sparkle](https://sparkle-project.org/), [Yams](https://github.com/jpsim/Yams), [SwiftSoup](https://github.com/scinfu/SwiftSoup), [swift-argument-parser](https://github.com/apple/swift-argument-parser)
- 既定フォント: [PlemolJP](https://github.com/yuru7/PlemolJP)
