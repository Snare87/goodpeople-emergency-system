// scripts/quick-check.js
console.log('🔍 빠른 시스템 체크\n');

const fs = require('fs');
const path = require('path');

// 1. 필수 파일 체크
console.log('📁 필수 파일 확인:');
const requiredFiles = [
  'firebase-admin-key.json',
  'packages/web-dashboard/src/services/callService.ts',
  'packages/mobile-responder/lib/services/improved_call_acceptance_service.dart'
];

requiredFiles.forEach(file => {
  const exists = fs.existsSync(path.join(__dirname, '..', file));
  console.log(`  ${exists ? '✅' : '❌'} ${file}`);
});

// 2. 설치 상태 체크
console.log('\n📦 패키지 확인:');
const nodeModulesExists = fs.existsSync(path.join(__dirname, '..', 'node_modules'));
const firebaseAdminExists = fs.existsSync(path.join(__dirname, '..', 'node_modules', 'firebase-admin'));

console.log(`  ${nodeModulesExists ? '✅' : '❌'} node_modules 폴더`);
console.log(`  ${firebaseAdminExists ? '✅' : '❌'} firebase-admin 패키지`);

// 3. 권장사항
console.log('\n💡 다음 단계:');
if (!firebaseAdminExists) {
  console.log('  1. install-admin.bat 실행');
}
if (!fs.existsSync(path.join(__dirname, '..', 'firebase-admin-key.json'))) {
  console.log('  2. Firebase 서비스 계정 키 다운로드');
  console.log('     → firebase-admin-key.json으로 저장');
}
console.log('  3. Firebase Console에서 규칙 업데이트');
console.log('  4. check-status.bat 실행');

console.log('\n또는 수동 테스트: MANUAL_TEST_GUIDE.md 참고');
