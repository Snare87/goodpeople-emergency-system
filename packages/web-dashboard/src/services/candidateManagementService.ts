// packages/web-dashboard/src/services/candidateManagementService.ts
import { ref, onValue, update, get } from 'firebase/database';
import { db } from '../firebase';

interface Candidate {
  id: string;
  userId: string;
  name: string;
  position: string;
  rank: string;
  certifications: string[];
  
  // 거리/시간 정보
  straightDistance: number;
  actualDistance: number;
  actualDistanceText: string;
  estimatedArrival: number;
  estimatedArrivalText: string;
  
  // 위치 정보
  currentLocation: {
    lat: number;
    lng: number;
  };
  
  // 메타 정보
  acceptedAt: number;
  score?: number;
  routeApiUsed: 'google' | 'tmap' | 'straight';
  lastUpdated?: number;
}

export class CandidateManagementService {
  // 후보자 목록 실시간 감지
  static subscribeToCandidates(
    callId: string,
    onUpdate: (candidates: Candidate[]) => void
  ): () => void {
    const candidatesRef = ref(db, `calls/${callId}/candidates`);
    
    const unsubscribe = onValue(candidatesRef, (snapshot) => {
      const candidatesData = snapshot.val() || {};
      const candidates: Candidate[] = Object.entries(candidatesData)
        .map(([id, data]) => ({
          id,
          ...(data as any)
        }));
      
      // 점수 계산
      const scoredCandidates = candidates.map(candidate => ({
        ...candidate,
        score: this.calculateScore(candidate)
      }));
      
      onUpdate(scoredCandidates);
    });
    
    return unsubscribe;
  }
  
  // 점수 계산
  static calculateScore(candidate: Candidate): number {
    let score = 0;
    
    // 1. 실제 도로 거리 점수 (0-40점)
    const maxDistance = 10000; // 10km
    const distanceScore = Math.max(0, 40 - (candidate.actualDistance / maxDistance * 40));
    score += distanceScore;
    
    // 2. 도착 시간 점수 (0-30점)
    const maxTime = 1800; // 30분
    const timeScore = Math.max(0, 30 - (candidate.estimatedArrival / maxTime * 30));
    score += timeScore;
    
    // 3. 자격증 점수 (0-20점)
    const certScore = Math.min(20, candidate.certifications.length * 5);
    score += certScore;
    
    // 4. 계급 점수 (0-10점)
    const rankScores: Record<string, number> = {
      '소방사': 5,
      '소방교': 6,
      '소방장': 7,
      '소방위': 8,
      '소방경': 9,
      '소방령': 10,
      '소방정': 10,
    };
    score += rankScores[candidate.rank] || 5;
    
    // 5. 경로 효율성 보너스 (최대 5점)
    const efficiency = candidate.straightDistance / candidate.actualDistance;
    if (efficiency > 0.8) {
      score += 5;
    }
    
    return Math.round(score * 10) / 10; // 소수점 1자리까지
  }
  
  // 최적 후보자 추천
  static getOptimalCandidate(candidates: Candidate[]): Candidate | null {
    if (candidates.length === 0) return null;
    
    return candidates.reduce((best, current) => 
      (current.score || 0) > (best.score || 0) ? current : best
    );
  }
  
  // 수동으로 대원 선정
  static async selectCandidate(
    callId: string,
    candidateId: string,
    selectedBy: string
  ): Promise<void> {
    try {
      // 선택된 후보자 정보 가져오기
      const candidateSnapshot = await get(
        ref(db, `calls/${callId}/candidates/${candidateId}`)
      );
      
      if (!candidateSnapshot.exists()) {
        throw new Error('후보자 정보를 찾을 수 없습니다.');
      }
      
      const candidateData = candidateSnapshot.val();
      
      // 재난 정보 업데이트
      await update(ref(db, `calls/${callId}`), {
        status: 'accepted',
        acceptedAt: Date.now(),
        selectedResponderId: candidateData.userId,
        selectionMethod: 'manual',
        selectedBy: selectedBy,
        responder: {
          id: candidateData.userId,
          name: candidateData.name,
          position: candidateData.position,
          rank: candidateData.rank,
          lat: candidateData.currentLocation.lat,
          lng: candidateData.currentLocation.lng,
          estimatedArrival: candidateData.estimatedArrival,
          estimatedArrivalText: candidateData.estimatedArrivalText,
        }
      });
      
      console.log(`[후보자 선정] ${candidateData.name} 대원이 선정되었습니다.`);
    } catch (error) {
      console.error('[후보자 선정 오류]', error);
      throw error;
    }
  }
  
