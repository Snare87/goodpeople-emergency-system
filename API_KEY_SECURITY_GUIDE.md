# 🔐 API 키 보안 가이드

## 🚨 긴급 조치 사항 (2025-05-30)

GitGuardian에서 API 키 노출을 감지했습니다. 다음 조치를 즉시 실행하세요:

### 1. 노출된 API 키 즉시 무효화

각 서비스 콘솔에 접속하여 노출된 키를 무효화하세요:

- **Google Cloud Console**: https://console.cloud.google.com/apis/credentials
- **Firebase Console**: https://console.firebase.google.com/project/goodpeople-95f54/settings/general
- **Kakao Developers**: https://developers.kakao.com/console/app
- **T Map**: https://openapi.sk.com/

### 2. 새 API 키 생성 및 보안 설정

#### Google Maps API 키:
1. 새 API 키 생성
2. **Application restrictions** 설정:
   - HTTP referrers: `https://goodpeople-95f54.web.app/*`, `http://localhost:3000/*`
3. **API restrictions** 설정:
   - Maps JavaScript API만 선택
4. **Quotas** 설정으로 일일 사용량 제한

#### Firebase API 키:
1. 프로젝트 설정에서 새 웹 앱 추가
2. 도메인 제한 설정
3. Firebase Security Rules 검토

#### Kakao/T Map API 키:
1. 새 키 발급
2. 허용 도메인/IP 설정
3. 일일 쿼터 설정

### 3. 로컬 환경 설정

```bash
# 1. .env 파일 생성 (Git에 추가되지 않음)
cp .env.example .env

# 2. 실제 API 키 입력
# 편집기로 .env 파일 열어서 수정

# 3. 절대 커밋하지 않기
git status  # .env 파일이 없어야 함
```

### 4. 팀원 공지사항

모든 팀원에게 다음 내용을 전달하세요:

```
📢 보안 공지

API 키 노출로 인해 모든 키가 갱신되었습니다.
1. 최신 코드를 pull 받으세요
2. .env.example을 참고하여 새 .env 파일을 생성하세요
3. Slack/이메일로 새 API 키를 전달받으세요
4. 절대 .env 파일을 커밋하지 마세요!
```

### 5. CI/CD 설정

GitHub Actions를 사용 중이라면:

```yaml
# .github/workflows/deploy.yml
env:
  FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
  GOOGLE_MAPS_API_KEY: ${{ secrets.GOOGLE_MAPS_API_KEY }}
  # ... 기타 키들
```

### 6. 추가 보안 조치

1. **정기적인 키 로테이션** (3개월마다)
2. **API 사용량 모니터링** 설정
3. **예산 알림** 설정 (비정상 사용 감지)
4. **보안 교육** 실시

### 7. 히스토리에서 완전 제거

⚠️ 주의: 이미 fork한 사람들과 협의 필요

```bash
# BFG Repo-Cleaner 사용 (권장)
java -jar bfg.jar --delete-files test-google-maps.html
java -jar bfg.jar --replace-text passwords.txt  # API 키 목록 파일

# 또는 filter-branch 사용
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch packages/web-dashboard/test-scripts/test-google-maps.html" \
  --prune-empty --tag-name-filter cat -- --all

# 강제 푸시
git push --force --all
git push --force --tags
```

### 8. 예방 조치

1. **pre-commit hook** 설정으로 API 키 패턴 검사
2. **GitGuardian** 또는 **GitHub secret scanning** 활성화
3. **코드 리뷰**시 민감정보 확인 필수

---

## 📞 문의사항

보안 관련 문의는 보안 담당자에게 연락하세요.

마지막 업데이트: 2025-05-30