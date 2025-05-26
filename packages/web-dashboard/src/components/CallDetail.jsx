// src/components/CallDetail.jsx
import React, { useState, useEffect } from 'react';
import CallInfoSection from './call-detail/CallInfoSection';
import CallTimeSection from './call-detail/CallTimeSection';
import ResponderInfo from './call-detail/ResponderInfo';
import CallActionButtons from './call-detail/CallActionButtons';

const CallDetail = ({ call, onDispatch, onComplete, onReactivate, onCancel }) => {
  // 실시간 갱신을 위한 타이머 상태 추가 (CallsList와 동일한 방식)
  const [currentTime, setCurrentTime] = useState(Date.now());
  
  // 타이머 간격을 3초로 설정 (CallsList와 동일)
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now());
    }, 3000);
    
    return () => clearInterval(timer);
  }, []);

  if (!call) {
    return <p className="text-gray-500">호출 항목을 선택하세요.</p>;
  }

  return (
    <div>
      <h3 className="text-lg font-semibold mb-2">
        {call.eventType} 지령서
      </h3>
      <p className="mb-2">주소: {call.address}</p>
      
      {/* 발생 정보 */}
      <CallInfoSection
        title="발생 정보"
        date={call.startAt}
        backgroundColor="bg-gray-50"
        showElapsedTime={true}
        currentTime={currentTime}
      />
      
      {/* 수락 정보 (있는 경우) */}
      {call.acceptedAt && (
        <CallTimeSection
          title="수락 정보"
          date={call.acceptedAt}
          startDate={call.startAt}
          backgroundColor="bg-blue-50"
        />
      )}
      
      {/* 완료 정보 (있는 경우) */}
      {call.completedAt && (
        <CallTimeSection
          title="완료 정보"
          date={call.completedAt}
          startDate={call.startAt}
          backgroundColor="bg-green-50"
        />
      )}
      
      {/* 응답자 정보 */}
      <ResponderInfo responder={call.responder} />
      
      {/* 액션 버튼들 */}
      <CallActionButtons
        call={call}
        onDispatch={onDispatch}
        onComplete={onComplete}
        onReactivate={onReactivate}
        onCancel={onCancel}
      />
    </div>
  );
};

export default React.memo(CallDetail);
