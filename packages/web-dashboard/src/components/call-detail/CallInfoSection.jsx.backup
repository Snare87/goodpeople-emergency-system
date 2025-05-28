import React from 'react';
import { formatDate, formatTime, getElapsedTime } from '../../utils/formatters';

const CallInfoSection = ({ title, date, backgroundColor, showElapsedTime = false, currentTime }) => {
  return (
    <div className={`mb-4 p-3 ${backgroundColor} rounded-lg`} style={{ maxWidth: '200px' }}>
      <h4 className="font-medium mb-2">{title}</h4>
      <p>날짜: {formatDate(date)}</p>
      <p>시간: {formatTime(date)}</p>
      {showElapsedTime && (
        <p className="text-xs text-gray-500 mt-1">
          {getElapsedTime(date, currentTime)}
        </p>
      )}
    </div>
  );
};

export default CallInfoSection;
