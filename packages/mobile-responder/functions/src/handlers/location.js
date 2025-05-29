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
    
    // 활성 임무가 있는 경우 해당 임무의 응답자 위치도 업데이트
    await updateActiveCallResponderLocation(userId, locationData);
    
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
 * 활성 임무의 응답자 위치 업데이트
 * @param {string} userId - 사용자 ID
 * @param {Object} locationData - 위치 데이터
 */
async function updateActiveCallResponderLocation(userId, locationData) {
  try {
    // 모든 활성 재난 확인
    const callsRef = admin.database().ref('calls');
    const snapshot = await callsRef
      .orderByChild('status')
      .equalTo('accepted')
      .once('value');
    
    if (!snapshot.exists()) return;
    
    const updates = {};
    
    // 해당 사용자가 응답자인 재난 찾기
    snapshot.forEach((callSnapshot) => {
      const call = callSnapshot.val();
      const callId = callSnapshot.key;
      
      // responder.id가 해당 사용자 ID를 포함하는지 확인
      if (call.responder && call.responder.id && call.responder.id.includes(userId)) {
        // 응답자 위치 업데이트
        updates[`calls/${callId}/responder/lat`] = locationData.lat;
        updates[`calls/${callId}/responder/lng`] = locationData.lng;
        updates[`calls/${callId}/responder/updatedAt`] = locationData.updatedAt;
        
        if (locationData.speed !== null) {
          updates[`calls/${callId}/responder/speed`] = locationData.speed;
        }
        
        logger.info('활성 임무 응답자 위치 업데이트', { 
          callId, 
          userId,
          lat: locationData.lat,
          lng: locationData.lng
        });
      }
    });
    
    // 업데이트가 있으면 실행
    if (Object.keys(updates).length > 0) {
      await admin.database().ref().update(updates);
    }
    
  } catch (error) {
    // 활성 임무 위치 업데이트 실패는 로그만 남기고 계속 진행
    logger.error('활성 임무 응답자 위치 업데이트 실패', { userId, error });
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

/**
 * 활성 임무의 응답자들 위치 조회
 * @returns {Promise<Object>} callId를 키로 하는 응답자 위치 맵
 */
async function getActiveRespondersLocations() {
  try {
    const locations = {};
    
    // 수락된 상태의 재난들 조회
    const callsRef = admin.database().ref('calls');
    const snapshot = await callsRef
      .orderByChild('status')
      .equalTo('accepted')
      .once('value');
    
    if (!snapshot.exists()) return locations;
    
    snapshot.forEach((callSnapshot) => {
      const call = callSnapshot.val();
      const callId = callSnapshot.key;
      
      if (call.responder && call.responder.lat && call.responder.lng) {
        locations[callId] = {
          responder: call.responder,
          destination: {
            lat: call.lat,
            lng: call.lng,
            address: call.address,
            eventType: call.eventType
          }
        };
      }
    });
    
    return locations;
    
  } catch (error) {
    logger.error('활성 응답자 위치 조회 실패', error);
    return {};
  }
}

module.exports = {
  updateUserLocation,
  getUserLastLocation,
  getUsersLocations,
  getActiveRespondersLocations
};
