// src/components/dashboard/DashboardLayout.tsx
import React from 'react';
import Card from '../common/Card';
import TabNav from '../common/TabNav';
import CallsList from '../CallsList';
import CallDetailPanel from './CallDetailPanel';
import GoogleMap from '../GoogleMap';
import { Call } from '../../services/callService';

type ListTab = 'active' | 'completed';

interface DashboardLayoutProps {
  // 데이터
  activeCalls: Call[];
  completedCalls: Call[];
  selectedCall: Call | null;
  selectedCallId: string | null;
  
  // 상태
  listTab: ListTab;
  setListTab: (tab: ListTab) => void;
  
  // 핸들러
  selectCall: (call: Call | null) => void;
  dispatchCall: (id: string) => Promise<void>;
  completeCall: (id: string) => Promise<void>;
  reactivateCall: (id: string) => Promise<void>;
  cancelCall: (id: string) => Promise<void>;
  
  // 지도
  mapCenter: [number, number];
}

const DashboardLayout: React.FC<DashboardLayoutProps> = ({
  // 데이터
  activeCalls,
  completedCalls,
  selectedCall,
  selectedCallId,
  
  // 상태
  listTab,
  setListTab,
  
  // 핸들러
  selectCall,
  dispatchCall,
  completeCall,
  reactivateCall,
  cancelCall,
  
  // 지도
  mapCenter
}) => {
  const [moveToLocation, setMoveToLocation] = React.useState<{ lat: number; lng: number; zoom?: number } | null>(null);
  
  const handleCandidateClick = (lat: number, lng: number) => {
    setMoveToLocation({ lat, lng, zoom: 15 });
  };
  
  // 디버깅 로그
  console.log('[DashboardLayout] selectedCallId:', selectedCallId, 'mapCenter:', mapCenter);
  console.log('[DashboardLayout] selectedCall:', selectedCall ? {
    id: selectedCall.id,
    eventType: selectedCall.eventType,
    status: selectedCall.status,
    candidatesCount: selectedCall.candidates ? Object.keys(selectedCall.candidates).length : 0
  } : null);
  const listTabs = [
    { key: 'active', label: '재난 목록' },
    { key: 'completed', label: '완료 목록' }
  ];

  return (
    <div className="h-[calc(100vh-88px)] flex gap-4">
      {/* 왼쪽: 재난 목록 (고정 너비) */}
      <div className="w-[500px] h-full">
        <div className="bg-white rounded-lg shadow h-full flex flex-col">
          <TabNav 
            tabs={listTabs}
            activeTab={listTab}
            onChange={setListTab as (key: string) => void}
          />
          
          {/* 스크롤 가능한 목록 영역 */}
          <div className="flex-1 overflow-y-auto p-4">
            {listTab === 'active' ? (
              <CallsList
                calls={activeCalls}
                onSelect={selectCall}
                selectedId={selectedCallId}
                onDispatch={(id: string) => dispatchCall(id)}
                onCancel={(id: string) => cancelCall(id)}
              />
            ) : (
              <CallsList
                calls={completedCalls}
                onSelect={selectCall}
                selectedId={selectedCallId}
                showCompletedInfo={true}
                onReactivate={(id: string) => reactivateCall(id)}
              />
            )}
          </div>
        </div>
      </div>

      {/* 오른쪽: 지령서와 지도 (나머지 너비) */}
      <div className="flex-1 h-full flex flex-col gap-4">
        {/* 지령서 패널 */}
        <div className="h-[45%]">
          <Card className="h-full">
            <CallDetailPanel
              key={selectedCall?.id || 'empty'}  // key 추가로 컴포넌트 재사용 방지
              call={selectedCall}
              onDispatch={dispatchCall}
              onComplete={completeCall}
              onReactivate={reactivateCall}
              onCancel={cancelCall}
              onCandidateClick={handleCandidateClick}
            />
          </Card>
        </div>

        {/* 지도 */}
        <div className="h-[55%]">
          <div className="bg-white rounded-lg shadow h-full relative overflow-hidden">
            <GoogleMap 
              calls={activeCalls} 
              center={mapCenter} 
              selectedCallId={selectedCallId || undefined}
              moveToLocation={moveToLocation}
            />
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardLayout;