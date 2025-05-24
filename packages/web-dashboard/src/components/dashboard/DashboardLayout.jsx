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
    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
      {/* 왼쪽: 재난 목록 */}
      <aside className="md:col-span-1">
        <Card className="h-[calc(100vh-200px)]">
          <TabNav 
            tabs={listTabs}
            activeTab={listTab}
            onChange={setListTab}
          />
          
          <div className="p-4 overflow-y-auto h-[calc(100%-48px)]">
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
        </Card>
      </aside>

      {/* 오른쪽: 지령서와 지도 */}
      <div className="md:col-span-2 grid grid-rows-2 gap-6" style={{ height: 'calc(100vh - 150px)' }}>
        {/* 지령서 패널 */}
        <Card>
          <CallDetailPanel
            call={selectedCall}
            onDispatch={dispatchCall}
            onComplete={completeCall}
            onReactivate={reactivateCall}
            onCancel={cancelCall}
          />
        </Card>

        {/* 지도 */}
        <Card title="지도">
          <KakaoMap calls={activeCalls} center={mapCenter} />
        </Card>
      </div>
    </div>
  );
};

export default DashboardLayout;