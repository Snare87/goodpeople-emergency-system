// src/constants/userRoles.ts
export const USER_ROLES = {
  ADMIN: 'admin',
  DISPATCHER: 'dispatcher',
  SUPERVISOR: 'supervisor',
  REPORTER: 'reporter'
} as const;

export const USER_ROLE_LABELS: Record<string, string> = {
  admin: '관리자',
  dispatcher: '상황실',
  supervisor: '감독관',
  reporter: '보고자'
};

export const USER_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected'
} as const;

export const USER_STATUS_LABELS: Record<string, string> = {
  pending: '승인대기',
  approved: '승인완료',
  rejected: '거부됨'
};

export const USER_POSITIONS = {
  FIRE_FIGHTER: '화재진압대원',
  RESCUER: '구조대원',
  PARAMEDIC: '구급대원'
} as const;

export const USER_RANKS: readonly string[] = [
  '소방사',
  '소방교',
  '소방장',
  '소방위',
  '소방경',
  '소방령',
  '소방정'
] as const;

// 타입 추출
export type UserRole = typeof USER_ROLES[keyof typeof USER_ROLES];
export type UserStatus = typeof USER_STATUS[keyof typeof USER_STATUS];
export type UserPosition = typeof USER_POSITIONS[keyof typeof USER_POSITIONS];
export type UserRank = typeof USER_RANKS[number];
