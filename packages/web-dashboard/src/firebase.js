// 1. firebase.js 파일 확장 - 인증 기능 추가
// src/firebase.js에 다음 코드 추가

import { initializeApp } from 'firebase/app';
import { getDatabase } from 'firebase/database';
import { getAuth } from 'firebase/auth'; // 추가

const firebaseConfig = {
  apiKey: "AIzaSyAiFfhuIMUilqYViNrBOr922ks8YO4or20",
  authDomain: "goodpeople-95f54.firebaseapp.com",
  databaseURL: "https://goodpeople-95f54-default-rtdb.asia-southeast1.firebasedatabase.app",
  projectId: "goodpeople-95f54",
  storageBucket: "goodpeople-95f54.firebasestorage.app",
  messagingSenderId: "24321943098",
  appId: "1:24321943098:web:18bf9c2cab0cd0cf96f703"
};

// Firebase 앱 초기화
const app = initializeApp(firebaseConfig);

// Realtime Database 인스턴스
export const db = getDatabase(app);

// Authentication 인스턴스 - 추가
export const auth = getAuth(app);