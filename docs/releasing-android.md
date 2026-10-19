# Android Release 发布流程

## GitHub Actions 验证

PR 和分支推送运行 `.github/workflows/ci.yml`，执行格式、分析和测试检查。
合并工作流到默认分支后，可在 Actions 中手动运行 `Android Release`，选择待验证分支；手动执行只上传 `signed-android-arm64` artifact，不创建 Release。

仓库需要配置 `RELEASE_KEYSTORE_BASE64`、`RELEASE_STORE_PASSWORD`、`RELEASE_KEY_ALIAS`、`RELEASE_KEY_PASSWORD` 四项 Actions Secrets。密钥通过临时目录注入，构建后清理，不进入 artifact。不要向不可信分支运行带签名密钥的工作流。

签名构建先运行格式检查、分析及测试，再验证 APK 签名与最终权限；若包含 `android.permission.INTERNET` 则失败。产物包含 APK、SHA256SUMS.txt、签名证书信息、权限清单和发布说明。手动下载后仍须真机验证安装、媒体读取及覆盖升级。

推送与 pubspec 版本一致的 `v*.*.*` 标签会创建 **Draft Release**，SHA-256 同时写入正文和附件。维护者确认后手动发布；流水线成功不代表严格可重现构建，也不代替真机验证。


## 签名策略

GitHub Releases 使用 SideByVR 专用的长期 release keystore。它与 Google Play 的 Play App Signing 密钥独立，两个渠道的 APK 不保证可以相互覆盖安装。正式密钥只保存在维护者的安全存储中，不提交到仓库。

首次配置时，将本机安全位置的 keystore 信息写入 `android/key.properties`（可参考 `android/key.properties.example`）。该文件已被 Git 忽略。丢失 release keystore 将导致后续版本无法覆盖升级已发布的 GitHub APK。

## 构建与验证

```sh
flutter --no-version-check build apk --release \
  --target-platform android-arm64 --split-per-abi --no-pub

# 生成的 ARM64 文件：
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

$ANDROID_HOME/build-tools/<version>/apksigner verify --verbose \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
sha256sum build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

确认 `apksigner` 显示 v2 或更高版本验证成功，并记录 SHA-256 到 GitHub Release 的说明中。上传前可将文件重命名为 README 约定的稳定名称：

`SideByVR-viewer-0.1.0-arm64.apk`

Debug APK 只用于本地开发和真机调试，不得作为公开 Release 上传。公开 APK 必须使用同一份 release keystore 重新构建。

## GitHub Release

创建版本标签（例如 `v0.1.0`），上传稳定命名的 ARM64 APK，并在 Release 说明中记录版本、架构、签名方式和 SHA-256。README 使用 `releases/latest/download/SideByVR-viewer-0.1.0-arm64.apk` 指向最新文件；更换文件名时必须同步更新两份 README。
