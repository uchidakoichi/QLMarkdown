<p align="center">
  <img src="assets/img/icon.png" width="150" alt="logo" />
</p>

# QLMarkdown (fork)

[sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) の個人用フォークです。Markdown ファイルの Quick Look プレビュー、設定用の GUI、コマンドラインツール、Shortcut 拡張を提供します。

機能そのものの説明（対応拡張子、Markdown の拡張機能、テーマ、CLI の使い方など）は本家のドキュメントをそのまま残してあります → [README.upstream.md](README.upstream.md)

このファイルには**本家との差分**だけを書いています。

**[ビルド済みアプリをダウンロード](https://github.com/uchidakoichi/QLMarkdown/releases/latest)** — インストール方法は [インストール](#インストール) を参照してください。

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

### 3. `<img>` タグの画像を表示する

Markdown の `![](...)` 記法だけでなく、HTML の `<img src="...">` で指定した画像も表示されます。`width` などの属性がそのまま効くので、Markdown 記法では指定できない表示サイズを指定できます。

```markdown
<img src="images/screenshot.png" width="400"/>
```

Quick Look のプレビューはベース URL を持たない HTML 文字列としてレンダリングされるため、`src` が相対パスのままでは Web ビューが解決できません。そこでローカルファイルを指す `src` は `data:` URI に埋め込みます（「Inline local images」が有効なとき）。対応する形式:

| `src` の書き方 | 例 |
|---|---|
| 相対パス（`./` 付きも可） | `img/a.png`、`./a.png`、`sub/dir/a.png` |
| パーセントエンコード | `my%20image.png` |
| 絶対パス | `/Users/me/Pictures/a.png` |
| `file://` URL | `file:///Users/me/Pictures/a.png` |

`http(s)://` と `data:` の `src` はそのまま Web ビューに任せます。段落中のインライン記述、シングルクォート、属性の順序、大文字の `<IMG>` にも対応します。

> [!IMPORTANT]
> `<img>` が描画されるには **Raw HTML（Inline HTML (unsafe)）が有効** である必要があります。cmark は raw HTML を無効にすると HTML ノードをすべて `<!-- raw HTML omitted -->` に置き換えるため、`<img>` だけを通すことはできません。このフォークでは既定で有効にしています。
>
> Raw HTML を有効にすると、`<script>` `<iframe>` `<style>` などの危険なタグは Tag filter 拡張がエスケープしますが、**`onerror=` のようなインラインのイベントハンドラは通ります**。信頼できない Markdown ファイルをプレビューする可能性がある場合は、設定画面で「Inline HTML (unsafe)」をオフにしてください（その場合 `<img>` も表示されなくなります）。

### 4. Quick Look から開くファイル以外の情報を排除

- レンダリング結果末尾のフッター（アプリ名・バージョン・著作権表示・寄付リンク）を削除
- 出力 HTML に埋め込まれていた `<!-- File generated with QLMarkdown ... -->` コメントを削除
- **100 ファイルごとに Quick Look 画面へ挿入されていた宣伝ブロック**（アイコン＋閲覧ファイル数＋寄付リンク＋開発者クレジット）と、そのためのレンダリング回数カウンタを削除
- 設定画面ツールバーの寄付ボタン、アプリメニューの項目、About ウィンドウのボタン、CLI が表示していた同様のメッセージを削除
- 上記に伴い不要になった「Show about info」スイッチと `about` 設定も削除

### 5. App Group を使わない

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

### 6. 既定値の変更

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
| Raw HTML (unsafe) | on | on（`<img>` の描画に必要） |
| Strikethrough | single tilde | 無効 |
| Highlight (`==`) | off | on |
| GitHub mention | off | on |
| Sub / Superscript | off | on |
| Preferred Quick Look size | Auto | 固定 1000 × 5000 px |

既定フォントの [PlemolJP Console NF](https://github.com/yuru7/PlemolJP) が入っていない環境では、CSS のフォールバック（本文は `-apple-system`、コードは `ui-monospace` / Menlo）で表示されます。

### 7. 不具合修正

- **フォントパネルでウェイトを選んでも反映されない** — 選択された face からファミリ名しか取り出しておらず、`font-weight` / `font-style` を出力していませんでした
- **フォントパネルの候補がすべてグレーアウトして選べない** — パネルを開く前に `NSViewController` へ `makeFirstResponder` していたため、`acceptsFirstResponder` が `false` の同コントローラは受け取れず、ファーストレスポンダがウィンドウに戻ってレスポンダチェーンから外れ、`NSFontPanel` が `changeFont(_:)` の処理先を見つけられずパネル全体を無効化していました。あわせて `AppDelegate` を `NSFontChanging` に準拠させ、フォーカス位置に依存しないようにしています
- **フォントパネルが画面の隅に開く** — 初回表示時に設定ウィンドウの中央へ配置するようにしました
- **Preferred Quick Look size が復元されない** — `update(from:)` が未保存のキーに対して値を `nil` で上書きしていたため、保存した固定サイズも既定値も反映されませんでした
- **スキップ対象言語のコードブロックがエスケープされない** — シンタックスハイライト拡張は `mermaid` / `math` / `markdown` を処理対象外にしていますが、その分岐でコード本文を無escapeで出力していたため、```markdown フェンスに書いた `<img>` や `<b>` が**実際のタグとして解釈されていました**。cmark 本体と同じく `houdini_escape_html0` でエスケープするよう修正しています（mermaid と math はクライアント側ライブラリが要素のテキストを読むため、ブラウザがエンティティを復元して従来どおり動作します）
- 設定のリロード時にフォント関連の設定が UI へ反映されていなかった点を修正

### 8. CLI のオプション追加

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

## インストール

方法は 2 つあります。**特に理由がなければ A** をおすすめします。

| | 所要時間 | 必要なもの |
|---|---|---|
| **A. ビルド済みアプリを使う** | 5 分ほど | ダウンロードとターミナルのコマンド 1 行 |
| **B. ソースからビルドする** | 初回 30 分〜1 時間 | Xcode、Homebrew |

**ターミナルの開き方**: `command + スペース` で Spotlight を開き、`ターミナル` と入力して Enter。以下のコマンドは 1 行ずつコピーして貼り付け、Enter を押してください。

## 方法 A: ビルド済みアプリを使う

### A-1: ダウンロードして `/Applications` に入れる

1. [Releases ページ](https://github.com/uchidakoichi/QLMarkdown/releases/latest) を開きます
2. **Assets** から `QLMarkdown-X.Y.Z-fork.N.zip` をダウンロードします
   - 現在の最新は [`QLMarkdown-1.5.2-fork.1.zip`](https://github.com/uchidakoichi/QLMarkdown/releases/download/v1.5.2-fork.1/QLMarkdown-1.5.2-fork.1.zip)（約 24 MB）です
3. zip をダブルクリックして展開し、出てきた **QLMarkdown.app** を `/Applications`（アプリケーションフォルダ）にドラッグします

### A-2: 隔離属性を外す（ここが重要）

このアプリは Apple の開発者証明書で署名・公証されていません（ad-hoc 署名です）。そのままでは macOS がインターネットからダウンロードしたファイルとしてブロックし、**「開発元を検証できないため開けません」** や **「"QLMarkdown.app" は壊れているため開けません」** と表示されます。

ターミナルで次の 1 行を実行してください。

```sh
xattr -dr com.apple.quarantine /Applications/QLMarkdown.app
```

何も表示されなければ成功です。

> [!NOTE]
> これは「ダウンロード済みファイル」の印を外すコマンドです。ソースはこのリポジトリで全て公開されているので、中身が気になる場合は方法 B で自分でビルドしてください。

### A-3: 起動して Quick Look を有効にする

```sh
open -a /Applications/QLMarkdown.app
```

**一度起動する**ことで macOS が Quick Look 拡張を認識します。そのうえで、システム設定 →「一般」→「ログイン項目と機能拡張」→ 一番下の「Quick Look」で **QLMarkdown** にチェックが入っていることを確認してください。

プレビューが出ない場合は、次を実行してから Finder を再起動してみてください。

```sh
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/QLMarkdown.app
killall Finder
```

### A-4: フォントを入れる（任意・推奨）

既定フォントの PlemolJP Console NF は [後述の手順 3](#手順-3-フォント-plemoljp-console-nf-をインストールする) でインストールできます。入れなくても動きますが、入れると既定の設定どおりの見た目になります。

インストールできたら [動作確認](#動作確認) へ進んでください。

## 方法 B: ソースからビルドする

ターミナルを使ったことがなくても進められるよう、順番に説明します。所要時間は初回で 30 分〜1 時間程度（うち大半は Xcode のインストールとビルドの待ち時間）です。

### 手順 1: Xcode をインストールする

App Store から [Xcode](https://apps.apple.com/jp/app/xcode/id497799835) をインストールします（十数 GB あるので時間がかかります）。

インストールが終わったら **一度 Xcode を起動して**、利用規約への同意と追加コンポーネントのインストールを済ませてください。その後、ターミナルで次を実行します。

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

`sudo` を使うので Mac のログインパスワードを聞かれます（入力しても画面には何も表示されませんが、そのまま打って Enter で大丈夫です）。

確認:

```sh
xcodebuild -version
```

`Xcode 26.6` のようにバージョンが表示されれば OK です。`xcode-select: error: tool 'xcodebuild' requires Xcode` と出る場合は上の `xcode-select` をやり直してください。

### 手順 2: Homebrew と必要なツールをインストールする

[Homebrew](https://brew.sh/index_ja) は macOS 用のパッケージ管理ツールです。未導入なら次を実行します（画面の指示に従ってください）。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

続いてビルドに必要なツールを入れます。

```sh
brew install autoconf automake libtool cmake
```

`cmake` は Markdown パーサ（cmark-gfm）の、`autoconf` / `automake` / `libtool` は正規表現ライブラリ（libpcre2）のビルドに使います。

### 手順 3: フォント PlemolJP Console NF をインストールする

このフォークは本文・コードの既定フォントに **PlemolJP Console NF** を使います。日本語対応のプログラミング用フォントで、8 種類のウェイトを持っているのでウェイト指定の機能をそのまま活かせます。

1. [PlemolJP のリリースページ](https://github.com/yuru7/PlemolJP/releases/latest) を開きます
2. **Assets** の中から **`PlemolJP_NF_vX.Y.Z.zip`**（`NF` = Nerd Fonts 版、アイコン用の文字が入っています）をダウンロードします
   - 執筆時点の最新は [`PlemolJP_NF_v3.1.0.zip`](https://github.com/yuru7/PlemolJP/releases/download/v3.1.0/PlemolJP_NF_v3.1.0.zip) です
   - `HS` は全角スペースを可視化しない版、無印は Nerd Fonts なしの版です。どれでも動きますが、以下は `NF` 版を前提に説明します
3. ダウンロードした zip をダブルクリックして展開します
4. 展開されたフォルダの中から、ファイル名が **`PlemolJPConsoleNF-`** で始まる `.ttf` ファイルをすべて選択します（`PlemolJPConsoleNF-Thin.ttf`、`PlemolJPConsoleNF-Regular.ttf` など 16 個）
5. 選択したファイルをダブルクリックすると **Font Book**（フォント）アプリが開くので、「インストール」を押します
   - まとめてインストールしたい場合は、選択したファイルを Finder で `~/Library/Fonts` フォルダにドラッグしても構いません

インストールできたか確認:

```sh
ls ~/Library/Fonts | grep PlemolJPConsoleNF | head
```

ファイル名が並べば OK です。

> [!NOTE]
> フォントを入れなくてもアプリは動きます。その場合は CSS のフォールバック（本文は macOS のシステムフォント、コードは `ui-monospace` / Menlo）で表示されます。あとから設定画面でお好きなフォントに変更することもできます。
>
> ファイル名の `PlemolJP35ConsoleNF-` は「半角 3 : 全角 5」の幅比率の別ファミリです。好みで使い分けてください（その場合は設定画面でフォントを選び直します）。

### 手順 4: ソースコードを取得する

```sh
cd ~/Developer 2>/dev/null || { mkdir -p ~/Developer && cd ~/Developer; }
git clone https://github.com/uchidakoichi/QLMarkdown.git
cd QLMarkdown
git submodule update --init
```

`git submodule update --init` は、このプロジェクトが利用している外部ライブラリ（cmark-gfm、highlight、PCRE2、JPCRE2）を取得します。**これを忘れるとビルドが失敗します。**

### 手順 5: ビルドする

```sh
xcodebuild -scheme QLMarkdown -configuration Release \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO -jobs 1 build
```

初回は 5〜15 分ほどかかります。大量のログが流れますが、最後に **`** BUILD SUCCEEDED **`** と表示されれば成功です。

> [!TIP]
> `-jobs 1` は必須です。外部ビルドツールを使うターゲット（`libpcre2`、`libjpcre2`、`highlight-wrapper`、`cmark-headers`）を並列でビルドすると `Internal inconsistency error: never received target ended message` で失敗することがあります。

### 手順 6: `/Applications` にインストールする

Apple の署名証明書が無い環境では、ビルド成果物をそのままコピーしても **Quick Look 拡張が未署名扱いになり、macOS に認識されません**。ad-hoc 署名を内側のバイナリから順に付け直す必要があります。

下のブロックを**まとめてコピーしてターミナルに貼り付け**、Enter を押してください（`QLMarkdown` のフォルダにいる状態で実行します）。

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

codesign -v --deep --strict "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
open -a "$APP"
```

`codesign -v --deep --strict` は**何も出力されなければ成功**です。最後に QLMarkdown の設定画面が開きます。

署名の内訳:

- **アプリ本体はエンタイトルメントなし（非サンドボックス）** で署名します。設定と補助ファイルをホームディレクトリ配下に読み書きするためです
- **拡張機能はサンドボックスを維持したまま** 署名します。サンドボックスが無いと Quick Look 拡張として登録されません

### 手順 7: Quick Look 拡張を有効にする

**アプリを一度起動する**と、macOS が Quick Look 拡張を認識します（手順 6 の最後で起動済みです）。

システム設定 →「一般」→「ログイン項目と機能拡張」→ 一番下の「Quick Look」を開き、**QLMarkdown** にチェックが入っていることを確認してください。

ターミナルで確認する場合:

```sh
pluginkit -mAvvv | grep -A2 org.sbarex.QLMarkdown
```

`+ org.sbarex.QLMarkdown.QLExtension` と `+` 付きで表示されれば有効です。

## 動作確認

適当な `.md` ファイルを Finder で選び、**スペースキー**を押してください。Markdown が整形されて表示されれば成功です。

```sh
printf '# 見出し\n\n**強調**と `コード` と [リンク](https://example.com)\n' > ~/Desktop/test.md
```

このコマンドでデスクトップにテスト用ファイルを作れます。

## うまくいかないとき

| 症状 | 対処 |
|---|---|
| `xcodebuild` が見つからない | 手順 1 の `xcode-select` をやり直す |
| ビルドが `No such file or directory` で失敗する | `git submodule update --init` を実行し忘れている |
| `Internal inconsistency error` で失敗する | `-jobs 1` を付ける |
| `cmake: command not found` | `brew install cmake` |
| Quick Look で従来どおりのプレビューが出る | 他の Quick Look 拡張と競合しています。システム設定の Quick Look で他をすべてオフにして切り分けてください |
| プレビューが真っ白 | 一度アプリを起動してから、Finder を再起動（`killall Finder`）してみてください |
| 「ほかのアプリからのデータへのアクセス権」を毎回聞かれる | 再ビルドすると ad-hoc 署名の ID が変わるため一度は聞かれます。毎回聞かれ続ける場合は、アプリ本体をエンタイトルメント付きで署名していないか確認してください |

> [!WARNING]
> **Sparkle の自動アップデートは使わないでください。** 署名が一致せず失敗するか、本家のリリース版で上書きされてこのフォークの変更がすべて失われます。

## アンインストール

```sh
osascript -e 'tell application "QLMarkdown" to quit' 2>/dev/null
rm -rf /Applications/QLMarkdown.app
rm -rf ~/Library/Application\ Support/QLMarkdown
rm -f ~/Library/Preferences/group.org.sbarex.qlmarkdown.plist
```

フォントも消す場合は Font Book から PlemolJP を削除してください。

## ライセンス・クレジット

本家と同じく [GPLv3](LICENSE.txt) です。

- 本家: [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) — SBAREX
- 使用ライブラリ: [cmark-gfm](https://github.com/github/cmark-gfm), [highlight](http://www.andre-simon.de/doku/highlight/en/highlight.php), [PCRE2](https://github.com/PhilipHazel/pcre2), [JPCRE2](https://github.com/jpcre2/jpcre2), [MathJax](https://www.mathjax.org/), [Mermaid](https://mermaid.js.org/), [Sparkle](https://sparkle-project.org/), [Yams](https://github.com/jpsim/Yams), [SwiftSoup](https://github.com/scinfu/SwiftSoup), [swift-argument-parser](https://github.com/apple/swift-argument-parser)
- 既定フォント: [PlemolJP](https://github.com/yuru7/PlemolJP)
