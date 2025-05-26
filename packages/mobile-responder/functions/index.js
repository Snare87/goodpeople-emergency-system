// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// 리전을 asia-southeast1로 설정
const region = "asia-southeast1";

// 로깅 헬퍼 함수
const logger = {
  info: (message, data = {}) => {
    console.log(`[INFO] ${message}`, JSON.stringify(data));
  },
  error: (message, error = {}) => {
    console.error(`[ERROR] ${message}`, error);
  },
  warning: (message, data = {}) => {
    console.log(`[WARNING] ${message}`, JSON.stringify(data));
  }
};

// Haversine 공식으로 두 지점 간 거리 계산 (km)
function calculateDistance(lat1, lon1, lat2, lon2) {
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

function toRad(value) {
  return value * Math.PI / 180;
}

// FCM 토큰 정리 함수
async function cleanupInvalidToken(userId, token) {
  try {
    logger.warning(`유효하지 않은 FCM 토큰 삭제`, { userId, tokenPrefix: token.substring(0, 20) });
    await admin.database().ref(`users/${userId}/fcmToken`).remove();
    return true;
  } catch (error) {
    logger.error(`FCM 토큰 삭제 실패`, error);
    return false;
  }
}

// 호출하기 알림 전송
exports.sendCallNotification = functions
  .region(region)
  .database
  .ref('/calls/{callId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    const callId = context.params.callId;
    
    logger.info(`알림 처리 시작`, {
      callId,
      beforeStatus: before.status,
      afterStatus: after.status
    });
    
    // 알림을 보내야 하는 경우들 체크
    let notificationType = null;
    let shouldSendNotification = false;
    
    // 1. idle -> dispatched: 호출하기 (new_call)
    if (before.status === 'idle' && after.status === 'dispatched') {
      notificationType = 'new_call';
      shouldSendNotification = true;
    }
    
    // 2. completed -> dispatched: 재호출하기 (recall)
    else if (before.status === 'completed' && after.status === 'dispatched') {
      notificationType = 'recall';
      shouldSendNotification = true;
    }
    
    // 3. 호출취소 후 다시 호출 체크
    else if (after.status === 'dispatched' && 
             after.cancellationCount === before.cancellationCount &&
             before.status === 'idle' &&
             before.dispatchedAt !== null) {
      notificationType = 'new_call';
      shouldSendNotification = true;
    }
    
    if (!shouldSendNotification) {
      logger.info(`알림 발송 조건에 해당하지 않음`, { callId });
      return null;
    }
    
    logger.info(`${notificationType} 알림 발송 시작`, { callId });
    
    try {
      // 재난 위치
      const callLat = after.lat;
      const callLng = after.lng;
      
      // 모든 사용자 가져오기
      const usersSnapshot = await admin.database().ref('users').once('value');
      const users = usersSnapshot.val() || {};
      
      const tokens = [];
      const userIds = [];
      
      logger.info(`대상 사용자 검색 시작`, {
        callLocation: { lat: callLat, lng: callLng },
        eventType: after.eventType
      });
      
      // 5km 이내 사용자 필터링
      for (const [userId, userData] of Object.entries(users)) {
        // 활성 사용자만 (승인됨, 알림 켜짐, 앱 권한 있음)
        if (userData.status !== 'approved' || 
            !userData.notificationEnabled || 
            !userData.permissions?.app) {
          continue;
        }
        
        // FCM 토큰이 있는지 확인
        if (!userData.fcmToken) {
          continue;
        }
        
        // 위치 정보가 있는 경우만 거리 계산
        if (userData.lastLocation && userData.lastLocation.lat && userData.lastLocation.lng) {
          const distance = calculateDistance(
            callLat, 
            callLng,
            userData.lastLocation.lat,
            userData.lastLocation.lng
          );
          
          // 5km 이내인 경우
          if (distance <= 5) {
            tokens.push(userData.fcmToken);
            userIds.push(userId);
            logger.info(`사용자 추가`, { 
              userId, 
              name: userData.name, 
              distance: `${distance.toFixed(2)}km` 
            });
          }
        } else if (userData.locationEnabled !== false) {
          // 위치 정보가 없지만 위치 권한이 켜져있는 경우
          tokens.push(userData.fcmToken);
          userIds.push(userId);
        }
      }
      
      if (tokens.length === 0) {
        logger.warning(`알림을 받을 대상이 없습니다`, { callId });
        return null;
      }
      
      logger.info(`알림 대상 확정`, { 
        callId, 
        targetCount: tokens.length,
        userIds 
      });
      
      // 알림 메시지 구성
      const notification = {
        title: notificationType === 'recall' ? '🚨 재난 재호출' : '🚨 긴급 출동',
        body: `${after.eventType} - ${after.address}`,
      };
      
      // 추가 데이터
      const data = {
        type: notificationType,
        callId: callId,
        eventType: after.eventType,
        address: after.address,
        lat: String(callLat),
        lng: String(callLng),
        info: after.info || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      };
      
      // FCM 메시지 전송
      logger.info(`FCM 메시지 전송 시작`, { callId, targetCount: tokens.length });
      
      // 성공 및 실패 카운터
      let successCount = 0;
      let failureCount = 0;
      const failedTokens = [];
      
      // 각 토큰에 대해 개별적으로 메시지 전송
      for (let i = 0; i < tokens.length; i++) {
        const token = tokens[i];
        const userId = userIds[i];
        
        try {
          // 개별 메시지 구성
          const singleMessage = {
            notification,
            data,
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
          
          // 단일 메시지 전송
          const response = await admin.messaging().send(singleMessage);
          successCount++;
          
        } catch (error) {
          failureCount++;
          failedTokens.push({ userId, token, error: error.message });
          
          // 토큰 관련 오류 처리
          if (error.code === 'messaging/invalid-registration-token' ||
              error.code === 'messaging/registration-token-not-registered') {
            // 유효하지 않은 토큰 삭제
            await cleanupInvalidToken(userId, token);
          }
          
          logger.error(`FCM 전송 실패`, {
            userId,
            error: error.message,
            code: error.code
          });
        }
      }
      
      // 전송 결과 로깅
      logger.info(`FCM 전송 완료`, {
        callId,
        successCount,
        failureCount,
        totalTargets: tokens.length
      });
      
      // 실패한 토큰이 있으면 상세 로깅
      if (failedTokens.length > 0) {
        logger.warning(`FCM 전송 실패 상세`, { 
          callId, 
          failedTokens: failedTokens.map(f => ({
            userId: f.userId,
            error: f.error,
            tokenPrefix: f.token.substring(0, 20)
          }))
        });
      }
      
      // 알림 로그 저장
      await admin.database().ref(`notification_logs/${callId}/${Date.now()}`).set({
        type: notificationType,
        targetUsers: userIds,
        successCount: successCount,
        failureCount: failureCount,
        timestamp: admin.database.ServerValue.TIMESTAMP,
        eventType: after.eventType,
        address: after.address,
        failedTokens: failedTokens.map(f => f.userId) // userId만 저장
      });
      
      logger.info(`알림 처리 완료`, { callId });
      
    } catch (error) {
      logger.error(`알림 처리 중 치명적 오류`, {
        callId,
        error: error.message,
        stack: error.stack
      });
      throw error; // Functions 로그에서 추적할 수 있도록 오류 재발생
    }
  });

// 사용자 위치 업데이트
exports.updateUserLocation = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 인증 확인
    if (!context.auth) {
      logger.warning(`인증되지 않은 위치 업데이트 시도`);
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    const { lat, lng } = data;
    
    if (!lat || !lng) {
      logger.warning(`잘못된 위치 데이터`, { userId, lat, lng });
      throw new functions.https.HttpsError('invalid-argument', 'lat and lng are required');
    }
    
    try {
      await admin.database().ref(`users/${userId}/lastLocation`).set({
        lat,
        lng,
        updatedAt: admin.database.ServerValue.TIMESTAMP,
      });
      
      logger.info(`위치 업데이트 성공`, { userId, lat, lng });
      
      return { success: true };
    } catch (error) {
      logger.error(`위치 업데이트 실패`, { userId, error: error.message });
      throw new functions.https.HttpsError('internal', 'Failed to update location');
    }
  });

