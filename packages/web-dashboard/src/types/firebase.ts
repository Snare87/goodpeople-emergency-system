// Firebase 타입 정의 보완
import { Timestamp } from 'firebase/firestore';

// Firebase에서 가져온 데이터 타입
export interface FirebaseCall {
  id?: string;
  eventType: string;
  address: string;
  location?: {
    lat: number;
    lng: number;
  };
  status: string;
  startAt: Timestamp | string;
  completedAt?: Timestamp | string;
  responder?: string;
  info?: string;
  reporterId?: string;
}

// Firebase User 타입
export interface FirebaseUser {
  uid: string;
  email: string | null;
  displayName?: string | null;
  photoURL?: string | null;
}

// Firebase 관련 에러 타입
export interface FirebaseError {
  code: string;
  message: string;
  name: string;
}
