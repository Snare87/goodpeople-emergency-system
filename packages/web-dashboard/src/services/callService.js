// src/services/callService.js
import { ref, onValue, off, update, get } from 'firebase/database';
import { db, auth } from '../firebase';

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

// 대원 수락 - 실제 사용자 데이터를 가져오는 버전
export const acceptCall = async (id, responderId = 'resp1', responderName = '김구조') => {
  try {
    // 현재 로그인한 사용자 정보 가져오기 (auth.currentUser 사용)
    const currentUser = auth.currentUser;
    if (!currentUser) {
      throw new Error('로그인한 사용자가 없습니다.');
    }
    
    // 사용자 데이터 가져오기
    const userSnapshot = await get(ref(db, `users/${currentUser.uid}`));
    let userData = {
      name: responderName,
      position: '대원' // 기본값
    };
    
    if (userSnapshot.exists()) {
      const data = userSnapshot.val();
      userData = {
        name: data.name || responderName,
        position: data.position || '대원',
        rank: data.rank || '소방사' // 계급 추가
      };
    }
    
    // 호출 수락 업데이트
    return update(ref(db, `calls/${id}`), { 
      status: 'accepted', 
      acceptedAt: Date.now(),
      responder: {
        id: `resp_${currentUser.uid}_${Date.now()}`,
        name: userData.name,
        position: userData.position,
        rank: userData.rank // 계급 추가
      }
    });
  } catch (error) {
    console.error('콜 수락 오류:', error);
    throw error;
  }
};

// 완료 처리
export const completeCall = (id) => {
  return update(ref(db, `calls/${id}`), { 
    status: 'completed', 
    completedAt: Date.now() 
  });
};

// 재호출 (수정된 버전)
export const reactivateCall = (id) => {
  return update(ref(db, `calls/${id}`), { 
    status: 'dispatched',
    completedAt: null,
    dispatchedAt: Date.now(),
    acceptedAt: null,      // 추가: 이전 수락 시간 삭제
    responder: null        // 기존 코드에 이미 있음
  });
};

// 호출취소 (수정된 버전)
export const cancelCall = async (id) => {
  // 먼저 현재 상태 확인
  const callRef = ref(db, `calls/${id}`);
  const snapshot = await get(callRef);
  
  if (snapshot.exists()) {
    const callData = snapshot.val();
    
    // dispatched 상태이고 responder가 없을 때만 취소 가능
    if (callData.status === 'dispatched' && !callData.responder) {
      return update(callRef, { 
        status: 'idle',
        dispatchedAt: null,
        acceptedAt: null,
        responder: null
      });
    }
  }
  
  throw new Error('취소할 수 없는 상태입니다.');
};