# Test Cases: PRO Expert Mode Optimization

## Overview
- **Total Test Cases**: 31
- **Based on**: ac.md (16개 AC → 16 happy path + 9 edge cases + 6 non-functional)
- **Features Covered**: 4

---

## Feature 1: 최적화 추천 컬럼 표시

### Entities
- **Primary**: Campaign, Recommendation
- **Related**: Dashboard

### UI Components
- `CampaignList` - 전문가모드 캠페인 목록 컨테이너
- `RecommendationColumn` - 추천 상태 컬럼
- `CampaignRow` - 개별 캠페인 행
- `RecommendationBadge` - 추천 상태 배지/아이콘
- `RecommendationDetailPanel` - 추천 상세 정보 패널

### Happy Path Test Cases

#### TC-1.1: 캠페인 목록에 추천 컬럼 표시
- **AC Reference**: AC 1 - 전문가모드 캠페인 목록에 '광고 최적화 추천' 컬럼이 표시된다
- **Given**:
  - 사용자가 전문가모드 대시보드에 로그인되어 있다
  - 10개의 캠페인이 존재한다
- **When**: 캠페인 목록 페이지가 로드된다
- **Then**:
  - 캠페인 테이블에 '광고 최적화 추천' 컬럼 헤더가 표시된다
  - 각 캠페인 행에 추천 컬럼 셀이 포함된다
  - 기존 컬럼(이름, 상태, 예산 등)은 그대로 유지된다

**UI State Transitions**:
```
Page Load → Fetch Campaigns → Render Table → Display Recommendation Column
```

**API Dependencies**:
- Endpoint: GET /api/campaigns?mode=expert&include=recommendations

---

#### TC-1.2: 캠페인별 추천 상태 표시
- **AC Reference**: AC 2 - 각 캠페인 행에 추천 상태가 표시된다 (추천 있음/없음/진단중)
- **Given**:
  - 사용자가 캠페인 목록을 보고 있다
  - 5개 캠페인: 2개 "추천 있음", 2개 "없음", 1개 "진단중"
- **When**: 추천 컬럼이 렌더링된다
- **Then**:
  - "추천 있음" 캠페인에 해당 상태 텍스트/배지가 표시된다
  - "없음" 캠페인에 빈 상태 또는 "없음" 표시가 나타난다
  - "진단중" 캠페인에 로딩 인디케이터가 표시된다
  - 상태별 색상 구분이 적용된다

**UI State Transitions**:
```
Row Render → Check Status → Display Badge (추천 있음 | 없음 | 진단중)
```

---

#### TC-1.3: 추천 캠페인 시각적 지시자 표시
- **AC Reference**: AC 3 - 추천이 있는 캠페인은 컬럼에 시각적 지시자(아이콘/배지)가 표시된다
- **Given**:
  - 사용자가 캠페인 목록을 보고 있다
  - 3개 캠페인에 활성 추천이 있다
- **When**: 추천 컬럼이 렌더링된다
- **Then**:
  - 추천이 있는 캠페인에 아이콘(예: 전구/별)이 표시된다
  - 아이콘이 눈에 띄는 색상(녹색/주황색)으로 표시된다
  - 여러 추천이 있으면 추천 개수가 배지에 표시된다
  - 추천이 없는 캠페인에는 아이콘이 없거나 흐린 상태로 표시된다

**UI State Transitions**:
```
Render Column → Check hasRecommendations → Display Icon + Count Badge
```

---

#### TC-1.4: 추천 상세 정보 조회
- **AC Reference**: AC 4 - 사용자가 컬럼의 항목을 클릭하면 추천 상세 정보가 표시된다
- **Given**:
  - 사용자가 캠페인 목록을 보고 있다
  - "추천 있음" 상태의 캠페인이 보인다
- **When**: 추천 컬럼의 아이콘/배지를 클릭한다
- **Then**:
  - 추천 상세 패널(모달 또는 드로어)이 열린다
  - 패널에 추천 제목, 설명, 제안 액션이 표시된다
  - "즉시 적용" 또는 "설정 화면으로 이동" 버튼이 포함된다
  - 패널 외부 클릭 시 패널이 닫힌다

**UI State Transitions**:
```
Click Badge → Fetch Details → Display Panel
                            ↘ Show Error (if fetch fails)
```

