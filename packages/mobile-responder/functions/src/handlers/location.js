// src/handlers/location.js

const admin = require('firebase-admin');
const functions = require('firebase-functions');
const logger = require('../utils/logger');
const { requireAuth, validateCoordinates } = require('../utils/validation');

/**
 * 위치 관련 핸들러
 */

/**
 * 사용자 위치 업데이트
 * @param {Object} data - 요청 데이터 (lat, lng)
 * @param {Object} context - Firebase Functions 컨텍스트
 * @returns {Promise<Object>} 응답 객체
 */
async function updateUserLocation(data, context) {
  // 인증 확인
  requireAuth(context);
  
  const userId = context.auth.uid;
  const { lat, lng } = data;
  
  // 위치 데이터 검증
  if (!validateCoordinates(lat, lng)) {
    logger.warning('잘못된 위치 데이터', { userId, lat, lng });
    throw new functions.https.HttpsError(
      'invalid-argument', 
      '유효하지 않은 GPS 좌표입니다'
    );
  }
  
  try {
    // 위치 업데이트
    const locationData = {
      lat,
      lng,
      updatedAt: admin.database.ServerValue.TIMESTAMP,
      accuracy: data.accuracy || null, // 선택적: 위치 정확도
      altitude: data.altitude || null, // 선택적: 고도
      speed: data.speed || null        // 선택적: 속도
    };
    
    await admin.database()
      .ref(`users/${userId}/lastLocation`)
      .set(locationData);
    
    // 위치 히스토리 저장 (선택적 - 분석용)
    await saveLocationHistory(userId, locationData);
    
    logger.info('위치 업데이트 성공', { 
      userId, 
      lat, 
      lng,
      accuracy: data.accuracy 
    });
    
    return { 
      success: true,
      timestamp: Date.now()
    };
    
  } catch (error) {
    logger.error('위치 업데이트 실패', { 
      userId, 
      error: error.message 
    });
    
    throw new functions.https.HttpsError(
      'internal', 
      '위치 업데이트에 실패했습니다'
    );
  }
}

/**
 * 위치 히스토리 저장 (분석 및 추적용)
 * @param {string} userId - 사용자 ID
 * @param {Object} locationData - 위치 데이터
 */
async function saveLocationHistory(userId, locationData) {
  try {
    // 최근 24시간 데이터만 유지
    const dayAgo = Date.now() - (24 * 60 * 60 * 1000);
    
    // 이전 데이터 정리
    const oldDataRef = admin.database()
      .ref(`location_history/${userId}`)
      .orderByChild('timestamp')
      .endAt(dayAgo);
    
    const oldDataSnapshot = await oldDataRef.once('value');
    
    // 삭제할 키 수집
    const keysToDelete = [];
    oldDataSnapshot.forEach((child) => {
      keysToDelete.push(child.key);
    });
    
    // 배치 삭제
    if (keysToDelete.length > 0) {
      const updates = {};
      keysToDelete.forEach(key => {
        updates[`location_history/${userId}/${key}`] = null;
      });
      await admin.database().ref().update(updates);
    }
    
    // 새 위치 저장
    await admin.database()
      .ref(`location_history/${userId}`)
      .push({
        ...locationData,
        timestamp: Date.now()
      });
      
  } catch (error) {
    // 히스토리 저장 실패는 무시 (메인 기능에 영향 없음)
    logger.error('위치 히스토리 저장 실패', error);
  }
}

/**
 * 사용자의 마지막 위치 가져오기
 * @param {string} userId - 사용자 ID
 * @returns {Promise<Object|null>} 위치 데이터
 */
async function getUserLastLocation(userId) {
  try {
    const snapshot = await admin.database()
      .ref(`users/${userId}/lastLocation`)
      .once('value');
      
    return snapshot.val();
  } catch (error) {
    logger.error('마지막 위치 조회 실패', { userId, error });
    return null;
  }
}

/**
 * 여러 사용자의 위치 일괄 조회
 * @param {Array<string>} userIds - 사용자 ID 목록
 * @returns {Promise<Object>} userId를 키로 하는 위치 데이터 맵
 */
async function getUsersLocations(userIds) {
  try {
    const locations = {};
    
    // 병렬로 위치 데이터 가져오기
    const promises = userIds.map(async (userId) => {
      const location = await getUserLastLocation(userId);
      if (location) {
        locations[userId] = location;
      }
    });
    
    await Promise.all(promises);
    
    return locations;
  } catch (error) {
    logger.error('사용자 위치 일괄 조회 실패', error);
    return {};
  }
}

module.exports = {
  updateUserLocation,
  getUserLastLocation,
  getUsersLocations
};
