// src/services/callService.ts
import { ref, onValue, off, update, get, runTransaction, remove, Unsubscribe } from 'firebase/database';
import { db, auth } from '../firebase';
import { FirebaseCall } from '../types/firebase';

// Call 타입 정의 - 새로운 다중 후보자 시스템
export interface Call {
  id: string;
  eventType: string;
  address: string;
  location?: {
    lat: number;
    lng: number;
  };
  status: string;
  startAt: string | number;
  completedAt?: number;
  dispatchedAt?: number;
  acceptedAt?: number;
  cancelledAt?: number;
  reactivatedAt?: number;
  cancellationCount?: number;
  reactivationCount?: number;
  info?: string;
  reporterId?: string;
  // 다중 후보자 시스템 필드
  candidates?: Record<string, {
    id: string;
    userId: string;
    name: string;
    position: string;
    rank?: string;
    acceptedAt: number;
    routeInfo?: {
      distance: number;
      distanceText: string;
      duration: number;
      durationText: string;
      calculatedAt: number;
    };
  }>;
  selectedResponder?: {
    id: string;
    userId: string;
    name: string;
    position: string;
    rank?: string;
    acceptedAt: number;
    selectedAt: number;
    routeInfo?: {
      distance: number;
      distanceText: string;
      duration: number;
      durationText: string;
      calculatedAt: number;
    };
  };
}

// 콜백 함수 타입
type CallsCallback = (calls: Call[]) => void;

// 데이터 변경 리스너 등록
export const subscribeToCalls = (onDataChanged: CallsCallback): (() => void) => {
  const callsRef = ref(db, 'calls');
  
  onValue(callsRef, (snapshot) => {
    try {
      const data = snapshot.val() || {};
      const calls: Call[] = Object.entries(data).map(([id, callData]) => {
        const call = callData as any;
        
        // lat/lng를 location 객체로 변환
        const processedCall: Call = {
          id,
          ...call
        };
        
        // lat과 lng가 있으면 location 객체 생성
        if (call.lat !== undefined && call.lng !== undefined) {
          processedCall.location = {
            lat: call.lat,
            lng: call.lng
          };
        }
        
        return processedCall;
      });
      
      console.log('[subscribeToCalls] Processed calls:', calls.map(c => ({
        id: c.id,
        eventType: c.eventType,
        status: c.status,
        candidatesCount: c.candidates ? Object.keys(c.candidates).length : 0,
        candidateIds: c.candidates ? Object.keys(c.candidates) : [],
        hasLocation: !!c.location,
        location: c.location
      })));
      
      onDataChanged(calls);
    } catch (error) {
      console.error("Error processing call data:", error);
    }
  });
  
  return () => off(callsRef);
};

// 호출하기
export const dispatchCall = (id: string): Promise<void> => {
  return update(ref(db, `calls/${id}`), { 
    status: 'dispatched',
    dispatchedAt: Date.now()
  });
};

// 대원 수락 - 새로운 다중 후보자 시스템으로 수정
export const acceptCall = async (
  id: string
): Promise<void> => {
  try {
    // 현재 로그인한 사용자 정보 가져오기
    const currentUser = auth.currentUser;
    if (!currentUser) {
      throw new Error('로그인한 사용자가 없습니다.');
    }
    
    // 사용자 데이터 가져오기
    const userSnapshot = await get(ref(db, `users/${currentUser.uid}`));
    if (!userSnapshot.exists()) {
      throw new Error('사용자 정보가 없습니다.');
    }
    
    const userData = userSnapshot.val();
    
    // Transaction을 사용한 원자적 업데이트
    const callRef = ref(db, `calls/${id}`);
    const result = await runTransaction(callRef, (currentData) => {
      // 데이터가 없으면 취소
      if (!currentData) {
        return; // Transaction abort
      }
      
      // status가 'dispatched'가 아니면 취소
      if (currentData.status !== 'dispatched') {
        return; // Transaction abort
      }
      
      // 후보자 정보 추가
      if (!currentData.candidates) {
        currentData.candidates = {};
      }
      
      // 이미 등록된 후보자인지 확인
      if (currentData.candidates[currentUser.uid]) {
        return; // 이미 수락한 경우
      }
      
      // 후보자로 추가
      currentData.candidates[currentUser.uid] = {
        id: currentUser.uid,
        userId: currentUser.uid,
        name: userData.name || '대원',
        position: userData.position || '대원',
        rank: userData.rank || '소방사',
        acceptedAt: Date.now()
      };
      
      return currentData;
    });
    
    // Transaction 결과 확인
    if (!result.committed) {
      // 최신 상태 확인하여 상세한 에러 메시지 제공
      const latestSnapshot = await get(callRef);
      if (latestSnapshot.exists()) {
        const latestData = latestSnapshot.val();
        if (latestData.status === 'idle') {
          throw new Error('호출이 취소된 재난입니다.');
        } else if (latestData.status === 'accepted') {
          throw new Error('이미 대원이 배정된 재난입니다.');
        } else if (latestData.status === 'completed') {
          throw new Error('이미 종료된 재난입니다.');
        } else if (latestData.candidates && latestData.candidates[currentUser.uid]) {
          throw new Error('이미 수락한 재난입니다.');
        }
      }
      throw new Error('수락할 수 없는 재난입니다.');
    }
    
    console.log('[대원 수락] 성공:', userData.name);
    
  } catch (error) {
    console.error('콜 수락 오류:', error);
    throw error;
  }
};