**API Dependencies**:
- Endpoint: GET /api/campaigns/:campaignId/recommendations

---

### Edge Cases

#### TC-1.E1: 추천 데이터 로딩 중 표시
- **Scenario**: 캠페인 데이터는 로드되었으나 추천 데이터는 아직 로딩 중
- **Given**: 사용자가 대시보드에 접속했다
- **When**: 캠페인 목록은 렌더링되었으나 추천 API 응답이 지연된다
- **Then**:
  - 캠페인 목록은 정상 표시된다
  - 추천 컬럼에 스켈레톤/스피너가 표시된다
  - 로딩 완료 후 페이지 새로고침 없이 상태가 업데이트된다

#### TC-1.E2: 추천 API 실패 시 에러 처리
- **Scenario**: 추천 서비스가 다운되었다
- **Given**: 사용자가 캠페인 목록을 보고 있다
- **When**: 추천 API가 500 에러를 반환한다
- **Then**:
  - 캠페인 목록은 정상 렌더링된다
  - 추천 컬럼에 "불러오기 실패" 상태와 재시도 버튼이 표시된다
  - 재시도 버튼 클릭 시 다시 요청이 전송된다

---

## Feature 2: 진단 및 추천 생성

### Entities
- **Primary**: Recommendation, DiagnosticResult
- **Related**: Campaign

### UI Components
- `DiagnosticStatus` - 진단 진행 상태 표시
- `RecommendationList` - 추천 목록 컨테이너
- `RecommendationCard` - 개별 추천 카드
- `PriorityBadge` - 우선순위 배지

### Happy Path Test Cases

#### TC-2.1: 캠페인 진단 수행
- **AC Reference**: AC 1 - 각 캠페인의 설정, 예산 소진율, 성과 지표가 분석되어 진단이 수행된다
- **Given**:
  - 캠페인이 7일 이상 운영 중이다
  - 예산, 소진율, 성과 데이터가 존재한다
- **When**: 진단이 트리거된다 (페이지 로드 또는 백그라운드)
- **Then**:
  - 진단 상태가 "진단중"으로 표시된다
  - 완료 시 "추천 있음" 또는 "이상 없음"으로 상태가 변경된다
  - UI가 자동으로 업데이트된다

**UI State Transitions**:
```
Trigger → 진단중 (spinner) → 완료 (추천 생성 or 이상 없음)
```

**API Dependencies**:
- Endpoint: POST /api/campaigns/:id/diagnose

---

#### TC-2.2: 우선순위별 액션 아이템 생성
- **AC Reference**: AC 2 - 진단 결과 우선순위가 높은 액션 아이템이 생성된다
- **Given**:
  - 진단이 5개 이슈를 발견했다
  - 이슈별 영향도가 다르다 (높음/중간/낮음)
- **When**: 추천 목록이 표시된다
- **Then**:
  - 추천이 우선순위 순서로 정렬된다 (높음 → 중간 → 낮음)
  - 높은 우선순위 항목에 시각적 구분이 적용된다 (빨강/주황 배지)
  - 각 항목에 예상 영향도가 표시된다

**UI State Transitions**:
```
Fetch Recommendations → Sort by Priority → Render Sorted List
```

---

#### TC-2.3: 캠페인별 개별 추천 표시
- **AC Reference**: AC 3 - 추천은 캠페인별로 개별적으로 표시된다
- **Given**:
  - 사용자가 10개 캠페인을 보유하고 있다
  - 3개 캠페인에 추천이 있다
- **When**: 캠페인 목록이 렌더링된다
- **Then**:
  - 각 캠페인 행에 해당 캠페인의 추천만 표시된다
  - 캠페인 A의 추천을 클릭하면 캠페인 A의 추천만 상세 표시된다
  - 추천이 캠페인 간 합산되지 않는다

**UI State Transitions**:
```
View List → Click Campaign Rec → Fetch Campaign-Specific Recs → Display
```

---

#### TC-2.4: 다중 추천 우선순위 정렬
- **AC Reference**: AC 4 - 같은 캠페인에 여러 추천이 있으면 우선순위 순서로 정렬되어 표시된다
- **Given**:
  - 캠페인 "Spring Sale"에 4개 추천이 있다
  - 우선순위: 높음 2개, 중간 1개, 낮음 1개
