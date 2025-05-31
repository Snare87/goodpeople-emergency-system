// scripts/migration/migrate-to-candidates-system.js
const admin = require('firebase-admin');
const serviceAccount = require('../../firebase-admin-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL || "https://goodpeople-95f54-default-rtdb.firebaseio.com"
});

const db = admin.database();

async function migrateData() {
  console.log('🚀 다중 후보자 시스템 마이그레이션 시작...\n');
  
  try {
    // 1. 백업 생성
    console.log('1️⃣ 데이터 백업 중...');
    const backupRef = db.ref(`backups/migration_${Date.now()}`);
    const callsSnapshot = await db.ref('calls').once('value');
    const callsData = callsSnapshot.val() || {};
    
    await backupRef.set({
      timestamp: new Date().toISOString(),
      calls: callsData
    });
    console.log('✅ 백업 완료\n');
    
    // 2. calls 데이터 마이그레이션
    console.log('2️⃣ calls 데이터 마이그레이션 중...');
    let migratedCount = 0;
    
    for (const [callId, callData] of Object.entries(callsData)) {
      console.log(`  - ${callId} 처리 중...`);
      
      const updates = {};
      
      // responder 필드가 있으면 selectedResponder로 변환
      if (callData.responder) {
        updates[`calls/${callId}/selectedResponder`] = {
          ...callData.responder,
          userId: callData.responder.id?.split('_')[1] || 'unknown',
          selectedAt: callData.acceptedAt || Date.now()
        };
        updates[`calls/${callId}/responder`] = null;
      }
      
      // candidates 필드 초기화 (빈 객체로)
      if (!callData.candidates) {
        updates[`calls/${callId}/candidates`] = {};
      }
      
      // 업데이트 실행
      if (Object.keys(updates).length > 0) {
        await db.ref().update(updates);
        migratedCount++;
        console.log(`    ✓ 마이그레이션 완료`);
      } else {
        console.log(`    - 변경사항 없음`);
      }
    }
    
    console.log(`\n✅ 마이그레이션 완료! 총 ${migratedCount}개 재난 업데이트됨\n`);
    
    // 3. Firestore incidents 확인 (있다면)
    console.log('3️⃣ Firestore incidents 컬렉션 확인...');
    console.log('   ⚠️  Firestore 데이터는 수동으로 확인 필요\n');
    
    // 4. 완료 보고서
    console.log('📊 마이그레이션 보고서');
    console.log('========================');
    console.log(`총 재난 수: ${Object.keys(callsData).length}`);
    console.log(`마이그레이션된 재난: ${migratedCount}`);
    console.log(`백업 위치: backups/migration_${Date.now()}`);
    console.log('\n✅ 모든 작업 완료!');
    
  } catch (error) {
    console.error('❌ 마이그레이션 오류:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

// 실행
migrateData();
