# Town Pass - 捷運運動體驗模組

## 專案簡介

「捷運動」是 Town Pass APP 中以台北捷運為主題的互動體驗，結合路線規劃、車廂運動推薦、歷史紀錄與積分機制，鼓勵通勤族在旅程中輕鬆完成伸展運動。此 README 總結了 `lib/page` 目錄下各頁面的責任與資料流程，協助開發者快速上手維護與擴充。

## 功能導覽

### 新旅程規劃（`lib/page/new_component/`）
- `NewComponentViewController` 載入捷運站、運動部位、運動項目與車廂擁擠度資料，透過 Haversine 公式計算距離並建立捷運路網圖，考量換線懲罰找出最佳路徑與預估時間。
- `NewComponentView` 以 `GetX` 管理狀態，提供自動完成的起/終點欄位、運動部位多選、預估時間與 CTA，並可從抽屜導覽至歷史與排行榜。

### 運動推薦（`lib/page/exercise_recommendation/`）
- `ExerciseRecommendationController` 解析上一頁傳入的路線結果，拆分旅程片段（依據捷運站），計算每段剩餘秒數與對應運動，並定時更新車站位置與提醒。
- `ExerciseRecommendationView` 搭配 `JourneyTrackerWidget`、`ExerciseTimerCard`、`ExerciseInfoCard` 呈現旅程進度、倒數與動作細節，完成後導向運動結果頁。

### 運動結果（`lib/page/exercise_result/`）
- `ExerciseResultView` 彙整旅程概況、積分與卡路里，支援擷取分享圖卡與呼叫 `PointsService` 上傳積分。
- `ExercisePlacesRepository` 讀取 `assets/mock_data/places.json`，依終點站回傳附近推薦場館。

### 運動歷史（`lib/page/exercise_history/`）
- `ExerciseHistoryController` 使用 `ExerciseHistoryService` 讀寫本地運動紀錄，計算統計資料並提供刪除/清空功能。
- `ExerciseHistoryView` 顯示統計卡、歷史清單與空狀態，支援下拉更新與展開動作細節。

### 積分排行榜（`lib/page/points_ranking/`）
- `PointsRankingPage` 透過 `PointsService` 抓取排行榜與個人總積分，清楚區分排行榜摘要、前十名與個人排名，並處理載入/錯誤狀態。

## 使用者旅程流程

1. 使用者在新旅程頁選擇起終點與運動部位並啟動規劃。
2. 系統計算捷運路線與預估時間，帶著參數進入運動推薦頁。
3. 使用者依照推薦動作完成運動，完成後自動跳轉至運動結果頁並儲存紀錄。
4. 使用者可以在運動歷史查詢過往紀錄，或在積分排行榜檢視目前排名。

## 主要資料來源與服務

- `TrainCrowdingService`：提供車廂擁擠度資訊，優化路線推薦。
- `GeoLocatorService`：取得使用者定位，依距離排序起點站。
- `ExerciseHistoryService`：管理本地運動紀錄及統計。
- `PointsService`：提交與查詢使用者積分與排行榜。
- `assets/mock_data/`：提供捷運站、運動項目、旅次時間與運動場館等離線資料。

## 開發注意事項

- 頁面狀態管理以 `GetX` 為主，請避免重複注入相同 controller。
- 多數資料載入採 `Future.wait` 併發，若新增資源請留意錯誤處理與載入指示。
- 路線計算建立於內部圖形資料結構，新增線路或站點時須同步更新 `assets/mock_data/mrt_travel_times.json`。
- 運動紀錄與積分提交需維持一致的 JSON 結構，以利後續改版或後端串接。

## 快速啟動

```bash
flutter pub get
flutter packages pub run build_runner build
flutter run
```

## 貢獻建議

- 新增運動動作時，請同時更新對應的 `assets/mock_data/exercise.json`、動作描述與圖示。
- 若擴充排行榜或積分規則，請同步調整 `PointsService` 與 UI 顯示。
- 發現問題或需要協助，歡迎提交 Issue 或 Pull Request，一起完善捷運運動體驗。