- **When**: 해당 캠페인의 추천 상세를 연다
- **Then**:
  - 높음 우선순위 추천이 최상단에 표시된다
  - 각 추천에 우선순위 배지가 표시된다
  - 낮은 우선순위는 하단에 배치된다

**UI State Transitions**:
```
Open Details → Fetch Recs → Sort (높음 → 낮음) → Render Sorted List
```

---

### Edge Cases

#### TC-2.E1: 진단 타임아웃
- **Scenario**: 진단 엔진 응답이 30초를 초과한다
- **Given**: 사용자가 진단을 트리거했다
- **When**: 30초 타임아웃이 발생한다
- **Then**:
  - "진단 시간이 초과되었습니다" 메시지가 표시된다
  - 재시도 버튼이 표시된다
  - 상태는 "진단중"으로 유지되며 마지막 시도 시간이 표시된다

#### TC-2.E2: 이상 없음 (추천 없음)
- **Scenario**: 캠페인이 최적 상태이다
- **Given**: 진단이 성공적으로 완료되었다
- **When**: 분석 결과 이슈가 없다
- **Then**:
  - 추천 컬럼에 "이상 없음" 또는 체크마크 아이콘이 표시된다
  - 클릭 시 "현재 최적화된 상태입니다" 메시지가 표시된다

---

## Feature 3: 추천 액션 실행

### Entities
- **Primary**: Recommendation
- **Related**: Campaign, SettingsPage

### UI Components
- `RecommendationDetailPanel` - 추천 상세 패널
- `ApplyButton` - 즉시 적용 버튼
- `NavigationLink` - 설정 화면 이동 링크
- `SuccessToast` - 성공 토스트 메시지
- `StatusBadge` - 완료/미완료 상태 배지

### Happy Path Test Cases

#### TC-3.1: 설정 화면으로 이동
- **AC Reference**: AC 1 - 추천 항목을 클릭하면 해당 설정 화면으로 이동한다
- **Given**:
  - 사용자가 "예산 증액 권장" 추천을 보고 있다
  - 추천 액션 타입이 "navigate"이다
- **When**: 추천 항목을 클릭한다
- **Then**:
  - 해당 캠페인의 예산 설정 화면으로 이동한다
  - 관련 설정 필드가 하이라이트되거나 스크롤된다
  - 추천 맥락이 유지된다 (예: 권장 값 표시)

**UI State Transitions**:
```
Click Recommendation → Navigate → Settings Page → Highlight Field
```

---

#### TC-3.2: 원클릭 즉시 적용
- **AC Reference**: AC 2 - 일부 추천은 "즉시 적용" 버튼으로 원클릭 적용이 가능하다
- **Given**:
  - 사용자가 "키워드 추가" 추천을 보고 있다
  - 추천 액션 타입이 "apply_instantly"이다
- **When**: "즉시 적용" 버튼을 클릭한다
- **Then**:
  - 확인 모달이 표시된다: "이 추천을 적용하시겠습니까?"
  - 확인 클릭 시 API 호출이 실행된다
  - 성공 시 토스트 메시지가 표시된다
  - 추천 상태가 "완료"로 변경된다

**UI State Transitions**:
```
Click "즉시 적용" → Confirm Modal → API Call → Success Toast → Update Status
                                             ↘ Error Toast (if fails)
```

**API Dependencies**:
- Endpoint: POST /api/recommendations/:id/apply

---

#### TC-3.3: 성공 메시지 표시
- **AC Reference**: AC 3 - 사용자가 추천을 적용하면 성공 메시지가 2초 동안 표시된다
- **Given**:
  - 사용자가 추천을 성공적으로 적용했다
- **When**: API가 성공 응답을 반환한다
- **Then**:
  - 우측 상단에 "추천이 적용되었습니다" 토스트가 표시된다
  - 토스트에 체크마크 아이콘이 포함된다
  - 정확히 2초 후 토스트가 자동으로 사라진다

**UI State Transitions**:
```
API Success → Show Toast (2s timer) → Fade Out → Hide
```

---

#### TC-3.4: 적용 후 상태 업데이트
- **AC Reference**: AC 4 - 적용된 추천의 상태가 업데이트되어 표시된다 (완료/미완료)
- **Given**:
  - 사용자가 추천을 성공적으로 적용했다
