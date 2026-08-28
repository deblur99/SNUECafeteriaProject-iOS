# 교대학식

서울교육대학교 교내 학생식당의 주간 식단 정보를 제공하는 **Apple 멀티플랫폼** 앱입니다.  
**iOS · iPadOS · watchOS · macOS**를 지원하며, 플랫폼별로 네이티브 SwiftUI 타깃을 둡니다.

| 플랫폼 | 타깃 / 스키마 | 비고 |
|--------|----------------|------|
| iPhone · iPad | `SNUECafeteriaProject` | 탭 UI, 위젯, App Intents, Watch 페어링 |
| Apple Watch | `SNUECafeteriaWatchApp` | 오늘·주간 목록, Smart Stack 위젯, 공유, iPhone 동기화 / 독립 조회 |
| Mac | `SNUECafeteriaMac` | NavigationSplitView, 단일 창, Mac 위젯 |

## 중요 안내

이 저장소는 **포트폴리오 및 구현 참고용 오픈소스 저장소**로 공개되어 있습니다.  
다만 서울교육대학교 정보전산원과 후생복지센터 협의 결과, **서울교대 식단 정보의 외부 앱 활용은 허용되지 않았습니다.**

따라서 이 프로젝트는 코드 열람과 개발 참고 목적에 한해 공개되며, 다음 행위는 허용하지 않습니다.

- 서울교대 식단 정보, 학교명, 서비스 맥락을 활용한 앱의 공개 배포
- App Store 출시, TestFlight 배포, 사설 배포, 재배포 등 앱 설치 파일 또는 빌드 산출물의 배포
- 상업적 이용 여부와 무관한 제3자 대상 서비스 운영

본 저장소의 공개는 서울교육대학교 또는 관련 부서의 **승인, 제휴, 공식 서비스 운영**을 의미하지 않습니다.

## 배포 책임 및 면책

- 식단 정보는 휴무, 교내 행사, 외부인 이용 제한 등으로 실제 운영과 다를 수 있습니다.
- 이 저장소를 포크, 수정, 빌드하여 배포하거나 재배포하는 경우, 그로 인해 발생하는 민원, 분쟁, 손해, 제재, 기타 불이익에 대한 책임은 **전적으로 배포자에게 있습니다**.
- 원저자는 무단 배포, 재배포, 제3자 서비스 운영 및 그 결과로 발생한 문제에 대해 책임지지 않습니다.
- 관련 기관의 요청 또는 운영 정책 변경이 있을 경우, 데이터 수집·사용·공개 범위는 변경되거나 중단될 수 있습니다.

## 주요 기능

### 오늘 탭
- 오늘과 내일의 중식·석식 메뉴를 카드 형태로 표시
- 휴무일, 식단 미등록일에 대한 빈 상태 처리
- 현재 보고 있는 날짜의 식단을 **이미지 또는 텍스트**로 공유 (미리보기에서 모드 전환)
- 공유 파일명: `SNUECafeteria_Menu_yyyyMMdd.png` / `.txt`

### 주간 탭
- 이번 주(월~금) 전체 식단 표시
- 주차 이동(이전/다음 주) 및 스와이프 전환
- 달력으로 원하는 주차 직접 선택
- 데이터 없는 날짜는 달력에서 선택 불가 처리
- 날짜별 식단 카드에서 이미지·텍스트 공유 (오늘 탭과 동일 포맷)

### 홈 화면 위젯
- iPhone · iPad · Mac 홈 화면에서 사용 (소스는 `SNUECafeteriaWidget` 공유)
- Small: 현재 시각 기준 활성 식사(중식 09:00–13:20 / 석식 13:21–18:00, `MealSchedule`과 동일)
- Medium: 오늘 중식·석식
- Large: 오늘·내일 중식·석식
- 위젯 탭 시 앱의 오늘/내일 화면으로 이동 (`snuecafeteria://`)
- App Groups 캐시(`AppGroupMealCache`)로 로드, 캐시 없으면 스켈레톤 플레이스홀더

### 시리 · 단축어 (App Intents)
- iPhone · iPad에서 사용 (macOS 단축어는 이후 과제)
- 지금 식단 조회 (이미지 / 텍스트)
- 특정 날짜 식단 조회 (이미지 / 텍스트 / 중·석식별 텍스트)
- 기간별 식단 조회
- 선택한 탭으로 앱 열기
- 텍스트·이미지 포맷은 앱 공유(`MealShareFormatter` / `MealShareExportView`)와 동일

### 알림 기능
- **중식 알림**: 식단이 있는 날짜에만 지정 시각 로컬 푸시 (기본 11:30)
- **석식 알림**: 식단이 있는 날짜에만 지정 시각 로컬 푸시 (기본 17:30)
- **주간 식단 업데이트 알림**: 매주 월요일 오전 9시
- 시간 피커로 알림 시각 변경
- 알림 권한 안내 모달 (최초 요청 / 거부 시 설정 앱 유도)
- 알림 권한 해제 시 앱 내 알림 설정 자동 OFF 동기화
- 알림 탭 시 앱의 오늘 탭으로 이동

