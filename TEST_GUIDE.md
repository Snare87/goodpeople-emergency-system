# 🧪 테스트 실행 가이드

## 📋 준비사항
1. Node.js 설치 확인
2. 의존성 설치 완료 (`npm install`)

## 🚀 테스트 실행 방법

### Windows (PowerShell/CMD)
```bash
# 프로젝트 루트에서
.\run-tests.bat

# 또는 직접 실행
cd packages\web-dashboard
npm test -- --watchAll=false
```

### Mac/Linux
```bash
# 프로젝트 루트에서
chmod +x run-tests.sh
./run-tests.sh

# 또는 직접 실행
cd packages/web-dashboard
npm test -- --watchAll=false
```

## 🎯 테스트 옵션

### 특정 테스트만 실행
```bash
# CallService 테스트만 실행
npm test CallService

# 특정 describe 블록만 실행
npm test -- -t "재난 수락 기능"
```

### 테스트 커버리지 확인
```bash
npm test -- --coverage --watchAll=false
```

### Watch 모드로 실행 (개발 중)
```bash
npm test
# 파일 변경 시 자동으로 테스트 재실행
```

## 📊 현재 테스트 현황

### `callService.test.ts`
- ✅ **재난 수락 기능 (acceptCall)**
  - 정상적으로 재난을 수락할 수 있어야 함
  - Firebase Functions 에러를 적절히 처리해야 함
  - 호출이 취소된 재난은 수락할 수 없어야 함
  - 로그인하지 않은 사용자는 수락할 수 없어야 함
  - 동시에 여러 명이 수락 시도시 한 명만 성공해야 함

- ✅ **재난 취소 기능 (cancelCall)**
  - 정상적으로 재난 호출을 취소할 수 있어야 함
  - 권한이 없는 사용자는 취소할 수 없어야 함
  - 이미 수락된 재난은 취소할 수 없어야 함

- ✅ **전체 시나리오 테스트**
  - 재난 발생부터 완료까지 전체 프로세스가 정상 동작해야 함
  - 호출 취소 프로세스가 정상 동작해야 함

## 🔧 트러블슈팅

### 테스트 실패 시
1. **모킹 확인**: Firebase Functions가 제대로 모킹되었는지 확인
2. **의존성 확인**: `node_modules` 재설치 (`npm ci`)
3. **캐시 정리**: `npm test -- --clearCache`

### 타입 에러 발생 시
```bash
# TypeScript 타입 체크
npm run type-check
```

## 📝 새로운 테스트 추가하기

```typescript
// 새로운 테스트 케이스 템플릿
it('새로운 기능이 정상 동작해야 함', async () => {
  // Given: 테스트 환경 설정
  const mockCallable = jest.fn().mockResolvedValue({
    data: { success: true }
  });
  (httpsCallable as jest.Mock).mockReturnValue(mockCallable);

  // When: 기능 실행
  const result = await someFunction();

  // Then: 결과 검증
  expect(mockCallable).toHaveBeenCalled();
  expect(result).toBeDefined();
});
```

## 💡 테스트 작성 팁

1. **AAA 패턴 사용**: Arrange(준비), Act(실행), Assert(검증)
2. **의미 있는 테스트 이름**: 무엇을 테스트하는지 명확히 작성
3. **엣지 케이스 고려**: 성공/실패 케이스 모두 테스트
4. **독립적인 테스트**: 각 테스트는 다른 테스트에 영향을 주지 않아야 함

---

**Happy Testing! 🎉**
