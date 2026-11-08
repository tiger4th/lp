# GIIN ストア用スクリーンショット・バナー生成スクリプト

App Store / Google Play 用のスクリーンショット（スマートフォン・タブレット）およびクリエイティブアセット（ヘッダ・検索結果・フィーチャーグラフィック）を一括生成する Swift スクリプト一式です。

## フォルダ構成

```text
screenshot/
├── raw/
│   ├── phone/              # スマホ用の元スクショ画像（472x1024）＆シェア画像
│   └── tablet/             # iPad用の元スクショ画像（768x1024）
├── scripts/
│   ├── generate_all.sh                  # 一括生成シェルスクリプト
│   ├── generate_screenshots.swift       # スマホ用（iOS 1242x2688 / Android 1080x1920）生成
│   ├── generate_tablet_screenshots.swift# タブレット用（2048x2732）生成
│   └── generate_creative_assets.swift   # ヘッダ・検索結果・Google Playバナー生成
├── ios_1242x2688/          # [出力] App Store 6.5インチ用
├── android_1080x1920/      # [出力] Google Play スマホ用
├── tablet_2048x2732/       # [出力] App Store 13インチiPad / Google Play タブレット用
└── creative_assets/        # [出力] プロダクトページヘッダ・検索結果・フィーチャーグラフィック
```

## 使い方（一括再生成）

ターミナルで以下のコマンドを実行するだけで、全画像が再生成されます。

```bash
sh /Users/tiger4th/git/lp/giin/img/screenshot/scripts/generate_all.sh
```

* キャッチコピーを変更したい場合は、各 `.swift` ファイル内の `slides` 配列または `drawText(...)` の文字列を書き換えて再実行してください。
* スクリーンショットを差し替えたい場合は、`raw/phone/` または `raw/tablet/` 内の同名ファイルを置き換えて再実行してください。
