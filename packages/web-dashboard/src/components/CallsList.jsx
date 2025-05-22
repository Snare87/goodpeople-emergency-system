// src/components/CallsList.jsx
import React, { useState, useEffect } from 'react';
import { formatTime, getElapsedTime } from '../utils/formatters';

const CallsList = React.memo(function CallsList({ calls, onSelect, selectedId, onDispatch, onReactivate, showCompletedInfo = false }) {
  // 실시간 갱신을 위한 타이머 상태 추가
  const [currentTime, setCurrentTime] = useState(Date.now());
  
  // 타이머 간격을 3초로 늘림 (3000ms) - 더 적은 리렌더링
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now());
    }, 3000);
    
    return () => clearInterval(timer);
  }, []);

  // 이벤트 타입에 따른 배경색 설정
  const getEventTypeColor = (type) => {
    switch(type) {
      case '화재': return 'bg-red-100';
      case '구조': return 'bg-blue-100';
      case '구급': return 'bg-green-100';
      case '기타': return 'bg-gray-100';
      default: return 'bg-white';
    }
  };

  // 클릭 핸들러
  const handleClick = (e, call, action) => {
    e.stopPropagation();
    if (action) action(call.id);
  };

  if (!calls || calls.length === 0) {
    return (
      <p className="text-gray-500">
        {showCompletedInfo ? '완료된 재난이 없습니다.' : '현재 대기 중인 재난이 없습니다.'}
      </p>
    );
  }

  return (
  <ul className="space-y-4 w-full">
    {calls.map(call => (
       <li
         key={call.id}
         onClick={() => onSelect?.(call)}
         className={`cursor-pointer p-4 ${getEventTypeColor(call.eventType)} rounded-lg shadow flex justify-between items-center
           ${selectedId === call.id ? 'ring-2 ring-primary' : ''}
           ${showCompletedInfo ? 'opacity-80' : ''} 
         `}
       >
          <div>
            <p className={`font-semibold ${selectedId === call.id ? 'text-lg' : ''}`}>
              {call.eventType || call.customerName}
            </p>
            <p className="text-sm text-gray-600">{call.address}</p>
            
            {/* 완료된 재난의 경우 완료 시간 표시 */}
            {showCompletedInfo && call.completedAt && (
              <p className="text-xs text-gray-500 mt-1">
                완료: {formatTime(call.completedAt)}
              </p>
            )}
          </div>
          <div className="text-right">
            <div className="flex items-center justify-end gap-2">
              <p className={`${selectedId === call.id ? 'text-lg font-bold' : 'text-sm'}`}>
                {formatTime(call.startAt) || call.time}
              </p>
              {call.startAt && !showCompletedInfo && (
                <span className="text-xs text-gray-500">
                  {getElapsedTime(call.startAt, currentTime)}
                </span>
              )}
            </div>
            
            {/* 활성 재난인 경우 상태 버튼 표시 */}
            {!showCompletedInfo && (() => {
              const status = call.status || 'idle';
              const hasResponder = !!call.responder;
              
              if (hasResponder) {
                return (
                  <button
                    className="mt-2 px-3 py-1 bg-green-500 text-white rounded"
                    disabled={true}
                  >
                    매칭완료
                  </button>
                );
              } else if (status === 'dispatched') {
                return (
                  <button
                    className="mt-2 px-3 py-1 bg-yellow-500 text-white rounded"
                    disabled={true}
                  >
                    찾는중
                  </button>
                );
              } else {
                // 기본 상태 - 호출하기
                return (
                  <button
                    className="mt-2 px-3 py-1 bg-primary text-white rounded hover:bg-blue-600"
                    onClick={(e) => handleClick(e, call, onDispatch)}
                  >
                    호출하기
                  </button>
                );
              }
            })()}
            
            {/* 완료된 재난에는 "종료됨"과 "재호출하기" 표시 */}
            {showCompletedInfo && (
              <div className="flex flex-col gap-2 mt-2">
                <span className="px-3 py-1 bg-gray-500 text-white rounded text-sm">
                  종료됨
                </span>
                <button
                  className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                  onClick={(e) => handleClick(e, call, onReactivate)}
                >
                  재호출하기
                </button>
              </div>
            )}
          </div>
       </li>
      ))}
    </ul>
  );
});

export default CallsList;