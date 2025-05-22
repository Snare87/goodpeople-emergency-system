// src/components/MapView.jsx
import React, { useEffect } from 'react';
import L from 'leaflet';
import { MapContainer, TileLayer, Marker, Popup, useMap } from 'react-leaflet';

// 마커 아이콘 경로 설정
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: require('leaflet/dist/images/marker-icon-2x.png'),
  iconUrl:        require('leaflet/dist/images/marker-icon.png'),
  shadowUrl:      require('leaflet/dist/images/marker-shadow.png'),
});

function MapEffect({ centerOn }) {
  const map = useMap();
  useEffect(() => {
    if (centerOn) {
      map.flyTo([centerOn.lat, centerOn.lng], 15, { duration: 1.0 });
    }
  }, [centerOn, map]);
  return null;
}

export default function MapView({ calls, centerOn }) {
  const defaultCenter = [37.5665, 126.9780];

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
        <Marker key={call.id} position={[call.lat, call.lng]}>
          <Popup>
            {call.customerName} – {call.address}
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}
