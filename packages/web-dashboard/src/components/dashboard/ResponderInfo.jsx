// src/components/dashboard/ResponderInfo.jsx
import React from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants/badgeVariants';
import { RANK_COLORS } from '../../constants/badgeVariants';

const ResponderInfo = ({ responder }) => {
  if (!responder) {
    return (
      <div className="bg-white p-2 rounded-lg shadow-sm w-full flex items-center justify-center h-14">
        <p className="text-sm text-gray-500">매칭된 응답자가 없습니다</p>
      </div>
    );
  }

  const badgeVariant = POSITION_BADGE_VARIANTS[responder.position] || 'default';
  
  // 계급 색상 가져오기
  const getRankBadge = (rank) => {
    const colorClass = RANK_COLORS[rank] || 'bg-gray-100 text-gray-800';
    return <span className={`px-2 py-0.5 ${colorClass} rounded-md text-xs font-medium`}>{rank}</span>;
  };

  return (
    <div className="bg-white p-2 rounded-lg shadow-sm w-full">
      <div className="flex flex-col space-y-2">
        <div className="flex items-center justify-between">
          <Badge variant={badgeVariant} size="sm">
            {responder.position || '대원'}
          </Badge>
          <Badge variant="warning" size="sm">진행중</Badge>
        </div>
        <div className="flex items-center space-x-2">
          {responder.rank && getRankBadge(responder.rank)}
          <span className="text-sm font-medium">{responder.name}</span>
        </div>
      </div>
    </div>
  );
};
export default ResponderInfo;