- **When**: 성공 응답 수신 후
- **Then**:
  - 추천 상태가 "대기"에서 "완료"로 변경된다
  - "완료" 배지가 추천 옆에 표시된다
  - 적용 시간이 표시된다 (예: "2분 전 적용됨")
  - 완료된 추천은 시각적으로 흐리게 처리되거나 하단으로 이동한다

**UI State Transitions**:
```
Apply Success → Update Local State → Re-render List → Show "완료" Badge
```

---

### Edge Cases

#### TC-3.E1: 적용 API 실패
- **Scenario**: 백엔드가 추천 적용에 실패한다
- **Given**: 사용자가 "즉시 적용"을 클릭하고 확인했다
- **When**: API가 500 에러를 반환한다
- **Then**:
  - 에러 토스트가 표시된다: "추천 적용에 실패했습니다. 다시 시도해주세요."
  - 추천 상태가 변경되지 않는다
  - 재시도 버튼이 표시된다

#### TC-3.E2: 확인 모달 취소
- **Scenario**: 사용자가 적용 전 취소한다
- **Given**: "즉시 적용" 클릭 후 확인 모달이 표시되었다
- **When**: "취소" 버튼을 클릭하거나 모달 외부를 클릭한다
- **Then**:
  - 모달이 닫힌다
  - API 호출이 발생하지 않는다
  - 추천 상태가 변경되지 않는다

#### TC-3.E3: 중복 적용 방지
- **Scenario**: 사용자가 이미 적용된 추천을 다시 적용하려 한다
- **Given**: 추천 상태가 "완료"이다
- **When**: 사용자가 "즉시 적용" 버튼을 클릭한다
- **Then**:
  - 버튼이 비활성화되어 있거나 표시되지 않는다
  - 또는 "이미 적용된 추천입니다" 메시지가 표시된다

---

## Feature 4: 사용자 경험

### Entities
- **Primary**: Dashboard
- **Related**: Campaign, UserPreference

### UI Components
- `DashboardLayout` - 메인 대시보드 컨테이너
- `ColumnToggle` - 컬럼 표시/숨김 토글
- `AsyncLoader` - 비동기 데이터 로더
- `RealtimeUpdater` - 실시간 갱신 컴포넌트

### Happy Path Test Cases

#### TC-4.1: 기존 레이아웃 유지
- **AC Reference**: AC 1 - 기존 캠페인 목록 레이아웃은 유지되고 새 컬럼만 추가된다
- **Given**:
  - 사용자가 기존 대시보드를 사용해왔다
  - 기존 컬럼: 이름, 상태, 예산, 소진액, 성과
- **When**: 추천 기능이 활성화된 상태로 대시보드를 연다
- **Then**:
  - 기존 모든 컬럼이 원래 위치에 유지된다
  - 추천 컬럼이 추가된다
  - 컬럼 너비가 비례적으로 자동 조정된다
  - 기존 컬럼이 제거되거나 순서가 변경되지 않는다

**UI State Transitions**:
```
Load Dashboard → Render Existing Columns → Insert Recommendation Column → Adjust Widths
```

---

#### TC-4.2: 컬럼 숨김 옵션
- **AC Reference**: AC 2 - 추천 기능은 선택적으로 숨길 수 있다 (컬럼 숨김 옵션)
- **Given**:
  - 사용자가 캠페인 목록을 보고 있다
  - 추천 컬럼이 표시 중이다
- **When**: 컬럼 설정에서 "광고 최적화 추천"을 비활성화한다
- **Then**:
  - 추천 컬럼이 숨겨진다
  - 다른 컬럼이 확장되어 공간을 채운다
  - 설정이 저장되어 페이지 새로고침 후에도 유지된다
  - 다시 활성화하면 컬럼이 표시된다

**UI State Transitions**:
```
Click Settings → Toggle Off → Hide Column → Save Preference → Re-layout
```

**API Dependencies**:
- Endpoint: PUT /api/users/preferences

---

#### TC-4.3: 비동기 추천 데이터 로드
- **AC Reference**: AC 3 - 대시보드 로드 시 추천 데이터는 별도로 비동기 로드된다
- **Given**:
  - 사용자가 대시보드에 접속한다
  - 캠페인 데이터 로드 200ms, 추천 데이터 로드 1.5s
