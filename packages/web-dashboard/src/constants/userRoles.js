// src/constants/userRoles.js
export const USER_ROLES = {
  ADMIN: 'admin',
  DISPATCHER: 'dispatcher',
  SUPERVISOR: 'supervisor',
  REPORTER: 'reporter'
};

export const USER_ROLE_LABELS = {
  admin: '관리자',
  dispatcher: '상황실',
  supervisor: '감독관',
  reporter: '보고자'
};

export const USER_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected'
};

export const USER_STATUS_LABELS = {
  pending: '승인대기',
  approved: '승인완료',
  rejected: '거부됨'
};

export const USER_POSITIONS = {
  FIRE_FIGHTER: '화재진압대원',
  RESCUER: '구조대원',
  PARAMEDIC: '구급대원'
};

export const USER_RANKS = [
  '소방사',
  '소방교',
  '소방장',
  '소방위',
  '소방경',
  '소방령',
  '소방정'
];