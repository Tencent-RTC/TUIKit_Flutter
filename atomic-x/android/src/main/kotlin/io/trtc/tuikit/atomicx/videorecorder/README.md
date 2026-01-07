# 开启美颜/纵横比设置

美颜和纵横比设置是 VideoRecorder 的高级功能。启用需满足以下条件：

## 1. 依赖 TXLiteAVSDK_Professional

在项目或任一模块的 Gradle 配置中添加依赖：

```gradle
dependencies {
    api "com.tencent.liteav:LiteAVSDK_Professional:latest.release"
}
```

- 如果工程中任一模块已依赖 TXLiteAVSDK_TRTC，请将其替换为 TXLiteAVSDK_Professional（不会影响其他模块使用）。
- 依赖 TXLiteAVSDK_Professional 后，可启用纵横比设置，兼容性与画质也会更好。

## 2. 开通“多媒体高级功能”权限

目前需通过内测申请开通“多媒体插件高级功能”（包含视频录制、音频录制、图片/视频编辑等能力）。

- 申请入口：多媒体插件高级功能内测申请地址（https://cloud.tencent.com/apply/p/wlav0nzz7dp）。

### 注意事项
1. 提交后通常在 1 个工作日内完成审核。建议使用企业认证的腾讯云账号进行申请，以提升通过率。
2. 内测使用日期截至 2026 年 7 月 1 日，届时所有内测使用权限将失效。
3. 在内测截止日期之前，将上线高级功能的付费购买方案（购买方式与插件市场其他插件一致，详见“插件市场概述及开通指引”）。若到期未购买，美颜功能将被屏蔽（不显示美颜按钮）；购买后将自动恢复显示（除非在配置中被强制屏蔽）。

## 3. 不同构建配置下的行为

- Release：
  - 若不满足启用条件，即使在配置中开启，高级功能也不会生效（相关按钮将自动隐藏）。
- Debug：
  - 点击不支持的功能时，会在 UI 中弹窗提示。
  - 如需在 Debug 版本中也屏蔽这些功能，可在 Config 或配置文件中关闭对应开关（详见配置说明）。



# Enable Beauty/Aspect Ratio Settings

Beauty and aspect ratio settings are advanced features of VideoRecorder. To enable them, the following conditions must be met:

## 1. Depend on TXLiteAVSDK_Professional

Add the dependency to your project or any module’s Gradle configuration:

```gradle
dependencies {
    api "com.tencent.liteav:LiteAVSDK_Professional:latest.release"
}
```

- If any module in your project already depends on TXLiteAVSDK_TRTC, replace it with TXLiteAVSDK_Professional (this will not affect other modules).
- After switching to TXLiteAVSDK_Professional, aspect ratio settings will be available, and overall compatibility and image quality will be improved.

## 2. Enable “Advanced Multimedia Features” Permission

You currently need to apply for internal testing access to the “Advanced Multimedia Plugin Features” (including video recording, audio recording, photo/video editing, etc.).

- Application link: Advanced Multimedia Plugin Features Early Access (https://cloud.tencent.com/apply/p/wlav0nzz7dp)

### Notes
1. Reviews are typically completed within one business day. We recommend applying with a Tencent Cloud enterprise-verified account to increase the approval rate.
2. The internal testing access is valid until July 1, 2026. After that date, all early-access permissions will expire.
3. A paid plan for advanced features will be available before the end of the early-access period (purchasing follows the same process as other plugins; see “Plugin Marketplace Overview and Activation Guide”). If not purchased upon expiration, the beauty feature will be disabled (the beauty button will be hidden). It will automatically reappear after purchase (unless explicitly disabled via configuration).

## 3. Behavior in Different Build Configurations

- Release:
  - If prerequisites are not met, the advanced features will not work even if enabled in the configuration (related buttons will be automatically hidden).
- Debug:
  - Tapping unsupported features will trigger a UI toast/dialog message.
  - If you wish to hide these features in Debug as well, disable the corresponding switches in the Config or the configuration file (see configuration documentation).