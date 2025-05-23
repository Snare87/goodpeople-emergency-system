// src/utils/formatters.js

// 시간 포맷 함수
export const formatTime = (timestamp) => {
  if (!timestamp) return '';
  try {
    const date = new Date(timestamp);
    return date.toLocaleTimeString('ko-KR', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: false
    });
  } catch (e) {
    return '';
  }
};

// 날짜 포맷 함수
export const formatDate = (timestamp) => {
  if (!timestamp) return '';
  try {
    const date = new Date(timestamp);
    return date.toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  } catch (e) {
    return '';
  }
};

// 날짜와 시간을 함께 표시하는 함수
export const formatDateTime = (timestamp) => {
  if (!timestamp) return '';
  try {
    const date = new Date(timestamp);
    return `${formatDate(timestamp)} ${formatTime(timestamp)}`;
  } catch (e) {
    return '';
  }
};

// 상세 경과 시간 계산 함수
export const getDetailedElapsedTime = (start, end) => {
  if (!start || !end) return '';
  
  try {
    const startTime = typeof start === 'string' ? new Date(start).getTime() : start;
    const endTime = typeof end === 'string' ? new Date(end).getTime() : end;
    
    if (isNaN(startTime) || isNaN(endTime)) return '';
    
    const diff = Math.max(0, Math.floor((endTime - startTime) / 1000));
    
    const hours = Math.floor(diff / 3600);
    const minutes = Math.floor((diff % 3600) / 60);
    const seconds = diff % 60;
    
    let result = '';
    if (hours > 0) result += `${hours}시간 `;
    if (minutes > 0) result += `${minutes}분 `;
    result += `${seconds}초`;
    
    return result;
  } catch (e) {
    return '';
  }
};

// 경과 시간 계산 함수 (현재 시간 기준)
export const getElapsedTime = (startAt, currentTime = Date.now()) => {
  if (!startAt) return '';
  
  try {
    const startTimestamp = typeof startAt === 'string' ? new Date(startAt).getTime() : startAt;
    
    if (isNaN(startTimestamp)) return '';
    
    const diff = Math.max(0, Math.floor((currentTime - startTimestamp) / 1000));
    
    if (diff < 60) return `${diff}초 전`;
    if (diff < 3600) return `${Math.floor(diff / 60)}분 전`;
    if (diff < 86400) return `${Math.floor(diff / 3600)}시간 ${Math.floor((diff % 3600) / 60)}분 전`;
    
    const date = new Date(startTimestamp);
    return date.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' });
  } catch (e) {
    return '';
  }
};