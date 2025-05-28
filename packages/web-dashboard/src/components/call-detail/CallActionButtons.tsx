import React from 'react';
import { Call } from '../../services/callService';

interface CallActionButtonsProps {
  call: Call;
  onDispatch: (id: string) => Promise<void>;
  onComplete: (id: string) => Promise<void>;
  onReactivate: (id: string) => Promise<void>;
  onCancel: (id: string) => Promise<void>;
}

const CallActionButtons: React.FC<CallActionButtonsProps> = ({ 
  call, 
  onDispatch, 
  onComplete, 
  onReactivate, 
  onCancel 
}) => {
  // 완료된 재난의 경우
  if (call.status === 'completed') {
    return (
      <div className="mt-6 flex justify-start gap-2">
        <button 
          className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
          onClick={() => onReactivate(call.id)}
        >
          재호출하기
        </button>
      </div>
    );
  }

  // 미완료 재난의 경우
  return (
    <div className="mt-6 flex justify-start gap-2">
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
    </div>
  );
};

export default CallActionButtons;