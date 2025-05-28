// packages/web-dashboard/src/constants/badgeVariants.js

import { CALL_STATUS } from './callTypes';
import { USER_STATUS, USER_POSITIONS } from './userRoles';

// Badge 컴포넌트의 variant에 사용되는 상수들
export const BADGE_VARIANTS = {
  DEFAULT: 'default',
  SUCCESS: 'success',
  WARNING: 'warning',
  DANGER: 'danger',
  INFO: 'info',
  PURPLE: 'purple',
  EMERALD: 'emerald'
};

// 상태별 Badge variant 매핑
export const STATUS_BADGE_VARIANTS = {
  // 사용자 상태
  [USER_STATUS.PENDING]: BADGE_VARIANTS.WARNING,
  [USER_STATUS.APPROVED]: BADGE_VARIANTS.SUCCESS,
  [USER_STATUS.REJECTED]: BADGE_VARIANTS.DANGER,
  
  // 재난 상태
  [CALL_STATUS.IDLE]: BADGE_VARIANTS.DEFAULT,
  [CALL_STATUS.DISPATCHED]: BADGE_VARIANTS.WARNING,
  [CALL_STATUS.ACCEPTED]: BADGE_VARIANTS.INFO,
  [CALL_STATUS.COMPLETED]: BADGE_VARIANTS.SUCCESS
};

// 직책별 Badge variant 매핑
export const POSITION_BADGE_VARIANTS = {
  [USER_POSITIONS.FIRE_FIGHTER]: BADGE_VARIANTS.DANGER,
  [USER_POSITIONS.RESCUER]: BADGE_VARIANTS.INFO,
  [USER_POSITIONS.PARAMEDIC]: BADGE_VARIANTS.EMERALD
};

// 계급별 색상 (Badge가 아닌 직접적인 스타일)
export const RANK_COLORS = {
  '소방사': 'bg-slate-100 text-slate-700',
  '소방교': 'bg-slate-200 text-slate-800',
  '소방장': 'bg-indigo-100 text-indigo-700',
  '소방위': 'bg-indigo-200 text-indigo-800',
  '소방경': 'bg-purple-100 text-purple-700',
  '소방령': 'bg-purple-200 text-purple-800',
  '소방정': 'bg-purple-300 text-purple-900'
};