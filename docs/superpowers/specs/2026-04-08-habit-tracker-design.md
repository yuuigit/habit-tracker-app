# 習慣トラッカーアプリ 設計ドキュメント

**Date:** 2026-04-08
**Status:** Approved

---

## 概要

スマートフォン向けの習慣トラッカーアプリ。毎日の習慣を記録し、連続達成日数（ストリーク）を可視化する。収益は Google AdMob の広告収益モデルで得る。iOS/Android 両対応で Flutter を使って開発する。

**ターゲットユーザー:** 習慣形成に取り組みたい一般ユーザー
**収益モデル:** 広告収益（Google AdMob）
**プラットフォーム:** iOS + Android（Flutter）

---

## Section 1: アーキテクチャ概要

### 技術スタック

| 役割 | 技術 |
|---|---|
| フレームワーク | Flutter（Dart） |
| ローカルDB | Hive |
| 状態管理 | Riverpod |
| 広告 | Google AdMob（flutter_local_notifications） |
| 通知 | flutter_local_notifications |

### 画面構成

1. **ホーム画面** — 今日の習慣一覧 + 達成チェック + バナー広告
2. **習慣追加・編集画面** — 習慣名・頻度・アイコン設定
3. **統計画面** — 連続日数・達成率グラフ（開くときにインタースティシャル広告）
4. **設定画面** — リマインダー通知設定

### 広告配置

- ホーム画面下部: バナー広告（常時表示）
- 統計画面を開く際: インタースティシャル広告（3回に1回まで）

---

## Section 2: データモデルとコンポーネント設計

### データモデル

```dart
// 習慣
class Habit {
  String id;
  String name;           // 例: "朝のランニング"
  String icon;           // アイコン絵文字
  List<int> frequency;   // 曜日指定 [1=月, 2=火, ..., 7=日]
  DateTime createdAt;
  DateTime? reminderTime; // 通知時間（任意）
}

// 達成記録
class HabitRecord {
  String id;
  String habitId;
  DateTime date;          // 達成した日付
}
```

### コンポーネント構成

| コンポーネント | 責務 |
|---|---|
| `HabitRepository` | DB の読み書き（Hive） |
| `HabitNotifier` | 状態管理（Riverpod Provider） |
| `HomeScreen` | 今日の習慣一覧、チェック操作 |
| `HabitFormScreen` | 習慣の追加・編集 |
| `StatsScreen` | 連続日数・達成率の表示 |
| `AdBanner` | AdMob バナー広告ウィジェット |

### データフロー

```
UI操作
  → HabitNotifier（Riverpod）
    → HabitRepository
      → Hive DB（ローカル保存）
  ← 状態更新（画面が自動再描画）
```

---

## Section 3: エラーハンドリング・通知・広告戦略

### エラーハンドリング

- DB 読み書き失敗時: スナックバーでユーザーに通知
- 習慣が0件の場合: 「最初の習慣を追加しましょう！」の空状態UI を表示

### 通知（リマインダー）

- パッケージ: `flutter_local_notifications`
- 習慣ごとに設定した時間に毎日プッシュ通知
- 曜日指定した日のみ通知

### 広告戦略（AdMob）

| 広告種別 | 場所 | 頻度 |
|---|---|---|
| バナー広告 | ホーム画面下部 | 常時 |
| インタースティシャル | 統計画面を開いた時 | 3回に1回まで |

- 開発中はテスト広告IDを使用し、本番広告は表示しない
- 初期リリースはバナーのみ。安定後にインタースティシャルを追加

### テスト方針

- Flutter の `widget_test` で主要画面のスモークテスト
- 習慣の追加・達成チェック・統計表示の基本フローをカバー

---

## 成功基準

- [ ] 習慣の追加・編集・削除ができる
- [ ] 今日の習慣をチェックして達成記録ができる
- [ ] 連続達成日数（ストリーク）が正しく表示される
- [ ] バナー広告がホーム画面に表示される
- [ ] iOS/Android 両方でビルド・動作確認できる