- **When**: 페이지가 로드된다
- **Then**:
  - 캠페인 목록이 즉시 렌더링된다
  - 추천 컬럼에 로딩 스켈레톤이 표시된다
  - 1.5초 후 추천 데이터가 채워진다
  - 전체 페이지 리로드나 UI 블로킹이 발생하지 않는다

**UI State Transitions**:
```
Page Load → Render Campaigns → Show Rec Skeleton → Fetch Recs (async) → Update Column
```

---

#### TC-4.4: 실시간 추천 갱신
- **AC Reference**: AC 4 - 페이지 이동 없이 추천 정보가 실시간으로 갱신된다
- **Given**:
  - 사용자가 캠페인 목록을 보고 있다
  - 백그라운드에서 새로운 추천이 생성된다
- **When**: 추천 상태가 변경된다 (예: 진단 완료)
- **Then**:
  - 추천 컬럼이 자동으로 업데이트된다
  - 새로운 "추천 있음" 배지가 페이지 새로고침 없이 나타난다
  - 부드러운 전환 애니메이션이 적용된다

**UI State Transitions**:
```
Idle → Background Update → Detect Change → Animate Transition → Update UI
```

**API Dependencies**:
- Polling: GET /api/campaigns/recommendations/updates?since={timestamp}

---

### Edge Cases

#### TC-4.E1: 컬럼 설정 저장 실패
- **Scenario**: 사용자 설정 저장 API가 실패한다
- **Given**: 사용자가 추천 컬럼을 숨김으로 변경했다
- **When**: 설정 저장 API가 실패한다
- **Then**:
  - "설정 저장에 실패했습니다" 경고 토스트가 표시된다
  - 컬럼 상태는 변경되지만 새로고침 시 원래 상태로 복원된다

#### TC-4.E2: 실시간 갱신 연결 끊김
- **Scenario**: 폴링/WebSocket 연결이 끊어진다
- **Given**: 사용자가 대시보드를 보고 있다
- **When**: 네트워크 연결이 일시적으로 끊긴다
- **Then**:
  - "연결 끊김" 인디케이터가 표시된다
  - 자동 재연결을 시도한다
  - 재연결 실패 시 수동 새로고침 버튼이 표시된다

---

## Non-Functional Test Scenarios

### Performance (from nfr.md)

#### TC-P1: 진단 API 응답 시간
- **NFR Reference**: 진단 응답 시간 - 캠페인당 평균 500ms, P99 1s 이내
- **Test**: 100개 캠페인에 대해 진단 API 호출
- **Pass Criteria**: 평균 응답 시간 ≤ 500ms, P99 ≤ 1s

#### TC-P2: 추천 컬럼 렌더링 시간
- **NFR Reference**: UI 렌더링 - 추천 컬럼 렌더링 500ms 이내
- **Test**: 데이터 수신 후 컬럼 렌더링 완료까지 시간 측정
- **Pass Criteria**: 렌더링 시간 ≤ 500ms

#### TC-P3: 페이지 로드 시간 증가율
- **NFR Reference**: 페이지 로드 - 기존 대비 20% 이상 증가하지 않음
- **Test**: 추천 기능 유/무에 따른 로드 시간 비교
- **Pass Criteria**: 로드 시간 증가 ≤ 20%

### Accessibility

#### TC-A1: 키보드 네비게이션
- **Test**: 키보드만으로 추천 컬럼 인터랙션
- **Pass Criteria**: Tab, Enter, Esc로 모든 기능 접근 가능

#### TC-A2: 스크린 리더 호환
- **Test**: 스크린 리더로 추천 상태 및 상세 정보 읽기
- **Pass Criteria**: 모든 추천 데이터가 올바르게 음성 출력

### Security (from nfr.md)

#### TC-S1: 타 사용자 추천 접근 차단
- **NFR Reference**: 접근 제어 - 자신의 캠페인 추천만 확인 가능
- **Test**: 다른 사용자의 캠페인 추천 API 요청
- **Pass Criteria**: 403 Forbidden 반환

---

**Sources**:
- AC: pro-expert-mode-optimization ac.md (16개 AC)
- NFR: pro-expert-mode-optimization nfr.md

*Generated*: 2026-02-02
