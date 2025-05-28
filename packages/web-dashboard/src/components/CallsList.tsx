// src/components/CallsList.tsx
import React, { memo, MouseEvent } from 'react';
import EmptyState from './common/EmptyState';
import Badge from './common/Badge';
import { formatTime, getElapsedTime } from '../utils/formatters';
import { useTimer } from '../hooks/useTimer';
import { CALL_TYPE_COLORS } from '../constants';
import { Call } from '../services/callService';

interface CallListItemProps {
  call: Call;
  isSelected: boolean;
  onSelect?: (call: Call) => void;
  onDispatch?: (id: string) => void;
  onCancel?: (id: string) => void;
  onReactivate?: (id: string) => void;
  showCompletedInfo?: boolean;
  currentTime: number;
}

const CallListItem = memo<CallListItemProps>(({ 
  call, 
  isSelected, 
  onSelect, 
  onDispatch, 
  onCancel, 
  onReactivate,
  showCompletedInfo,
  currentTime 
}) => {
  const handleClick = (e: MouseEvent, action?: (id: string) => void) => {
    e.stopPropagation();
    if (action) action(call.id);
  };

  const bgColor = CALL_TYPE_COLORS[call.eventType] || 'bg-white';

  return (
    <li
      onClick={() => onSelect?.(call)}
      className={`cursor-pointer p-4 ${bgColor} rounded-lg shadow flex justify-between items-center
        ${isSelected ? 'ring-2 ring-primary' : ''}
        ${showCompletedInfo ? 'opacity-80' : ''} 
        hover:shadow-md transition-shadow
      `}
    >
      <div className="flex-1">
        <p className={`font-semibold ${isSelected ? 'text-lg' : ''}`}>
          {call.eventType}
        </p>
        <p className="text-sm text-gray-600">{call.address}</p>
        
         {/* 상황 정보 미리보기 */}
        {call.info && (
          <div className="mt-2 p-2 bg-white rounded border border-gray-200">
            <p className="text-xs text-gray-700 font-medium">
              {call.info.length > 30 ? `${call.info.substring(0, 30)}...` : call.info}
            </p>
          </div>
        )}
        
        {/* 완료 시간 */}
        {showCompletedInfo && call.completedAt && (
          <p className="text-xs text-gray-500 mt-1">
            완료: {formatTime(call.completedAt)}
          </p>
        )}
      </div>

      <div className="ml-4 text-right">
        <div className="flex items-center justify-end gap-2">
          <p className={`${isSelected ? 'text-lg font-bold' : 'text-sm'}`}>
            {formatTime(call.startAt)}
          </p>
          {call.startAt && !showCompletedInfo && (
            <span className="text-xs text-gray-500">
              {getElapsedTime(call.startAt, currentTime)}
            </span>
          )}
        </div>
        
        {/* 액션 버튼 */}
        <div className="mt-2">
          {!showCompletedInfo ? (
            // 활성 재난 버튼
            <>
              {call.responder ? (
                <Badge variant="success">매칭완료</Badge>
              ) : call.status === 'dispatched' ? (
                <div className="flex flex-col gap-1">
                  <Badge variant="warning">찾는중</Badge>
                  {onCancel && (
                    <button
                      className="px-3 py-1 bg-gray-500 text-white rounded text-sm hover:bg-gray-600"
                      onClick={(e) => handleClick(e, onCancel)}
                    >
                      취소
                    </button>
                  )}
                </div>
              ) : (
                onDispatch && (
                  <button
                    className="px-3 py-1 bg-primary text-white rounded hover:bg-blue-600"
                    onClick={(e) => handleClick(e, onDispatch)}
                  >
                    호출하기
                  </button>
                )
              )}
            </>
          ) : (
            // 완료된 재난 버튼
            <div className="flex flex-col gap-2">
              <Badge variant="default">종료됨</Badge>
              {onReactivate && (
                <button
                  className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600"
                  onClick={(e) => handleClick(e, onReactivate)}
                >
                  재호출하기
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </li>
  );
});

CallListItem.displayName = 'CallListItem';

interface CallsListProps {
  calls: Call[];
  onSelect?: (call: Call | null) => void;
  selectedId?: string | null;
  onDispatch?: (id: string) => void;
  onReactivate?: (id: string) => void;
  onCancel?: (id: string) => void;
  showCompletedInfo?: boolean;
}

const CallsList: React.FC<CallsListProps> = ({ 
  calls, 
  onSelect, 
  selectedId, 
  onDispatch, 
  onReactivate, 
  onCancel, 
  showCompletedInfo = false 
}) => {
  const currentTime = useTimer(3000);

  if (!calls || calls.length === 0) {
    return (
      <EmptyState
        icon={showCompletedInfo ? "✅" : "📋"}
        title={showCompletedInfo ? '완료된 재난이 없습니다.' : '현재 대기 중인 재난이 없습니다.'}
      />
    );
  }

  return (
    <ul className="space-y-4 w-full">
      {calls.map(call => (
        <CallListItem
          key={call.id}
          call={call}
          isSelected={selectedId === call.id}
          onSelect={onSelect}
          onDispatch={onDispatch}
          onCancel={onCancel}
          onReactivate={onReactivate}
          showCompletedInfo={showCompletedInfo}
          currentTime={currentTime}
        />
      ))}
    </ul>
  );
};

export default memo(CallsList);