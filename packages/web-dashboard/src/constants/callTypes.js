// packages/web-dashboard/src/constants/callTypes.js

// 재난 유형
export const CALL_TYPES = {
  FIRE: '화재',
  RESCUE: '구조',
  EMERGENCY: '구급',
  OTHER: '기타'
};

// 재난 상태
export const CALL_STATUS = {
  IDLE: 'idle',
  DISPATCHED: 'dispatched',
  ACCEPTED: 'accepted',
  COMPLETED: 'completed'
};

// 재난 유형별 색상 (배경색)
export const CALL_TYPE_COLORS = {
  [CALL_TYPES.FIRE]: 'bg-red-100',
  [CALL_TYPES.RESCUE]: 'bg-blue-100',
  [CALL_TYPES.EMERGENCY]: 'bg-green-100',
  [CALL_TYPES.OTHER]: 'bg-gray-100'
};

// 재난 유형별 아이콘
export const CALL_TYPE_ICONS = {
  [CALL_TYPES.FIRE]: '🔥',
  [CALL_TYPES.RESCUE]: '🚨',
  [CALL_TYPES.EMERGENCY]: '🚑',
  [CALL_TYPES.OTHER]: '⚠️'
};

// 재난 상태별 라벨
export const CALL_STATUS_LABELS = {
  [CALL_STATUS.IDLE]: '대기중',
  [CALL_STATUS.DISPATCHED]: '호출중',
  [CALL_STATUS.ACCEPTED]: '진행중',
  [CALL_STATUS.COMPLETED]: '완료'
};