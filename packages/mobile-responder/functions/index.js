// functions/index.js
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// 리전을 asia-southeast1로 설정
const region = "asia-southeast1";

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

// 호출하기 알림 전송
exports.sendCallNotification = functions
  .region(region)
  .database
  .ref('/calls/{callId}')
  .onUpdate(async (change, context) => {
    const before = change.before.val();
    const after = change.after.val();
    const callId = context.params.callId;
    
    console.log(`\n========== 알림 처리 시작 ==========`);
    console.log(`Call ID: ${callId}`);
    console.log(`이전 상태: ${before.status}`);
    console.log(`현재 상태: ${after.status}`);
    console.log(`이전 dispatchedAt: ${before.dispatchedAt}`);
    console.log(`현재 dispatchedAt: ${after.dispatchedAt}`);
    
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
    // 취소 횟수가 증가하지 않았는데 dispatched 상태가 되면 취소 후 재호출
    else if (after.status === 'dispatched' && 
             after.cancellationCount === before.cancellationCount &&
             before.status === 'idle' &&
             before.dispatchedAt !== null) {
      notificationType = 'new_call';
      shouldSendNotification = true;
    }
    
    if (!shouldSendNotification) {
      console.log('❌ 알림 발송 조건에 해당하지 않음');
      console.log(`========== 알림 처리 종료 ==========\n`);
      return null;
    }
    
    console.log(`Sending ${notificationType} notification for call ${callId}`);
    
    // 재난 위치
    const callLat = after.lat;
    const callLng = after.lng;
    
    // 모든 사용자 가져오기
    const usersSnapshot = await admin.database().ref('users').once('value');
    const users = usersSnapshot.val() || {};
    
    const tokens = [];
    const userIds = [];
    
    console.log(`\n🔍 대상 사용자 검색 시작`);
    console.log(`재난 위치: ${callLat}, ${callLng}`);
    
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
          console.log(`User ${userId} is ${distance.toFixed(2)}km away - sending notification`);
        } else {
          console.log(`User ${userId} is ${distance.toFixed(2)}km away - too far`);
        }
      } else if (userData.locationEnabled === false) {
        // 위치 정보를 제공하지 않는 사용자는 알림 제외
        console.log(`User ${userId} has location disabled - skipping`);
      } else {
        // 위치 정보가 없지만 위치 권한이 켜져있는 경우 (신규 사용자 등) 알림 전송
        tokens.push(userData.fcmToken);
        userIds.push(userId);
        console.log(`User ${userId} has no location yet - sending notification`);
      }
    }
    
    if (tokens.length === 0) {
      console.log('❌ 알림을 받을 대상이 없습니다');
      console.log(`========== 알림 처리 종료 ==========\n`);
      return null;
    }
    
    console.log(`\n✅ 알림 대상: ${tokens.length}명`);
    console.log(`대상 사용자 ID: ${userIds.join(', ')}`);
    
    // 알림 메시지 구성
    const notification = {
      title: notificationType === 'recall' ? '🚨 재난 재호출' : '🚨 긴급 출동',
      body: `${after.eventType} - ${after.address}`,
    };
    
    const data = {
      type: notificationType,
      callId: callId,
      eventType: after.eventType,
      address: after.address,
      lat: String(callLat),
      lng: String(callLng),
      info: after.info || '',
    };
    
    // FCM 메시지 전송
    const message = {
      notification,
      data,
      tokens,
      android: {
        priority: 'high',
        notification: {
          channelId: 'emergency_channel',
          priority: 'high',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };
    
    try {
      const response = await admin.messaging().sendMulticast(message);
      console.log(`\n📨 FCM 전송 결과:`);
      console.log(`✅ 성공: ${response.successCount}개`);
      console.log(`❌ 실패: ${response.failureCount}개`);
      
      // 실패한 경우 상세 로그
      if (response.failureCount > 0) {
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            console.log(`실패 - 사용자 ${userIds[idx]}: ${resp.error.message}`);
          }
        });
      }
      
      // 알림 로그 저장
      await admin.database().ref(`notification_logs/${callId}/${Date.now()}`).set({
        type: notificationType,
        targetUsers: userIds,
        successCount: response.successCount,
        failureCount: response.failureCount,
        timestamp: admin.database.ServerValue.TIMESTAMP,
      });
      
      console.log(`========== 알림 처리 완료 ==========\n`);
    } catch (error) {
      console.error('❌ FCM 전송 오류:', error);
      console.log(`========== 알림 처리 실패 ==========\n`);
    }
    
    return null;
  });

// 사용자 위치 업데이트
exports.updateUserLocation = functions
  .region(region)
  .https.onCall(async (data, context) => {
    // 인증 확인
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    const { lat, lng } = data;
    
    if (!lat || !lng) {
      throw new functions.https.HttpsError('invalid-argument', 'lat and lng are required');
    }
    
    try {
      await admin.database().ref(`users/${userId}/lastLocation`).set({
        lat,
        lng,
        updatedAt: admin.database.ServerValue.TIMESTAMP,
      });
      
      return { success: true };
    } catch (error) {
      console.error('Error updating location:', error);
      throw new functions.https.HttpsError('internal', 'Failed to update location');
    }
  });

// FCM 토큰 업데이트
exports.updateFcmToken = functions
  .region(region)
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }
    
    const userId = context.auth.uid;
    const { token } = data;
    
    if (!token) {
      throw new functions.https.HttpsError('invalid-argument', 'token is required');
    }
    
    try {
      await admin.database().ref(`users/${userId}/fcmToken`).set(token);
      return { success: true };
    } catch (error) {
      console.error('Error updating FCM token:', error);
      throw new functions.https.HttpsError('internal', 'Failed to update token');
    }
  });