#!/bin/bash
# test-clean.sh - 깔끔한 테스트 실행 스크립트

echo "🧪 GoodPeople Emergency System - 깔끔한 테스트 실행"
echo "================================================"

# 웹 대시보드 디렉토리로 이동
cd packages/web-dashboard

echo ""
echo "📋 테스트 환경 설정 중..."
# 환경 변수 설정 (CI 환경)
export CI=true

echo ""
echo "🚀 개별 테스트 실행 중..."
echo "-------------------"

# 개별 테스트 파일 실행
echo "1️⃣ CallService 테스트..."
npm test -- --testPathPattern=callService.test.ts --watchAll=false --silent

echo ""
echo "2️⃣ Formatters 테스트..."
npm test -- --testPathPattern=formatters.test.ts --watchAll=false --silent

echo ""
echo "3️⃣ UserManagement 테스트..."
npm test -- --testPathPattern=useUserManagement.test.ts --watchAll=false --silent

echo ""
echo "4️⃣ Badge 테스트..."
npm test -- --testPathPattern=Badge.test.tsx --watchAll=false --silent

echo ""
echo "-------------------"
echo "📊 전체 요약:"
echo ""

# 전체 테스트 실행 (요약만 표시)
npm test -- --watchAll=false --verbose=false --reporters=jest-silent-reporter 2>/dev/null || npm test -- --watchAll=false --verbose=false

echo ""
echo "✅ 테스트 실행 완료!"
echo ""
echo "💡 개별 테스트 실행:"
echo "- CallService만: npm test -- callService --watchAll=false"
echo "- Formatters만: npm test -- formatters --watchAll=false"
echo "- 자세한 출력: npm test -- --watchAll=false --verbose"
