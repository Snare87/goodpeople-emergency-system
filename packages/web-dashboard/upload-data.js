// upload-data.js
const { initializeApp } = require('firebase/app');
const { getDatabase, ref, set } = require('firebase/database');

// Firebase 설정 (본인의 프로젝트 설정으로 변경 필요)
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
const db = getDatabase(app);

// 현재 시간 및 날짜
const now = Date.now();
const today = new Date();
const dateString = today.toISOString().split('T')[0]; // "YYYY-MM-DD" 형식

// 샘플 데이터 (현재 시간 기준)
const sampleCalls = {
  "call1": {
    "eventType": "화재",
    "address": "서울 강남구 테헤란로 10",
    "lat": 37.5013,
    "lng": 127.0396,
    "startAt": now - (30 * 60 * 1000), // 30분 전
    "date": dateString,
    "status": "idle"
  },
  "call2": {
    "eventType": "구급",
    "address": "서울 중구 을지로 5",
    "lat": 37.572, 
    "lng": 126.9794,
    "startAt": now - (45 * 60 * 1000), // 45분 전
    "date": dateString,
    "status": "idle"
  },
  "call3": {
    "eventType": "구조",
    "address": "서울 송파구 올림픽로 300",
    "lat": 37.5139,
    "lng": 127.0592,
    "startAt": now - (15 * 60 * 1000), // 15분 전
    "date": dateString,
    "status": "idle"
  },
  "call4": {
    "eventType": "기타",
    "address": "서울 서초구 서초대로 330",
    "lat": 37.4923,
    "lng": 127.0292,
    "startAt": now - (60 * 60 * 1000), // 1시간 전
    "date": dateString,
    "status": "dispatched"
  },
  "call5": {
    "eventType": "화재",
    "address": "서울 용산구 한남대로 42",
    "lat": 37.5346,
    "lng": 127.0016,
    "startAt": now - (20 * 60 * 1000), // 20분 전
    "date": dateString,
    "status": "idle"
  },
  "call6": {
    "eventType": "구급",
    "address": "서울 동대문구 왕산로 214",
    "lat": 37.5791,
    "lng": 127.0258,
    "startAt": now - (10 * 60 * 1000), // 10분 전
    "date": dateString,
    "status": "dispatched",
    "responder": {
      "id": "resp1",
      "name": "김구조",
      "position": "구급대원"
    }
  },
  "call7": {
    "eventType": "구조",
    "address": "서울 마포구 양화로 45",
    "lat": 37.5536,
    "lng": 126.9237,
    "startAt": now - (55 * 60 * 1000), // 55분 전
    "date": dateString,
    "status": "dispatched"
  },
  "call8": {
    "eventType": "기타",
    "address": "서울 광진구 능동로 120",
    "lat": 37.5500,
    "lng": 127.0736,
    "startAt": now - (5 * 60 * 1000), // 5분 전
    "date": dateString,
    "status": "idle"
  }
};

// Firebase에 데이터 업로드
async function uploadData() {
  try {
    await set(ref(db, 'calls'), sampleCalls);
    console.log('샘플 데이터가 성공적으로 업로드되었습니다.');
  } catch (error) {
    console.error('데이터 업로드 중 오류 발생:', error);
  }
}

uploadData();