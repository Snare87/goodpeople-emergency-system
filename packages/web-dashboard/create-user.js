// 6. 테스트 사용자 생성 스크립트
// create-user.js (루트 디렉토리에 생성)

const { initializeApp } = require('firebase/app');
const { getAuth, createUserWithEmailAndPassword } = require('firebase/auth');

// Firebase 설정
const firebaseConfig = {
  apiKey: "AIzaSyAiFfhuIMUilqYViNrBOr922ks8YO4or20",
  authDomain: "goodpeople-95f54.firebaseapp.com",
  databaseURL: "https://goodpeople-95f54-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "goodpeople-95f54",
  storageBucket: "goodpeople-95f54.firebasestorage.app",
  messagingSenderId: "24321943098",
  appId: "1:24321943098:web:18bf9c2cab0cd0cf96f703"
};

// Firebase 초기화
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);

// 테스트 사용자 정보
const email = 'admin@korea.kr';
const password = 'admin1234';

// 사용자 생성 함수
async function createUser() {
  try {
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    console.log('테스트 사용자가 성공적으로 생성되었습니다:', userCredential.user.uid);
  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      console.log('이미 존재하는 사용자입니다. 로그인에 사용하세요.');
    } else {
      console.error('사용자 생성 오류:', error.code, error.message);
    }
  }
}

// 스크립트 실행
createUser().then(() => process.exit());