  // 자동 선정 (AI 기반)
  static async autoSelectCandidate(callId: string): Promise<void> {
    try {
      // 모든 후보자 가져오기
      const candidatesSnapshot = await get(ref(db, `calls/${callId}/candidates`));
      
      if (!candidatesSnapshot.exists()) {
        throw new Error('후보자가 없습니다.');
      }
      
      const candidatesData = candidatesSnapshot.val();
      const candidates: Candidate[] = Object.entries(candidatesData)
        .map(([id, data]) => ({
          id,
          ...(data as any),
          score: this.calculateScore(data as any)
        }));
      
      // 최적 후보자 선정
      const optimal = this.getOptimalCandidate(candidates);
      
      if (!optimal) {
        throw new Error('선정할 수 있는 후보자가 없습니다.');
      }
      
      // 자동 선정 실행
      await this.selectCandidate(callId, optimal.id, 'AI_AUTO_SELECT');
      
      console.log(`[자동 선정] ${optimal.name} 대원이 자동 선정되었습니다. (점수: ${optimal.score})`);
    } catch (error) {
      console.error('[자동 선정 오류]', error);
      throw error;
    }
  }
  
  // 후보자 통계 생성
  static getCandidateStats(candidates: Candidate[]) {
    if (candidates.length === 0) {
      return {
        total: 0,
        avgDistance: 0,
        avgArrivalTime: 0,
        closestCandidate: null,
        fastestCandidate: null,
      };
    }
    
    const avgDistance = candidates.reduce((sum, c) => sum + c.actualDistance, 0) / candidates.length;
    const avgArrivalTime = candidates.reduce((sum, c) => sum + c.estimatedArrival, 0) / candidates.length;
    
    const closestCandidate = candidates.reduce((closest, current) =>
      current.actualDistance < closest.actualDistance ? current : closest
    );
    
    const fastestCandidate = candidates.reduce((fastest, current) =>
      current.estimatedArrival < fastest.estimatedArrival ? current : fastest
    );
    
    return {
      total: candidates.length,
      avgDistance: Math.round(avgDistance),
      avgArrivalTime: Math.round(avgArrivalTime / 60), // 분 단위
      closestCandidate,
      fastestCandidate,
    };
  }
  
  // 후보자 모집 시간 설정
  static async setCandidateWindow(
    callId: string,
    windowMinutes: number = 2
  ): Promise<void> {
    const windowEnd = Date.now() + (windowMinutes * 60 * 1000);
    
    await update(ref(db, `calls/${callId}`), {
      candidateWindowEnd: windowEnd,
      candidateWindowMinutes: windowMinutes,
    });
  }
  
  // 후보자 모집 마감 확인
  static async checkAndCloseWindow(callId: string): Promise<boolean> {
    const callSnapshot = await get(ref(db, `calls/${callId}`));
    
    if (!callSnapshot.exists()) return false;
    
    const callData = callSnapshot.val();
    const windowEnd = callData.candidateWindowEnd;
    
    if (!windowEnd || Date.now() < windowEnd) {
      return false; // 아직 마감 시간이 아님
    }
    
    // 마감 시간이 지났으면 자동 선정 실행
    if (callData.status === 'dispatched' && !callData.selectedResponderId) {
      await this.autoSelectCandidate(callId);
      return true;
    }
    
    return false;
  }
}

export default CandidateManagementService;
