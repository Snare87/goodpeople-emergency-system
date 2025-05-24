// src/constants/callTypes.js
export const CALL_TYPES = {
  FIRE: '화재',
  RESCUE: '구조',
  EMERGENCY: '구급',
  OTHER: '기타'
};

export const CALL_STATUS = {
  IDLE: 'idle',
  DISPATCHED: 'dispatched',
  ACCEPTED: 'accepted',
  COMPLETED: 'completed'
};

export const CALL_TYPE_COLORS = {
  '화재': 'bg-red-100',
  '구조': 'bg-blue-100',
  '구급': 'bg-green-100',
  '기타': 'bg-gray-100'
};

export const CALL_TYPE_ICONS = {
  '화재': '🔥',
  '구조': '🚨',
  '구급': '🚑',
  '기타': '⚠️'
};

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

// src/constants/badgeVariants.js
export const STATUS_BADGE_VARIANTS = {
  pending: 'warning',
  approved: 'success',
  rejected: 'danger',
  idle: 'default',
  dispatched: 'warning',
  accepted: 'info',
  completed: 'success'
};

export const POSITION_BADGE_VARIANTS = {
  '화재진압대원': 'danger',
  '구조대원': 'info',
  '구급대원': 'emerald'
};

export const RANK_COLORS = {
  '소방사': 'bg-slate-100 text-slate-700',
  '소방교': 'bg-slate-200 text-slate-800',
  '소방장': 'bg-indigo-100 text-indigo-700',
  '소방위': 'bg-indigo-200 text-indigo-800',
  '소방경': 'bg-purple-100 text-purple-700',
  '소방령': 'bg-purple-200 text-purple-800',
  '소방정': 'bg-purple-300 text-purple-900'
};