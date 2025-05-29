// src/components/MapLegend.tsx
import React from 'react';

interface MapLegendProps {
  style?: React.CSSProperties;
}

export default function MapLegend({ style }: MapLegendProps) {
  const legendItems = [
    { color: '#F44336', label: '대기/요청', icon: '⚠️' },
    { color: '#FF9800', label: '선택됨', icon: '🔍' },
    { color: '#4CAF50', label: '출동중', icon: '🚑' },
    { color: '#4CAF50', label: '출동중(선택)', icon: '🚑', strokeColor: '#FF9800', strokeWidth: 4 },
    { color: '#9E9E9E', label: '완료', icon: '✅' },
    { color: '#2196F3', label: '대원 위치', icon: '🚑', isResponder: true }
  ];

  return (
    <div 
      style={{
        position: 'absolute',
        bottom: 20,
        right: 20,
        backgroundColor: 'white',
        padding: 15,
        borderRadius: 8,
        boxShadow: '0 2px 6px rgba(0,0,0,0.3)',
        zIndex: 1000,
        ...style
      }}
    >
      <h4 style={{ margin: '0 0 10px 0', fontSize: 14, fontWeight: 600 }}>범례</h4>
      {legendItems.map((item, index) => (
        <div 
          key={index} 
          style={{ 
            display: 'flex', 
            alignItems: 'center', 
            marginBottom: index < legendItems.length - 1 ? 8 : 0 
          }}
        >
          {item.isResponder ? (
            <div
              style={{
                width: 20,
                height: 20,
                borderRadius: '50%',
                backgroundColor: item.color,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 10,
                marginRight: 8
              }}
            >
              {item.icon}
            </div>
          ) : (
            <svg width="20" height="20" style={{ marginRight: 8 }}>
              <circle
                cx="10"
                cy="10"
                r="8"
                fill={item.color}
                stroke={item.strokeColor || 'white'}
                strokeWidth={item.strokeWidth || 2}
              />
            </svg>
          )}
          <span style={{ fontSize: 13 }}>{item.label}</span>
        </div>
      ))}
    </div>
  );
}