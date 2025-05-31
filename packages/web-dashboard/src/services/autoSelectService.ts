// 자동 선택 서비스
// 60초 카운트다운 후 AI 점수 기반 자동 선택

import { ref, get, update } from 'firebase/database';
import { db } from '../firebase';
import { aiScoringService } from './aiScoringService';

interface AutoSelectConfig {
  enabled: boolean;
  countdownSeconds: number;
  startedAt?: number;
}

interface AutoSelectStatus {
  isActive: boolean;
  remainingSeconds: number;
  willSelectUserId?: string;
  willSelectUserName?: string;
}

export class AutoSelectService {
  private timers: Map<string, NodeJS.Timeout> = new Map();
  private countdownIntervals: Map<string, NodeJS.Timeout> = new Map();
  private callbacks: Map<string, (status: AutoSelectStatus) => void> = new Map();

  /**
   * 자동 선택 시작
   */
  async startAutoSelect(
    callId: string, 
    countdownSeconds: number = 60,
    onStatusUpdate?: (status: AutoSelectStatus) => void
  ): Promise<void> {
    console.log(`[자동선택] 시작 - 호출 ID: ${callId}, 대기시간: ${countdownSeconds}초`);
    
    // 이전 타이머 정리
    this.stopAutoSelect(callId);

    // 콜백 저장
    if (onStatusUpdate) {
      this.callbacks.set(callId, onStatusUpdate);
    }

    // 자동 선택 설정 저장
    const config: AutoSelectConfig = {
      enabled: true,
      countdownSeconds,
      startedAt: Date.now()
    };

    await update(ref(db, `calls/${callId}`), {
      autoSelectConfig: config
    });

    // 카운트다운 시작
    let remaining = countdownSeconds;
    
    const countdownInterval = setInterval(async () => {
      remaining--;
      
      // 최적 후보자 계산
      const bestCandidate = await this.calculateBestCandidate(callId);
      
      // 상태 업데이트
      const status: AutoSelectStatus = {
        isActive: true,
        remainingSeconds: remaining,
        willSelectUserId: bestCandidate?.userId,
        willSelectUserName: bestCandidate?.name
      };
      
      // 콜백 실행
      const callback = this.callbacks.get(callId);
      if (callback) {
        callback(status);
      }

      if (remaining <= 0) {
        clearInterval(countdownInterval);
        this.countdownIntervals.delete(callId);
      }
    }, 1000);

    this.countdownIntervals.set(callId, countdownInterval);

    // 자동 선택 타이머
    const timer = setTimeout(async () => {
      await this.executeAutoSelect(callId);
    }, countdownSeconds * 1000);

    this.timers.set(callId, timer);
  }

  /**
   * 자동 선택 중지
   */
  async stopAutoSelect(callId: string): Promise<void> {
    console.log(`[자동선택] 중지 - 호출 ID: ${callId}`);
    
    // 타이머 정리
    const timer = this.timers.get(callId);
    if (timer) {
      clearTimeout(timer);
      this.timers.delete(callId);
    }

    // 카운트다운 정리
    const interval = this.countdownIntervals.get(callId);
    if (interval) {
      clearInterval(interval);
      this.countdownIntervals.delete(callId);
    }

    // 콜백 정리
    this.callbacks.delete(callId);

    // 설정 업데이트
    await update(ref(db, `calls/${callId}`), {
      autoSelectConfig: {
        enabled: false,
        countdownSeconds: 0
      }
    });

    // 중지 상태 전달
    const callback = this.callbacks.get(callId);
    if (callback) {
      callback({
        isActive: false,
        remainingSeconds: 0
      });
    }
  }

  /**
   * 자동 선택 실행
   */
  private async executeAutoSelect(callId: string): Promise<void> {
    try {
      console.log(`[자동선택] 실행 중 - 호출 ID: ${callId}`);
      
      const bestCandidate = await this.calculateBestCandidate(callId);
      
      if (!bestCandidate) {
        console.log('[자동선택] 선택 가능한 후보자가 없습니다');
        return;
      }

      // 선택 실행
      await this.selectCandidate(callId, bestCandidate.userId);
      
      console.log(`[자동선택] 완료 - 선택된 대원: ${bestCandidate.name}`);
      
      // 완료 상태 전달
      const callback = this.callbacks.get(callId);
      if (callback) {
        callback({
          isActive: false,
          remainingSeconds: 0,
          willSelectUserId: bestCandidate.userId,
          willSelectUserName: bestCandidate.name
        });
      }
      
    } catch (error) {
      console.error('[자동선택] 오류:', error);
    } finally {
      // 정리
      this.timers.delete(callId);
      this.countdownIntervals.delete(callId);
      this.callbacks.delete(callId);
    }
  }

