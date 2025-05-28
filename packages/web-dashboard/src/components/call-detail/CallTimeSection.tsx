import React from 'react';
import { formatDate, formatTime, getDetailedElapsedTime } from '../../utils/formatters';

interface CallTimeSectionProps {
  title: string;
  date: string | number;
  startDate: string | number;
  backgroundColor: string;
}

const CallTimeSection: React.FC<CallTimeSectionProps> = ({ 
  title, 
  date, 
  startDate, 
  backgroundColor 
}) => {
  return (
    <div className={`mb-4 p-3 ${backgroundColor} rounded-lg`}>
      <h4 className="font-medium mb-2">{title}</h4>
      <p>날짜: {formatDate(date)}</p>
      <p>시간: {formatTime(date)}</p>
      <p className="mt-1">
        {title === '완료 정보' ? '총 소요 시간' : '경과 시간'}: 
        {getDetailedElapsedTime(startDate, date)}
      </p>
    </div>
  );
};

export default CallTimeSection;