### 설정 탭
- 알림 설정 (중식·석식·주간 알림 ON/OFF, 시각 변경)
- 오픈소스 라이선스 목록

### Apple Watch
- **오늘·내일** / **이번 주(월~일)** 목록 모드 전환 (짧은 페이드, 스크롤 애니메이션 없음)
- 현재 식사로 스크롤 (대상 없으면 오늘 중·석식 glow 폴백)
- iPhone과 WatchConnectivityKit으로 식단 동기화
- iPhone 미연결 시 Firestore REST `runQuery`로 이번 주만 독립 조회
- 알림 탭 시 해당 날짜·식사로 스크롤
- **Smart Stack 위젯** (`SNUECafeteriaWatchWidgetExtension`, `accessoryRectangular`): 오늘 현재 끼니·메뉴 요약, 탭 시 앱 오늘 식단으로 이동 (`snuecafeteria-watch://today`)
- 동기화·캐시 갱신 시 `WidgetCenter.reloadAllTimelines()`로 위젯 타임라인 갱신
- **공유**: 워치 **ShareLink**로 식단 **텍스트** 공유 (메시지·메일 등 — Android 수신자도 본문 읽기 가능)
  - iPhone 경유 WatchConnectivity 릴레이는 `sendMessage` 크래시로 **제거** (별도 서버 릴레이는 보류)
  - 워치 단독 AirDrop·이미지 공유는 Apple이 서드파티에 제공하지 않음
- 툴바: leading 현재 식단 이동 · trailing 오늘/주간 전환 · bottomBar 공유
- Accent color: system blue

### macOS (`SNUECafeteriaMac`)
- 네이티브 SwiftUI 앱 (Catalyst 아님). 스키마: `SNUECafeteriaMac`
- NavigationSplitView로 오늘 / 주간 / 설정
- Firestore·SwiftData 동기화, 로컬 알림, 텍스트·이미지 공유
- **단일 창**: `Window` 씬 + 새 창 메뉴 비활성 · Dock 재오픈 시 기존 창만 전면화 · 마지막 창 닫으면 종료
- **표시 이름**: `CFBundleDisplayName` / `CFBundleName` = `교대학식` · `PRODUCT_NAME`은 ASCII(`SNUECafeteriaMac`) 유지 (한글 PRODUCT_NAME은 CodeSign NFD/NFC 실패)
- **위젯**: iOS와 동일 UI (`SNUECafeteriaWidget` 소스 공유) · ExtensionKit 타깃 `SNUECafeteriaMacWidgetExtension`
- **App Groups**: Mac은 Team ID 접두 `44HRTG996V.com.deblurlab.SNUECafeteriaProject` (iOS `group.`과 별도)
- 오늘·주간 끼니/날짜 전환: **짧은 페이드** (`MealPeriodTransition`)
- 주간 달력·알림 시각: 팝오버 + 컴팩트 피커
- 설정 Form 최대 너비·토글 레이아웃 정리, 오픈소스 목록 스크롤 가능
- 빈 식단: `MealContentUnavailableView` (다크 ContentUnavailable 카드 회피)
- 공유 미리보기: 저장(`NSSavePanel`) + 하단 `ShareLink`, 클립보드 복사용 `ProxyRepresentation`
- 알림 재스케줄 시 **이미 지난 시각은 스킵** (포그라운드 재진입 스팸 방지)
- Watch·App Intents 단축어는 미포함 (이후 과제)
- 최소 배포: macOS 26.0 · 번들 ID: `com.deblurlab.SNUECafeteriaProject.mac`
- Firebase용 `GoogleService-Info.plist`는 로컬 배치 (콘솔에 Mac 번들 등록 권장)

### 플랫폼별 네비게이션
- **iPhone · iPad 오늘**: `TabView` + `.page` — 끼니 가로 스와이프, 페이지 안 세로 스크롤 유지
- **iPhone · iPad 주간**: 3패널 스와이프 + `dragOffset` — 세로 스크롤은 가로 드래그 중에만 잠금
- **macOS 오늘·주간**: 페이드 전환 (스크롤 페이지 전환 없음)
- **watchOS**: 오늘·내일 / 이번 주 모드 전환 (짧은 페이드)

### 데이터 동기화
- Firebase Firestore에서 식단 데이터 수신
- SwiftData로 앱 로컬 캐싱, 네트워크 없이도 최근 데이터 사용 가능
- **iPhone · iPad · Watch**: App Groups로 위젯·App Intents·워치와 식단 캐시 공유 (`group.com.deblurlab…`)
- **macOS**: Team ID App Group으로 앱↔위젯 캐시 공유 (`44HRTG996V.com.deblurlab…`) · Watch/Intents 없음
- 중식·석식 시간대는 `MealSchedule`로 앱·위젯·워치·Intents가 공유
- WatchConnectivityKit으로 iPhone ↔ Apple Watch 식단 동기화
- 앱 포그라운드 진입 시 자동 동기화
- Firestore 스냅샷 리스너로 위젯 타임라인 갱신 (`WidgetCenter.reloadAllTimelines`)
- 네트워크 미연결 시 오류 안내 후 로컬 데이터 표시

