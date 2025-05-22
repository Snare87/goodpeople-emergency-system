// src/components/KakaoMap.jsx
import React, { useEffect, useRef } from 'react';

export default function KakaoMap({ calls, center }) {
  const mapRef = useRef(null);

  useEffect(() => {
    if (!window.kakao || !mapRef.current) return;
    const { maps } = window.kakao;
    const container = mapRef.current;

    // 이전에 렌더링된 맵(DOM)을 지웁니다.
    container.innerHTML = '';

    // 맵을 새로 생성
    const map = new maps.Map(container, {
      center: new maps.LatLng(center[0], center[1]),
      level: 3,
    });

    // 콜마다 마커 추가
    calls.forEach(call => {
      const marker = new maps.Marker({
        map,
        position: new maps.LatLng(call.lat, call.lng),
      });
      const info = new maps.InfoWindow({
        content: `<div style="padding:8px;">${call.customerName}<br/>${call.address}</div>`
      });
      maps.event.addListener(marker, 'click', () => {
        info.open(map, marker);
      });
    });

    // 선택된 위치가 바뀌면 지도를 이동
    map.setCenter(new maps.LatLng(center[0], center[1]));
  }, [calls, center]);

  return (
    <div
      ref={mapRef}
      style={{ width: '100%', height: '320px', borderRadius: '0.5rem' }}
    />
  );
}
