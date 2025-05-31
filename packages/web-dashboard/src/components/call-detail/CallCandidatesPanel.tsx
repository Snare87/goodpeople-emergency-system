// src/components/call-detail/CallCandidatesPanel.tsx
import React, { useState } from 'react';
import { Call, selectResponder, deselectResponder } from '../../services/callService';
import { FiClock, FiMapPin, FiUser, FiCheck } from 'react-icons/fi';

interface CallCandidatesPanelProps {
  call: Call;
  onSelectionComplete?: () => void;
}

export default function CallCandidatesPanel({ call, onSelectionComplete }: CallCandidatesPanelProps) {
  const [isSelecting, setIsSelecting] = useState(false);

  if (!call || call.status !== 'dispatched' || !call.candidates) {
    return null;
  }

  const candidatesList = Object.values(call.candidates) as Array<{
    userId: string;
    name: string;
    position: string;
    rank?: string;
    acceptedAt: number;
    routeInfo?: {
      distance: number;
      distanceText: string;
      duration: number;
      durationText: string;
    };
  }>;

  if (candidatesList.length === 0) {
    return (
      <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mt-4">
        <h4 className="font-semibold text-yellow-800 mb-2">
          <FiUser className="inline mr-2" />
          대기 중...
        </h4>
        <p className="text-sm text-yellow-700">
          아직 수락한 대원이 없습니다. 대원들의 응답을 기다리고 있습니다.
        </p>
      </div>
    );
  }

  const handleSelectCandidate = async (candidateId: string) => {
    if (isSelecting) return;
    
    setIsSelecting(true);
    try {
      await selectResponder(call.id, candidateId);
      if (onSelectionComplete) {
        onSelectionComplete();
      }
    } catch (error) {
      console.error('대원 선택 실패:', error);
      alert('대원 선택에 실패했습니다.');
    } finally {
      setIsSelecting(false);
    }
  };

  return (
    <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mt-4">
      <h4 className="font-semibold text-blue-800 mb-3">
        <FiUser className="inline mr-2" />
        후보 대원 목록 ({candidatesList.length}명)
      </h4>
      
      <div className="space-y-2">
        {candidatesList.map((candidate) => (
          <div
            key={candidate.userId}
            className="bg-white border border-blue-200 rounded p-3 flex justify-between items-center"
          >
            <div className="flex-1">
              <div className="font-semibold">{candidate.name}</div>
              <div className="text-sm text-gray-600">
                {candidate.position} {candidate.rank && `· ${candidate.rank}`}
              </div>
              {candidate.routeInfo && (
                <div className="text-sm text-gray-500 mt-1">
                  <FiClock className="inline mr-1" size={12} />
                  {candidate.routeInfo.durationText}
                  <FiMapPin className="inline ml-2 mr-1" size={12} />
                  {candidate.routeInfo.distanceText}
                </div>
              )}
            </div>
            
            <button
              onClick={() => handleSelectCandidate(candidate.userId)}
              disabled={isSelecting}
              className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
            >
              {isSelecting ? (
                <span>선택 중...</span>
              ) : (
                <>
                  <FiCheck />
                  선택
                </>
              )}
            </button>
          </div>
        ))}
      </div>
      
      <div className="mt-3 text-sm text-blue-700">
        ※ 대원을 선택하면 해당 대원에게 출동 명령이 전달됩니다.
      </div>
    </div>
  );
}
