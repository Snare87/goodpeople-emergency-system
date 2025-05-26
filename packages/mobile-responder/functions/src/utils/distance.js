// src/utils/distance.js

/**
 * 두 GPS 좌표 간의 거리를 계산하는 유틸리티
 */

/**
 * 도(degree)를 라디안(radian)으로 변환
 * @param {number} value - 도 단위 값
 * @returns {number} 라디안 값
 */
function toRad(value) {
  return value * Math.PI / 180;
}

/**
 * Haversine 공식을 사용하여 두 GPS 좌표 간의 거리 계산
 * @param {number} lat1 - 첫 번째 지점의 위도
 * @param {number} lon1 - 첫 번째 지점의 경도
 * @param {number} lat2 - 두 번째 지점의 위도
 * @param {number} lon2 - 두 번째 지점의 경도
 * @returns {number} 두 지점 간의 거리 (km)
 */
function calculateDistance(lat1, lon1, lat2, lon2) {
  // 입력값 검증
  if (!isValidCoordinate(lat1, lon1) || !isValidCoordinate(lat2, lon2)) {
    throw new Error('유효하지 않은 GPS 좌표입니다');
  }

  const R = 6371; // 지구 반경 (km)
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  
  return R * c;
}

/**
 * GPS 좌표의 유효성 검증
 * @param {number} lat - 위도
 * @param {number} lon - 경도
 * @returns {boolean} 유효한 좌표인지 여부
 */
function isValidCoordinate(lat, lon) {
  return lat != null && 
         lon != null && 
         !isNaN(lat) && 
         !isNaN(lon) &&
         lat >= -90 && 
         lat <= 90 && 
         lon >= -180 && 
         lon <= 180;
}

/**
 * 거리를 사용자 친화적인 문자열로 포맷
 * @param {number} distance - 거리 (km)
 * @returns {string} 포맷된 거리 문자열
 */
function formatDistance(distance) {
  if (distance < 1) {
    return `${Math.round(distance * 1000)}m`;
  }
  return `${distance.toFixed(1)}km`;
}

module.exports = {
  calculateDistance,
  isValidCoordinate,
  formatDistance
};
