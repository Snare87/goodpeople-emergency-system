// packages/web-dashboard/src/constants/index.ts

// 모든 상수를 한 곳에서 export
export * from './callTypes';
export * from './userRoles';
export * from './badgeVariants';

// 공통으로 사용되는 상수들
export const APP_NAME = 'GoodPeople' as const;
export const DEFAULT_CENTER: [number, number] = [37.5665, 126.9780]; // 서울시청 좌표

// 시간 관련 상수
export const TIMER_INTERVAL = 3000 as const; // 3초
export const LOCATION_UPDATE_INTERVAL = 30000 as const; // 30초

// 권한 관련 상수
export const PERMISSIONS = {
  APP: 'app',
  WEB: 'web',
  ADMIN: 'admin',
  DISPATCHER: 'dispatcher'
} as const;

// 메시지 상수
export const MESSAGES = {
  NO_PERMISSION: '권한이 없습니다.',
  LOGIN_REQUIRED: '로그인이 필요합니다.',
  WEB_PERMISSION_REQUIRED: '웹 대시보드 접근 권한이 없습니다. 관리자에게 문의하세요.',
  APPROVAL_PENDING: '승인 대기중입니다. 관리자 승인 후 이용 가능합니다.',
  ACCOUNT_BLOCKED: '계정이 차단되었습니다. 관리자에게 문의하세요.'
} as const;

// 타입 추출
export type Permission = typeof PERMISSIONS[keyof typeof PERMISSIONS];
