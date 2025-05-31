// AI 점수 계산 서비스 (개선된 버전)
// 재난 종류별 자격증 가중치 및 상위/하위 자격증 처리

interface ScoringWeights {
  eta: number;        // 도착 시간 가중치 (초 단위)
  distance: number;   // 거리 가중치 (km 단위)
  qualification: number; // 자격증 가중치
  rank: number;       // 계급 가중치
  responseTime: number; // 응답 시간 가중치 (NEW)
}

interface CandidateScore {
  userId: string;
  totalScore: number;
  breakdown: {
    etaScore: number;
    distanceScore: number;
    qualificationScore: number;
    rankScore: number;
    responseTimeScore: number; // NEW
  };
  isOptimal: boolean;
}

// 기본 가중치 설정
const DEFAULT_WEIGHTS: ScoringWeights = {
  eta: 1.0,           // ETA가 가장 중요 (1초 = 1점)
  distance: 0.5,      // 거리는 보조 지표 (1km = 0.5점)
  qualification: -100, // 자격증 보너스 (음수 = 점수 감소 = 유리)
  rank: -50,          // 계급 보너스
  responseTime: -0.1  // 응답 시간 보너스 (1초 빨리 = 0.1점 감소) 
};

// 계급별 점수
const RANK_SCORES: Record<string, number> = {
  '소방사': 0,
  '소방교': 1,
  '소방장': 2,
  '소방위': 3,
  '소방경': 4,
  '소방령': 5,
};

// 재난 종류별 자격증 점수
const CERTIFICATION_SCORES_BY_EVENT: Record<string, Record<string, number>> = {
  '화재': {
    '화재대응능력 1급': 30,  // 화재에 가장 적합
    '화재대응능력 2급': 20,
    '인명구조사 1급': 15,   // 화재 시 구조도 중요
    '인명구조사 2급': 10,
    '간호사': 10,           // 화재 시 의료 지원
    '응급구조사 1급': 10,
    '응급구조사 2급': 5,
  },
  '구조': {
    '인명구조사 1급': 30,   // 구조에 가장 적합
    '인명구조사 2급': 20,
    '화재대응능력 1급': 15, // 구조 시 화재 위험
    '화재대응능력 2급': 10,
    '간호사': 15,          // 구조 후 의료 지원
    '응급구조사 1급': 15,
    '응급구조사 2급': 10,
  },
  '구급': {
    '간호사': 30,          // 구급에 가장 적합
    '응급구조사 1급': 30,
    '응급구조사 2급': 20,
    '인명구조사 1급': 10,   // 구급 시 구조 능력
    '인명구조사 2급': 5,
    '화재대응능력 1급': 5,  // 구급 시 최소 점수
    '화재대응능력 2급': 3,
  },
  '기타': {
    // 기타 재난은 모든 자격증 균등
    '간호사': 15,
    '응급구조사 1급': 15,
    '응급구조사 2급': 10,
    '인명구조사 1급': 15,
    '인명구조사 2급': 10,
    '화재대응능력 1급': 15,
    '화재대응능력 2급': 10,
  }
};

// 상위 자격증 매핑 (하위 자격증 → 상위 자격증)
const CERTIFICATION_HIERARCHY: Record<string, string> = {
  '응급구조사 2급': '응급구조사 1급',  // 1급이 2급의 상위
  '화재대응능력 2급': '화재대응능력 1급',
  '인명구조사 2급': '인명구조사 1급',
};

// 동등 자격증 그룹 (같은 업무 영역)
const EQUIVALENT_CERTIFICATIONS = [
  ['간호사', '응급구조사 1급'], // 거의 동일한 업무 영역
];

export class AIScoringService {
  private weights: ScoringWeights;

  constructor(customWeights?: Partial<ScoringWeights>) {
    this.weights = { ...DEFAULT_WEIGHTS, ...customWeights };
  }