  /**
   * 최적 후보자 계산
   */
  private async calculateBestCandidate(callId: string): Promise<any | null> {
    try {
      // 호출 정보 가져오기
      const callSnapshot = await get(ref(db, `calls/${callId}`));
      if (!callSnapshot.exists()) {
        return null;
      }

      const callData = callSnapshot.val();
      const candidates = callData.candidates || {};

      if (Object.keys(candidates).length === 0) {
        return null;
      }

      // 사용자 정보 가져오기
      const usersSnapshot = await get(ref(db, 'users'));
      const userData = usersSnapshot.val() || {};

      // AI 점수 계산 (재난 종류 고려)
      const scores = aiScoringService.calculateCandidateScores(
        candidates, 
        userData,
        callData.eventType, // 재난 종류 추가
        callData.dispatchedAt // 호출 시간 추가
      );
      
      if (scores.length === 0) {
        return null;
      }
      
      // 경로 정보가 있는 후보자만 필터링
      const validScores = scores.filter(score => {
        const candidate = candidates[score.userId];
        return candidate?.routeInfo && score.totalScore < 50000;
      });
      
      if (validScores.length === 0) {
        console.log('[자동선택] 경로 정보가 있는 후보자가 없습니다');
        return null;
      }

      // 최고 점수 후보자
      const bestScore = validScores[0];
      const bestCandidate = candidates[bestScore.userId];

      return {
        ...bestCandidate,
        score: bestScore
      };

    } catch (error) {
      console.error('[자동선택] 후보자 계산 오류:', error);
      return null;
    }
  }

  /**
   * 후보자 선택
   */
  private async selectCandidate(callId: string, candidateUserId: string): Promise<void> {
    try {
      const callRef = ref(db, `calls/${callId}`);
      const snapshot = await get(callRef);
      
      if (!snapshot.exists()) {
        throw new Error('호출 정보를 찾을 수 없습니다');
      }

      const callData = snapshot.val();
      const candidate = callData.candidates?.[candidateUserId];
      
      if (!candidate) {
        throw new Error('후보자 정보를 찾을 수 없습니다');
      }

      // 선택된 대원 정보 설정
      await update(callRef, {
        selectedResponder: {
          ...candidate,
          selectedAt: Date.now(),
          selectedBy: 'auto' // 자동 선택 표시
        },
        status: 'accepted',
        acceptedAt: Date.now(),
        autoSelectConfig: {
          enabled: false,
          countdownSeconds: 0,
          completedAt: Date.now()
        }
      });

    } catch (error) {
      console.error('[자동선택] 선택 오류:', error);
      throw error;
    }
  }

  /**
   * 자동 선택 상태 확인
   */
  async getAutoSelectStatus(callId: string): Promise<AutoSelectStatus> {
    try {
      const snapshot = await get(ref(db, `calls/${callId}`));
      if (!snapshot.exists()) {
        return { isActive: false, remainingSeconds: 0 };
      }

      const callData = snapshot.val();
      const config = callData.autoSelectConfig as AutoSelectConfig | undefined;

      if (!config?.enabled || !config.startedAt) {
        return { isActive: false, remainingSeconds: 0 };
      }

      const elapsed = Math.floor((Date.now() - config.startedAt) / 1000);
      const remaining = Math.max(0, config.countdownSeconds - elapsed);

      if (remaining <= 0) {
        return { isActive: false, remainingSeconds: 0 };
      }

      // 최적 후보자 정보 포함
      const bestCandidate = await this.calculateBestCandidate(callId);

      return {
        isActive: true,
        remainingSeconds: remaining,
        willSelectUserId: bestCandidate?.userId,
        willSelectUserName: bestCandidate?.name
      };

    } catch (error) {
      console.error('[자동선택] 상태 확인 오류:', error);
      return { isActive: false, remainingSeconds: 0 };
    }
  }
}

// 싱글톤 인스턴스
export const autoSelectService = new AutoSelectService();
