// src/components/dashboard/CandidatesInfo.tsx
import React, { useState, useEffect } from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants';
import { ref, get } from 'firebase/database';
import { db } from '../../firebase';
import { selectResponder, deselectResponder } from '../../services/callService';

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
  onCancelSelection?: (callId: string) => void;
}

const CandidatesInfo: React.FC<CandidatesInfoProps> = ({ 
  callId, 
  candidates, 
  selectedResponder,
  onSelectCandidate,
  onCancelSelection 
}) => {
  const [candidatesCerts, setCandidatesCerts] = useState<Record<string, string[]>>({});
  const [loading, setLoading] = useState<boolean>(false);
  const [selecting, setSelecting] = useState<string | null>(null);
  
  console.log('[CandidatesInfo] 렌더링:', {
    callId,
    hasCandidates: !!candidates,
    candidatesCount: candidates ? Object.keys(candidates).length : 0,
    hasSelectedResponder: !!selectedResponder,
    hasOnSelectCandidate: !!onSelectCandidate,
    selectedResponder: selectedResponder,
    candidatesKeys: candidates ? Object.keys(candidates) : []
  });

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
    console.log('[handleSelectCandidate] 시작:', candidate.name);
    console.log('[handleSelectCandidate] onSelectCandidate:', !!onSelectCandidate);
    console.log('[handleSelectCandidate] selecting:', selecting);
    
    if (selecting) {
      console.log('[handleSelectCandidate] 이미 선택 중이므로 종료');
      return;
    }
    
    try {
      setSelecting(candidate.userId);
      
      // selectResponder 함수 사용
      console.log('[handleSelectCandidate] selectResponder 호출');
      await selectResponder(callId, candidate.userId);
      
      // 콜백 호출
      if (onSelectCandidate) {
        onSelectCandidate(callId, candidate);
      }
      console.log('[handleSelectCandidate] 전체 프로세스 완료');
    } catch (error) {
      console.error('대원 선택 실패:', error);
      alert('대원 선택에 실패했습니다.');
    } finally {
      setSelecting(null);
    }
  };

  // 대원 선택 취소 함수
  const handleCancelSelection = async () => {
    if (!onCancelSelection) return;
    
    try {
      console.log('[대원 선택 취소] 시작');
      
      // deselectResponder 함수 사용
      await deselectResponder(callId);
      
      console.log('[대원 선택 취소] 완료');
      
      if (onCancelSelection) {
        onCancelSelection(callId);
      }
    } catch (error) {
      console.error('대원 선택 취소 실패:', error);
      alert('대원 선택 취소에 실패했습니다.');
    }
  };

  // 전체 UI 렌더링
  return (
    <div className="bg-white p-6 rounded-lg shadow-sm w-full h-full flex flex-col">
      {/* 선택된 대원이 있는 경우 */}
      {selectedResponder && (
        <div className="mb-4 p-4 bg-green-50 rounded-lg border-2 border-green-300">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center space-x-3">
              <Badge variant={POSITION_BADGE_VARIANTS[selectedResponder.position] || 'default' as any} size="md">
                {selectedResponder.position || '대원'}
              </Badge>
              <span className="text-lg font-medium">
                {selectedResponder.rank || '소방사'} {selectedResponder.name}
              </span>
              <Badge variant="success" size="sm">배정된 대원</Badge>
            </div>
            {onCancelSelection && (
              <button
                onClick={handleCancelSelection}
                className="px-3 py-1 text-sm bg-red-500 text-white rounded-md hover:bg-red-600 transition-colors"
              >
                선택 취소
              </button>
            )}
          </div>
          
          {/* 경로 정보 */}
          {selectedResponder.routeInfo && (
            <div className="grid grid-cols-2 gap-4 mt-3">
              <div className="bg-white p-2 rounded">
                <p className="text-xs text-gray-600">거리</p>
                <p className="font-bold text-green-900">
                  {selectedResponder.routeInfo.distanceText}
                </p>
              </div>
              <div className="bg-white p-2 rounded">
                <p className="text-xs text-gray-600">예상 시간</p>
                <p className="font-bold text-green-900">
                  {selectedResponder.routeInfo.durationText}
                </p>
              </div>
            </div>
          )}
        </div>
      )}
      
      {/* 후보자 목록 헤더 */}
      <div className="flex items-center justify-between mb-4">
        <h4 className="text-lg font-semibold">
          {selectedResponder ? '추가 후보자' : '후보자 목록'}
        </h4>
        {candidates && Object.keys(candidates).length > 0 && (
          <Badge variant="info" size="sm">
            {selectedResponder 
              ? Object.keys(candidates).length - 1  // 선택된 대원 제외
              : Object.keys(candidates).length
            }명 대기중
          </Badge>
        )}
      </div>

      {/* 후보자가 없거나 선택된 대원만 있는 경우 */}
      {(!candidates || Object.keys(candidates).length === 0 || 
        (selectedResponder && Object.keys(candidates).length === 1 && candidates[selectedResponder.userId])) ? (
        <div className="flex-1 flex items-center justify-center">
          <p className="text-base text-gray-500">
            {selectedResponder ? '추가 후보자가 없습니다' : '수락한 대원이 없습니다'}
          </p>
        </div>
      ) : (
        /* 후보자 목록 */
        <div className="flex-1 overflow-y-auto space-y-3">
        {Object.values(candidates)
          .filter(candidate => {
            // 선택된 대원은 후보자 목록에서 제외
            const shouldExclude = selectedResponder && candidate.userId === selectedResponder.userId;
            console.log('[필터링]', candidate.name, 'userId:', candidate.userId, 
              'selectedResponder userId:', selectedResponder?.userId, '제외?:', shouldExclude);
            return !shouldExclude;
          })
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
                    onClick={(e) => {
                      e.stopPropagation();
                      console.log('[버튼 클릭] 후보자:', candidate.name);
                      handleSelectCandidate(candidate);
                    }}
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
      )}
    </div>
  );
};

export default CandidatesInfo;