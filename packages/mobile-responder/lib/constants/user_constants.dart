class UserConstants {
  // 부서 목록
  static const List<String> departments = ['전북소방본부'];

  // 계급 목록
  static const List<String> ranks = [
    '소방사',
    '소방교',
    '소방장',
    '소방위',
    '소방경',
    '소방령',
    '소방정',
  ];

  // 직책 목록
  static const List<String> positions = ['화재진압대원', '구조대원', '구급대원'];

  // 자격증 목록
  static const List<String> certifications = [
    '응급구조사 1급',
    '응급구조사 2급',
    '간호사',
    '화재대응능력 1급',
    '화재대응능력 2급',
    '인명구조사 1급',
    '인명구조사 2급',
  ];

  // 기본값
  static const String defaultDepartment = '전북소방본부';
  static const String defaultRank = '소방사';
  static const String defaultPosition = '화재진압대원';
}
