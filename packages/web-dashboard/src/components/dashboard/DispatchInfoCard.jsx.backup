// src/components/dashboard/DispatchInfoCard.jsx
import React from 'react';
import { formatDate, formatTime, getElapsedTime } from '../../utils/formatters';

const DispatchInfoCard = ({ call, currentTime }) => {
  if (!call) return null;

  return (
    <div className="space-y-4">
      {/* 발생 정보 */}
      <div className="p-3 bg-gray-50 rounded-lg">
        <h4 className="font-medium mb-2">발생 정보</h4>
        <p>주소: {call.address}</p>
        <p>날짜: {formatDate(call.startAt)}</p>
        <p>시간: {formatTime(call.startAt)}</p>
        <p className="text-xs text-gray-500 mt-1">
          {getElapsedTime(call.startAt, currentTime)}
        </p>
      </div>

      {/* 수락 정보 */}
      {call.acceptedAt && (
        <div className="p-3 bg-blue-50 rounded-lg">
          <h4 className="font-medium mb-2">수락 정보</h4>
          <p>날짜: {formatDate(call.acceptedAt)}</p>
          <p>시간: {formatTime(call.acceptedAt)}</p>
        </div>
      )}

      {/* 완료 정보 */}
      {call.completedAt && (
        <div className="p-3 bg-green-50 rounded-lg">
          <h4 className="font-medium mb-2">완료 정보</h4>
          <p>날짜: {formatDate(call.completedAt)}</p>
          <p>시간: {formatTime(call.completedAt)}</p>
        </div>
      )}
    </div>
  );
};

export default DispatchInfoCard;