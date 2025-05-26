// src/handlers/fcmToken.js

const admin = require('firebase-admin');
const functions = require('firebase-functions');
const logger = require('../utils/logger');
const { requireAuth, validateFcmToken } = require('../utils/validation');
const { createMessage } = require('../utils/fcm');

/**
 * FCM 토큰 관련 핸들러
 */

/**
 * FCM 토큰 업데이트
 * @param {Object} data - 요청 데이터 (token)
 * @param {Object} context - Firebase Functions 컨텍스트
 * @returns {Promise<Object>} 응답 객체
 */
async function updateFcmToken(data, context) {
  // 인증 확인
  requireAuth(context);
  
  const userId = context.auth.uid;
  const { token } = data;
  
  // 토큰 검증
  if (!validateFcmToken(token)) {
    logger.warning('잘못된 FCM 토큰 형식', { userId });
    throw new functions.https.HttpsError(
      'invalid-argument', 
      '유효하지 않은 FCM 토큰 형식입니다'
    );
  }
  
  try {
    // 이전 토큰 조회 (변경 감지용)
    const previousTokenSnapshot = await admin.database()
      .ref(`users/${userId}/fcmToken`)
      .once('value');
    const previousToken = previousTokenSnapshot.val();
    
    // 토큰이 변경된 경우에만 업데이트
    if (previousToken !== token) {
      // 토큰 업데이트
      await admin.database()
        .ref(`users/${userId}`)
        .update({
          fcmToken: token,
          fcmTokenUpdatedAt: admin.database.ServerValue.TIMESTAMP
        });
      
      // 토큰 변경 로그
      await logTokenChange(userId, previousToken, token);
      
      logger.info('FCM 토큰 업데이트 성공', { 
        userId, 
        tokenPrefix: token.substring(0, 20) + '...',
        isNewToken: !previousToken
      });
    } else {
      logger.info('FCM 토큰 변경 없음', { userId });
    }
    
    return { 
      success: true,
      updated: previousToken !== token
    };
    
  } catch (error) {
    logger.error('FCM 토큰 업데이트 실패', { 
      userId, 
      error: error.message 
    });
    
    throw new functions.https.HttpsError(
      'internal', 
      'FCM 토큰 업데이트에 실패했습니다'
    );
  }
}

/**
 * FCM 테스트 메시지 전송
 * @param {Object} data - 요청 데이터 (token)
 * @param {Object} context - Firebase Functions 컨텍스트
 * @returns {Promise<Object>} 응답 객체
 */
async function testFcmSend(data, context) {
  const { token } = data;
  
  // 토큰 검증
  if (!validateFcmToken(token)) {
    logger.warning('테스트 FCM 전송 - 잘못된 토큰 형식');
    throw new functions.https.HttpsError(
      'invalid-argument', 
      '유효하지 않은 FCM 토큰 형식입니다'
    );
  }
  
  // 테스트 메시지 생성
  const notification = {
    title: '🚨 테스트 알림',
    body: '굿피플 119 시스템 알림 테스트입니다',
  };
  
  const messageData = {
    type: 'test',
    timestamp: String(Date.now()),
    message: '이것은 테스트 메시지입니다'
  };
  
  const testMessage = createMessage(notification, messageData, token);
  
  try {
    // 메시지 전송
    const response = await admin.messaging().send(testMessage);
    
    logger.info('테스트 메시지 전송 성공', { 
      messageId: response,
      tokenPrefix: token.substring(0, 20) + '...'
    });
    
    // 인증된 사용자인 경우 테스트 로그 저장
    if (context.auth) {
      await saveTestLog(context.auth.uid, response);
    }
    
    return { 
      success: true, 
      messageId: response,
      timestamp: Date.now()
    };
    
  } catch (error) {
    logger.error('테스트 메시지 전송 실패', { 
      error: error.message, 
      code: error.code 
    });
    
    // 토큰 오류인 경우 명확한 메시지 전달
    if (error.code === 'messaging/invalid-registration-token' ||
        error.code === 'messaging/registration-token-not-registered') {
      throw new functions.https.HttpsError(
        'failed-precondition', 
        '유효하지 않은 FCM 토큰입니다. 앱을 다시 시작해주세요.'
      );
    }
    
    throw new functions.https.HttpsError(
      'internal', 
      `알림 전송 실패: ${error.message}`
    );
  }
}

/**
 * 토큰 변경 로그 저장
 * @param {string} userId - 사용자 ID
 * @param {string|null} previousToken - 이전 토큰
 * @param {string} newToken - 새 토큰
 */
async function logTokenChange(userId, previousToken, newToken) {
  try {
    await admin.database()
      .ref(`fcm_token_history/${userId}`)
      .push({
        previousToken: previousToken ? previousToken.substring(0, 20) + '...' : null,
        newToken: newToken.substring(0, 20) + '...',
        timestamp: admin.database.ServerValue.TIMESTAMP,
        userAgent: null // 추후 클라이언트 정보 추가 가능
      });
  } catch (error) {
    // 로그 저장 실패는 무시
    logger.error('토큰 변경 로그 저장 실패', error);
  }
}

/**
 * 테스트 로그 저장
 * @param {string} userId - 사용자 ID
 * @param {string} messageId - 메시지 ID
 */
async function saveTestLog(userId, messageId) {
  try {
    await admin.database()
      .ref(`fcm_test_logs/${userId}`)
      .push({
        messageId,
        timestamp: admin.database.ServerValue.TIMESTAMP,
        success: true
      });
  } catch (error) {
    // 로그 저장 실패는 무시
    logger.error('테스트 로그 저장 실패', error);
  }
}

module.exports = {
  updateFcmToken,
  testFcmSend
};
