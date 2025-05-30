// lib/config/feature_flags.dart
class FeatureFlags {
  // 기능별 플래그
  static bool enableMultipleCandidate = false;
  static bool enableDistanceMatrixAPI = false;
  static bool enableAutoSelection = false;
  static bool enableCandidateWaitingScreen = false;
  
  // 단계별 활성화
  static void enablePhase1() {
    // 거리 계산만 활성화 (표시 X)
    enableDistanceMatrixAPI = true;
  }
  
  static void enablePhase2() {
    // 다중 후보 + 대기 화면
    enableMultipleCandidate = true;
    enableCandidateWaitingScreen = true;
    enableDistanceMatrixAPI = true;
  }
  
  static void enablePhase3() {
    // 전체 기능 활성화
    enableMultipleCandidate = true;
    enableDistanceMatrixAPI = true;
    enableAutoSelection = true;
    enableCandidateWaitingScreen = true;
  }
  
  // 테스트 모드
  static bool isTestMode = true;
  static bool useMockData = true;
}
