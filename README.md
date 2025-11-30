# PublishMSBuild.macOS

自动化 macOS .app bundle 打包的 MSBuild 工具。

[![NuGet](https://img.shields.io/badge/nuget-v1.0.0--preview-blue)](https://github.com/interface95/PublishMSBuild.macOS)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## 功能

- ✅ 自动创建 macOS .app bundle
- ✅ 自动生成 .tar.gz 归档
- ✅ 支持 AOT 编译
- ✅ 自动代码签名
- ✅ 自动查找图标（Assets/*.icns）

## 快速开始

### 1. 安装 NuGet 包

```xml
<PackageReference Include="PublishMSBuild.macOS" Version="1.0.0-preview" />
```

### 2. 发布应用

```bash
dotnet publish -r osx-arm64 -c Release --self-contained true -p:PublishAot=true
```

自动生成：
- `YourApp.app` - macOS 应用 bundle
- `YourApp-osx-arm64.tar.gz` - 压缩归档

## 配置示例

```xml
<PropertyGroup>
  <MacOSBundleIdentifier>com.mycompany.myapp</MacOSBundleIdentifier>
  <MacOSAppName>MyApp</MacOSAppName>
  <MacOSIconPath>$(ProjectDir)Assets/AppIcon.icns</MacOSIconPath>
</PropertyGroup>
```

## 文档

完整文档请查看：[src/PublishMSBuild.macOS/README.md](src/PublishMSBuild.macOS/README.md)

包含：
- 详细配置参数对照表（bash 脚本 vs MSBuild）
- 图标配置和创建指南
- 所有可用属性说明
- 故障排除

## 项目结构

```
PublishMSBuild.macOS/
├── src/
│   └── PublishMSBuild.macOS/     # NuGet 包源代码
│       ├── build/
│       │   ├── PublishMSBuild.macOS.props
│       │   └── PublishMSBuild.macOS.targets
│       └── README.md             # 详细文档
├── AvaloniaApplication1/         # 示例应用
└── .github/workflows/            # 自动发布工作流
```

## 开发

### 本地构建

```bash
cd src/PublishMSBuild.macOS
dotnet pack -c Release -o ../../nupkgs
```

### 自动发布

推送到 `main` 分支时，GitHub Actions 会自动：
1. 构建并打包
2. 发布到 `local-packages/`
3. 提交更新

## 许可证

MIT License
