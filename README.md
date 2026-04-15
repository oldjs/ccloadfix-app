# ccLoadFix App

ccLoadFix 移动端管理 App，用 Flutter 构建，配合 [ccLoadFix](https://github.com/oldjs/ccLoadFix) AI API 网关使用。

## 功能

- 管理员密码登录认证
- 仪表盘：总览统计、活跃请求、RPM/QPS、版本信息
- 渠道管理：查看状态、启用/禁用、调整优先级、测试渠道、冷却管理
- 请求日志：可筛选（时间/渠道/模型/状态码）、分页、详情查看
- 统计图表：请求量/延迟/费用/Token 多维度图表 + 渠道模型统计表格
- API Token 管理：创建/启停/删除、费用限额
- 系统设置：查看/编辑/重置服务端配置
- Material Design 3 风格，支持亮色/暗色主题
- 中文界面

## 运行

```bash
flutter run
```

## 构建 APK

```bash
flutter build apk
```

## 连接

App 启动后输入 ccLoadFix 服务器地址和管理员密码（对应服务端环境变量 `CCLOAD_ADMIN_PASSWORD`）即可使用。

支持 HTTP 和 HTTPS 连接。
