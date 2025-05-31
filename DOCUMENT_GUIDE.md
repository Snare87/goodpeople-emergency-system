# 📝 프로젝트 문서 관리 가이드

## 정기적으로 업데이트해야 할 파일들

### 1. PROJECT_CONTEXT.md (가장 중요!)
**언제 업데이트**: 
- 새로운 기능 추가할 때
- 데이터 구조 변경할 때
- 새로운 문제/해결법 발견할 때
- 작업 완료할 때마다

**업데이트할 섹션**:
- `💾 데이터베이스 구조` - Firebase 구조 변경 시
- `🐛 자주 발생하는 문제와 해결법` - 새로운 에러 해결 시
- `📝 작업 로그` - 매일 작업 후
- `🔑 핵심 변경사항` - 중요한 변경 시

### 2. CLAUDE_START.md
**언제 업데이트**: 
- 프로젝트 구조 크게 변경될 때
- 새로운 중요 파일 추가될 때

### 3. README.md
**언제 업데이트**:
- 새로운 기능 추가
- 새로운 문서 생성
- 의존성 변경

## 업데이트 예시

### PROJECT_CONTEXT.md에 새 작업 추가하기
```markdown
### 2025년 2월 1일
- ✅ 푸시 알림 시스템 구현
- ✅ FCM 토큰 관리 추가
- 🐛 문제: FCM 토큰 중복 문제 → 해결: Set 사용
```

### 새로운 데이터 필드 추가 시
```markdown
// PROJECT_CONTEXT.md의 데이터베이스 구조 섹션에 추가
"fcmToken": "string (optional)",  // 푸시 알림용 토큰
"lastNotificationAt": "timestamp (optional)"
```

## 🎯 팁

1. **매일 작업 끝날 때** PROJECT_CONTEXT.md 업데이트하기
2. **큰 변경사항**은 별도 문서로 만들기 (예: PUSH_NOTIFICATION_GUIDE.md)
3. **에러 해결**할 때마다 해결법 기록하기
4. **Claude와 대화 내용 중 중요한 것**은 바로 기록하기

## Git 커밋 메시지와 함께
```bash
git add PROJECT_CONTEXT.md
git commit -m "docs: 2025-02-01 작업 내용 업데이트"
```

---

기억하세요: 문서는 미래의 나와 Claude를 위한 것입니다! 📚
