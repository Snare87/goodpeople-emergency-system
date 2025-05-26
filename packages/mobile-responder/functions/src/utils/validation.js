// src/utils/validation.js

const functions = require('firebase-functions');

/**
 * 입력값 검증 유틸리티
 */

/**
 * 인증 검증
 * @param {Object} context - Firebase Functions 컨텍스트
 * @throws {functions.https.HttpsError} 인증되지 않은 경우
 */
function requireAuth(context) {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      '인증이 필요한 기능입니다'
    );
  }
}

/**
 * 필수 필드 검증
 * @param {Object} data - 검증할 데이터
 * @param {Array<string>} requiredFields - 필수 필드 목록
 * @throws {functions.https.HttpsError} 필수 필드가 없는 경우
 */
function validateRequiredFields(data, requiredFields) {
  const missingFields = requiredFields.filter(field => !data[field]);
  
  if (missingFields.length > 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `필수 필드가 누락되었습니다: ${missingFields.join(', ')}`
    );
  }
}

/**
 * GPS 좌표 검증
 * @param {number} lat - 위도
 * @param {number} lng - 경도
 * @returns {boolean} 유효한 좌표인지 여부
 */
function validateCoordinates(lat, lng) {
  if (typeof lat !== 'number' || typeof lng !== 'number') {
    return false;
  }
  
  if (isNaN(lat) || isNaN(lng)) {
    return false;
  }
  
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
    return false;
  }
  
  return true;
}

/**
 * FCM 토큰 형식 검증
 * @param {string} token - FCM 토큰
 * @returns {boolean} 유효한 토큰 형식인지 여부
 */
function validateFcmToken(token) {
  if (!token || typeof token !== 'string') {
    return false;
  }
  
  // FCM 토큰은 일반적으로 100자 이상
  if (token.length < 100) {
    return false;
  }
  
  // 기본적인 형식 검증 (영숫자, 하이픈, 언더스코어, 콜론만 포함)
  const tokenRegex = /^[a-zA-Z0-9\-_:]+$/;
  return tokenRegex.test(token);
}

/**
 * 사용자 데이터 검증
 * @param {Object} userData - 사용자 데이터
 * @returns {Object} 검증 결과 {isValid: boolean, errors: Array<string>}
 */
function validateUserData(userData) {
  const errors = [];
  
  // 상태 검증
  if (userData.status !== 'approved') {
    errors.push('승인되지 않은 사용자');
  }
  
  // 알림 권한 검증
  if (!userData.notificationEnabled) {
    errors.push('알림이 비활성화됨');
  }
  
  // 앱 권한 검증
  if (!userData.permissions?.app) {
    errors.push('앱 사용 권한 없음');
  }
  
  // FCM 토큰 검증
  if (!userData.fcmToken) {
    errors.push('FCM 토큰 없음');
  }
  
  return {
    isValid: errors.length === 0,
    errors
  };
}

module.exports = {
  requireAuth,
  validateRequiredFields,
  validateCoordinates,
  validateFcmToken,
  validateUserData
};
