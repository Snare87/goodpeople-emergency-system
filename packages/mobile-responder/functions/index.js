// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Firebase Admin 초기화
admin.initializeApp();

// 핸들러 모듈 가져오기
const { handleCallNotification } = require('./src/handlers/notifications');
const { updateUserLocation } = require('./src/handlers/location');
const { updateFcmToken, testFcmSend } = require('./src/handlers/fcmToken');

// 리전 설정 (한국/동남아시아)
const region = "asia-southeast1";

/**
 * 호출 상태 변경 시 알림 전송
 * 
 * 트리거 조건:
 * - idle -> dispatched: 새로운 호출
 * - completed -> dispatched: 재호출
 * - 호출 취소 후 다시 호출
 */
exports.sendCallNotification = functions
  .region(region)
  .database
  .ref('/calls/{callId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    const callId = context.params.callId;
    
    // 알림 핸들러에 위임
    return handleCallNotification(before, after, callId);
  });

/**
 * 사용자 위치 업데이트
 * 
 * 클라이언트에서 주기적으로 호출하여 사용자의 현재 위치를 업데이트
 * 이 위치 정보는 근처 재난 알림을 보내는데 사용됨
 */
exports.updateUserLocation = functions
  .region(region)
  .https.onCall(async (data, context) => {
    return updateUserLocation(data, context);
  });

/**
 * FCM 토큰 업데이트
 * 
 * 앱 시작 시 또는 토큰 갱신 시 호출하여 FCM 토큰을 업데이트
 * 푸시 알림을 받기 위해 필수
 */
exports.updateFcmToken = functions
  .region(region)
  .https.onCall(async (data, context) => {
    return updateFcmToken(data, context);
  });

/**
 * FCM 테스트 메시지 전송
 * 
 * 알림 설정 테스트용 함수
 * 주어진 토큰으로 테스트 알림을 전송
 */
exports.testFcmSend = functions
  .region(region)
  .https.onCall(async (data, context) => {
    return testFcmSend(data, context);
  });

/**
 * 예약된 작업: 비활성 토큰 정리 (선택적)
 * 
 * 매일 새벽 3시에 실행되어 유효하지 않은 FCM 토큰을 정리
 * (비용 절감을 위해 주석 처리됨 - 필요시 활성화)
 */
// exports.cleanupInvalidTokens = functions
//   .region(region)
//   .pubsub
//   .schedule('0 3 * * *')
//   .timeZone('Asia/Seoul')
//   .onRun(async (context) => {
//     // 구현 필요: 유효하지 않은 토큰 정리 로직
//     console.log('Cleanup task would run here');
//   });

/**
 * HTTP 트리거: 시스템 상태 확인 (선택적)
 * 
 * Functions의 상태를 확인하는 헬스체크 엔드포인트
 */
exports.healthCheck = functions
  .region(region)
  .https.onRequest(async (req, res) => {
    res.status(200).json({
      status: 'healthy',
      region: region,
      timestamp: new Date().toISOString(),
      version: '2.0.0' // 개선된 버전
    });
  });
