// src/handlers/notifications.js

const admin = require('firebase-admin');
const logger = require('../utils/logger');
const { calculateDistance, formatDistance } = require('../utils/distance');
const { sendToMultipleTokens } = require('../utils/fcm');
const { validateUserData } = require('../utils/validation');

/**
 * 알림 전송 핸들러
 */

// 상수 정의
const NOTIFICATION_RADIUS_KM = 5; // 알림 전송 반경 (km)

/**
 * 호출 상태 변경 시 알림 전송
 * @param {Object} before - 변경 전 호출 데이터
 * @param {Object} after - 변경 후 호출 데이터
 * @param {string} callId - 호출 ID
 */
async function handleCallNotification(before, after, callId) {
  logger.info('알림 처리 시작', {
    callId,
    beforeStatus: before.status,
    afterStatus: after.status
  });
  
  // 알림 타입 결정
  const notificationType = determineNotificationType(before, after);
  
  if (!notificationType) {
    logger.info('알림 발송 조건에 해당하지 않음', { callId });
    return null;
  }
  
  logger.info(`${notificationType} 알림 발송 시작`, { callId });
  
  try {
    // 알림 대상 사용자 찾기
    const targets = await findNotificationTargets(after);
    
    if (targets.length === 0) {
      logger.warning('알림을 받을 대상이 없습니다', { callId });
      return null;
    }
    
    logger.info('알림 대상 확정', { 
      callId, 
      targetCount: targets.length,
      userIds: targets.map(t => t.userId)
    });
    
    // 알림 메시지 생성
    const { notification, data } = createNotificationContent(notificationType, after, callId);
    
    // FCM 메시지 전송
    const results = await sendToMultipleTokens(targets, notification, data);
    
    // 전송 결과 로깅
    logger.info('FCM 전송 완료', {
      callId,
      ...results
    });
    
    // 알림 로그 저장
    await saveNotificationLog(callId, notificationType, after, targets, results);
    
    logger.info('알림 처리 완료', { callId });
    
    return results;
    
  } catch (error) {
    logger.error('알림 처리 중 오류', {
      callId,
      error: error.message,
      stack: error.stack
    });
    throw error;
  }
}

/**
 * 알림 타입 결정
 * @param {Object} before - 변경 전 데이터
 * @param {Object} after - 변경 후 데이터
 * @returns {string|null} 알림 타입
 */
function determineNotificationType(before, after) {
  // 1. idle -> dispatched: 새로운 호출
  if (before.status === 'idle' && after.status === 'dispatched') {
    return 'new_call';
  }
  
  // 2. completed -> dispatched: 재호출
  if (before.status === 'completed' && after.status === 'dispatched') {
    return 'recall';
  }
  
  // 3. 호출 취소 후 다시 호출
  if (after.status === 'dispatched' && 
      after.cancellationCount === before.cancellationCount &&
      before.status === 'idle' &&
      before.dispatchedAt !== null) {
    return 'new_call';
  }
  
  return null;
}

/**
 * 알림 대상 사용자 찾기
 * @param {Object} callData - 호출 데이터
 * @returns {Promise<Array>} 대상 사용자 목록
 */
async function findNotificationTargets(callData) {
  const { lat: callLat, lng: callLng } = callData;
  
  // 모든 사용자 가져오기
  const usersSnapshot = await admin.database().ref('users').once('value');
  const users = usersSnapshot.val() || {};
  
  const targets = [];
  
  logger.info('대상 사용자 검색 시작', {
    callLocation: { lat: callLat, lng: callLng },
    eventType: callData.eventType
  });
  
  // 각 사용자 검증 및 필터링
  for (const [userId, userData] of Object.entries(users)) {
    // 사용자 데이터 검증
    const validation = validateUserData(userData);
    if (!validation.isValid) {
      logger.debug(`사용자 제외: ${userId}`, { reasons: validation.errors });
      continue;
    }
    
    // 거리 기반 필터링
    const isWithinRange = checkUserDistance(userData, callLat, callLng);
    
    if (isWithinRange) {
      targets.push({
        userId,
        token: userData.fcmToken,
        name: userData.name,
        distance: isWithinRange.distance
      });
      
      logger.info('사용자 추가', { 
        userId, 
        name: userData.name, 
        distance: formatDistance(isWithinRange.distance)
      });
    }
  }
  
  // 거리순으로 정렬 (가까운 사용자 우선)
  targets.sort((a, b) => (a.distance || 999) - (b.distance || 999));
  
  return targets;
}

/**
 * 사용자 거리 확인
 * @param {Object} userData - 사용자 데이터
 * @param {number} callLat - 호출 위도
 * @param {number} callLng - 호출 경도
 * @returns {Object|null} 거리 정보 또는 null
 */
function checkUserDistance(userData, callLat, callLng) {
  // 위치 정보가 있는 경우
  if (userData.lastLocation?.lat && userData.lastLocation?.lng) {
    try {
      const distance = calculateDistance(
        callLat, 
        callLng,
        userData.lastLocation.lat,
        userData.lastLocation.lng
      );
      
      // 반경 내인 경우
      if (distance <= NOTIFICATION_RADIUS_KM) {
        return { distance, hasLocation: true };
      }
    } catch (error) {
      logger.error('거리 계산 오류', error);
    }
  }
  // 위치 정보가 없지만 위치 권한이 켜져있는 경우
  else if (userData.locationEnabled !== false) {
    return { distance: null, hasLocation: false };
  }
  
  return null;
}

/**
 * 알림 콘텐츠 생성
 * @param {string} notificationType - 알림 타입
 * @param {Object} callData - 호출 데이터
 * @param {string} callId - 호출 ID
 * @returns {Object} 알림 콘텐츠
 */
function createNotificationContent(notificationType, callData, callId) {
  const notification = {
    title: notificationType === 'recall' ? '🚨 재난 재호출' : '🚨 긴급 출동',
    body: `${callData.eventType} - ${callData.address}`,
  };
  
  const data = {
    type: notificationType,
    callId: callId,
    eventType: callData.eventType,
    address: callData.address,
    lat: String(callData.lat),
    lng: String(callData.lng),
    info: callData.info || '',
    timestamp: String(Date.now()),
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
  };
  
  return { notification, data };
}

/**
 * 알림 로그 저장
 * @param {string} callId - 호출 ID
 * @param {string} notificationType - 알림 타입
 * @param {Object} callData - 호출 데이터
 * @param {Array} targets - 대상 사용자 목록
 * @param {Object} results - 전송 결과
 */
async function saveNotificationLog(callId, notificationType, callData, targets, results) {
  try {
    const logData = {
      type: notificationType,
      targetUsers: targets.map(t => ({
        userId: t.userId,
        name: t.name,
        distance: t.distance ? formatDistance(t.distance) : 'unknown'
      })),
      successCount: results.successCount,
      failureCount: results.failureCount,
      timestamp: admin.database.ServerValue.TIMESTAMP,
      eventType: callData.eventType,
      address: callData.address,
      failures: results.failures || []
    };
    
    await admin.database()
      .ref(`notification_logs/${callId}/${Date.now()}`)
      .set(logData);
      
  } catch (error) {
    logger.error('알림 로그 저장 실패', error);
    // 로그 저장 실패는 전체 프로세스를 중단시키지 않음
  }
}

module.exports = {
  handleCallNotification
};