  /**
   * 모든 후보자의 AI 점수 계산
   */
  calculateCandidateScores(
    candidates: Record<string, any>,
    userData: Record<string, any>,
    eventType: string = '기타',
    dispatchedAt?: number // 호출 시간 추가
  ): CandidateScore[] {
    const scores: CandidateScore[] = [];

    // 각 후보자별 점수 계산
    for (const [userId, candidate] of Object.entries(candidates)) {
      const userInfo = userData[userId] || {};
      const score = this.calculateSingleCandidateScore(candidate, userInfo, eventType, dispatchedAt);
      scores.push({
        userId,
        ...score
      });
    }

    // 점수순 정렬 (낮을수록 좋음)
    scores.sort((a, b) => a.totalScore - b.totalScore);

    // 최적 후보자 표시 (상위 1명 - 테스트용)
    scores.forEach((score, index) => {
      score.isOptimal = index < 1; // 테스트를 위해 1명만
    });

    return scores;
  }

  /**
   * 단일 후보자 점수 계산
   */
  private calculateSingleCandidateScore(
    candidate: any,
    userInfo: any,
    eventType: string,
    dispatchedAt?: number
  ): Omit<CandidateScore, 'userId'> {
    // routeInfo가 없는 경우 처리
    const hasRouteInfo = candidate.routeInfo && 
      candidate.routeInfo.duration !== undefined && 
      candidate.routeInfo.distance !== undefined;
    
    // 1. ETA 점수 (초 단위)
    const etaSeconds = hasRouteInfo ? candidate.routeInfo.duration : 99999; // 999999를 99999로 변경
    const etaScore = etaSeconds * this.weights.eta;

    // 2. 거리 점수 (미터 → 킬로미터 변환)
    const distanceKm = hasRouteInfo ? (candidate.routeInfo.distance / 1000) : 99.999; // 999999를 99.999km로 변경
    const distanceScore = distanceKm * this.weights.distance;

    // 3. 자격증 점수 (재난 종류별, 중복 제거)
    const certifications = candidate.certifications || userInfo.certifications || [];
    const qualificationScore = this.calculateQualificationScore(certifications, eventType);

    // 4. 계급 점수
    const rankScore = this.calculateRankScore(
      candidate.rank || userInfo.rank || '소방사'
    );
    
    // 5. 응답 시간 점수 (빠를수록 좋음)
    let responseTimeScore = 0;
    if (dispatchedAt && candidate.acceptedAt) {
      const responseSeconds = Math.floor((candidate.acceptedAt - dispatchedAt) / 1000);
      responseTimeScore = Math.max(0, responseSeconds); // 음수 방지, 초 단위
    }

    // 총점 계산 (낮을수록 좋음)
    const totalScore = etaScore + distanceScore + 
      (qualificationScore * this.weights.qualification / 100) +
      (rankScore * this.weights.rank / 100) +
      (responseTimeScore * this.weights.responseTime);

    return {
      totalScore,
      breakdown: {
        etaScore,
        distanceScore,
        qualificationScore,
        rankScore,
        responseTimeScore
      },
      isOptimal: false // 나중에 설정됨
    };
  }

  /**
   * 자격증 점수 계산 (중복 제거 및 재난 종류별 가중치)
   */
  private calculateQualificationScore(certifications: string[], eventType: string): number {
    if (!certifications || certifications.length === 0) return 0;

    // 1. 상위/하위 자격증 중복 제거
    const processedCerts = this.removeDuplicateCertifications(certifications);

    // 2. 재난 종류별 점수 테이블 선택
    const scoreTable = CERTIFICATION_SCORES_BY_EVENT[eventType] || CERTIFICATION_SCORES_BY_EVENT['기타'];

    // 3. 점수 계산
    let totalScore = 0;
    for (const cert of processedCerts) {
      if (scoreTable[cert]) {
        totalScore += scoreTable[cert];
      }
    }

    return totalScore;
  }

