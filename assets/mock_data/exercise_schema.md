# Exercise Schema 定義

## TypeScript Definition

```typescript
interface Exercise {
  /** 運動名稱 */
  name: string;

  /** 每秒消耗的卡路里 */
  calPerSec: number;

  /** 是否可以在擁擠環境中進行 */
  doInCrowded: boolean;

  /** 運動部位（可多選）*/
  parts: string[];

  /** 媒體資源路徑（圖片或影片） */
  media: string;

  /** 運動描述說明 */
  description: string;
}

type ExercisesJson = Exercise[];
```

## 欄位說明

### `name` (string, required)
- 運動的名稱
- 範例：`"深蹲"`、`"站姿肩頸拉伸"`

### `calPerSec` (number, required)
- 每秒消耗的卡路里數
- 單位：大卡/秒
- 範例：`0.05` 表示每秒消耗 0.05 大卡

### `doInCrowded` (boolean, required)
- 是否適合在擁擠環境（如尖峰時段捷運車廂）中進行
- `true`: 可以在擁擠環境中進行
- `false`: 需要較大空間，不適合擁擠環境

### `parts` (string[], required)
- 運動訓練的身體部位
- 支援多個部位（陣列格式）
- 可用的值：
  - `"upper_body"` - 上半身（肩膀、手臂、胸部、背部）
  - `"lower_body"` - 下半身（大腿、小腿、臀部）
  - `"core"` - 核心（腹部、腰部）
  - `"full_body"` - 全身
  - `"neck_shoulder"` - 頸部與肩膀

### `media` (string, required)
- 運動示範的媒體檔案路徑
- 支援圖片或影片
- 路徑相對於 `assets/image/` 目錄
- 範例：`"exercises/image.png"`

### `description` (string, required)
- 運動的詳細說明
- 包含運動效果、注意事項等
- 範例：`"深蹲是一種簡單有效的下肢運動，可以鍛鍊大腿肌肉，增強下肢力量。"`

## 範例資料

```json
{
  "name": "站姿肩頸拉伸",
  "calPerSec": 0.02,
  "doInCrowded": true,
  "parts": ["neck_shoulder", "upper_body"],
  "media": "exercises/image.png",
  "description": "輕柔的肩頸伸展動作，適合在捷運上進行，可以有效緩解長時間使用手機或久坐造成的肩頸僵硬。"
}
```

## 使用情境

### 運動推薦邏輯
1. 使用者選擇想訓練的身體部位（如 `"neck_shoulder"`）
2. 系統篩選 `parts` 陣列中包含該部位的所有運動
3. 根據環境擁擠程度（`doInCrowded`）進一步篩選
4. 計算預估消耗熱量（`calPerSec * 運動時間`）

### 篩選範例
```typescript
// 篩選適合肩頸的運動
const neckShoulderExercises = exercises.filter(
  ex => ex.parts.includes("neck_shoulder")
);

// 篩選適合擁擠環境的運動
const crowdedExercises = exercises.filter(
  ex => ex.doInCrowded === true
);

// 組合條件：適合肩頸且可在擁擠環境進行
const suitableExercises = exercises.filter(
  ex => ex.parts.includes("neck_shoulder") && ex.doInCrowded
);
```

## 版本歷史

- **v1.0.0** (2025-11-08)
  - 初始版本
  - 支援多部位選擇（`parts` 改為陣列）
  - 新增 7 種運動範例

