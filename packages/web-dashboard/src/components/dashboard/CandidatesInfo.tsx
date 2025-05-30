// src/components/dashboard/CandidatesInfo.tsx
import React, { useState, useEffect } from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants';
import { ref, get, set } from 'firebase/database';
import { db } from '../../firebase';

interface Candidate {
  id: string;
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
    calculatedAt: number;
  };
}

interface CandidatesInfoProps {
  callId: string;
  candidates?: Record<string, Candidate>;
  selectedResponder?: any;
  onSelectCandidate?: (callId: string, candidate: Candidate) => void;
}

const CandidatesInfo: React.FC<CandidatesInfoProps> = ({ 
  callId, 
  candidates, 
  selectedResponder,
  onSelectCandidate 
}) => {
  const [candidatesCerts, setCandidatesCerts] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState<boolean>(false);
  const [selecting, setSelecting] = useState<string | null>(null);

  useEffect(() => {
    const loadCertifications = async () => {
      if (!candidates || Object.keys(candidates).length === 0) return;
      
      try {
        setLoading(true);
        const certsData: Record<string, string[]> = {};
        
        for (const candidate of Object.values(candidates)) {
          const userSnapshot = await get(ref(db, `users/${candidate.userId}`));
          if (userSnapshot.exists()) {
            const userData = userSnapshot.val();
            certsData[candidate.userId] = userData.certifications || [];
          }
        }
        
        setCandidatesCerts(certsData);
      } catch (error) {
        console.error('자격증 정보 로드 실패:', error);
      } finally {
        setLoading(false);
      }
    };
    
    loadCertifications();
  }, [candidates]);

  const handleSelectCandidate = async (candidate: Candidate) => {
    if (!onSelectCandidate || selecting) return;
    
    try {
      setSelecting(candidate.userId);
      
      // Firebase에 직접 업데이트
      await set(ref(db, `calls/${callId}/selectedResponder`), {
        ...candidate,
        selectedAt: Date.now()
      });
      
      // status를 accepted로 변경
      await set(ref(db, `calls/${callId}/status`), 'accepted');
      
      // 콜백 호출
      if (onSelectCandidate) {
        onSelectCandidate(callId, candidate);
      }
    } catch (error) {
      console.error('대원 선택 실패:', error);
      alert('대원 선택에 실패했습니다.');
    } finally {
      setSelecting(null);
    }
  };

  // 이미 선택된 대원이 있는 경우
  if (selectedResponder) {
    const certs = candidatesCerts[selectedResponder.userId] || [];
    const badgeVariant = POSITION_BADGE_VARIANTS[selectedResponder.position] || 'default';
    
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm w-full h-full flex flex-col">
        {/* 상단: 대원 정보 */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center space-x-3">
            <Badge variant={badgeVariant as any} size="md">
              {selectedResponder.position || '대원'}
            </Badge>
            <span className="text-lg font-medium">
              {selectedResponder.rank || '소방사'}
            </span>
            <span className="text-lg font-medium">
              {selectedResponder.name}
            </span>
          </div>
          <Badge variant="success" size="md">배정됨</Badge>
        </div>
        
        {/* 경로 정보 */}
        {selectedResponder.routeInfo && (
          <div className="mb-4 p-4 bg-green-50 rounded-lg border border-green-200">
            <div className="flex items-center justify-between mb-2">
              <h4 className="text-sm font-semibold text-green-800">
                🗺️ 예상 도착 정보 (T맵)
              </h4>
              <Badge variant="success" size="sm">
                최종 선택됨
              </Badge>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-xs text-gray-600">거리</p>
                <p className="text-lg font-bold text-green-900">
                  {selectedResponder.routeInfo.distanceText}
                </p>
              </div>
              <div>
                <p className="text-xs text-gray-600">예상 시간</p>
                <p className="text-lg font-bold text-green-900">
                  {selectedResponder.routeInfo.durationText}
                </p>
              </div>
            </div>
          </div>
        )}
        
        {/* 자격증 정보 */}
        <div className="flex-1">
          <h4 className="text-sm font-semibold text-gray-700 mb-3">보유 자격증</h4>
          {certs.length > 0 ? (
            <div className="space-y-2">
              {certs.map((cert, index) => (
                <div 
                  key={index} 
                  className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg text-sm font-medium"
                >
                  {cert}
                </div>
              ))}
            </div>
          ) : (
            <div className="text-sm text-gray-400">자격증 정보 없음</div>
          )}
        </div>
      </div>
    );
  }

  // 후보자가 없는 경우
  if (!candidates || Object.keys(candidates).length === 0) {
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm w-full flex flex-col items-center justify-center h-full">
        <p className="text-base text-gray-500">수락한 대원이 없습니다</p>
      </div>
    );
  }

  // 후보자 목록 표시
  const candidatesList = Object.values(candidates);
  
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm w-full h-full flex flex-col">
      <div className="flex items-center justify-between mb-4">
        <h4 className="text-lg font-semibold">후보자 목록</h4>
        <Badge variant="info" size="sm">
          {candidatesList.length}명 대기중
        </Badge>
      </div>
      
      <div className="flex-1 overflow-y-auto space-y-3">
        {candidatesList
          .sort((a, b) => {
            // 거리순으로 정렬 (가까운 순)
            const distA = a.routeInfo?.distance || Infinity;
            const distB = b.routeInfo?.distance || Infinity;
            return distA - distB;
          })
          .map((candidate) => {
            const certs = candidatesCerts[candidate.userId] || [];
            const badgeVariant = POSITION_BADGE_VARIANTS[candidate.position] || 'default';
            const isSelecting = selecting === candidate.userId;
            
            return (
              <div 
                key={candidate.userId}
                className="p-4 border border-gray-200 rounded-lg hover:border-blue-300 transition-colors"
              >
                {/* 대원 정보 */}
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center space-x-2">
                    <Badge variant={badgeVariant as any} size="sm">
                      {candidate.position}
                    </Badge>
                    <span className="text-sm font-medium">
                      {candidate.rank} {candidate.name}
                    </span>
                  </div>
                  <button
                    onClick={() => handleSelectCandidate(candidate)}
                    disabled={isSelecting}
                    className={`px-3 py-1 text-sm font-medium rounded-md transition-colors ${
                      isSelecting 
                        ? 'bg-gray-300 text-gray-500 cursor-not-allowed' 
                        : 'bg-blue-500 text-white hover:bg-blue-600'
                    }`}
                  >
                    {isSelecting ? '선택중...' : '선택'}
                  </button>
                </div>
                
                {/* 경로 정보 */}
                {candidate.routeInfo && (
                  <div className="grid grid-cols-3 gap-2 mb-2 text-sm">
                    <div className="bg-gray-50 p-2 rounded">
                      <p className="text-xs text-gray-500">거리</p>
                      <p className="font-semibold">{candidate.routeInfo.distanceText}</p>
                    </div>
                    <div className="bg-gray-50 p-2 rounded">
                      <p className="text-xs text-gray-500">시간</p>
                      <p className="font-semibold">{candidate.routeInfo.durationText}</p>
                    </div>
                    <div className="bg-gray-50 p-2 rounded">
                      <p className="text-xs text-gray-500">수락 시각</p>
                      <p className="font-semibold">
                        {new Date(candidate.acceptedAt).toLocaleTimeString('ko-KR', {
                          hour: '2-digit',
                          minute: '2-digit'
                        })}
                      </p>
                    </div>
                  </div>
                )}
                
                {/* 자격증 정보 */}
                {loading ? (
                  <div className="text-xs text-gray-400">자격증 로딩중...</div>
                ) : certs.length > 0 ? (
                  <div className="flex flex-wrap gap-1">
                    {certs.map((cert, index) => (
                      <span 
                        key={index}
                        className="px-2 py-1 bg-gray-100 text-gray-600 rounded text-xs"
                      >
                        {cert}
                      </span>
                    ))}
                  </div>
                ) : (
                  <div className="text-xs text-gray-400">자격증 정보 없음</div>
                )}
              </div>
            );
          })}
      </div>
    </div>
  );
};

export default CandidatesInfo;