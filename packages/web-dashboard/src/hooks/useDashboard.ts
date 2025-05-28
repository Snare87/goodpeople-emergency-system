// src/hooks/useDashboard.ts
import { useState, useMemo } from 'react';
import useCallsData from './useCallsData';
import { useTimer } from './useTimer';

type ListTab = 'active' | 'completed';

interface UseDashboardReturn extends ReturnType<typeof useCallsData> {
  currentTime: number;
  listTab: ListTab;
  setListTab: (tab: ListTab) => void;
  mapCenter: [number, number];
}

export const useDashboard = (): UseDashboardReturn => {
  const callsData = useCallsData();
  const currentTime = useTimer(3000);
  const [listTab, setListTab] = useState<ListTab>('active');

  // 지도 중심 좌표
  const mapCenter = useMemo((): [number, number] => {
    const { selectedCall } = callsData;
    if (selectedCall && selectedCall.location) {
      return [selectedCall.location.lat, selectedCall.location.lng];
    }
    return [37.5665, 126.9780];
  }, [callsData.selectedCall]);

  return {
    ...callsData,
    currentTime,
    listTab,
    setListTab,
    mapCenter
  };
};