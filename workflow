name: Putty

# 触发器
on:
  push:
    tags:
      - v*
  pull_request:
    tags:
      - v*

jobs:
  build:

    runs-on: ubuntu-latest
    # 设置jdk环境为1.8
    steps:
    - uses: actions/checkout@v2
    - name: set up JDK 1.8
      uses: actions/setup-java@v1
      with:
        java-version: 1.8
    # 获取打包秘钥
    - name: Checkout Android Keystore
      uses: actions/checkout@v2
      with:
        repository: 存储android打包用的key的仓库（格式：用户名/仓库名）
        token: ${{ secrets.TOKEN }} # 连接仓库的token,需要单独配置
        path: keystore # 仓库的根目录名
    # 打包release
    - name: Build with Gradle
      run: bash ./gradlew assembleRelease
    # 创建release
    - name: Create Release
      id: create_release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        #GitHub 会自动创建 GITHUB_TOKEN 密码以在工作流程中使用。 
        #您可以使用 GITHUB_TOKEN 在工作流程运行中进行身份验证。
        #当您启用 GitHub Actions 时，GitHub 在您的仓库中安装 GitHub 应用程序。 
        #GITHUB_TOKEN 密码是一种 GitHub 应用程序 安装访问令牌。 
        #您可以使用安装访问令牌代表仓库中安装的 GitHub 应用程序 进行身份验证。 
        #令牌的权限仅限于包含您的工作流程的仓库。 更多信息请参阅“GITHUB_TOKEN 的权限”。
        #在每个作业开始之前， GitHub 将为作业提取安装访问令牌。 令牌在作业完成后过期。
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        draft: false
        prerelease: false
    # 获取apk版本号
    - name: Get Version Name
      uses: actions/github-script@v3
      id: get-version
      with:
        script: |
          const str=process.env.GITHUB_REF;
          return str.substring(str.indexOf("v"));
        result-encoding: string
    # 上传至release的资源
    - name: Upload Release Asset
      id: upload-release-asset 
      uses: actions/upload-release-asset@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        upload_url: ${{ steps.create_release.outputs.upload_url }} # 上传网址，无需改动
        asset_path: app/build/outputs/apk/release/app-release.apk # 上传路径
        asset_name: LightTimetable-${{steps.get-version.outputs.result}}.apk # 资源名
        asset_content_type: application/vnd.android.package-archiv #资源类型
    # 存档打包的文件
    - name: Archive production artifacts
      uses: actions/upload-artifact@v2
      with:
        name: build
        path: app/build/outputs #将打包之后的文件全部上传（里面会有混淆的map文件）
