// src/components/call-detail/EnhancedCandidatesPanel.tsx
import React, { useState, useEffect } from 'react';
import { Call, selectResponder } from '../../services/callService';
import { aiScoringService } from '../../services/aiScoringService';
import { autoSelectService } from '../../services/autoSelectService';
import { FiClock, FiMapPin, FiUser, FiCheck, FiAward, FiZap, FiPlay, FiPause } from 'react-icons/fi';
import { ref, onValue, off } from 'firebase/database';
import { db } from '../../firebase';

interface EnhancedCandidatesPanelProps {
  call: Call;
  onSelectionComplete?: () => void;
  onCandidateClick?: (lat: number, lng: number) => void; // 지도 이동 콜백
}

interface CandidateWithScore {
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
  aiScore?: number;
  isOptimal?: boolean;
  recommendationReason?: string;
}

export default function EnhancedCandidatesPanel({ 
  call, 
  onSelectionComplete,
  onCandidateClick 
}: EnhancedCandidatesPanelProps) {
  const [isSelecting, setIsSelecting] = useState(false);
  const [candidatesWithScores, setCandidatesWithScores] = useState<CandidateWithScore[]>([]);
  const [autoSelectEnabled, setAutoSelectEnabled] = useState(false);
  const [countdown, setCountdown] = useState(0);
  const [willSelectUserId, setWillSelectUserId] = useState<string | undefined>();
  const [userDataMap, setUserDataMap] = useState<Record<string, any>>({});
  
  // 디버깅: 어떤 call의 candidates를 표시하고 있는지 확인
  useEffect(() => {
    if (call?.candidates) {
      console.log(`[EnhancedCandidatesPanel] Call ${call.id} - ${call.eventType} has ${Object.keys(call.candidates).length} candidates`);
    }
  }, [call]);

  // 사용자 데이터 가져오기
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
    if (!call.candidates || Object.keys(userDataMap).length === 0) return;

    // 재난 종류를 전달하여 점수 계산
    const scores = aiScoringService.calculateCandidateScores(
      call.candidates, 
      userDataMap,
      call.eventType, // 재난 종류 추가
      call.dispatchedAt // 호출 시간 추가
    );
    
    const candidatesArray = Object.entries(call.candidates).map(([userId, candidate]) => {
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
          call.eventType
        ) : undefined,
        // 자격증 정보 추가
        certifications: userData.certifications || []
      } as CandidateWithScore;
    });

    // AI 점수 순으로 정렬 (낮을수록 좋음)
    candidatesArray.sort((a, b) => (a.aiScore || 999999) - (b.aiScore || 999999));
    
    setCandidatesWithScores(candidatesArray);
  }, [call.candidates, userDataMap, call.eventType]);

  // 자동 선택 상태 업데이트
  useEffect(() => {
    // 경로 정보가 있는 후보자가 있는지 확인
    const hasValidCandidates = candidatesWithScores.some(c => 
      c.routeInfo && (c.aiScore || 999999) < 50000
    );
    
    if (autoSelectEnabled && call.status === 'dispatched' && hasValidCandidates) {
      autoSelectService.startAutoSelect(call.id, 60, (status) => {
        setCountdown(status.remainingSeconds);
        setWillSelectUserId(status.willSelectUserId);
        
        if (!status.isActive) {
          setAutoSelectEnabled(false);
        }
      });
    } else {
      autoSelectService.stopAutoSelect(call.id);
      setCountdown(0);
      setWillSelectUserId(undefined);
      // 유효한 후보자가 없으면 자동선택 비활성화
      if (autoSelectEnabled && !hasValidCandidates) {
        setAutoSelectEnabled(false);
      }
    }
    
    return () => {
      autoSelectService.stopAutoSelect(call.id);
    };
  }, [autoSelectEnabled, call.id, call.status, candidatesWithScores]);

  if (!call || (call.status !== 'dispatched' && call.status !== 'accepted') || !call.candidates) {
    return null;
  }

  if (candidatesWithScores.length === 0) {
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
    setAutoSelectEnabled(false); // 수동 선택 시 자동 선택 중지
    
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

  const handleCandidateClick = (candidate: CandidateWithScore) => {
    // 대원의 현재 위치로 지도 이동 (routeInfo에서 추출하거나 별도 위치 정보 사용)
    // 일단 목적지(재난 위치)로 이동
    if (onCandidateClick && call.location) {
      onCandidateClick(call.location.lat, call.location.lng);
    }
  };

  const formatAIScore = (score?: number): string => {
    if (!score) return '-';
    // 경로 정보가 없는 경우 높은 점수를 '정보 없음'으로 표시  
    if (score > 50000) return '경로정보 없음';
    return Math.round(score).toLocaleString() + '점';
  };

  const formatCertifications = (certifications: string[]): string => {
    if (!certifications || certifications.length === 0) return '없음';
    return certifications.slice(0, 2).join(', ') + (certifications.length > 2 ? ` 외 ${certifications.length - 2}개` : '');
  };

  // 재난 종류에 따른 아이콘
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
    <div className="bg-white border border-gray-200 rounded-lg p-4 mt-4 shadow-sm">
      {/* 헤더 */}
      <div className="flex justify-between items-center mb-4">
        <h4 className="font-semibold text-gray-800 flex items-center">
          <FiUser className="mr-2" />
          후보 대원 목록 ({candidatesWithScores.length}명)
        </h4>
        
        {/* 자동 선택 토글 */}
        {call.status === 'dispatched' && (
          <div className="flex items-center gap-2">
            <label className="flex items-center cursor-pointer">
              <input
                type="checkbox"
                checked={autoSelectEnabled}
                onChange={(e) => setAutoSelectEnabled(e.target.checked)}
                className="mr-2"
              />
              <span className="text-sm font-medium text-gray-700">자동 선택</span>
            </label>
            {autoSelectEnabled && countdown > 0 && (
              <div className="flex items-center text-sm text-blue-600 font-semibold">
                <FiClock className="mr-1" />
                {countdown}초
              </div>
            )}
          </div>
        )}
      </div>

      {/* 재난 종류별 자격증 중요도 안내 */}
      <div className="bg-gray-50 border border-gray-200 rounded p-2 mb-3 text-xs text-gray-600">
        <span className="font-semibold">{getEventIcon(call.eventType)} {call.eventType} 재난</span>
        <span className="ml-2">자격증 중요도: {
          call.eventType === '화재' ? '화재대응능력 > 인명구조사 > 기타' :
          call.eventType === '구조' ? '인명구조사 > 화재대응/의료' :
          call.eventType === '구급' ? '간호사/응급구조사 > 기타' :
          '모든 자격증 균등'
        }</span>
      </div>

      {/* 자동 선택 안내 */}
      {autoSelectEnabled && countdown > 0 && (
        <div className="bg-blue-50 border border-blue-200 rounded p-3 mb-4 flex items-center">
          <FiZap className="text-blue-600 mr-2" />
          <span className="text-sm text-blue-800">
            {countdown}초 후 AI가 최적의 대원을 자동으로 선택합니다.
          </span>
        </div>
      )}
      
      {/* 후보자 목록 */}
      <div className="space-y-3">
        {candidatesWithScores.map((candidate) => {
          const isWillBeSelected = autoSelectEnabled && willSelectUserId === candidate.userId;
          const userData = userDataMap[candidate.userId] || {};
          
          return (
            <div
              key={candidate.userId}
              onClick={() => handleCandidateClick(candidate)}
              className={`
                border rounded-lg p-4 cursor-pointer transition-all
                ${candidate.isOptimal ? 'border-blue-400 bg-blue-50' : 'border-gray-200 bg-white'}
                ${isWillBeSelected ? 'ring-2 ring-blue-500 shadow-lg' : ''}
                hover:shadow-md
              `}
            >
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  {/* 대원 정보 */}
                  <div className="flex items-center gap-2 mb-1">
                    <span className="font-semibold text-gray-800">{candidate.name}</span>
                    {candidate.isOptimal && (
                      <span className="px-2 py-1 bg-blue-500 text-white text-xs rounded-full flex items-center">
                        <FiAward className="mr-1" size={10} />
                        최적
                      </span>
                    )}
                    {isWillBeSelected && (
                      <span className="px-2 py-1 bg-green-500 text-white text-xs rounded-full animate-pulse">
                        자동 선택 예정
                      </span>
                    )}
                  </div>
                  
                  <div className="text-sm text-gray-600 mb-2">
                    {candidate.position} {candidate.rank && `· ${candidate.rank}`}
                  </div>
                  
                  {/* 경로 정보 */}
                  {candidate.routeInfo && (
                    <div className="flex items-center gap-4 text-sm text-gray-600 mb-2">
                      <span className="flex items-center">
                        <FiClock className="mr-1" size={12} />
                        {candidate.routeInfo.durationText}
                      </span>
                      <span className="flex items-center">
                        <FiMapPin className="mr-1" size={12} />
                        {candidate.routeInfo.distanceText}
                      </span>
                    </div>
                  )}
                  
                  {/* 자격증 정보 (재난 종류에 맞는 자격증 강조) */}
                  <div className="text-xs text-gray-500 mb-2">
                    자격증: {aiScoringService.formatCertifications(userData.certifications || [])}
                  </div>
                  
                  {/* AI 점수 및 추천 이유 */}
                  <div className="flex items-center justify-between">
                    <div className="text-xs text-gray-500">
                      AI 점수: {formatAIScore(candidate.aiScore)}점
                      {candidate.recommendationReason && (
                        <span className="ml-2 text-blue-600">
                          ({candidate.recommendationReason})
                        </span>
                      )}
                    </div>
                  </div>
                </div>
                
                {/* 선택 버튼 */}
                {call.status === 'dispatched' && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleSelectCandidate(candidate.userId);
                    }}
                    disabled={isSelecting}
                    className={`
                      px-4 py-2 rounded font-medium transition-all flex items-center gap-2
                      ${candidate.isOptimal 
                        ? 'bg-blue-500 text-white hover:bg-blue-600' 
                        : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                      }
                      disabled:opacity-50 disabled:cursor-not-allowed
                    `}
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
                )}
              </div>
            </div>
          );
        })}
      </div>
      
      {/* 안내 메시지 */}
      <div className="mt-4 text-sm text-gray-600">
        <p>※ 대원을 클릭하면 위치를 확인할 수 있습니다.</p>
        <p>※ AI 점수는 도착시간, 거리, {call.eventType} 재난에 적합한 자격증, 계급을 종합 평가합니다.</p>
      </div>
    </div>
  );
}
