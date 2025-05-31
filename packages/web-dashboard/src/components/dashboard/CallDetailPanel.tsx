// src/components/dashboard/CallDetailPanel.tsx
import React, { useState, useEffect } from 'react';
import EmptyState from '../common/EmptyState';
import CallStatusButtons from './CallStatusButtons';
import DispatchInfoCard from './DispatchInfoCard';
import EnhancedCandidatesInfo from './EnhancedCandidatesInfo';
import SituationInfo from './SituationInfo';
import { Call } from '../../services/callService';

interface CallDetailPanelProps {
  call: Call | null;
  onDispatch: (id: string) => Promise<void>;
  onComplete: (id: string) => Promise<void>;
  onReactivate: (id: string) => Promise<void>;
  onCancel: (id: string) => Promise<void>;
  onCandidateClick?: (lat: number, lng: number) => void;
}

const CallDetailPanel: React.FC<CallDetailPanelProps> = ({ 
  call, 
  onDispatch, 
  onComplete, 
  onReactivate, 
  onCancel,
  onCandidateClick 
}) => {
  const [currentTime, setCurrentTime] = useState<number>(Date.now());

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
    <div className="h-full p-4 flex">
      {/* 좌측: 기본 정보 */}
      <div className="w-[300px] pr-4 flex flex-col">
        <h3 className="text-lg font-semibold mb-4">
          {call.eventType} 상황
        </h3>
        
        <div className="flex-1">
          <DispatchInfoCard call={call} currentTime={currentTime} />
        </div>
        
        <div className="mt-4">
          <CallStatusButtons
            call={call}
            onDispatch={onDispatch}
            onComplete={onComplete}
            onReactivate={onReactivate}
            onCancel={onCancel}
          />
        </div>
      </div>
      
       {/* 중앙: 후보자/응답자 정보 */}
      <div className="w-[400px] px-4">
        <div className="bg-gray-100 rounded-lg p-4 h-full flex flex-col">
          <h3 className="text-lg font-semibold mb-3">
            {call.selectedResponder ? '배정된 대원' : '후보자 목록'}
          </h3>
          <div className="flex-1">
            <EnhancedCandidatesInfo 
              key={`${call.id}-candidates`}  // key 추가로 컴포넌트 재사용 방지
              call={call}
              callId={call.id}
              candidates={call.candidates}
              selectedResponder={call.selectedResponder}
              onSelectCandidate={(callId, candidate) => {
                console.log('후보자 선택됨:', candidate.name);
                // Firebase 업데이트는 EnhancedCandidatesInfo 내부에서 처리됨
              }}
              onCancelSelection={(callId) => {
                console.log('대원 선택 취소됨');
                // Firebase 업데이트는 EnhancedCandidatesInfo 내부에서 처리됨
              }}
              onCandidateClick={onCandidateClick}
            />
          </div>
        </div>
      </div>
      
      {/* 우측: 상황 정보 */}
      <div className="flex-1 pl-4">
        <SituationInfo info={call.info} />
      </div>
    </div>
  );
};

export default CallDetailPanel;