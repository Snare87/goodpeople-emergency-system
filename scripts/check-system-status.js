// scripts/check-system-status.js
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-admin-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL || "https://goodpeople-95f54-default-rtdb.firebaseio.com"
});

const db = admin.database();

async function checkSystemStatus() {
  console.log('🔍 시스템 상태 확인 중...\n');
  
  try {
    // 1. Calls 분석
    console.log('📋 Calls 데이터 분석');
    console.log('========================');
    const callsSnapshot = await db.ref('calls').once('value');
    const calls = callsSnapshot.val() || {};
    
    let stats = {
      total: 0,
      byStatus: {},
      hasResponder: 0,
      hasSelectedResponder: 0,
      hasCandidates: 0,
      candidatesCount: 0
    };
    
    Object.entries(calls).forEach(([id, call]) => {
      stats.total++;
      stats.byStatus[call.status] = (stats.byStatus[call.status] || 0) + 1;
      
      if (call.responder) stats.hasResponder++;
      if (call.selectedResponder) stats.hasSelectedResponder++;
      if (call.candidates && Object.keys(call.candidates).length > 0) {
        stats.hasCandidates++;
        stats.candidatesCount += Object.keys(call.candidates).length;
      }
    });
    
    console.log(`총 재난 수: ${stats.total}`);
    console.log('\n상태별 분포:');
    Object.entries(stats.byStatus).forEach(([status, count]) => {
      console.log(`  - ${status}: ${count}개`);
    });
    
    console.log('\n시스템 타입:');
    console.log(`  - 구 시스템 (responder): ${stats.hasResponder}개`);
    console.log(`  - 새 시스템 (selectedResponder): ${stats.hasSelectedResponder}개`);
    console.log(`  - 후보자 있는 재난: ${stats.hasCandidates}개`);
    console.log(`  - 총 후보자 수: ${stats.candidatesCount}명`);
    
    // 2. Users 분석
    console.log('\n\n👥 Users 데이터 분석');
    console.log('========================');
    const usersSnapshot = await db.ref('users').once('value');
    const users = usersSnapshot.val() || {};
    
    let userStats = {
      total: 0,
      byRole: {},
      byPosition: {},
      onDuty: 0,
      locationEnabled: 0,
      withCertifications: 0
    };
    
    Object.values(users).forEach(user => {
      userStats.total++;
      
      // 역할별
      if (user.roles) {
        user.roles.forEach(role => {
          userStats.byRole[role] = (userStats.byRole[role] || 0) + 1;
        });
      }
      
      // 직책별
      userStats.byPosition[user.position] = (userStats.byPosition[user.position] || 0) + 1;
      
      // 상태
      if (user.isOnDuty) userStats.onDuty++;
      if (user.locationEnabled) userStats.locationEnabled++;
      if (user.certifications && user.certifications.length > 0) {
        userStats.withCertifications++;
      }
    });
    
    console.log(`총 사용자 수: ${userStats.total}`);
    console.log('\n역할별 분포:');
    Object.entries(userStats.byRole).forEach(([role, count]) => {
      console.log(`  - ${role}: ${count}명`);
    });
    
    console.log('\n직책별 분포:');
    Object.entries(userStats.byPosition).forEach(([position, count]) => {
      console.log(`  - ${position}: ${count}명`);
    });
    
    console.log('\n활성 상태:');
    console.log(`  - 근무 중: ${userStats.onDuty}명`);
    console.log(`  - 위치 공유 중: ${userStats.locationEnabled}명`);
    console.log(`  - 자격증 보유: ${userStats.withCertifications}명`);
    
    // 3. 시스템 권장사항
    console.log('\n\n💡 권장사항');
    console.log('========================');
    
    if (stats.hasResponder > 0) {
      console.log('⚠️  구 시스템 데이터가 발견되었습니다.');
      console.log('   → migrate-system.bat 실행을 권장합니다.');
    } else if (stats.hasSelectedResponder === 0) {
      console.log('✅ 구 시스템 데이터가 없습니다.');
      console.log('   → 새 시스템을 바로 사용할 수 있습니다.');
    } else {
      console.log('✅ 새 시스템이 활성화되어 있습니다.');
    }
    
    console.log('\n✨ 분석 완료!');
    
  } catch (error) {
    console.error('❌ 분석 오류:', error);
  }
  
  process.exit(0);
}

// 실행
checkSystemStatus();
