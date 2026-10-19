# AGENTS.md — SideByVR Viewer

## 协作约定

- 与维护者使用中文交流；Git 提交信息使用中文标题与多行正文。
- 在 feature/fix 分支工作，不直接提交到 `main`。保留用户已有改动，任务完成时报告修改、验证结果和待验项目。
- 当前维护环境为 WSL，常用 shell 为 fish；Windows 路径需转换为实际 WSL 挂载路径，不硬编码驱动器。
- Python 辅助脚本使用 `uv run --no-project python`，优先标准库；需要跨平台的脚本处理 Windows UTF-8 输出。
- 搜索优先使用 `rg`。库/API 的用法以当前版本官方文档为准；有 Context7 时先解析库 ID 再查询。不要为普通业务逻辑修改额外查询无关框架资料。

## 项目定位与边界

这是独立的 Flutter Android 本地 SBS 图片/视频查看器，不是 Unity 工程。应用标识为 `com.sidebyvr.viewer`，Flutter 包名为 `sidebyvr`。

首版聚焦系统目录授权、本地文件夹和 ZIP、双目显示、手柄与查看偏好。不要引入账号、支付、云端上传、生成流水线、私有后端或生产 API 配置。公开工程构建不需要 `.env`、服务端凭据或商业签名材料。

开源筹备计划、完整许可证审计和发布过程记录由维护者在独立私有仓库维护，不复制进本仓库。这里保存应用源码、测试及面向使用者和贡献者的公开文档。不要假设旁边的私有工程是构建依赖。

## 代码入口与结构

| 路径 | 职责 |
| --- | --- |
| `lib/main.dart` | 应用入口、主题、初始显示模式 |
| `lib/app_info.dart` | 应用名称与展示版本 |
| `lib/pages/home_menu_page.dart` | 本地目录、继续浏览、设置、退出 |
| `lib/pages/saf_browser_page.dart` | SAF 目录/ZIP 浏览、普通图片 SBS 开关、媒体缓存与 Viewer 导航 |
| `lib/pages/viewer_page.dart` | 图片/视频切换、手柄、缩放、位移、眼间距与图集边界 |
| `lib/pages/settings_page.dart` | 查看偏好和应用内许可证入口 |
| `lib/models/media_item.dart` | 媒体类型识别与显式 SBS 文件过滤 |
| `lib/services/` | SAF 原生桥接、共享手柄事件流、本地目录和查看偏好 |
| `lib/widgets/` | 双目菜单、图片拆分与缓存、视频显示、ZIP 提取 |
| `android/app/src/main/kotlin/com/sidebyvr/viewer/MainActivity.kt` | Android 存储和手柄桥接 |
| `test/` | 过滤、ZIP、偏好、缓存、手柄、菜单与模拟存储流程测试 |

导航主线为 `MyApp → HomeMenuPage → SafBrowserPage → ViewerPage`。图片渲染通过 `ImageSource` 与缓存协作；不要在显示组件中重新引入远程服务耦合。

## 开发与验证

已验证基线为 Flutter 3.47.0、Java 17、Android SDK 36。SDK 约束以 `pubspec.yaml` 为准，依赖保留 `pubspec.lock`；不要在功能修改中顺带升级依赖或 Flutter。

从仓库根目录运行：

```sh
flutter --no-version-check pub get
flutter --no-version-check analyze --no-pub
flutter --no-version-check test --no-pub
flutter --no-version-check test --no-pub test/local_viewer_flow_test.dart
flutter --no-version-check build apk --debug --target-platform android-arm64 --no-pub
```

使用 `dart format` 格式化改动的 Dart 文件。只有依赖已在本地缓存时才使用 `pub get --offline`。若工具只配置在 fish 中，从 fish 执行；不要把某台机器的 SDK 绝对路径写进公共构建文件。

APK 默认产物为 `build/app/outputs/flutter-apk/app-debug.apk`。用于交付的副本放到本工程忽略的 `tmp/` 下，不假定 Windows Downloads 可用。正式 Release 签名尚未配置，不能把 Debug APK 改名为 Release。

验证按修改范围执行：代码运行分析及相关测试；Android 资源或原生变动执行 Android 构建；文档检查链接和语言一致性即可，不需要为纯文档变更重复构建。基线曾通过 36 项测试，但应报告本次实际结果，不把历史结果当作本次执行。

真机 SAF 授权恢复、冷启动手柄焦点、离线使用、视频兼容性和干净检出构建仍需完成。模拟平台通道测试、页面渲染或 APK 编译不能代替真机验证。

## 容易误改的行为

- 默认仅显示 `.sbs.jpg`、`.sbs.jpeg`、`.sbs.png`、`.sbs.mp4`，不区分大小写。识别图片容器不等于确认图片是 SBS。
- 普通 JPG/JPEG/PNG 必须由用户主动开启 Images as SBS 模式；退出浏览页重置。文件夹、子目录、跨图集和 ZIP 必须使用一致规则。
- ZIP 缓存清单绑定版本与过滤模式，改变过滤规则时评估缓存失效。保留路径穿越检查及数量/大小限制，不能只放宽文件后缀。
- 当前图片按左右各半显示，保留半图比例；未实现 Half-SBS 校正、眼序交换、上下排列、JPS/MPO 或 GIF 浏览入口。存在 GIF widget 不代表支持 GIF 选择。
- 图片缓存使用 JPEG 中间表示，不保留 PNG 透明度和无损特性；奇数宽末尾一列会舍弃。不要做超出实现的格式承诺。
- Android 焦点依赖显式请求和页面返回后的恢复，不能仅依赖 `autofocus`。保留统一广播手柄流，避免多个页面抢占原生监听。
- 浏览页 RB/R 切普通图片模式；查看器 RB 切提示层、A/X 调眼间距，左摇杆缩放/切图，右摇杆位移。视频方向键用于定位和音量。更新说明前核对实际事件处理，不沿用旧项目快捷键。
- 修复异步导航时检查 `mounted`、加载状态、输入恢复和重复打开。真实 Isolate 解码的 widget 测试需要正确处理 `runAsync` 与导航等待。

## 双语文档与资源

- 英文首页为 `README.md`，中文首页为 `README_zh.md`。英文文档保持原名，中文对应文件使用 `_zh.md`。
- 文档正文按语言分离；两份 README 和各文档内部链接应跳转到同语言页面，顶部保留对应页面的语言切换。中文说明可保留实际英文按钮名并给出解释。
- 修改用户可见行为时同步两种语言的使用说明、格式矩阵和必要的更新日志。Issue 模板也分中英文。
- `docs/samples/README.md` 与 `README_zh.md` 引用公开 R2 缩略图和 SBS 原图 URL；只存链接，不下载大型样例进仓库。缩略图仅为单眼预览，下载链接应指向完整 SBS。
- `docs/images/vr-equipment.jpg` 是设备说明插画，不是应用截图。后续界面图片使用真机截图；不要重新加入被撤下的测试渲染预览。
- README 的 Android 下载地址目前按维护者要求留空。未经确定不要编造 GitHub owner、Release URL、邮箱或已上线状态。
- 发布版本时同步 `pubspec.yaml`、`lib/app_info.dart`、`VERSION` 和两份 README 的版本徽章，保留 pubspec 的构建号含义。

不要提交 `.env`、签名材料、SDK 本地配置、缓存、APK/AAB、私人媒体、用户数据或第三方反编译资料。资源需有明确来源；公开文档不要携带私有仓库绝对路径或内部凭据。遵循 `.gitignore`，但不要把它当成内容审查的替代。
