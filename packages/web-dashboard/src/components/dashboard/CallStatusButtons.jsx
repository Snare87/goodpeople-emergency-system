// src/components/dashboard/CallStatusButtons.jsx
import React from 'react';
import { CALL_STATUS } from '../../constants/callTypes';

const CallStatusButtons = ({ call, onDispatch, onComplete, onReactivate, onCancel }) => {
  if (!call) return null;

  const { status, responder } = call;

  // 완료된 재난
  if (status === CALL_STATUS.COMPLETED) {
    return (
      <button 
        className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
        onClick={() => onReactivate(call.id)}
      >
        재호출하기
      </button>
    );
  }

  // 미완료 재난
  return (
    <div className="flex gap-2">
      {/* 호출하기 버튼 (idle 상태) */}
      {status === CALL_STATUS.IDLE && (
        <button 
          className="px-4 py-2 bg-primary text-white rounded hover:bg-blue-600"
          onClick={() => onDispatch(call.id)}
        >
          호출하기
        </button>
      )}
      
      {/* 찾는중 상태 */}
      {status === CALL_STATUS.DISPATCHED && !responder && (
        <>
          <button 
            className="px-4 py-2 bg-yellow-500 text-white rounded"
            disabled={true}
          >
            찾는중
          </button>
          <button 
            className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
            onClick={() => onCancel(call.id)}
          >
            호출취소
          </button>
        </>
      )}
      
      {/* 매칭완료 상태 */}
      {responder && (
        <button 
          className="px-4 py-2 bg-green-500 text-white rounded"
          disabled={true}
        >
          매칭완료
        </button>
      )}
      
      {/* 재난종료 버튼 */}
      <button 
        className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
        onClick={() => onComplete(call.id)}
      >
        재난종료
      </button>
    </div>
  );
};

export default CallStatusButtons;

// src/components/dashboard/DispatchInfoCard.jsx
import React from 'react';
import { formatDate, formatTime, getElapsedTime } from '../../utils/formatters';

const DispatchInfoCard = ({ call, currentTime }) => {
  if (!call) return null;

  return (
    <div className="space-y-4">
      {/* 발생 정보 */}
      <div className="p-3 bg-gray-50 rounded-lg">
        <h4 className="font-medium mb-2">발생 정보</h4>
        <p>주소: {call.address}</p>
        <p>날짜: {formatDate(call.startAt)}</p>
        <p>시간: {formatTime(call.startAt)}</p>
        <p className="text-xs text-gray-500 mt-1">
          {getElapsedTime(call.startAt, currentTime)}
        </p>
      </div>

      {/* 수락 정보 */}
      {call.acceptedAt && (
        <div className="p-3 bg-blue-50 rounded-lg">
          <h4 className="font-medium mb-2">수락 정보</h4>
          <p>날짜: {formatDate(call.acceptedAt)}</p>
          <p>시간: {formatTime(call.acceptedAt)}</p>
        </div>
      )}

      {/* 완료 정보 */}
      {call.completedAt && (
        <div className="p-3 bg-green-50 rounded-lg">
          <h4 className="font-medium mb-2">완료 정보</h4>
          <p>날짜: {formatDate(call.completedAt)}</p>
          <p>시간: {formatTime(call.completedAt)}</p>
        </div>
      )}
    </div>
  );
};

export default DispatchInfoCard;

// src/components/dashboard/ResponderInfo.jsx
import React from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants/badgeVariants';

const ResponderInfo = ({ responder }) => {
  if (!responder) {
    return (
      <div className="bg-white p-3 rounded-lg shadow-sm w-full flex items-center justify-center h-16">
        <p className="text-gray-500">매칭된 응답자가 없습니다</p>
      </div>
    );
  }

  const badgeVariant = POSITION_BADGE_VARIANTS[responder.position] || 'default';

  return (
    <div className="bg-white p-3 rounded-lg shadow-sm w-full">
      <div className="flex flex-row items-center justify-between">
        <div className="flex items-center space-x-2">
          <Badge variant={badgeVariant}>
            {responder.position || '대원'}
          </Badge>
          <span className="font-medium">{responder.name}</span>
        </div>
        <Badge variant="warning">진행중</Badge>
      </div>
    </div>
  );
};

export default ResponderInfo;

// src/components/dashboard/SituationInfo.jsx
import React from 'react';

const SituationInfo = ({ info }) => {
  return (
    <div className="bg-gray-200 rounded-lg flex items-center justify-center p-4 h-full">
      <div className="text-center">
        <h3 className="text-lg font-semibold mb-2 text-gray-800">상황 정보</h3>
        <p className="text-gray-600 font-medium">
          {info || '상세 정보가 없습니다'}
        </p>
      </div>
    </div>
  );
};

export default SituationInfo;

// src/components/dashboard/CallDetailPanel.jsx
import React, { useState, useEffect } from 'react';
import EmptyState from '../common/EmptyState';
import CallStatusButtons from './CallStatusButtons';
import DispatchInfoCard from './DispatchInfoCard';
import ResponderInfo from './ResponderInfo';
import SituationInfo from './SituationInfo';

const CallDetailPanel = ({ 
  call, 
  onDispatch, 
  onComplete, 
  onReactivate, 
  onCancel 
}) => {
  const [currentTime, setCurrentTime] = useState(Date.now());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now());
    }, 3000);
    
    return () => clearInterval(timer);
  }, []);

  if (!call) {
    return (
      <div className="h-full flex items-center justify-center">
        <EmptyState
          icon="📋"
          title="재난 목록을 선택하세요"
          description="좌측의 재난 목록에서 항목을 선택하면 상세 정보가 표시됩니다."
        />
      </div>
    );
  }

  return (
    <div className="grid grid-cols-12 gap-4 h-full">
      {/* 좌측: 기본 지령서 정보 (3/12) */}
      <div className="col-span-3 flex flex-col">
        <h3 className="text-lg font-semibold mb-2">
          {call.eventType} 상황
        </h3>
        
        <DispatchInfoCard call={call} currentTime={currentTime} />
        
        {/* 상태에 따른 버튼 */}
        <div className="mt-auto flex justify-center gap-2">
          <CallStatusButtons
            call={call}
            onDispatch={onDispatch}
            onComplete={onComplete}
            onReactivate={onReactivate}
            onCancel={onCancel}
          />
        </div>
      </div>
      
      {/* 중앙: 응답자 정보 (3/12) */}
      <div className="col-span-3 bg-gray-100 rounded-lg p-4 flex flex-col">
        <h3 className="text-lg font-semibold mb-3">응답자</h3>
        <div className="flex-1 flex items-center justify-center">
          <ResponderInfo responder={call.responder} />
        </div>
      </div>
      
      {/* 우측: 상황 정보 (6/12) */}
      <div className="col-span-6">
        <SituationInfo info={call.info} />
      </div>
    </div>
  );
};

export default CallDetailPanel;

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