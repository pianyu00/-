# 轻记账

一款精致优雅的 Flutter 记账应用，支持多主题、多语言、图表分析、CSV 导入导出。

## 功能

- **三种视图**：列表、日历、图表（柱状图 + 饼图），左右滑动切换月份
- **数据可视化**：月度收支柱状图、分类占比饼图，点击查看明细
- **多主题系统**：9 套精心设计的配色主题，支持深色模式
- **双语支持**：中文 / English，随系统语言自动切换
- **CSV 导入导出**：备份和迁移数据到 Downloads 目录
- **搜索过滤**：按类型、分类、关键词搜索账单记录
- **毛玻璃 UI**：PremiumGlass 毛玻璃组件，精致的光影和动画效果
- **触感反馈**：全局 HapticFeedback 震动反馈
- **数字动画**：AnimatedCounter 数字滚动动画

## 技术栈

- **框架**：Flutter + Dart
- **状态管理**：Provider (ChangeNotifier)
- **数据库**：SQLite (sqflite)
- **图表**：fl_chart
- **本地存储**：shared_preferences
- **国际化**：Flutter i18n / 自定义翻译映射
- **平台通道**：Android MediaStore / ContentResolver

## 截图

| 主页 | 添加记录 | 设置 |
|------|----------|------|
| 列表视图 | 日历视图 | 图表统计 |

## 构建

```bash
# 获取依赖
flutter pub get

# 运行
flutter run

# 构建 APK
flutter build apk --release

# 构建 arm64-v8a
flutter build apk --release --target-platform android-arm64
```

## 项目结构

```
lib/
├── main.dart
├── database/
│   └── database_helper.dart    # SQLite 操作
├── models/
│   ├── record.dart             # 数据模型
│   ├── app_themes.dart         # 9 套主题 + 设计 Token
│   └── categories.dart         # 收支分类
├── pages/
│   ├── home_page.dart          # 主页
│   ├── add_record_page.dart    # 添加/编辑
│   ├── search_page.dart        # 搜索
│   ├── settings_page.dart      # 设置
│   └── about_page.dart         # 关于
├── providers/
│   └── app_settings_provider.dart
├── utils/
│   ├── strings.dart            # 中英文翻译
│   └── file_helper.dart        # 文件写入
└── widgets/
    ├── animated_counter.dart
    ├── bounce_tap.dart
    └── premium_ui.dart
```

## License

MIT
