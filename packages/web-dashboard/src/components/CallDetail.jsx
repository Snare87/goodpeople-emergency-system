// src/components/CallDetail.jsx
import React, { useState, useEffect } from 'react';
import { formatDate, formatTime, formatDateTime, getDetailedElapsedTime, getElapsedTime } from '../utils/formatters';

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
      
      {/* 발생 정보 (날짜/시간) - 경과 시간 부분 수정 */}
      <div className="mb-4 p-3 bg-gray-50 rounded-lg" style={{ maxWidth: '200px' }}>
        <h4 className="font-medium mb-2">발생 정보</h4>
        <p>날짜: {formatDate(call.startAt)}</p>
        <p>시간: {formatTime(call.startAt)}</p>
        <p className="text-xs text-gray-500 mt-1">
          {getElapsedTime(call.startAt, currentTime)}
        </p>
      </div>
      
      {/* 수락 정보 (있는 경우) */}
      {call.acceptedAt && (
        <div className="mb-4 p-3 bg-blue-50 rounded-lg">
          <h4 className="font-medium mb-2">수락 정보</h4>
          <p>날짜: {formatDate(call.acceptedAt)}</p>
          <p>시간: {formatTime(call.acceptedAt)}</p>
          <p className="mt-1">경과 시간: {getDetailedElapsedTime(call.startAt, call.acceptedAt)}</p>
        </div>
      )}
      
      {/* 완료 정보 (있는 경우) */}
      {call.completedAt && (
        <div className="mb-4 p-3 bg-green-50 rounded-lg">
          <h4 className="font-medium mb-2">완료 정보</h4>
          <p>날짜: {formatDate(call.completedAt)}</p>
          <p>시간: {formatTime(call.completedAt)}</p>
          <p className="mt-1">총 소요 시간: {getDetailedElapsedTime(call.startAt, call.completedAt)}</p>
        </div>
      )}
      
      {/* 응답자 정보 (있는 경우) */}
      {call.responder && (
        <div className="mt-4 p-3 bg-yellow-50 rounded-lg">
          <h4 className="font-medium mb-2">응답자 정보</h4>
          <p>이름: {call.responder.name}</p>
          {call.responder.position && (
            <p>직책: {call.responder.position}</p>
          )}
        </div>
      )}
      
      {/* 상태에 따른 버튼 */}
      <div className="mt-6 flex justify-start gap-2">
        {/* 버튼 코드는 변경 없음 */}
        {/* 완료된 재난의 경우 재호출하기 버튼 표시 */}
        {call.status === 'completed' ? (
          <button 
            className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
            onClick={() => onReactivate(call.id)}
          >
            재호출하기
          </button>
        ) : (
          // 미완료 재난의 경우 기존 버튼들 표시
          <>
            {/* 호출하기 버튼 (idle 상태일 때) */}
            {call.status === 'idle' && (
              <button 
                className="px-4 py-2 bg-primary text-white rounded hover:bg-blue-600"
                onClick={() => onDispatch(call.id)}
              >
                호출하기
              </button>
            )}
            
             {/* 찾는중 상태일 때 호출취소 버튼 표시 */}
            {call.status === 'dispatched' && !call.responder && (
              <div className="flex gap-2">
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
              </div>
            )}
            
            {/* 매칭완료 버튼 (responder가 있을 때) */}
            {call.responder && (
              <button 
                className="px-4 py-2 bg-green-500 text-white rounded"
                disabled={true}
              >
                매칭완료
              </button>
            )}
            
            {/* 재난종료 버튼 (미완료 상태에만 표시) */}
            <button 
              className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
              onClick={() => onComplete(call.id)}
            >
              재난종료
            </button>
          </>
        )}
      </div>
    </div>
  );
};

export default React.memo(CallDetail);