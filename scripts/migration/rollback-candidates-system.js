// scripts/migration/rollback-candidates-system.js
const admin = require('firebase-admin');
const serviceAccount = require('../../firebase-admin-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL || "https://goodpeople-95f54-default-rtdb.firebaseio.com"
});

const db = admin.database();

async function rollback(backupTimestamp) {
  console.log('🔄 롤백 시작...\n');
  
  try {
    // 1. 백업 데이터 확인
    if (!backupTimestamp) {
      console.log('사용 가능한 백업 목록:');
      const backupsSnapshot = await db.ref('backups').once('value');
      const backups = backupsSnapshot.val() || {};
      
      Object.keys(backups).forEach(key => {
        console.log(`  - ${key} (${backups[key].timestamp})`);
      });
      
      console.log('\n사용법: node rollback-candidates-system.js <backup_timestamp>');
      process.exit(0);
    }
    
    // 2. 백업 데이터 로드
    console.log(`백업 로드 중: backups/${backupTimestamp}`);
    const backupSnapshot = await db.ref(`backups/${backupTimestamp}`).once('value');
    const backupData = backupSnapshot.val();
    
    if (!backupData) {
      console.error('❌ 백업을 찾을 수 없습니다.');
      process.exit(1);
    }
    
    // 3. 롤백 실행
    console.log('데이터 복원 중...');
    await db.ref('calls').set(backupData.calls);
    
    console.log('✅ 롤백 완료!');
    
  } catch (error) {
    console.error('❌ 롤백 오류:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

// 실행
const backupTimestamp = process.argv[2];
rollback(backupTimestamp);