  /**
   * 중복 자격증 제거 (상위 자격증만 유지)
   */
  private removeDuplicateCertifications(certifications: string[]): string[] {
    const processed = new Set<string>();
    const toRemove = new Set<string>();

    // 1. 상위/하위 관계 처리
    for (const cert of certifications) {
      // 하위 자격증이 있고, 상위 자격증도 보유한 경우
      const upperCert = CERTIFICATION_HIERARCHY[cert];
      if (upperCert && certifications.includes(upperCert)) {
        toRemove.add(cert); // 하위 자격증 제거
      }
    }

    // 2. 동등 자격증 처리 (간호사, 응급구조사 1급)
    for (const group of EQUIVALENT_CERTIFICATIONS) {
      const hasMultiple = group.filter(cert => certifications.includes(cert));
      if (hasMultiple.length > 1) {
        // 첫 번째 것만 유지하고 나머지 제거
        for (let i = 1; i < hasMultiple.length; i++) {
          toRemove.add(hasMultiple[i]);
        }
      }
    }

    // 3. 최종 자격증 목록 생성
    for (const cert of certifications) {
      if (!toRemove.has(cert)) {
        processed.add(cert);
      }
    }

    return Array.from(processed);
  }

  /**
   * 계급 점수 계산
   */
  private calculateRankScore(rank: string): number {
    return RANK_SCORES[rank] || 0;
  }

  /**
   * 점수를 사람이 읽기 쉬운 형태로 포맷
   */
  formatScore(score: CandidateScore): string {
    const { breakdown } = score;
    return `총점: ${Math.round(score.totalScore)}점
      - 도착시간: ${Math.round(breakdown.etaScore)}점
      - 거리: ${Math.round(breakdown.distanceScore)}점
      - 자격증: ${breakdown.qualificationScore}점
      - 계급: ${breakdown.rankScore}점`;
  }

  /**
   * 최적 후보자 추천 이유 생성
   */
  getRecommendationReason(
    candidate: any, 
    score: CandidateScore,
    eventType: string
  ): string {
    const reasons = [];

    // ETA가 짧은 경우 (경로 정보가 있을 때만)
    if (candidate.routeInfo?.duration) {
      const etaMinutes = Math.ceil(candidate.routeInfo.duration / 60);
      if (etaMinutes <= 5) {
        reasons.push(`도착시간 ${etaMinutes}분`);
      }
    }
    
    // 빠른 응답 (응답 시간이 30초 이내인 경우)
    if (score.breakdown.responseTimeScore > 0 && score.breakdown.responseTimeScore <= 30) {
      reasons.push('빠른 응답');
    }

    // 재난 종류별 전문 자격증
    const certs = candidate.certifications || [];
    const processedCerts = this.removeDuplicateCertifications(certs);

    if (eventType === '화재' && processedCerts.some(c => c.includes('화재대응'))) {
      reasons.push('화재 전문');
    } else if (eventType === '구조' && processedCerts.some(c => c.includes('인명구조'))) {
      reasons.push('구조 전문');
    } else if (eventType === '구급' && processedCerts.some(c => 
      c.includes('간호사') || c.includes('응급구조사'))) {
      reasons.push('의료 전문');
    }

    // 고위 계급인 경우
    if (score.breakdown.rankScore >= 3) {
      reasons.push('경험 풍부');
    }

    return reasons.length > 0 
      ? reasons.join(', ') 
      : '종합 평가 우수';
  }

  /**
   * 자격증 목록을 표시용 텍스트로 변환 (중복 제거)
   */
  formatCertifications(certifications: string[]): string {
    if (!certifications || certifications.length === 0) return '없음';
    
    const processed = this.removeDuplicateCertifications(certifications);
    if (processed.length <= 2) {
      return processed.join(', ');
    }
    
    return processed.slice(0, 2).join(', ') + ` 외 ${processed.length - 2}개`;
  }
}

// 싱글톤 인스턴스
export const aiScoringService = new AIScoringService();
