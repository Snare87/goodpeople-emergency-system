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