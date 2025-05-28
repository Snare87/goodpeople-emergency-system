import React from 'react';
import { formatDate, formatTime, getElapsedTime } from '../../utils/formatters';

interface CallInfoSectionProps {
  title: string;
  date: string | number;
  backgroundColor: string;
  showElapsedTime?: boolean;
  currentTime?: number;
}

const CallInfoSection: React.FC<CallInfoSectionProps> = ({ 
  title, 
  date, 
  backgroundColor, 
  showElapsedTime = false, 
  currentTime 
}) => {
  return (
    <div className={`mb-4 p-3 ${backgroundColor} rounded-lg`} style={{ maxWidth: '200px' }}>
      <h4 className="font-medium mb-2">{title}</h4>
      <p>날짜: {formatDate(date)}</p>
      <p>시간: {formatTime(date)}</p>
      {showElapsedTime && currentTime && (
        <p className="text-xs text-gray-500 mt-1">
          {getElapsedTime(date, currentTime)}
        </p>
      )}
    </div>
  );
};

export default CallInfoSection;