// scripts/test-candidates-system.js
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-admin-key.json');

// Firebase Admin 초기화
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_DATABASE_URL || "https://goodpeople-95f54-default-rtdb.firebaseio.com"
});

const db = admin.database();

// 테스트 시나리오
async function testCandidatesSystem() {
  console.log('🧪 다중 후보자 시스템 테스트 시작...\n');
  
  try {
    // 1. 테스트용 재난 생성
    console.log('1️⃣ 테스트 재난 생성...');
    const testCallId = `test_call_${Date.now()}`;
    const testCall = {
      address: "서울 강남구 테스트로 123",
      eventType: "화재",
      info: "테스트 화재 상황",
      lat: 37.5013,
      lng: 127.0396,
      startAt: Date.now(),
      status: "idle"
    };
    
    await db.ref(`calls/${testCallId}`).set(testCall);
    console.log(`✅ 테스트 재난 생성: ${testCallId}\n`);
    
    // 2. 호출하기
    console.log('2️⃣ 재난 호출...');
    await db.ref(`calls/${testCallId}`).update({
      status: 'dispatched',
      dispatchedAt: Date.now()
    });
    console.log('✅ 호출 완료\n');
    
    // 3. 여러 대원이 수락 (시뮬레이션)
    console.log('3️⃣ 대원들이 수락 중...');
    const testUsers = ['TestUser001', 'TestUser002', 'TestUser003'];
    
    for (const userId of testUsers) {
      // 사용자 정보 가져오기
      const userSnapshot = await db.ref(`users/${userId}`).once('value');
      const userData = userSnapshot.val();
      
      if (userData) {
        const candidateData = {
          id: userId,
          userId: userId,
          name: userData.name,
          position: userData.position,
          rank: userData.rank,
          acceptedAt: Date.now() + Math.random() * 5000, // 랜덤 시간차
          routeInfo: {
            distance: Math.floor(Math.random() * 5000) + 1000, // 1-6km
            distanceText: `${(Math.random() * 5 + 1).toFixed(1)}km`,
            duration: Math.floor(Math.random() * 1200) + 300, // 5-25분
            durationText: `${Math.floor(Math.random() * 20) + 5}분`,
            calculatedAt: Date.now(),
            routeApiUsed: 'simulation'
          }
        };
        
        await db.ref(`calls/${testCallId}/candidates/${userId}`).set(candidateData);
        console.log(`  ✓ ${userData.name} (${userData.position}) 수락`);
      }
    }
    console.log('✅ 3명의 대원이 수락\n');
    
    // 4. 대원 선택
    console.log('4️⃣ 대원 선택 중...');
    await new Promise(resolve => setTimeout(resolve, 2000)); // 2초 대기
    
    // 가장 가까운 대원 선택 (시뮬레이션)
    const candidatesSnapshot = await db.ref(`calls/${testCallId}/candidates`).once('value');
    const candidates = candidatesSnapshot.val() || {};
    
    let selectedCandidate = null;
    let minDistance = Infinity;
    
    Object.values(candidates).forEach(candidate => {
      if (candidate.routeInfo.distance < minDistance) {
        minDistance = candidate.routeInfo.distance;
        selectedCandidate = candidate;
      }
    });
    
    if (selectedCandidate) {
      await db.ref(`calls/${testCallId}`).update({
        status: 'accepted',
        selectedResponder: {
          ...selectedCandidate,
          selectedAt: Date.now()
        }
      });
      console.log(`✅ ${selectedCandidate.name}님 선택 (거리: ${selectedCandidate.routeInfo.distanceText})\n`);
    }
    
    // 5. 결과 확인
    console.log('5️⃣ 최종 상태 확인...');
    const finalSnapshot = await db.ref(`calls/${testCallId}`).once('value');
    const finalData = finalSnapshot.val();
    
    console.log('📊 테스트 결과:');
    console.log(`  - 상태: ${finalData.status}`);
    console.log(`  - 후보자 수: ${Object.keys(finalData.candidates || {}).length}`);
    console.log(`  - 선택된 대원: ${finalData.selectedResponder?.name || '없음'}`);
    
    // 6. 테스트 데이터 정리
    console.log('\n6️⃣ 테스트 데이터 정리...');
    const cleanup = await promptUser('테스트 데이터를 삭제하시겠습니까? (y/n): ');
    if (cleanup.toLowerCase() === 'y') {
      await db.ref(`calls/${testCallId}`).remove();
      console.log('✅ 테스트 데이터 삭제 완료');
    }
    
    console.log('\n✨ 테스트 완료!');
    
  } catch (error) {
    console.error('❌ 테스트 오류:', error);
  }
  
  process.exit(0);
}

// 사용자 입력 받기
function promptUser(question) {
  const readline = require('readline').createInterface({
    input: process.stdin,
    output: process.stdout
  });
  
  return new Promise(resolve => {
    readline.question(question, answer => {
      readline.close();
      resolve(answer);
    });
  });
}

// 실행
testCandidatesSystem();
