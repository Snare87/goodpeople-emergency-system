// src/pages/DashboardPage.jsx
import React from 'react';
import Header from '../components/Header';
import DashboardLayout from '../components/dashboard/DashboardLayout';
import { useDashboard } from '../hooks/useDashboard';
import { 
  dispatchCall, 
  completeCall, 
  reactivateCall, 
  cancelCall 
} from '../services/callService';

export default function DashboardPage() {
  const {
    activeCalls,
    completedCalls,
    selectedCall,
    selectedCallId,
    selectCall,
    listTab,
    setListTab,
    mapCenter
  } = useDashboard();

  return (
    <div className="h-screen flex flex-col bg-gray-50">
      <Header title="대시보드" />

      <main className="flex-1 p-4 overflow-hidden">
        <DashboardLayout
          // 데이터
          activeCalls={activeCalls}
          completedCalls={completedCalls}
          selectedCall={selectedCall}
          selectedCallId={selectedCallId}
          
          // 상태
          listTab={listTab}
          setListTab={setListTab}
          
          // 핸들러
          selectCall={selectCall}
          dispatchCall={dispatchCall}
          completeCall={completeCall}
          reactivateCall={reactivateCall}
          cancelCall={cancelCall}
          
          // 지도
          mapCenter={mapCenter}
        />
      </main>
    </div>
  );
}