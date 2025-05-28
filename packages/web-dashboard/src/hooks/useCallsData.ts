// src/hooks/useCallsData.ts
import { useState, useEffect, useMemo } from 'react';
import { subscribeToCalls, Call } from '../services/callService';

interface UseCallsDataReturn {
  activeCalls: Call[];
  completedCalls: Call[];
  selectedCall: Call | null;
  selectedCallId: string | null;
  selectCall: (call: Call | null) => void;
  setSelectedCallId: (id: string | null) => void;
}

export default function useCallsData(): UseCallsDataReturn {
  const [allCalls, setAllCalls] = useState<Call[]>([]);
  const [selectedCallId, setSelectedCallId] = useState<string | null>(null);
  
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
      .sort((a, b) => {
        const aTime = typeof a.startAt === 'number' ? a.startAt : new Date(a.startAt).getTime();
        const bTime = typeof b.startAt === 'number' ? b.startAt : new Date(b.startAt).getTime();
        return bTime - aTime;
      });
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
  const selectCall = (call: Call | null) => {
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