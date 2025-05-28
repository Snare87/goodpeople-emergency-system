// src/components/MapView.tsx
import React, { useEffect } from 'react';
import L from 'leaflet';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';
import { Call } from '../services/callService';

// 마커 아이콘 경로 설정
import markerIcon2x from 'leaflet/dist/images/marker-icon-2x.png';
import markerIcon from 'leaflet/dist/images/marker-icon.png';
import markerShadow from 'leaflet/dist/images/marker-shadow.png';

delete (L.Icon.Default.prototype as any)._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: markerIcon2x,
  iconUrl: markerIcon,
  shadowUrl: markerShadow,
});

interface MapEffectProps {
  centerOn: { lat: number; lng: number } | null;
}

function MapEffect({ centerOn }: MapEffectProps) {
  const map = useMap();
  useEffect(() => {
    if (centerOn) {
      map.flyTo([centerOn.lat, centerOn.lng], 15, { duration: 1.0 });
    }
  }, [centerOn, map]);
  return null;
}

interface MapViewProps {
  calls: Call[];
  centerOn: { lat: number; lng: number } | null;
}

export default function MapView({ calls, centerOn }: MapViewProps) {
  const defaultCenter: [number, number] = [37.5665, 126.9780];

  return (
    <MapContainer
      center={defaultCenter}
      zoom={13}
      scrollWheelZoom={false}
      className="w-full h-80 rounded-lg shadow"
    >
      <TileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution="© OpenStreetMap contributors"
      />

      <MapEffect centerOn={centerOn} />

      {calls.map(call => (
        call.location ? (
          <Marker key={call.id} position={[call.location.lat, call.location.lng]}>
            <Popup>
              {call.eventType} – {call.address}
            </Popup>
          </Marker>
        ) : null
      ))}
    </MapContainer>
  );
}