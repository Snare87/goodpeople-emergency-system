// src/hooks/useDashboard.js
import { useState, useMemo } from 'react';
import useCallsData from './useCallsData';
import { useTimer } from './useTimer';

export const useDashboard = () => {
  const callsData = useCallsData();
  const currentTime = useTimer(3000);
  const [listTab, setListTab] = useState('active');

  // 지도 중심 좌표
  const mapCenter = useMemo(() => {
    const { selectedCall } = callsData;
    return selectedCall
      ? [selectedCall.lat, selectedCall.lng]
      : [37.5665, 126.9780];
  }, [callsData.selectedCall]);

  return {
    ...callsData,
    currentTime,
    listTab,
    setListTab,
    mapCenter
  };
};