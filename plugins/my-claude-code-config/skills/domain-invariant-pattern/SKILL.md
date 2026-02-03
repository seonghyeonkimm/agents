---
name: domain-invariant-pattern
description: |
  도메인 불변식(Invariant)을 재사용 가능한 헬퍼 함수로 추출하는 패턴.
  Use when: Entity 설계 시 비즈니스 규칙 추출, 테스트 케이스에서 조건 식별,
  UI/API/테스트에서 동일 로직 재사용이 필요할 때.
globs:
  - "**/_models/**/*.ts"
  - "**/models/**/*.ts"
  - "**/domain/**/*.ts"
---

# Domain Invariant Pattern

도메인 불변식을 헬퍼 함수로 추출하여 UI, API, 테스트에서 재사용하는 패턴.

## 헬퍼 함수 유형

| 접두사 | 용도 | 반환 타입 | 예시 |
|--------|------|-----------|------|
| `is*` | 상태 조건 체크 | `boolean` | `isMaximizeConversionsBidding()` |
| `get*` | 불변식 고려한 파생값 | 도메인 타입 | `getDailyBudget()` |
| `can*` | 행동 가능 여부 | `boolean` | `canEditDailyBudget()` |
| `should*` | 조건부 동작 체크 | `boolean` | `shouldShowBudgetWarning()` |

## Given/When/Then에서 추출

```
Given 분석 → is* (상태 조건)
When 분석  → can* (가능 조건)
Then 분석  → get*, should* (파생값, 동작 조건)
```

**예시:**
| # | Given | When | Then | 추출 헬퍼 |
|---|-------|------|------|-----------|
| 1 | 입찰 전략이 "전환수 최대화" | 일예산 수정 시도 | 필드 비활성화 | `isMaximizeConversionsBidding`, `canEditDailyBudget` |
| 2 | 일예산 < 일소진액×3 | 대시보드 진입 | 경고 표시 | `shouldShowBudgetWarning` |

## 의존성 순서 (Layer)

```
Layer 1 (Base): is* 함수들 (의존성 없음)
    ↓
Layer 2 (Derived): can*, get* (is* 의존)
    ↓
Layer 3 (Composite): should* (여러 함수 조합)
```

```typescript
// Layer 1
function isMaximizeConversionsBidding(adGroup: AdGroup): boolean {
  return adGroup.biddingType === 'MAXIMIZE_CONVERSIONS';
}

// Layer 2 (Layer 1 사용)
function canEditDailyBudget(adGroup: AdGroup): boolean {
  return !isMaximizeConversionsBidding(adGroup);
}

function getDailyBudget(adGroup: AdGroup): number | null {
  if (isMaximizeConversionsBidding(adGroup)) return null;
  return adGroup.dailyBudget;
}

// Layer 3 (Layer 1, 2 사용)
function shouldShowBidSettings(adGroup: AdGroup, campaign: Campaign): boolean {
  return canEditDailyBudget(adGroup) && campaign.status !== 'PAUSED';
}
```

## 사용 위치별 예시

### UI 렌더링

```tsx
function DailyBudgetField({ adGroup }: Props) {
  const disabled = !canEditDailyBudget(adGroup);
  const value = getDailyBudget(adGroup);

  return (
    <NumberInput
      value={value}
      disabled={disabled}
      placeholder={disabled ? "자동 설정" : "금액 입력"}
    />
  );
}
```

### API 요청 Body

```typescript
function buildUpdateRequest(adGroup: AdGroup): UpdateRequest {
  return {
    id: adGroup.id,
    ...(shouldIncludeBidAmount(adGroup) && { bidAmount: adGroup.bidAmount }),
    dailyBudget: getDailyBudget(adGroup),
  };
}
```

### 테스트 코드

```typescript
describe('일예산 수정', () => {
  it('전환수 최대화 입찰이면 수정 불가', () => {
    const adGroup = createAdGroup({ biddingType: 'MAXIMIZE_CONVERSIONS' });

    expect(canEditDailyBudget(adGroup)).toBe(false);
    expect(getDailyBudget(adGroup)).toBeNull();
  });
});
```

## 파일 구조

Entity 파일 내부에 헬퍼 함수를 함께 정의:

```typescript
// src/domain/AdGroup.ts (또는 _models/AdGroup.ts)

// Entity 타입
export interface AdGroup {
  id: string;
  biddingType: BiddingType;
  dailyBudget: number;
}

// ===== Invariant Helpers =====

export function isMaximizeConversionsBidding(adGroup: AdGroup): boolean {
  return adGroup.biddingType === 'MAXIMIZE_CONVERSIONS';
}

export function canEditDailyBudget(adGroup: AdGroup): boolean {
  return !isMaximizeConversionsBidding(adGroup);
}

export function getDailyBudget(adGroup: AdGroup): number | null {
  if (isMaximizeConversionsBidding(adGroup)) return null;
  return adGroup.dailyBudget;
}
```

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| 헬퍼 함수 중복 | UI/API에서 각각 구현 | 공통 invariants.ts에 정의 |
| 조건 불일치 | 같은 규칙을 다르게 해석 | Single Source of Truth 원칙 |
| 테스트 누락 | 헬퍼 함수를 테스트 안 함 | 헬퍼 함수별 단위 테스트 필수 |
| 의존성 순환 | is* 함수가 can* 함수 호출 | Layer 구조 준수 |
| 과도한 추상화 | 모든 조건을 헬퍼로 추출 | 재사용되는 경우만 추출 |