## 기술 스택

| 분류 | 사용 기술 |
|------|-----------|
| 언어 | Swift 6 |
| UI | SwiftUI |
| 로컬 저장 | SwiftData |
| 위젯 · 단축어 | WidgetKit, App Intents, App Groups |
| Apple Watch | WatchConnectivityKit |
| 백엔드 | Firebase Firestore, Analytics, Crashlytics |
| 알림 | UserNotifications (로컬 알림) |
| 네트워크 | Network.framework (NWPathMonitor) |
| 최소 배포 타깃 | iOS 26.0 (iPhone·iPad), watchOS 11.0, macOS 26.0 |
| 프로젝트 | Tuist 4.204 |
| 플랫폼 | iOS · iPadOS · watchOS · macOS (네이티브 멀티타깃) |

## 프로젝트 구조

```
SNUECafeteriaProjectiOS/  iPhone·iPad 진입점·Assets·Info·entitlements·Firebase plist
SNUECafeteriaProject/     iOS·iPadOS·macOS 공유 앱 계층 (화면, 동기화, 알림, 공유)
SNUECafeteriaMac/         macOS 진입점·Assets·entitlements·Firebase plist
SNUECafeteriaWidget/      홈 화면 위젯 (iPhone·iPad·Mac 공유 소스)
SNUECafeteriaWatchApp/    Apple Watch 앱
SNUECafeteriaWatchWidget/ Apple Watch Smart Stack 위젯 (accessoryRectangular)
Shared/
  Models/                 CachedDayMeal, MealType, MealSchedule
  Cache/                  AppGroupMealCache
  Intents/                App Intents (iPhone·iPad)
  Sharing/                MealShareFormatter, MealShareExportView, MealShareRelayPayload
  WatchConnectivity/      iPhone ↔ Watch 식단 동기화, iOS 공유 수신 bridge
  Extensions/             View+PlatformChrome, WidgetTimelineReload
Project.swift             Tuist 멀티플랫폼 프로젝트 정의
.github/workflows/        macOS Developer ID 서명·공증·Release
ci/                       exportOptions 등 CI 보조 파일
```

Xcode 프로젝트 파일은 커밋하지 않습니다. `tuist generate`로 생성합니다.

macOS 위젯 확장 번들 ID: `com.deblurlab.SNUECafeteriaProject.mac.widget` (ExtensionKit).

## 프로젝트 생성

```bash
mise install          # tuist 4.204.0
tuist generate        # Xcode workspace 생성
```

Firebase용 `GoogleService-Info.plist`는 저장소에 포함되지 않습니다. 로컬에 두고 `tuist generate`를 실행하세요.

- iPhone · iPad · Watch: `SNUECafeteriaProjectiOS/GoogleService-Info.plist`
- macOS: `SNUECafeteriaMac/GoogleService-Info.plist` (`BUNDLE_ID` = `com.deblurlab.SNUECafeteriaProject.mac`)

서명·리소스 경로는 Xcode에서 수동 수정하지 말고 `Project.swift`에 둡니다. `tuist generate`가 프로젝트를 덮어씁니다.

## macOS GitHub Release (서명·공증)

태그 `mac-v*` 푸시(또는 Actions 수동 실행) 시 `.github/workflows/macos-release.yml`이 Developer ID 서명 → Notary → Release zip을 만듭니다.

```bash
git tag mac-v1.0.0
git push origin mac-v1.0.0
```

필수 Secrets: `MAC_CERTIFICATE_BASE64`, `MAC_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `APP_STORE_CONNECT_API_KEY_ID`, `APP_STORE_CONNECT_API_ISSUER_ID`, `APP_STORE_CONNECT_API_KEY_P8`, `GOOGLE_SERVICE_INFO_PLIST_MAC_BASE64`.  
App Groups용 Developer ID 프로필이 필요하면 `MAC_PROVISION_PROFILE_APP_BASE64` / `MAC_PROVISION_PROFILE_WIDGET_BASE64`도 추가하세요. 상세는 워크플로 파일 상단 주석을 참고하세요.

로컬에서 plist를 base64로 인코딩하는 예:

```bash
base64 -i SNUECafeteriaMac/GoogleService-Info.plist | pbcopy
```

## 라이선스

소스코드 자체는 MIT License를 따릅니다. 자세한 내용은 [LICENSE.md](LICENSE.md)를 참고하세요.

단, 위 라이선스는 서울교육대학교 식단 정보, 학교명, 서비스 맥락을 이용한 앱 배포 또는 서비스 운영에 대한 허가를 의미하지 않습니다. 관련 배포 제한과 책임 범위는 위 **중요 안내** 및 **배포 책임 및 면책** 항목을 따릅니다.
