# GitHub Actions 工作流配置说明

本项目包含自动化的 NuGet 包发布工作流。

## 工作流文件

- `.github/workflows/nuget-publish.yml` - 主要的 NuGet 发布工作流

## 工作流触发条件

### 1. 推送到主分支 (Push to main/master)
当推送代码到 `main` 或 `master` 分支时：
- ✅ 自动构建项目
- ✅ 打包 NuGet 包
- ✅ 将包复制到 `local-packages/` 目录并提交

### 2. Pull Request
当创建 PR 时：
- ✅ 自动构建和测试
- ❌ 不发布包

### 3. 发布 Release
当在 GitHub 上创建 Release 时：
- ✅ 自动构建项目
- ✅ 打包 NuGet 包
- ✅ 发布到 NuGet.org（需要配置 API Key）
- ✅ 或发布到 GitHub Packages（如果没有 NuGet API Key）

### 4. 手动触发 (workflow_dispatch)
可以在 GitHub Actions 页面手动运行工作流

## 配置要求

### 发布到 NuGet.org

1. 在 [nuget.org](https://www.nuget.org/) 创建账号
2. 生成 API Key
3. 在 GitHub 仓库设置中添加 Secret：
   - Name: `NUGET_API_KEY`
   - Value: 你的 NuGet API Key

### 发布到 GitHub Packages

如果不配置 `NUGET_API_KEY`，包会自动发布到 GitHub Packages。

使用 GitHub Packages 中的包：
```xml
<!-- NuGet.Config -->
<configuration>
  <packageSources>
    <add key="github" value="https://nuget.pkg.github.com/YOUR_USERNAME/index.json" />
  </packageSources>
  <packageSourceCredentials>
    <github>
      <add key="Username" value="YOUR_USERNAME" />
      <add key="ClearTextPassword" value="YOUR_GITHUB_TOKEN" />
    </github>
  </packageSourceCredentials>
</configuration>
```

## 工作流任务

### Job 1: Build
- 在所有触发条件下运行
- 恢复依赖、构建、打包
- 上传 NuGet 包作为 artifact

### Job 2: Publish to NuGet
- 仅在 Release 或手动触发时运行
- 发布到 NuGet.org 或 GitHub Packages

### Job 3: Publish Local
- 仅在推送到主分支时运行
- 将包复制到 `local-packages/` 目录
- 自动提交更改

## 版本管理

在 `src/AutoMacBundle.Build/AutoMacBundle.Build.csproj` 中更新版本号：

```xml
<Version>0.1.4</Version>
```

## 本地测试

在推送前，可以使用本地工作流测试：
```bash
# 使用 Antigravity 工作流
/build-publish-nuget
```
