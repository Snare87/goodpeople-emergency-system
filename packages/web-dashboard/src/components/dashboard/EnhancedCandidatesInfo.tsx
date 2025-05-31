// src/components/dashboard/EnhancedCandidatesInfo.tsx
import React, { useState, useEffect } from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants';
import { ref, get, onValue, off } from 'firebase/database';
import { db } from '../../firebase';
import { selectResponder, deselectResponder } from '../../services/callService';
import { aiScoringService } from '../../services/aiScoringService';
import { autoSelectService } from '../../services/autoSelectService';
import { FiClock, FiMapPin, FiAward, FiZap } from 'react-icons/fi';

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

interface CandidateWithScore extends Candidate {
  aiScore?: number;
  isOptimal?: boolean;
  recommendationReason?: string;
  certifications?: string[];
}

interface EnhancedCandidatesInfoProps {
  call: any; // 전체 call 객체를 받아서 eventType 사용
  callId: string;
  candidates?: Record<string, Candidate>;
  selectedResponder?: any;
  onSelectCandidate?: (callId: string, candidate: Candidate) => void;
  onCancelSelection?: (callId: string) => void;
  onCandidateClick?: (lat: number, lng: number) => void;
}

const EnhancedCandidatesInfo: React.FC<EnhancedCandidatesInfoProps> = ({ 
  call,
  callId, 
  candidates, 
  selectedResponder,
  onSelectCandidate,
  onCancelSelection,
  onCandidateClick 
}) => {
  const [userDataMap, setUserDataMap] = useState<Record<string, any>>({});
  const [candidatesWithScores, setCandidatesWithScores] = useState<CandidateWithScore[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [selecting, setSelecting] = useState<string | null>(null);
  const [autoSelectEnabled, setAutoSelectEnabled] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const [willSelectUserId, setWillSelectUserId] = useState<string | undefined>();
  
  // 디버깅: props 변경 추적
  useEffect(() => {
    console.log(`[EnhancedCandidatesInfo] Props changed:`, {
      callId,
      eventType: call?.eventType,
      status: call?.status,
      candidatesCount: candidates ? Object.keys(candidates).length : 0,
      candidateIds: candidates ? Object.keys(candidates) : []
    });
  }, [callId, call, candidates]);
  
  // callId가 변경되면 자동 선택 상태 초기화
  useEffect(() => {
    setAutoSelectEnabled(false);
    setCountdown(0);
    setWillSelectUserId(undefined);
  }, [callId]);

  // 사용자 데이터 실시간 구독
  useEffect(() => {
    const usersRef = ref(db, 'users');
    const unsubscribe = onValue(usersRef, (snapshot) => {
      if (snapshot.exists()) {
        setUserDataMap(snapshot.val());
      }
    });

    return () => off(usersRef, 'value', unsubscribe);
  }, []);

  // AI 점수 계산 및 정렬
  useEffect(() => {
    if (!candidates || Object.keys(userDataMap).length === 0) {
      setCandidatesWithScores([]);
      return;
    }

    const scores = aiScoringService.calculateCandidateScores(
      candidates, 
      userDataMap,
      call?.eventType || '기타',
      call?.dispatchedAt // dispatchedAt 전달
    );
    
    console.log('[EnhancedCandidatesInfo] AI 점수 계산 결과:', scores.map(s => ({
      userId: s.userId,
      totalScore: s.totalScore,
      hasRouteInfo: candidates[s.userId]?.routeInfo ? true : false
    })));
    
    const candidatesArray = Object.entries(candidates).map(([userId, candidate]) => {
      const score = scores.find(s => s.userId === userId);
      const userData = userDataMap[userId] || {};
      
      return {
        ...candidate,
        userId,
        aiScore: score?.totalScore,
        isOptimal: score?.isOptimal,
        recommendationReason: score ? aiScoringService.getRecommendationReason(
          candidate, 
          score, 
          call?.eventType || '기타'
        ) : undefined,
        certifications: userData.certifications || []
      } as CandidateWithScore;
    });

    // AI 점수 순으로 정렬 (낮을수록 좋음)
    candidatesArray.sort((a, b) => (a.aiScore || 999999) - (b.aiScore || 999999));
    
    setCandidatesWithScores(candidatesArray);
  }, [candidates, userDataMap, call?.eventType]);

  // 자동 선택 상태 업데이트
  useEffect(() => {
    // 경로 정보가 있는 후보자가 있는지 확인
    const hasValidCandidates = candidatesWithScores.some(c => 
      c.routeInfo && (c.aiScore || 999999) < 50000
    );
    
    if (autoSelectEnabled && call?.status === 'dispatched' && !selectedResponder && hasValidCandidates) {
      autoSelectService.startAutoSelect(callId, 60, (status) => {
        setCountdown(status.remainingSeconds);
        setWillSelectUserId(status.willSelectUserId);
        
        if (!status.isActive) {
          setAutoSelectEnabled(false);
        }
      });
    } else {
      autoSelectService.stopAutoSelect(callId);
      setCountdown(0);
      setWillSelectUserId(undefined);
      // 유효한 후보자가 없으면 자동선택 비활성화
      if (autoSelectEnabled && !hasValidCandidates) {
        setAutoSelectEnabled(false);
      }
    }
    
    return () => {
      autoSelectService.stopAutoSelect(callId);
    };
  }, [autoSelectEnabled, callId, call?.status, selectedResponder, candidatesWithScores]);

  const handleSelectCandidate = async (candidate: Candidate) => {
    if (selecting) return;
    
    try {
      setSelecting(candidate.userId);
      setAutoSelectEnabled(false); // 수동 선택 시 자동 선택 중지
      
      await selectResponder(callId, candidate.userId);
      
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

  const handleCancelSelection = async () => {
    if (!onCancelSelection) return;
    
    try {
      await deselectResponder(callId);
      
      if (onCancelSelection) {
        onCancelSelection(callId);
      }
    } catch (error) {
      console.error('대원 선택 취소 실패:', error);
      alert('대원 선택 취소에 실패했습니다.');
    }
  };

  const formatAIScore = (score?: number): string => {
    if (!score) return '-';
    // 경로 정보가 없는 경우 높은 점수를 '정보 없음'으로 표시
    if (score > 50000) return '경로정보 없음';
    return Math.round(score).toLocaleString() + '점';
  };

  const getEventIcon = (eventType: string): string => {
    const icons: Record<string, string> = {
      '화재': '🔥',
      '구조': '🚨',
      '구급': '🚑',
      '기타': '⚠️'
    };
    return icons[eventType] || '⚠️';
  };

  return (
    <div className="bg-white p-4 rounded-lg shadow-sm w-full h-full flex flex-col">
      {/* 선택된 대원이 있는 경우 */}
      {selectedResponder && (
        <div className="mb-4 p-3 bg-green-50 rounded-lg border-2 border-green-300">
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center space-x-2">
              <Badge variant={POSITION_BADGE_VARIANTS[selectedResponder.position] || 'default' as any} size="md">
                {selectedResponder.position || '대원'}
              </Badge>
              <span className="text-base font-medium">
                {selectedResponder.rank || '소방사'} {selectedResponder.name}
              </span>
              <Badge variant="success" size="sm">배정된 대원</Badge>
            </div>
            {onCancelSelection && (
              <button
                onClick={handleCancelSelection}
                className="px-2 py-1 text-xs bg-red-500 text-white rounded hover:bg-red-600 transition-colors"
              >
                취소
              </button>
            )}
          </div>
          
          {selectedResponder.routeInfo && (
            <div className="grid grid-cols-2 gap-2 mt-2">
              <div className="bg-white p-1.5 rounded text-xs">
                <p className="text-gray-600">거리</p>
                <p className="font-bold text-green-900">
                  {selectedResponder.routeInfo.distanceText}
                </p>
              </div>
              <div className="bg-white p-1.5 rounded text-xs">
                <p className="text-gray-600">예상 시간</p>
                <p className="font-bold text-green-900">
                  {selectedResponder.routeInfo.durationText}
                </p>
              </div>
            </div>
          )}
        </div>
      )}
      
      {/* 후보자 목록 헤더 */}
      <div className="flex items-center justify-between mb-3">
        <h4 className="text-base font-semibold flex items-center">
          {selectedResponder ? '추가 후보자' : '후보자 목록'}
          {candidatesWithScores.length > 0 && (
            <Badge variant="info" size="sm" className="ml-2">
              {candidatesWithScores.filter(c => !selectedResponder || c.userId !== selectedResponder.userId).length}명
            </Badge>
          )}
        </h4>
        {/* 디버깅 정보 추가 */}
        <span className="text-xs text-gray-500">
          CallID: {callId} | EventType: {call?.eventType}
        </span>
        {!selectedResponder && call?.status === 'dispatched' && candidatesWithScores.length > 0 && (
          <div className="flex items-center gap-2">
            <label className="flex items-center cursor-pointer text-xs">
              <input
                type="checkbox"
                checked={autoSelectEnabled}
                onChange={(e) => setAutoSelectEnabled(e.target.checked)}
                className="mr-1"
              />
              <span className="font-medium text-gray-700">자동 선택</span>
            </label>
            {autoSelectEnabled && countdown > 0 && (
              <div className="flex items-center text-xs text-blue-600 font-semibold">
                <FiClock className="mr-1" size={12} />
                {countdown}초
              </div>
            )}
          </div>
        )}
      </div>

      {/* 재난 종류별 자격증 중요도 안내 */}
      {call?.eventType && candidatesWithScores.length > 0 && (
        <div className="bg-gray-50 border border-gray-200 rounded p-2 mb-2 text-xs text-gray-600">
          <span className="font-semibold">{getEventIcon(call.eventType)} {call.eventType} 재난</span>
          <span className="ml-2">자격증 중요도: {
            call.eventType === '화재' ? '화재대응능력 > 인명구조' :
            call.eventType === '구조' ? '인명구조 > 응급구조' :
            call.eventType === '구급' ? '간호사/응급구조 > 기타' :
            '모든 자격증 균등'
          }</span>
        </div>
      )}

      {/* 자동 선택 안내 */}
      {autoSelectEnabled && countdown > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded p-2 mb-2 flex items-center text-xs">
          <FiZap className="text-blue-600 mr-1" size={14} />
          <span className="text-blue-800">
            {countdown}초 후 AI가 최적의 대원을 자동으로 선택합니다.
          </span>
        </div>
      )}

      {/* 후보자 목록 */}
      {candidatesWithScores.length === 0 || 
        (selectedResponder && candidatesWithScores.length === 1 && candidatesWithScores[0].userId === selectedResponder.userId) ? (
        <div className="flex-1 flex items-center justify-center">
          <p className="text-sm text-gray-500">
            {selectedResponder ? '추가 후보자가 없습니다' : '수락한 대원이 없습니다'}
          </p>
        </div>
      ) : (
        <div className="flex-1 overflow-y-auto space-y-2">
          {candidatesWithScores
            .filter(candidate => !selectedResponder || candidate.userId !== selectedResponder.userId)
            .map((candidate) => {
              const isSelecting = selecting === candidate.userId;
              const isWillBeSelected = autoSelectEnabled && willSelectUserId === candidate.userId;
              const badgeVariant = POSITION_BADGE_VARIANTS[candidate.position] || 'default';
              
              return (
                <div 
                  key={candidate.userId}
                  onClick={() => {
                    if (onCandidateClick && call?.location) {
                      onCandidateClick(call.location.lat, call.location.lng);
                    }
                  }}
                  className={`
                    p-3 border rounded-lg cursor-pointer transition-all
                    ${candidate.isOptimal ? 'border-blue-400 bg-blue-50' : 'border-gray-200 bg-white'}
                    ${isWillBeSelected ? 'ring-2 ring-blue-500 shadow-lg' : ''}
                    hover:shadow-md
                  `}
                >
                  {/* 대원 정보 */}
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-center space-x-2">
                      <Badge variant={badgeVariant as any} size="sm">
                        {candidate.position}
                      </Badge>
                      <span className="text-sm font-medium">
                        {candidate.rank} {candidate.name}
                      </span>
                      {candidate.isOptimal && (
                        <span className="px-1.5 py-0.5 bg-blue-500 text-white text-xs rounded-full flex items-center">
                          <FiAward className="mr-0.5" size={10} />
                          최적
                        </span>
                      )}
                      {isWillBeSelected && (
                        <span className="px-1.5 py-0.5 bg-green-500 text-white text-xs rounded-full animate-pulse">
                          자동 선택 예정
                        </span>
                      )}
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleSelectCandidate(candidate);
                      }}
                      disabled={isSelecting}
                      className={`px-3 py-1 text-xs font-medium rounded transition-colors ${
                        candidate.isOptimal
                          ? 'bg-blue-500 text-white hover:bg-blue-600'
                          : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      } disabled:opacity-50 disabled:cursor-not-allowed`}
                    >
                      {isSelecting ? '선택중...' : '선택'}
                    </button>
                  </div>
                  
                  {/* 경로 및 AI 정보 */}
                  <div className="grid grid-cols-3 gap-1.5 text-xs">
                    {candidate.routeInfo && (
                      <>
                        <div className="bg-gray-50 p-1.5 rounded">
                          <p className="text-gray-500">거리</p>
                          <p className="font-semibold">{candidate.routeInfo.distanceText}</p>
                        </div>
                        <div className="bg-gray-50 p-1.5 rounded">
                          <p className="text-gray-500">시간</p>
                          <p className="font-semibold">{candidate.routeInfo.durationText}</p>
                        </div>
                      </>
                    )}
                    <div className="bg-gray-50 p-1.5 rounded">
                      <p className="text-gray-500">AI점수</p>
                      <p className="font-semibold">{formatAIScore(candidate.aiScore)}</p>
                    </div>
                  </div>
                  
                  {/* 자격증 및 추천 이유 */}
                  <div className="mt-2">
                    {candidate.certifications && candidate.certifications.length > 0 && (
                      <div className="text-xs text-gray-600 mb-1">
                        자격증: {aiScoringService.formatCertifications(candidate.certifications)}
                      </div>
                    )}
                    {candidate.recommendationReason && (
                      <div className="text-xs text-blue-600">
                        추천: {candidate.recommendationReason}
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
        </div>
      )}
    </div>
  );
};

export default EnhancedCandidatesInfo;
