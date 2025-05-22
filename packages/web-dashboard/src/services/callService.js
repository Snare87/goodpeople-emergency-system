// src/services/callService.js
import { ref, onValue, off, update } from 'firebase/database';
import { db } from '../firebase';

// 데이터 변경 리스너 등록
export const subscribeToCalls = (onDataChanged) => {
  const callsRef = ref(db, 'calls');
  
  const unsubscribe = onValue(callsRef, (snapshot) => {
    try {
      const data = snapshot.val() || {};
      const calls = Object.entries(data).map(([id, call]) => ({ id, ...call }));
      onDataChanged(calls);
    } catch (error) {
      console.error("Error processing call data:", error);
    }
  });
  
  return () => off(callsRef);
};

// 호출하기
export const dispatchCall = (id) => {
  return update(ref(db, `calls/${id}`), { 
    status: 'dispatched',
    dispatchedAt: Date.now() 
  });
};

// 대원 수락
export const acceptCall = (id, responderId = 'resp1', responderName = '김구조') => {
  return update(ref(db, `calls/${id}`), { 
    status: 'accepted', 
    acceptedAt: Date.now(),
    responder: {
      id: responderId,
      name: responderName,
      position: '구급대원'
    }
  });
};

// 완료 처리
export const completeCall = (id) => {
  return update(ref(db, `calls/${id}`), { 
    status: 'completed', 
    completedAt: Date.now() 
  });
};

// 재호출
export const reactivateCall = (id) => {
  return update(ref(db, `calls/${id}`), { 
    status: 'dispatched',  // 바로 dispatched 상태로 설정
    completedAt: null,
    dispatchedAt: Date.now()
  });
};