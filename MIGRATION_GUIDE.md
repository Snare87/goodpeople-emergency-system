# 다중 후보자 시스템 마이그레이션 가이드

## 개요
기존 단일 대원 배정 시스템에서 다중 후보자 시스템으로 전환하는 가이드입니다.

## 시스템 비교

### 구 시스템 (단일 대원)
- 한 번에 한 명의 대원만 수락 가능
- 먼저 수락한 대원이 자동 배정
- 필드: `responder`

### 새 시스템 (다중 후보자)
- 여러 대원이 동시에 수락 가능
- 상황실에서 최적 대원 선택
- 필드: `candidates`, `selectedResponder`

## 데이터 구조

### Call 객체
```javascript
{
  id: string,
  eventType: string,
  address: string,
  location: { lat: number, lng: number },
  status: 'idle' | 'dispatched' | 'accepted' | 'completed',
  
  // 다중 후보자 시스템
  candidates: {
    [userId]: {
      userId: string,
      name: string,
      position: string,
      rank: string,
      acceptedAt: number,
      routeInfo: {
        distance: number,        // 미터
        distanceText: string,    // "2.3km"
        duration: number,        // 초
        durationText: string,    // "15분"
        calculatedAt: number
      }
    }
  },
  
  selectedResponder: {
    // candidates와 동일 + selectedAt
  }
}
```

## 마이그레이션 절차

### 1. 현재 시스템 상태 확인
```bash
check-status.bat
```

### 2. 데이터 백업 및 마이그레이션
```bash
migrate-system.bat
```

### 3. 시스템 테스트
```bash
test-system.bat
```

### 4. 문제 발생 시 롤백
```bash
cd scripts\migration
node rollback-candidates-system.js <백업_타임스탬프>
```

## 주요 변경사항

### 웹 대시보드
- ✅ `CallsList.tsx`: 새 상태 표시
- ✅ `CandidatesInfo.tsx`: 후보자 목록 및 선택
- ✅ `callService.ts`: 새 데이터 구조 지원

### 모바일 앱
- ✅ `improved_call_acceptance_service.dart`: 다중 후보자 등록
- ✅ 데이터 구조 통일 (객체 형태)
- ❌ `incident_candidate_service.dart`: 제거 필요

## 운영 시나리오

### 1. 재난 발생 및 호출
1. 상황실에서 "호출하기" 클릭
2. 상태: `idle` → `dispatched`

### 2. 대원들 수락
1. 여러 대원이 동시에 수락 가능
2. 각 대원의 위치/경로 정보 자동 계산
3. `candidates` 객체에 추가

### 3. 대원 선택
1. 상황실에서 후보자 목록 확인
2. 최적 대원 선택 (거리, 자격증 등 고려)
3. 상태: `dispatched` → `accepted`
4. `selectedResponder` 설정

### 4. 유연한 운영
- 선택 취소 가능
- 추가 대원 배정 가능
- 후보자 목록 유지

## 주의사항

1. **Firebase 규칙 업데이트 필요**
   - `candidates` 필드 쓰기 권한
   - `selectedResponder` 필드 쓰기 권한

2. **모바일 앱 업데이트 필수**
   - 새로운 서비스 사용
   - 구 서비스 제거

3. **실시간 모니터링**
   - Firebase Console에서 데이터 변경 확인
   - 에러 로그 모니터링

## 문제 해결

### Q: 마이그레이션 후 데이터가 사라졌어요
A: 백업에서 복원하세요:
```bash
cd scripts\migration
node rollback-candidates-system.js
```

### Q: 대원 선택이 안 돼요
A: 다음을 확인하세요:
1. Firebase 규칙
2. 콘솔 에러 메시지
3. 네트워크 연결

### Q: 구 시스템과 새 시스템이 혼재되어 있어요
A: `migrate-system.bat` 재실행

## 연락처
문제 발생 시 개발팀에 문의하세요.
