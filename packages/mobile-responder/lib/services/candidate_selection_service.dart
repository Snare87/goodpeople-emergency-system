// lib/services/candidate_selection_service.dart
import 'package:goodpeople_responder/models/candidate/candidate.dart';

class CandidateSelectionService {
  // 최적 대원 자동 선정
  static Candidate selectOptimalResponder(List<Candidate> candidates) {
    if (candidates.isEmpty) {
      throw Exception('후보자가 없습니다');
    }
    
    // 각 후보자의 점수 계산
    final scoredCandidates = candidates.map((candidate) {
      double score = calculateScore(candidate);
      return candidate.copyWith(score: score);
    }).toList();
    
    // 점수가 가장 높은 대원 선정
    scoredCandidates.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
    return scoredCandidates.first;
  }
  
  // 후보자 점수 계산
  static double calculateScore(Candidate candidate) {
    double score = 0;
    
    // 1. 실제 도로 거리 점수 (0-40점)
    const maxDistance = 10000.0; // 10km
    final distanceScore = (40 - (candidate.actualDistance / maxDistance * 40))
        .clamp(0, 40);
    score += distanceScore;
    
    // 2. 도착 예상 시간 점수 (0-30점)
    const maxTime = 1800; // 30분 (초)
    final timeScore = (30 - (candidate.estimatedArrival / maxTime * 30))
        .clamp(0, 30);
    score += timeScore;
    
    // 3. 자격증 점수 (0-20점)
    final certScore = (candidate.certifications.length * 5)
        .clamp(0, 20)
        .toDouble();
    score += certScore;
    
    // 4. 계급 점수 (0-10점)
    final rankScore = _getRankScore(candidate.rank);
    score += rankScore;
    
    // 5. 보너스: 경로 효율성 (최대 5점)
    if (candidate.hasEfficientRoute) {
      score += 5;
    }
    
    return score;
  }
  
  // 계급별 점수
  static double _getRankScore(String rank) {
    const rankScores = {
      '소방사': 5.0,
      '소방교': 6.0,
      '소방장': 7.0,
      '소방위': 8.0,
      '소방경': 9.0,
      '소방령': 10.0,
      '소방정': 10.0,
    };
    
    return rankScores[rank] ?? 5.0;
  }
  
  // 재난 유형별 가중치 적용 (향후 구현)
  static double applyDisasterTypeWeight(
    Candidate candidate,
    String disasterType,
  ) {
    double multiplier = 1.0;
    
    // 예: 화재 -> 화재대응능력 자격증 보유자 우대
    if (disasterType.contains('화재')) {
      if (candidate.certifications.any((cert) => cert.contains('화재대응'))) {
        multiplier = 1.2;
      }
    }
    
    // 예: 구조 -> 인명구조사 자격증 보유자 우대
    if (disasterType.contains('구조') || disasterType.contains('붕괴')) {
      if (candidate.certifications.any((cert) => cert.contains('인명구조'))) {
        multiplier = 1.2;
      }
    }
    
    // 예: 응급환자 -> 응급구조사 자격증 보유자 우대
    if (disasterType.contains('응급') || disasterType.contains('환자')) {
      if (candidate.certifications.any((cert) => cert.contains('응급구조'))) {
        multiplier = 1.3;
      }
    }
    
    return (candidate.score ?? 0) * multiplier;
  }
  
  // 후보자 정렬 (다양한 기준)
  static List<Candidate> sortCandidates(
    List<Candidate> candidates, {
    SortCriteria criteria = SortCriteria.byScore,
  }) {
    final sorted = List<Candidate>.from(candidates);
    
    switch (criteria) {
      case SortCriteria.byScore:
        sorted.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
        break;
      case SortCriteria.byTime:
        sorted.sort((a, b) => a.estimatedArrival.compareTo(b.estimatedArrival));
        break;
      case SortCriteria.byDistance:
        sorted.sort((a, b) => a.actualDistance.compareTo(b.actualDistance));
        break;
      case SortCriteria.byEfficiency:
        sorted.sort((a, b) => b.routeEfficiency.compareTo(a.routeEfficiency));
        break;
    }
    
    return sorted;
  }
}

enum SortCriteria {
  byScore,      // AI 점수 기준
  byTime,       // 도착 시간 기준
  byDistance,   // 거리 기준
  byEfficiency, // 경로 효율성 기준
}
