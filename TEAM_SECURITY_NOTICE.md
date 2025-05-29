# 📢 보안 공지: API 키 노출 대응

**날짜**: 2025년 5월 30일  
**심각도**: 🔴 높음  
**영향 범위**: 전체 개발팀

## 🚨 상황

GitGuardian에서 GitHub 저장소에 5개의 API 키가 노출된 것을 감지했습니다.

## ✅ 조치 완료 사항

1. **노출된 파일들을 Git에서 제거**
2. **.gitignore 업데이트**로 재발 방지
3. **보안 가이드 문서** 작성
4. **예제 파일** 생성

## 🎯 팀원 필수 작업

### 1. 최신 코드 받기
```bash
git pull origin main
```

### 2. 환경 설정 파일 생성

#### Web Dashboard (.env)
```bash
cd packages/web-dashboard
cp .env.example .env
# 편집기로 .env 열어서 새 API 키 입력
```

#### Mobile Responder (.env)
```bash
cd packages/mobile-responder  
cp .env.example .env
# 편집기로 .env 열어서 새 API 키 입력
```

### 3. Firebase 설정 재생성
```bash
# Flutter 프로젝트 디렉토리에서
cd packages/mobile-responder
flutterfire configure

# iOS 개발자는 추가로:
# Firebase Console에서 GoogleService-Info.plist 다운로드
# ios/Runner 폴더에 복사
```

### 4. 새 API 키 받기

다음 채널을 통해 새 API 키를 전달받으세요:
- [ ] Slack DM
- [ ] 팀 미팅
- [ ] 보안 이메일

## ⚠️ 주의사항

**절대 하지 말아야 할 것들:**
- ❌ API 키를 코드에 하드코딩
- ❌ .env 파일을 Git에 커밋
- ❌ Firebase 설정 파일을 Git에 커밋
- ❌ API 키를 공개 채널에 공유

**항상 해야 할 것들:**
- ✅ .env.example을 참고하여 .env 생성
- ✅ git status로 커밋 전 확인
- ✅ API 키는 안전한 채널로만 공유

## 📚 참고 문서

- `API_KEY_SECURITY_GUIDE.md` - 일반 API 키 보안
- `FIREBASE_SECURITY_GUIDE.md` - Firebase 보안 설정
- `.env.example` 파일들 - 환경변수 템플릿

## 🆘 문의

문제가 있으면 보안 담당자에게 연락하세요.

---

**이 공지를 확인했다면 Slack에 ✅ 이모지로 확인 부탁드립니다.**