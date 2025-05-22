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
    "startAt": now - (30 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "2층 건물 화재, 인명피해 우려, 소방차 2대 필요"
  },
  "call2": {
    "eventType": "구급",
    "address": "서울 중구 을지로 5",
    "lat": 37.572, 
    "lng": 126.9794,
    "startAt": now - (45 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "교통사고 환자 1명, 의식 있음, 다리 골절 의심"
  },
  "call3": {
    "eventType": "구조",
    "address": "서울 송파구 올림픽로 300",
    "lat": 37.5139,
    "lng": 127.0592,
    "startAt": now - (15 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "지하 주차장 갇힌 사람 1명, 특수장비 필요"
  },
  "call4": {
    "eventType": "기타",
    "address": "서울 서초구 서초대로 330",
    "lat": 37.4923,
    "lng": 127.0292,
    "startAt": now - (60 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "엘리베이터 고장으로 인한 고립, 노인 3명"
  },
  "call5": {
    "eventType": "화재",
    "address": "서울 용산구 한남대로 42",
    "lat": 37.5346,
    "lng": 127.0016,
    "startAt": now - (20 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "아파트 15층 화재, 대피 진행 중, 연기 확산"
  },
  "call6": {
    "eventType": "구급",
    "address": "서울 동대문구 왕산로 214",
    "lat": 37.5791,
    "lng": 127.0258,
    "startAt": now - (10 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "심정지 환자, CPR 진행 중, 제세동기 필요"
  },
  "call7": {
    "eventType": "구조",
    "address": "서울 마포구 양화로 45",
    "lat": 37.5536,
    "lng": 126.9237,
    "startAt": now - (55 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "하천 추락 사고, 수난구조대 출동 요청"
  },
  "call8": {
    "eventType": "구급",
    "address": "서울 광진구 능동로 120",
    "lat": 37.5500,
    "lng": 127.0736,
    "startAt": now - (5 * 60 * 1000),
    "date": dateString,
    "status": "idle",
    "info": "70대 남자, 쓰러짐, 의식 호흡 없음, 심정지 추정"
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