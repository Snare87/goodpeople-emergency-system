// src/components/dashboard/IncidentCandidatesPanel.tsx
import React, { useEffect, useState } from 'react';
import { 
  ref,
  onValue,
  update,
  runTransaction,
  serverTimestamp,
  get
} from 'firebase/database';
import { db } from '../../firebase';
import { FiClock, FiMapPin, FiUser, FiAward, FiCheck } from 'react-icons/fi';

interface Candidate {
  id: string;
  acceptedAt: any;
  lat: number;
  lng: number;
  distanceKm?: number;
  etaSec?: number;
  qualificationScore: number;
  state: 'pending' | 'cancel';
  responderInfo: {
    name: string;
    position: string;
    rank: string;
    phone?: string;
  };
}

interface IncidentCandidatesPanelProps {
  incidentId: string;
  incidentStatus: string;
  onCandidateSelect?: (candidateId: string) => void;
}

export function IncidentCandidatesPanel({ 
  incidentId, 
  incidentStatus,
  onCandidateSelect 
}: IncidentCandidatesPanelProps) {
  const [candidates, setCandidates] = useState<Candidate[]>([]);
  const [selectedCandidate, setSelectedCandidate] = useState<string | null>(null);
  const [autoSelectEnabled, setAutoSelectEnabled] = useState(true);
  const [isAssigning, setIsAssigning] = useState(false);

  useEffect(() => {
    if (!incidentId) return;

    // 후보자 실시간 구독
    const candidatesRef = ref(db, `incidents/${incidentId}/candidates`);
    const unsubscribe = onValue(candidatesRef, (snapshot) => {
      const candidatesList: Candidate[] = [];
      const data = snapshot.val();
      
      if (data) {
        Object.entries(data).forEach(([userId, candidateData]: [string, any]) => {
          if (candidateData.state === 'pending') {
            candidatesList.push({
              id: userId,
              ...candidateData
            } as Candidate);
          }
        });
      }

      // ETA 기준 정렬 (짧은 순)
      candidatesList.sort((a, b) => {
        const etaA = a.etaSec ?? 999999;
        const etaB = b.etaSec ?? 999999;
        return etaA - etaB;
      });

      setCandidates(candidatesList);
    });

    return () => unsubscribe();
  }, [incidentId]);

  // 점수 계산
  const calculateScore = (candidate: Candidate): number => {
    const w1 = 1.0;  // ETA 가중치
    const w3 = 1.0;  // 자격 페널티 가중치
    
    const etaScore = (candidate.etaSec || 999999) * w1;
    const qualificationPenalty = candidate.qualificationScore === 0 ? 300 : 0;
    
    return Math.round((etaScore + (qualificationPenalty * w3)) / 10) / 10;
  };

  // 수동 선택
  const handleManualSelect = async (candidateId: string) => {
    if (isAssigning || incidentStatus !== 'broadcasting') return;
    
    setIsAssigning(true);
    
    try {
      const candidate = candidates.find(c => c.id === candidateId);
      if (!candidate) return;

      const incidentRef = ref(db, `incidents/${incidentId}`);
      
      await runTransaction(incidentRef, async (currentData) => {
        if (!currentData || currentData.status !== 'broadcasting') {
          throw new Error('이미 배정된 재난입니다');
        }

        // 재난 상태 업데이트
        return {
          ...currentData,
          status: 'assigned',
          chosenResponderId: candidateId,
          assignedAt: serverTimestamp(),
          selectionMethod: 'manual',
        };
      });

      console.log(`수동 배정 완료: ${candidate.responderInfo.name}`);
      if (onCandidateSelect) {
        onCandidateSelect(candidateId);
      }
      
    } catch (error) {
      console.error('배정 오류:', error);
      alert('배정 중 오류가 발생했습니다.');
    } finally {
      setIsAssigning(false);
    }
  };

  // ETA 포맷
  const formatEta = (etaSec?: number): string => {
    if (!etaSec) return '계산 중...';
    const minutes = Math.ceil(etaSec / 60);
    return `${minutes}분`;
  };

  // 거리 포맷
  const formatDistance = (distanceKm?: number): string => {
    if (!distanceKm) return '-';
    return `${distanceKm.toFixed(1)}km`;
  };

  if (incidentStatus !== 'broadcasting') {
    return (
      <div className="p-4 text-center text-gray-500">
        이미 배정이 완료된 재난입니다.
      </div>
    );
  }

  if (candidates.length === 0) {
    return (
      <div className="p-4 text-center">
        <div className="text-gray-500 mb-2">아직 수락한 대원이 없습니다</div>
        <div className="text-sm text-gray-400">대원들의 수락을 기다리는 중...</div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* 헤더 */}
      <div className="p-4 border-b bg-gray-50">
        <div className="flex justify-between items-center mb-2">
          <h3 className="text-lg font-semibold flex items-center gap-2">
            <FiUser className="text-gray-600" />
            후보 대원 ({candidates.length}명)
          </h3>
          <div className="flex items-center gap-2">
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={autoSelectEnabled}
                onChange={(e) => setAutoSelectEnabled(e.target.checked)}
                className="rounded"
              />
              자동 선택
            </label>
          </div>
        </div>
        
        {/* 자동 선택 안내 */}
        {autoSelectEnabled && (
          <div className="text-xs text-gray-500 bg-blue-50 p-2 rounded">
            5초 후 ETA가 가장 짧은 대원이 자동으로 선택됩니다
          </div>
        )}
      </div>

      {/* 후보자 목록 */}
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {candidates.map((candidate, index) => {
          const score = calculateScore(candidate);
          const isOptimal = index === 0; // ETA 최단 = 최적

          return (
            <div
              key={candidate.id}
              className={`border rounded-lg p-4 transition-all ${
                isOptimal ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'
              } ${selectedCandidate === candidate.id ? 'ring-2 ring-blue-500' : ''}`}
              onClick={() => setSelectedCandidate(candidate.id)}
            >
              {/* 최적 배지 */}
              {isOptimal && (
                <div className="flex items-center gap-1 text-xs bg-blue-500 text-white px-2 py-1 rounded-full w-fit mb-2">
                  <FiAward />
                  최적 대원
                </div>
              )}

              <div className="flex justify-between items-start">
                {/* 대원 정보 */}
                <div className="flex-1">
                  <div className="font-semibold text-lg">
                    {candidate.responderInfo.name}
                  </div>
                  <div className="text-sm text-gray-600">
                    {candidate.responderInfo.rank} · {candidate.responderInfo.position}
                  </div>
                  
                  {/* 자격증 점수 */}
                  {candidate.qualificationScore > 0 && (
                    <div className="mt-1 text-xs text-green-600">
                      자격점수: {candidate.qualificationScore}점
                    </div>
                  )}
                </div>

                {/* 거리/시간 정보 */}
                <div className="text-right">
                  <div className="flex items-center justify-end gap-1 text-2xl font-bold text-blue-600">
                    <FiClock className="text-lg" />
                    {formatEta(candidate.etaSec)}
                  </div>
                  <div className="flex items-center justify-end gap-1 text-sm text-gray-500">
                    <FiMapPin className="text-xs" />
                    {formatDistance(candidate.distanceKm)}
                  </div>
                </div>
              </div>

              {/* 하단 정보 */}
              <div className="mt-3 pt-3 border-t border-gray-100 flex justify-between items-center">
                <div className="text-xs text-gray-500">
                  AI 점수: {score}점
                </div>
                
                {/* 선택 버튼 */}
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    handleManualSelect(candidate.id);
                  }}
                  disabled={isAssigning}
                  className={`px-4 py-1.5 rounded text-sm font-medium transition-colors ${
                    isOptimal
                      ? 'bg-blue-500 text-white hover:bg-blue-600'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  } disabled:opacity-50 disabled:cursor-not-allowed`}
                >
                  {isAssigning ? '배정 중...' : '선택'}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* 하단 통계 */}
      <div className="p-4 border-t bg-gray-50 text-sm">
        <div className="grid grid-cols-2 gap-4 text-center">
          <div>
            <div className="text-gray-500">평균 도착시간</div>
            <div className="font-semibold">
              {formatEta(
                candidates.reduce((sum, c) => sum + (c.etaSec || 0), 0) / candidates.length
              )}
            </div>
          </div>
          <div>
            <div className="text-gray-500">평균 거리</div>
            <div className="font-semibold">
              {formatDistance(
                candidates.reduce((sum, c) => sum + (c.distanceKm || 0), 0) / candidates.length
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
