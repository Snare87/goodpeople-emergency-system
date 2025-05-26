// src/utils/fcm.js

const admin = require('firebase-admin');
const logger = require('./logger');

/**
 * FCM 메시지 전송 관련 유틸리티
 */

/**
 * 유효하지 않은 FCM 토큰 정리
 * @param {string} userId - 사용자 ID
 * @param {string} token - FCM 토큰
 * @returns {Promise<boolean>} 정리 성공 여부
 */
async function cleanupInvalidToken(userId, token) {
  try {
    logger.warning('유효하지 않은 FCM 토큰 삭제', { 
      userId, 
      tokenPrefix: token.substring(0, 20) + '...' 
    });
    
    await admin.database().ref(`users/${userId}/fcmToken`).remove();
    
    // 토큰 삭제 로그 기록
    await admin.database().ref(`fcm_cleanup_logs/${userId}/${Date.now()}`).set({
      token: token.substring(0, 20) + '...', // 보안상 일부만 저장
      reason: 'invalid_token',
      timestamp: admin.database.ServerValue.TIMESTAMP
    });
    
    return true;
  } catch (error) {
    logger.error('FCM 토큰 삭제 실패', error);
    return false;
  }
}

/**
 * FCM 메시지 생성
 * @param {Object} notification - 알림 정보 (title, body)
 * @param {Object} data - 추가 데이터
 * @param {string} token - FCM 토큰
 * @returns {Object} FCM 메시지 객체
 */
function createMessage(notification, data, token) {
  return {
    notification,
    data: {
      ...data,
      // 모든 데이터는 문자열이어야 함
      ...Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)])
      )
    },
    token,
    android: {
      priority: 'high',
      notification: {
        channelId: 'emergency_channel',
        priority: 'high',
        sound: 'default',
        defaultSound: true,
        notificationCount: 1,
        visibility: 'public',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          contentAvailable: true,
          alert: {
            title: notification.title,
            body: notification.body,
          },
        },
      },
      headers: {
        'apns-priority': '10',
      },
    },
  };
}

/**
 * 여러 토큰에 FCM 메시지 전송
 * @param {Array<{userId: string, token: string}>} targets - 전송 대상 목록
 * @param {Object} notification - 알림 정보
 * @param {Object} data - 추가 데이터
 * @returns {Promise<Object>} 전송 결과
 */
async function sendToMultipleTokens(targets, notification, data) {
  const results = {
    successCount: 0,
    failureCount: 0,
    failures: []
  };

  // 배치 처리를 위한 청크 크기 (FCM 권장사항)
  const BATCH_SIZE = 500;
  
  // 대상을 배치로 분할
  for (let i = 0; i < targets.length; i += BATCH_SIZE) {
    const batch = targets.slice(i, i + BATCH_SIZE);
    
    // 병렬로 메시지 전송
    const promises = batch.map(async ({ userId, token }) => {
      try {
        const message = createMessage(notification, data, token);
        const response = await admin.messaging().send(message);
        
        results.successCount++;
        
        return { success: true, userId, response };
      } catch (error) {
        results.failureCount++;
        results.failures.push({ userId, error: error.message });
        
        // 토큰 관련 오류 처리
        if (isTokenError(error)) {
          await cleanupInvalidToken(userId, token);
        }
        
        logger.error('FCM 전송 실패', {
          userId,
          error: error.message,
          code: error.code
        });
        
        return { success: false, userId, error: error.message };
      }
    });
    
    // 배치 전송 완료 대기
    await Promise.all(promises);
    
    // 다음 배치 전송 전 잠시 대기 (과부하 방지)
    if (i + BATCH_SIZE < targets.length) {
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  
  return results;
}

/**
 * FCM 토큰 관련 오류인지 확인
 * @param {Error} error - 에러 객체
 * @returns {boolean} 토큰 오류 여부
 */
function isTokenError(error) {
  const tokenErrorCodes = [
    'messaging/invalid-registration-token',
    'messaging/registration-token-not-registered',
    'messaging/invalid-recipient',
    'messaging/invalid-argument'
  ];
  
  return tokenErrorCodes.includes(error.code);
}

module.exports = {
  cleanupInvalidToken,
  createMessage,
  sendToMultipleTokens,
  isTokenError
};
