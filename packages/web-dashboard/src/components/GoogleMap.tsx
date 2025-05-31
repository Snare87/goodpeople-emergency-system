// src/components/GoogleMap.tsx
import React, { useEffect, useRef, useState, useCallback } from 'react';
import { Call } from '../services/callService';
import { db } from '../firebase';
import { ref, onValue, off } from 'firebase/database';
import MapLegend from './MapLegend';

// Google Maps 타입 정의 확장
declare global {
  interface Window {
    google?: {
      maps: {
        Map: any;
        LatLng: any;
        Marker: any;
        InfoWindow: any;
        Polyline: any;
        LatLngBounds: any;
        Size: any;
        Point: any;
        SymbolPath: {
          CIRCLE: any;
          FORWARD_CLOSED_ARROW: any;
        };
        event: {
          addListener: (instance: any, event: string, handler: () => void) => void;
          trigger: (instance: any, event: string) => void;
        };
      };
    };
    googleMapsLoaded?: boolean;
    initMap?: () => void;
  }
}

interface Responder {
  id: string;
  name: string;
  position: string;
  rank: string;
  lat: number;
  lng: number;
  updatedAt: number;
}

interface ResponderWithMission extends Responder {
  callId: string;
  eventType: string;
  destination: {
    lat: number;
    lng: number;
  };
}

interface GoogleMapProps {
  calls: Call[];
  center: [number, number];
  selectedCallId?: string;
}