// FCM 토큰 업데이트
exports.updateFcmToken = functions
  .region(region)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      logger.warning(`인증되지 않은 FCM 토큰 업데이트 시도`);
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    const { token } = data;
    
    if (!token) {
      logger.warning(`잘못된 FCM 토큰`, { userId });
      throw new functions.https.HttpsError('invalid-argument', 'token is required');
    }
    
    try {
      await admin.database().ref(`users/${userId}/fcmToken`).set(token);
      logger.info(`FCM 토큰 업데이트 성공`, { userId, tokenPrefix: token.substring(0, 20) });
      
      return { success: true };
    } catch (error) {
      logger.error(`FCM 토큰 업데이트 실패`, { userId, error: error.message });
      throw new functions.https.HttpsError('internal', 'Failed to update token');
    }
  });

// 테스트용 FCM 전송 함수
exports.testFcmSend = functions
  .region(region)
  .https.onCall(async (data, context) => {
    const { token } = data;
    
    if (!token) {
      logger.warning(`테스트 FCM 전송 - 토큰 없음`);
      throw new functions.https.HttpsError('invalid-argument', 'token is required');
    }
    
    const testMessage = {
      notification: {
        title: '🚨 테스트 알림',
        body: '이것은 테스트 메시지입니다',
      },
      data: {
        type: 'test',
        timestamp: String(Date.now()),
      },
      token: token,
      android: {
        priority: 'high',
        notification: {
          channelId: 'emergency_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
    };
    
    try {
      const response = await admin.messaging().send(testMessage);
      logger.info(`테스트 메시지 전송 성공`, { messageId: response });
      return { success: true, messageId: response };
    } catch (error) {
      logger.error(`테스트 메시지 전송 실패`, { error: error.message, code: error.code });
      
      // 토큰 오류인 경우 명확한 메시지 전달
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        throw new functions.https.HttpsError('failed-precondition', '유효하지 않은 FCM 토큰입니다.');
      }
      
      throw new functions.https.HttpsError('internal', error.message);
    }
  });