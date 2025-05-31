// src/components/dashboard/CallStatusButtons.tsx
import React from 'react';
import { CALL_STATUS } from '../../constants';
import { Call } from '../../services/callService';

interface CallStatusButtonsProps {
  call: Call | null;
  onDispatch: (id: string) => Promise<void>;
  onComplete: (id: string) => Promise<void>;
  onReactivate: (id: string) => Promise<void>;
  onCancel: (id: string) => Promise<void>;
}

const CallStatusButtons: React.FC<CallStatusButtonsProps> = ({ 
  call, 
  onDispatch, 
  onComplete, 
  onReactivate, 
  onCancel 
}) => {
  if (!call) return null;

  const { status, selectedResponder } = call;

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
      {status === CALL_STATUS.DISPATCHED && !selectedResponder && (
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
      {selectedResponder && (
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