// functions/src/incident-functions.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

// 환경 변수에서 Google Maps API 키 가져오기
const GOOGLE_MAPS_API_KEY = functions.config().maps?.apikey || '';

interface DistanceMatrixResult {
  distanceKm: number;
  etaSec: number;
}

// 1. 후보자 등록 시 거리/ETA 계산
export const onCandidateWrite = functions.firestore
  .document('incidents/{incidentId}/candidates/{candidateId}')
  .onWrite(async (change, context) => {
    const { incidentId, candidateId } = context.params;
    
    // 삭제된 경우 무시
    if (!change.after.exists) {
      return null;
    }
    
    const candidateData = change.after.data();
    if (!candidateData) return null;
    
    // 이미 계산된 경우 스킵
    if (candidateData.distanceKm && candidateData.etaSec) {
      return null;
    }
    
    try {
      // 재난 정보 가져오기
      const incidentDoc = await db.doc(`incidents/${incidentId}`).get();
      const incident = incidentDoc.data();
      
      if (!incident) {
        console.error('Incident not found:', incidentId);
        return null;
      }
      
      // Distance Matrix API 호출
      const result = await calculateDistanceMatrix(
        { lat: candidateData.lat, lng: candidateData.lng },
        { lat: incident.lat, lng: incident.lng }
      );
      
      // 결과 업데이트
      await change.after.ref.update({
        distanceKm: result.distanceKm,
        etaSec: result.etaSec,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      console.log(`Updated candidate ${candidateId}: ${result.distanceKm}km, ${result.etaSec}s`);
      
      // 자동 선택 타이머 시작 (최초 후보자인 경우)
      const candidatesSnapshot = await db
        .collection(`incidents/${incidentId}/candidates`)
        .get();
      
      if (candidatesSnapshot.size === 1) {
        // 최초 후보자 - holdWindow 후 자동 선택 예약
        const holdWindowSec = incident.holdWindowSec || 5;
        
        await scheduleFunctionCall(
          'autoAssign',
          { incidentId },
          holdWindowSec * 1000 // 밀리초로 변환
        );
      }
      
    } catch (error) {
      console.error('Error calculating distance:', error);
    }
    
    return null;
  });

// 2. 자동 선택 함수
export const autoAssign = functions.https.onCall(async (data, context) => {
  const { incidentId } = data;
  
  if (!incidentId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'incidentId is required'
    );
  }
  
  try {
    // 재난 정보 확인
    const incidentRef = db.doc(`incidents/${incidentId}`);
    const incidentDoc = await incidentRef.get();
    
    if (!incidentDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Incident not found');
    }
    
    const incident = incidentDoc.data()!;
    
    // 이미 할당된 경우 스킵
    if (incident.status !== 'broadcasting' || incident.chosenResponderId) {
      console.log('Incident already assigned:', incidentId);
      return { success: false, reason: 'already_assigned' };
    }
    
    // 모든 후보자 가져오기
    const candidatesSnapshot = await db
      .collection(`incidents/${incidentId}/candidates`)
      .where('state', '==', 'pending')
      .get();
    
    if (candidatesSnapshot.empty) {
      console.log('No candidates available');
      return { success: false, reason: 'no_candidates' };
    }
    
    // 점수 계산 및 최적 후보 선택
    let bestCandidate: any = null;
    let bestScore = Infinity;
    
    candidatesSnapshot.forEach(doc => {
      const candidate = doc.data();
      
      // 점수 계산 (낮을수록 좋음)
      const score = calculateScore(candidate);
      
      if (score < bestScore) {
        bestScore = score;
        bestCandidate = {
          id: doc.id,
          ...candidate
        };
      }
    });
    
    if (!bestCandidate) {
      return { success: false, reason: 'no_valid_candidate' };
    }
    
    // 트랜잭션으로 할당
    await db.runTransaction(async (transaction) => {
      // 재난 상태 업데이트
      transaction.update(incidentRef, {
        status: 'assigned',
        chosenResponderId: bestCandidate.id,
        assignedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      // 선택된 후보자에게 알림
      await sendAssignmentNotification(bestCandidate.id, incidentId, 'ASSIGNED');
      
      // 다른 후보자들에게 대기 해제 알림
      candidatesSnapshot.forEach(doc => {
        if (doc.id !== bestCandidate.id) {
          sendAssignmentNotification(doc.id, incidentId, 'STANDBY');
        }
      });
    });
    
    console.log(`Auto-assigned incident ${incidentId} to ${bestCandidate.id}`);
    return { 
      success: true, 
      assignedTo: bestCandidate.id,
      etaSec: bestCandidate.etaSec 
    };
    
  } catch (error) {
    console.error('Error in autoAssign:', error);
    throw new functions.https.HttpsError('internal', 'Failed to auto-assign');
  }
});

// 3. 할당 취소 처리
export const onAssignmentCancel = functions.firestore
  .document('incidents/{incidentId}')
  .onUpdate(async (change, context) => {
    const { incidentId } = context.params;
    const before = change.before.data();
    const after = change.after.data();
    
    // 할당 취소 감지
    if (before.chosenResponderId && !after.chosenResponderId && 
        after.status === 'broadcasting') {
      
      console.log('Assignment cancelled, finding next candidate...');
      
      // 이전 할당자를 제외하고 다시 자동 할당
      await autoAssign({ incidentId }, {} as any);
    }
  });

// Distance Matrix API 호출
async function calculateDistanceMatrix(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number }
): Promise<DistanceMatrixResult> {
  
  const url = 'https://maps.googleapis.com/maps/api/distancematrix/json';
  
  try {
    const response = await axios.get(url, {
      params: {
        origins: `${origin.lat},${origin.lng}`,
        destinations: `${destination.lat},${destination.lng}`,
        mode: 'driving',
        language: 'ko',
        key: GOOGLE_MAPS_API_KEY,
      }
    });
    
    const element = response.data.rows[0]?.elements[0];
    
    if (element?.status === 'OK') {
      return {
        distanceKm: element.distance.value / 1000,
        etaSec: element.duration.value,
      };
    }
    
    // 폴백: 직선 거리 기반 추정
    console.warn('Distance Matrix API failed, using fallback');
    const directDistance = getDirectDistance(origin, destination);
    
    return {
      distanceKm: directDistance,
      etaSec: Math.round(directDistance * 60), // 평균 60초/km
    };
    
  } catch (error) {
    console.error('Distance Matrix API error:', error);
    throw error;
  }
}

// 직선 거리 계산 (폴백용)
function getDirectDistance(
  origin: { lat: number; lng: number },
  destination: { lat: number; lng: number }
): number {
  const R = 6371; // 지구 반경 (km)
  const dLat = toRad(destination.lat - origin.lat);
  const dLng = toRad(destination.lng - origin.lng);
  
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(toRad(origin.lat)) * Math.cos(toRad(destination.lat)) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

function toRad(deg: number): number {
  return deg * (Math.PI/180);
}

// 점수 계산 함수
function calculateScore(candidate: any): number {
  const w1 = 1.0;  // ETA 가중치
  const w2 = 0.0;  // 거리 가중치 (현재 미사용)
  const w3 = 1.0;  // 자격 페널티 가중치
  
  const etaScore = (candidate.etaSec || 999999) * w1;
  const distanceScore = (candidate.distanceKm || 999) * w2;
  
  // 자격증 페널티 (자격증 없으면 300초 추가)
  const qualificationPenalty = candidate.qualificationScore === 0 ? 300 : 0;
  
  return etaScore + distanceScore + (qualificationPenalty * w3);
}

// 푸시 알림 발송
async function sendAssignmentNotification(
  responderId: string,
  incidentId: string,
  type: 'ASSIGNED' | 'STANDBY'
) {
  // FCM 토큰 가져오기
  const userDoc = await db.doc(`users/${responderId}`).get();
  const fcmToken = userDoc.data()?.fcmToken;
  
  if (!fcmToken) {
    console.warn(`No FCM token for user ${responderId}`);
    return;
  }
  
  const message = {
    token: fcmToken,
    notification: {
      title: type === 'ASSIGNED' ? '🚨 출동 확정!' : '📢 대기 해제',
      body: type === 'ASSIGNED' 
        ? '귀하가 이 재난에 배정되었습니다. 즉시 출동하세요!'
        : '다른 대원이 배정되었습니다. 대기해주셔서 감사합니다.',
    },
    data: {
      type: type,
      incidentId: incidentId,
    },
    android: {
      priority: 'high' as const,
      notification: {
        sound: 'default',
        priority: 'high' as const,
        visibility: 'public' as const,
      },
    },
  };
  
  try {
    await admin.messaging().send(message);
    console.log(`Notification sent to ${responderId}: ${type}`);
  } catch (error) {
    console.error('Error sending notification:', error);
  }
}

// Cloud Tasks를 이용한 지연 실행
async function scheduleFunctionCall(
  functionName: string,
  payload: any,
  delayMs: number
) {
  // Cloud Scheduler 또는 setTimeout 사용
  // 실제 환경에서는 Cloud Tasks 권장
  setTimeout(async () => {
    if (functionName === 'autoAssign') {
      await autoAssign(payload, {} as any);
    }
  }, delayMs);
}
