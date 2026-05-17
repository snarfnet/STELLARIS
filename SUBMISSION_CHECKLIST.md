# STELLARIS 提出準備チェックリスト

## GitHub

- GitHub Actions: `.github/workflows/ios-build.yml`
- Xcode project: `STELLARIS.xcodeproj`
- Scheme: `STELLARIS`
- Bundle ID: `com.tokyonasu.STELLARIS`
- Team ID: `83VGKGSQUH`
- Minimum iOS: `15.0`

## App Store Connect 前に確認

- アプリ名、サブタイトル、説明文
- スクリーンショット
- 1024px アプリアイコン
- プライバシー回答
- 年齢制限
- 価格
- テスト用メモ

## ビルド

GitHub Actions の `iOS Build` が通れば、Debug ビルドの土台は確認済みです。

配布用のArchiveはMacのXcodeで作成します。署名、証明書、App Store ConnectアップロードはAppleアカウントに紐づくため、GitHubには秘密情報を置かない構成にしています。
