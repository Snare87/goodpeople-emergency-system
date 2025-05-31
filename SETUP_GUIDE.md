# 다중 후보자 시스템 설정 가이드

## 🚀 빠른 시작

### 옵션 1: 자동 마이그레이션 (추천)
```bash
# 1. 빠른 체크
quick-check.bat

# 2. Firebase Admin 설치 (필요시)
install-admin.bat

# 3. 시스템 상태 확인
check-status.bat

# 4. 마이그레이션 실행
migrate-system.bat

# 5. 테스트
test-system.bat
```

### 옵션 2: 수동 설정
1. Firebase Console에서 규칙 업데이트 ([가이드](FIREBASE_RULES_UPDATE.md))
2. 웹/모바일 앱에서 직접 테스트 ([가이드](MANUAL_TEST_GUIDE.md))

## 📁 파일 구조
```
C:\goodpeople-emergency-system\
├── quick-check.bat          # 시스템 빠른 체크
├── install-admin.bat        # Firebase Admin SDK 설치
├── check-status.bat         # 현재 시스템 상태 확인
├── migrate-system.bat       # 데이터 마이그레이션
├── test-system.bat          # 시스템 테스트
├── MIGRATION_GUIDE.md       # 상세 마이그레이션 가이드
├── FIREBASE_RULES_UPDATE.md # Firebase 규칙 업데이트 가이드
└── MANUAL_TEST_GUIDE.md     # 수동 테스트 가이드
```

## 🔑 중요 사항

### Firebase 서비스 계정 키
자동 마이그레이션을 위해서는 서비스 계정 키가 필요합니다:
1. [Firebase Console](https://console.firebase.google.com) → 프로젝트 설정
2. 서비스 계정 → 새 비공개 키 생성
3. `firebase-admin-key.json`으로 저장

### Firebase 규칙
반드시 Firebase 규칙을 먼저 업데이트하세요!
- 파일: `firebase-rules-updated.json`
- 가이드: [FIREBASE_RULES_UPDATE.md](FIREBASE_RULES_UPDATE.md)

## 🎯 주요 변경사항
- 단일 대원 시스템 → 다중 후보자 시스템
- 상황실에서 최적 대원 선택 가능
- 유연한 배정 관리 (취소, 재선택)

## ❓ 문제 해결
- Firebase Admin 키가 없다면 → 수동 테스트 진행
- 마이그레이션 실패 시 → 롤백 기능 사용
- 선택 버튼이 작동하지 않는다면 → Firebase 규칙 확인

## 📞 지원
문제 발생 시 개발팀에 문의하세요.
