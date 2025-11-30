# PublishMSBuild.macOS

自动化创建 macOS .app bundle 和归档文件的 MSBuild 工具包。支持 AOT 编译、自动代码签名和灵活配置。

## 功能特性

- ✅ 自动创建 macOS .app bundle
- ✅ 自动生成 .tar.gz 归档文件
- ✅ 支持 AOT (Ahead-of-Time) 编译
- ✅ 自动代码签名（ad-hoc）
- ✅ 可配置的 bundle 属性
- ✅ 自动处理图标文件
- ✅ 与原 bash 脚本参数完全兼容

## 快速开始

### 安装

#### 方式 1: 使用 NuGet 包（推荐）

```xml
<PackageReference Include="PublishMSBuild.macOS" Version="1.0.0-preview" />
```

#### 方式 2: 直接引用 MSBuild 文件

```xml
<Import Project="../src/PublishMSBuild.macOS/build/PublishMSBuild.macOS.props" />
<Import Project="../src/PublishMSBuild.macOS/build/PublishMSBuild.macOS.targets" />
```

### 基本使用

```bash
dotnet publish -r osx-arm64 -c Release --self-contained true -p:PublishAot=true
```

发布完成后会自动生成：
- `YourApp.app` - macOS 应用 bundle
- `YourApp-osx-arm64.tar.gz` - 压缩归档文件

## 配置参数对照表

### 脚本参数 vs MSBuild 属性

| bash 脚本参数 | MSBuild 属性 | 说明 | 默认值 |
|--------------|-------------|------|--------|
| `--project` | N/A | 自动使用当前项目 | - |
| `--runtime` | `MacOSBundleRuntime` | 运行时标识符 | `osx-arm64` |
| `--configuration` | N/A | 使用 dotnet publish 的配置 | `Release` |
| `--app-name` | `MacOSAppName` | 应用显示名称 | `$(AssemblyName)` |
| `--app-executable` | `MacOSAppExecutable` | Bundle 内可执行文件名 | `$(AssemblyName)` |
| `--bundle-identifier` | `MacOSBundleIdentifier` | CFBundleIdentifier | `com.avalonia.protoparse` |
| `--icon` | `MacOSIconPath` | .icns 图标文件路径 | 自动查找 `Assets/*.icns` |
| `--icon-name` | `MacOSIconName` | Bundle 内图标文件名 | `AppIcon` |
| `--app-version` | `MacOSAppVersion` | 应用版本号 | `$(Version)` 或 `1.0.0` |
| `--publish-dir` | `$(PublishDir)` | 发布输出目录 | 自动 |

### 额外的 MSBuild 属性

| 属性 | 说明 | 默认值 |
|------|------|--------|
| `MacOSBundleEnabled` | 是否启用自动打包 | `true` |
| `MacOSBundleArchiveEnabled` | 是否创建 .tar.gz 归档 | `true` |
| `MacOSOpenFinder` | 完成后是否打开 Finder | `false` |
| `MacOSBundleLSMinimumVersion` | 最低系统版本 | `10.15` |
| `MacOSBundleRoot` | Bundle 根目录路径 | `$(ProjectDir)$(MacOSAppName).app` |
| `MacOSArchivePath` | 归档文件路径 | `$(ProjectDir)$(MacOSAppName)-$(MacOSBundleRID).tar.gz` |

## 配置示例

### 最小配置

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="PublishMSBuild.macOS" Version="1.0.0-preview" />
  </ItemGroup>
</Project>
```

### 完整配置

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    
    <!-- macOS Bundle 配置 -->
    <MacOSBundleIdentifier>com.mycompany.myapp</MacOSBundleIdentifier>
    <MacOSAppName>MyAwesomeApp</MacOSAppName>
    <MacOSAppExecutable>MyAwesomeApp</MacOSAppExecutable>
    <MacOSAppVersion>2.1.0</MacOSAppVersion>
    
    <!-- 图标配置 -->
    <MacOSIconPath>$(ProjectDir)Assets/CustomIcon.icns</MacOSIconPath>
    <MacOSIconName>CustomIcon</MacOSIconName>
    
    <!-- 运行时配置 -->
    <MacOSBundleRuntime>osx-arm64</MacOSBundleRuntime>
    <MacOSBundleLSMinimumVersion>11.0</MacOSBundleLSMinimumVersion>
    
    <!-- 功能开关 -->
    <MacOSBundleEnabled>true</MacOSBundleEnabled>
    <MacOSBundleArchiveEnabled>true</MacOSBundleArchiveEnabled>
    <MacOSOpenFinder>false</MacOSOpenFinder>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="PublishMSBuild.macOS" Version="1.0.0-preview" />
  </ItemGroup>
</Project>
```

## 图标配置

### 自动查找图标

如果不指定 `MacOSIconPath`，工具会**自动在 `Assets/` 目录下查找第一个 `.icns` 文件**。

**推荐目录结构：**
```
YourProject/
├── Assets/
│   └── AppIcon.icns    ← 自动找到这个文件
├── YourProject.csproj
└── ...
```

### 指定自定义图标路径

如果图标文件不在 `Assets/` 目录，或者想使用特定的图标文件：

```xml
<PropertyGroup>
  <!-- 方式 1: 相对路径 -->
  <MacOSIconPath>$(ProjectDir)Resources/MyIcon.icns</MacOSIconPath>
  
  <!-- 方式 2: 绝对路径 -->
  <MacOSIconPath>/path/to/icon.icns</MacOSIconPath>
</PropertyGroup>
```

### 创建 .icns 文件

在 macOS 上从 PNG 创建 .icns：

```bash
# 创建 iconset 目录
mkdir MyIcon.iconset

# 生成各种尺寸（需要一个 1024x1024 的源图片）
sips -z 16 16     icon.png --out MyIcon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out MyIcon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out MyIcon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out MyIcon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out MyIcon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out MyIcon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out MyIcon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out MyIcon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out MyIcon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out MyIcon.iconset/icon_512x512@2x.png

# 转换为 .icns
iconutil -c icns MyIcon.iconset

# 移动到项目 Assets 目录
mv MyIcon.icns YourProject/Assets/
```

## 发布命令

### 基本发布（AOT）

```bash
dotnet publish -r osx-arm64 -c Release --self-contained true -p:PublishAot=true
```

### 指定自定义配置

```bash
dotnet publish -r osx-arm64 -c Release \
  --self-contained true \
  -p:PublishAot=true \
  -p:MacOSAppName="MyApp" \
  -p:MacOSBundleIdentifier="com.example.myapp" \
  -p:MacOSAppVersion="1.2.3"
```

### Intel Mac (x64)

```bash
dotnet publish -r osx-x64 -c Release --self-contained true -p:PublishAot=true
```

## 输出结构

```
YourProject/
├── YourApp.app/
│   └── Contents/
│       ├── Info.plist
│       ├── MacOS/
│       │   ├── YourApp          # 可执行文件
│       │   └── *.dylib          # 依赖库
│       └── Resources/
│           └── AppIcon.icns
└── YourApp-osx-arm64.tar.gz
```

## 版本管理

更新版本号：
```bash
# 编辑 src/PublishMSBuild.macOS/PublishMSBuild.macOS.csproj
<Version>0.1.4</Version>
```

提交并推送后会自动发布新版本到 `local-packages/`。

## 许可证

MIT License