export default function GoogleMap({ calls, center, selectedCallId }: GoogleMapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const googleMapRef = useRef<any>(null);
  const markersRef = useRef<Map<string, any>>(new Map());
  const responderMarkersRef = useRef<Map<string, any>>(new Map());
  const polylinesRef = useRef<Map<string, any>>(new Map());
  const [responders, setResponders] = useState<Map<string, ResponderWithMission>>(new Map());
  const [mapsLoaded, setMapsLoaded] = useState(false);

  // 디버깅 로그
  console.log('[GoogleMap] Render - calls:', calls.length, 'selectedCallId:', selectedCallId, 'mapsLoaded:', mapsLoaded);

  // Google Maps API 로드 대기
  useEffect(() => {
    const checkGoogleMaps = () => {
      if (window.google && window.google.maps) {
        setMapsLoaded(true);
      }
    };

    // 이미 로드되었는지 확인
    checkGoogleMaps();

    // 이벤트 리스너 추가
    window.addEventListener('googleMapsLoaded', checkGoogleMaps);

    return () => {
      window.removeEventListener('googleMapsLoaded', checkGoogleMaps);
    };
  }, []);

  // 대원 실시간 위치 추적
  useEffect(() => {
    const acceptedCalls = calls.filter(call => call.status === 'accepted' && call.selectedResponder);
    console.log('[GoogleMap] Accepted calls with responders:', acceptedCalls.length);
    const responderListeners: { [key: string]: () => void } = {};

    // 현재 responders에서 더 이상 accepted 상태가 아닌 호출 제거
    setResponders(prev => {
      const newMap = new Map(prev);
      // 완료되었거나 취소된 호출의 대원 마커 제거
      Array.from(newMap.keys()).forEach(callId => {
        const call = calls.find(c => c.id === callId);
        if (!call || call.status !== 'accepted') {
          console.log('[GoogleMap] Removing responder for call:', callId, 'status:', call?.status);
          newMap.delete(callId);
        }
      });
      return newMap;
    });

    acceptedCalls.forEach(call => {
      if (call.selectedResponder?.id && call.location) {
        const responderRef = ref(db, `calls/${call.id}/selectedResponder`);
        
        const unsubscribe = onValue(responderRef, (snapshot) => {
          if (snapshot.exists()) {
            const responderData = snapshot.val();
            setResponders(prev => {
              const newMap = new Map(prev);
              newMap.set(call.id, {
                ...responderData,
                callId: call.id,
                eventType: call.eventType,
                destination: { lat: call.location!.lat, lng: call.location!.lng }
              });
              return newMap;
            });
          }
        });

        responderListeners[call.id] = () => off(responderRef, 'value', unsubscribe as any);
      }
    });

    return () => {
      Object.values(responderListeners).forEach(unsubscribe => unsubscribe());
    };
  }, [calls]);

  // 대원 마커 및 경로 업데이트
  useEffect(() => {
    if (!googleMapRef.current || !window.google || !mapsLoaded) return;

    const { maps } = window.google;

    // 기존 대원 마커 제거
    responderMarkersRef.current.forEach(marker => marker.setMap(null));
    responderMarkersRef.current.clear();

    // 기존 경로 제거
    polylinesRef.current.forEach(polyline => polyline.setMap(null));
    polylinesRef.current.clear();

    // 대원별 마커 및 경로 생성
    responders.forEach((responder, callId) => {
      // 해당 호출이 여전히 accepted 상태인지 확인
      const call = calls.find(c => c.id === callId);
      if (!call || call.status !== 'accepted') {
        console.log('[GoogleMap] Skipping responder marker for non-accepted call:', callId);
        return;
      }
      // 대원 위치 마커
      const responderMarker = new maps.Marker({
        position: new maps.LatLng(responder.lat, responder.lng),
        map: googleMapRef.current,
        title: `${responder.name} (${responder.position})`,
        icon: {
          url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(`
            <svg width="40" height="40" viewBox="0 0 40 40" xmlns="http://www.w3.org/2000/svg">
              <circle cx="20" cy="20" r="18" fill="#2196F3" stroke="white" stroke-width="2"/>
              <text x="20" y="26" font-family="Arial" font-size="20" fill="white" text-anchor="middle">🚑</text>
            </svg>
          `),
          scaledSize: new maps.Size(40, 40),
          anchor: new maps.Point(20, 20),
        },
        zIndex: 1000,
      });

      // 대원 정보창
      const infoWindow = new maps.InfoWindow({
        content: `
          <div style="padding: 10px; min-width: 200px;">
            <h4 style="margin: 0 0 8px 0;">${responder.name}</h4>
            <p style="margin: 4px 0;"><strong>직책:</strong> ${responder.position}</p>
            <p style="margin: 4px 0;"><strong>계급:</strong> ${responder.rank}</p>
            <p style="margin: 4px 0;"><strong>임무:</strong> ${responder.eventType}</p>
            <p style="margin: 4px 0; font-size: 12px; color: #666;">
              마지막 업데이트: ${new Date(responder.updatedAt).toLocaleTimeString()}
            </p>
          </div>
        `,
      });

      maps.event.addListener(responderMarker, 'click', () => {
        infoWindow.open(googleMapRef.current, responderMarker);
      });

      responderMarkersRef.current.set(callId, responderMarker);

      // 대원 위치에서 목적지까지 경로 표시
      if (responder.destination) {
        const path = [
          new maps.LatLng(responder.lat, responder.lng),
          new maps.LatLng(responder.destination.lat, responder.destination.lng),
        ];

        const polyline = new maps.Polyline({
          path: path,
          geodesic: true,
          strokeColor: '#2196F3',
          strokeOpacity: 0.8,
          strokeWeight: 3,
          map: googleMapRef.current,
          icons: [{
            icon: {
              path: maps.SymbolPath.FORWARD_CLOSED_ARROW,
              scale: 3,
            },
            offset: '100%',
          }],
        });

        polylinesRef.current.set(callId, polyline);
      }
    });
  }, [responders, mapsLoaded]);

  // 맵 초기화 및 재난 마커 표시
  useEffect(() => {
    if (!window.google || !mapRef.current || !mapsLoaded) return;

    const { maps } = window.google;
    const container = mapRef.current;

    // 맵 생성
    if (!googleMapRef.current) {
      googleMapRef.current = new maps.Map(container, {
        center: new maps.LatLng(center[0], center[1]),
        zoom: 11,
        mapTypeControl: true,
        streetViewControl: false,
        fullscreenControl: true,
      });
    }

    // 기존 재난 마커 제거
    markersRef.current.forEach(marker => marker.setMap(null));
    markersRef.current.clear();

    // 재난별 마커 추가
    calls.forEach(call => {
      if (!call.location) return;

      const isSelected = call.id === selectedCallId;
      const isAccepted = call.status === 'accepted';
      const isCompleted = call.status === 'completed';
      
      // 마커 색상 결정 (우선순위: 완료 > 수락 > 선택 > 기본)
      let markerColor = '#F44336'; // 기본: 빨간색 (idle, dispatched)
      let strokeColor = 'white';
      let strokeWeight = 2;
      
      if (isCompleted) {
        markerColor = '#9E9E9E'; // 완료: 회색
      } else if (isAccepted) {
        markerColor = '#4CAF50'; // 수락됨: 초록색
        if (isSelected) {
          strokeColor = '#FF9800'; // 선택된 수락: 주황색 테두리
          strokeWeight = 4;
        }
      } else if (isSelected) {
        markerColor = '#FF9800'; // 선택됨: 주황색
      }

      const marker = new maps.Marker({
        position: new maps.LatLng(call.location.lat, call.location.lng),
        map: googleMapRef.current,
        title: call.eventType,
        icon: {
          path: maps.SymbolPath.CIRCLE,
          scale: isSelected ? 12 : 10,
          fillColor: markerColor,
          fillOpacity: 0.9,
          strokeColor: strokeColor,
          strokeWeight: strokeWeight,
          anchor: new maps.Point(0, 0),
        },
        zIndex: isSelected ? 999 : (isAccepted ? 500 : 100),
      });

      // 정보창 내용
      let content = `
        <div style="padding: 10px; min-width: 250px;">
          <h3 style="margin: 0 0 10px 0; color: ${markerColor};">
            🚨 ${call.eventType}
          </h3>
          <p style="margin: 5px 0;"><strong>주소:</strong> ${call.address}</p>
          <p style="margin: 5px 0;"><strong>상태:</strong> 
            <span style="color: ${markerColor}; font-weight: bold;">
              ${
                call.status === 'idle' ? '⚠️ 대기중' :
                call.status === 'dispatched' ? '📢 출동요청' :
                call.status === 'accepted' ? '🚑 출동중' :
                call.status === 'completed' ? '✅ 완료' : call.status
              }
            </span>
          </p>
      `;

      if (call.info) {
        content += `<p style="margin: 5px 0;"><strong>상황:</strong> ${call.info}</p>`;
      }

      if (call.selectedResponder) {
        content += `
          <hr style="margin: 10px 0;">
          <p style="margin: 5px 0;"><strong>담당 대원:</strong> ${call.selectedResponder.name}</p>
          <p style="margin: 5px 0;"><strong>직책:</strong> ${call.selectedResponder.position}</p>
        `;
      }

      content += '</div>';

      const infoWindow = new maps.InfoWindow({ content });

      maps.event.addListener(marker, 'click', () => {
        infoWindow.open(googleMapRef.current, marker);
      });

      markersRef.current.set(call.id, marker);
    });

    // 선택된 재난이 있으면 중심 이동
    if (selectedCallId) {
      const selectedCall = calls.find(c => c.id === selectedCallId);
      console.log('[GoogleMap] Selected call found:', selectedCall);
      if (selectedCall?.location) {
        const newCenter = new maps.LatLng(selectedCall.location.lat, selectedCall.location.lng);
        googleMapRef.current.setCenter(newCenter);
        googleMapRef.current.setZoom(14);
        console.log('[GoogleMap] Moved to:', selectedCall.location.lat, selectedCall.location.lng);
        
        // 선택된 마커의 정보창 열기
        const selectedMarker = markersRef.current.get(selectedCallId);
        if (selectedMarker) {
          maps.event.trigger(selectedMarker, 'click');
        }
      }
    } else {
      // 모든 마커를 포함하는 bounds 계산
      if (calls.length > 0) {
        const bounds = new maps.LatLngBounds();
        calls.forEach(call => {
          if (call.location) {
            bounds.extend(new maps.LatLng(call.location.lat, call.location.lng));
          }
        });
        
        // 대원 위치도 bounds에 포함
        responders.forEach(responder => {
          bounds.extend(new maps.LatLng(responder.lat, responder.lng));
        });

        googleMapRef.current.fitBounds(bounds, 50); // 50px padding
      } else {
        googleMapRef.current.setCenter(new maps.LatLng(center[0], center[1]));
        googleMapRef.current.setZoom(11);
      }
    }
  }, [calls, center, selectedCallId, responders, mapsLoaded]);

  if (!mapsLoaded) {
    return (
      <div style={{
        position: 'absolute',
        top: 0,
        left: 0,
        width: '100%',
        height: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#f0f0f0'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ marginBottom: '10px' }}>지도를 불러오는 중...</div>
          <div style={{ fontSize: '12px', color: '#666' }}>Google Maps를 로드하고 있습니다.</div>
        </div>
      </div>
    );
  }

  return (
    <>
      <div
        ref={mapRef}
        style={{ 
          position: 'absolute',
          top: 0,
          left: 0,
          width: '100%', 
          height: '100%'
        }}
      />
      <MapLegend />
    </>
  );
}
