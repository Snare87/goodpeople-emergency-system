const admin = require('firebase-admin');

// Firebase Admin SDK 초기화
// 서비스 계정 키 파일이 필요합니다
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://goodpeople-95f54-default-rtdb.firebaseio.com"
});

const auth = admin.auth();

// 테스트 유저 목록
const testUsers = [
  { email: 'test001@korea.kr', password: 'test1234', displayName: '박민수', uid: 'TestUser001' },
  { email: 'test002@korea.kr', password: 'test1234', displayName: '이정훈', uid: 'TestUser002' },
  { email: 'test003@korea.kr', password: 'test1234', displayName: '김서연', uid: 'TestUser003' },
  { email: 'test004@korea.kr', password: 'test1234', displayName: '최강호', uid: 'TestUser004' },
  { email: 'test005@korea.kr', password: 'test1234', displayName: '윤재영', uid: 'TestUser005' },
  { email: 'test006@korea.kr', password: 'test1234', displayName: '송민지', uid: 'TestUser006' },
  { email: 'test007@korea.kr', password: 'test1234', displayName: '장현우', uid: 'TestUser007' },
  { email: 'test008@korea.kr', password: 'test1234', displayName: '한도현', uid: 'TestUser008' },
  { email: 'test009@korea.kr', password: 'test1234', displayName: '정유진', uid: 'TestUser009' },
  { email: 'test010@korea.kr', password: 'test1234', displayName: '오성민', uid: 'TestUser010' }
];

async function createTestUsers() {
  for (const user of testUsers) {
    try {
      const userRecord = await auth.createUser({
        uid: user.uid,
        email: user.email,
        password: user.password,
        displayName: user.displayName,
        emailVerified: true // 이메일 인증 건너뛰기
      });
      console.log(`✅ Created user: ${userRecord.email} (${userRecord.uid})`);
    } catch (error) {
      console.error(`❌ Error creating user ${user.email}:`, error.message);
    }
  }
  
  console.log('\n✨ Test user creation completed!');
  process.exit(0);
}

createTestUsers();
