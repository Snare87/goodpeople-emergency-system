// src/components/dashboard/DashboardLayout.jsx
import React from 'react';
import Card from '../common/Card';
import TabNav from '../common/TabNav';
import CallsList from '../CallsList';
import CallDetailPanel from './CallDetailPanel';
import KakaoMap from '../KakaoMap';

const DashboardLayout = ({
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
            onChange={setListTab}
          />
          
          {/* 스크롤 가능한 목록 영역 */}
          <div className="flex-1 overflow-y-auto p-4">
            {listTab === 'active' ? (
              <CallsList
                calls={activeCalls}
                onSelect={selectCall}
                selectedId={selectedCallId}
                onDispatch={dispatchCall}
                onCancel={cancelCall}
              />
            ) : (
              <CallsList
                calls={completedCalls}
                onSelect={selectCall}
                selectedId={selectedCallId}
                showCompletedInfo={true}
                onReactivate={reactivateCall}
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
              call={selectedCall}
              onDispatch={dispatchCall}
              onComplete={completeCall}
              onReactivate={reactivateCall}
              onCancel={cancelCall}
            />
          </Card>
        </div>

        {/* 지도 */}
        <div className="h-[55%]">
          <div className="bg-white rounded-lg shadow h-full relative overflow-hidden">
            <KakaoMap calls={activeCalls} center={mapCenter} />
          </div>
        </div>
      </div>
    </div>
  );
};

export default DashboardLayout;