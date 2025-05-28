// src/hooks/useCallsData.js
import { useState, useEffect, useMemo } from 'react';
import { subscribeToCalls } from '../services/callService';

export default function useCallsData() {
  const [allCalls, setAllCalls] = useState([]);
  const [selectedCallId, setSelectedCallId] = useState(null);
  
  // 데이터베이스 리스너 설정
  useEffect(() => {
    const unsubscribe = subscribeToCalls((calls) => {
      setAllCalls(calls);
    });
    
    return unsubscribe;
  }, []);
  
  // 활성 재난과 완료된 재난 분류
  const activeCalls = useMemo(() => {
    return allCalls
      .filter(call => call.status !== 'completed')
      .sort((a, b) => (b.startAt || 0) - (a.startAt || 0));
  }, [allCalls]);
  
  const completedCalls = useMemo(() => {
    return allCalls
      .filter(call => call.status === 'completed')
      .sort((a, b) => (b.completedAt || 0) - (a.completedAt || 0));
  }, [allCalls]);
  
  // 선택된 콜 찾기
  const selectedCall = useMemo(() => {
    if (!selectedCallId) return null;
    return allCalls.find(call => call.id === selectedCallId) || null;
  }, [allCalls, selectedCallId]);
  
  // 콜 선택 핸들러
  const selectCall = (call) => {
    setSelectedCallId(call?.id || null);
  };
  
  return {
    activeCalls,
    completedCalls,
    selectedCall,
    selectedCallId,
    selectCall,
    setSelectedCallId
  };
}