// 완료 처리
export const completeCall = async (id: string): Promise<void> => {
  console.log('[completeCall] 시작:', id);
  try {
    // 먼저 기본 필드 업데이트
    await update(ref(db, `calls/${id}`), { 
      status: 'completed', 
      completedAt: Date.now()
    });
    
    // 명시적으로 필드 삭제 (candidates는 유지)
    const fieldsToRemove = [
      'acceptedAt', 
      'selectedResponder'
    ];
    
    await Promise.all(
      fieldsToRemove.map(field => 
        remove(ref(db, `calls/${id}/${field}`))
          .catch(() => {}) // 필드가 없어도 에러 방지
      )
    );
    
    console.log('[completeCall] 업데이트 성공 - candidates 유지');
  } catch (error) {
    console.error('[completeCall] 업데이트 실패:', error);
    throw error;
  }
};

// 호출 취소 - Transaction 적용
export const cancelCall = async (id: string): Promise<void> => {
  console.log('[cancelCall] 시작:', id);
  const callRef = ref(db, `calls/${id}`);
  
  const result = await runTransaction(callRef, (currentData) => {
    if (!currentData) {
      return; // Transaction abort
    }
    
    // dispatched 또는 accepted 상태일 때 취소 가능
    if (currentData.status === 'dispatched' || currentData.status === 'accepted') {
      const currentCancellationCount = currentData.cancellationCount || 0;
      
      // 새로운 객체 생성 (필요한 필드만 포함)
      const updatedData = {
        ...currentData,
        status: 'idle',
        cancelledAt: Date.now(),
        cancellationCount: currentCancellationCount + 1
      };
      
      // 삭제할 필드들 (candidates는 유지)
      delete updatedData.dispatchedAt;
      delete updatedData.acceptedAt;
      delete updatedData.selectedResponder;
      // delete updatedData.candidates; // 후보자 목록은 유지
      
      return updatedData;
    }
    
    return; // Transaction abort
  });
  
  if (!result.committed) {
    console.error('[cancelCall] Transaction 실패');
    throw new Error('취소할 수 없는 상태입니다.');
  }
  console.log('[cancelCall] 취소 성공');
};

// 재호출 (수정된 버전)
export const reactivateCall = async (id: string): Promise<void> => {
  console.log('[reactivateCall] 시작:', id);
  try {
    const snapshot = await get(ref(db, `calls/${id}`));
    if (!snapshot.exists()) {
      throw new Error('Call not found');
    }
    
    const callData = snapshot.val() as Call;
    const currentReactivationCount = callData.reactivationCount || 0;
    
    // 기본 필드 업데이트
    await update(ref(db, `calls/${id}`), { 
      status: 'dispatched',
      dispatchedAt: Date.now(),
      reactivatedAt: Date.now(),
      reactivationCount: currentReactivationCount + 1
    });
    
    // 명시적으로 필드 삭제 (재호출 시 새로 시작, candidates는 유지)
    const fieldsToRemove = [
      'completedAt',
      'acceptedAt',
      'selectedResponder'
      // 'candidates'  // 재호출 시에도 후보자 목록 유지
    ];
    
    await Promise.all(
      fieldsToRemove.map(field => 
        remove(ref(db, `calls/${id}/${field}`))
          .catch(() => {}) // 필드가 없어도 에러 방지
      )
    );
    
    console.log('[reactivateCall] 재호출 성공');
  } catch (error) {
    console.error('[reactivateCall] 실패:', error);
    throw error;
  }
};

// 대원 선택 - 다중 후보자 시스템
export const selectResponder = async (
  callId: string,
  candidateId: string
): Promise<void> => {
  console.log('[selectResponder] 시작:', callId, candidateId);
  
  try {
    const callRef = ref(db, `calls/${callId}`);
    
    // Transaction을 사용한 원자적 업데이트
    const result = await runTransaction(callRef, (currentData) => {
      if (!currentData) {
        return; // Transaction abort
      }
      
      // 후보자가 있는지 확인
      if (!currentData.candidates || !currentData.candidates[candidateId]) {
        console.error('[선택 실패] 후보자를 찾을 수 없음');
        return; // Transaction abort
      }
      
      const candidate = currentData.candidates[candidateId];
      
      // 선택된 대원 정보 설정
      currentData.selectedResponder = {
        ...candidate,
        selectedAt: Date.now()
      };
      
      // 상태를 accepted로 변경
      currentData.status = 'accepted';
      currentData.acceptedAt = Date.now();
      
      return currentData;
    });
    
    if (!result.committed) {
      throw new Error('대원 선택에 실패했습니다.');
    }
    
    console.log('[selectResponder] 선택 성공');
  } catch (error) {
    console.error('[selectResponder] 오류:', error);
    throw error;
  }
};

// 대원 선택 취소
export const deselectResponder = async (callId: string): Promise<void> => {
  console.log('[deselectResponder] 시작:', callId);
  
  try {
    const callRef = ref(db, `calls/${callId}`);
    
    // Transaction을 사용한 원자적 업데이트
    const result = await runTransaction(callRef, (currentData) => {
      if (!currentData) {
        return; // Transaction abort
      }
      
      // 선택된 대원이 있는 경우만 취소 가능
      if (!currentData.selectedResponder) {
        return; // Transaction abort
      }
      
      // 선택된 대원 정보 삭제
      delete currentData.selectedResponder;
      delete currentData.acceptedAt;
      
      // 상태를 dispatched로 되돌림
      currentData.status = 'dispatched';
      
      return currentData;
    });
    
    if (!result.committed) {
      throw new Error('대원 선택 취소에 실패했습니다.');
    }
    
    console.log('[deselectResponder] 취소 성공');
  } catch (error) {
    console.error('[deselectResponder] 오류:', error);
    throw error;
  }
};
