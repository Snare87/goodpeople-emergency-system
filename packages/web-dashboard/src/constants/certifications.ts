// src/constants/certifications.ts
export const AVAILABLE_CERTIFICATIONS = [
  '응급구조사 1급',
  '응급구조사 2급',
  '간호사',
  '화재대응능력 1급',
  '화재대응능력 2급',
  '인명구조사 1급',
  '인명구조사 2급',
] as const;

export type CertificationType = typeof AVAILABLE_CERTIFICATIONS[number];

// 자격증별 색상 매핑
export const CERTIFICATION_COLORS: Record<string, string> = {
  '응급구조사 1급': 'danger',
  '응급구조사 2급': 'warning',
  '간호사': 'purple', 
  '인명구조사 1급': 'info',
  '인명구조사 2급': 'default',
  '화재대응능력 1급': 'emerald',
  '화재대응능력 2급': 'success',
};

// 자격증 색상 가져오기 함수
export const getCertificationVariant = (cert: string): string => {
  // 정확히 일치하는 경우 확인
  if (CERTIFICATION_COLORS[cert]) {
    return CERTIFICATION_COLORS[cert];
  }
  
  // 부분 일치 확인 (하위 호환성)
  for (const [key, variant] of Object.entries(CERTIFICATION_COLORS)) {
    if (cert.includes(key.split(' ')[0])) {
      return variant;
    }
  }
  
  return 'default';
};