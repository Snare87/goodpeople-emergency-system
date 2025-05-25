// src/components/dashboard/ResponderInfo.jsx
import React from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants/badgeVariants';

const ResponderInfo = ({ responder }) => {
  if (!responder) {
    return (
      <div className="bg-white p-3 rounded-lg shadow-sm w-full flex items-center justify-center h-16">
        <p className="text-gray-500">매칭된 응답자가 없습니다</p>
      </div>
    );
  }

  const badgeVariant = POSITION_BADGE_VARIANTS[responder.position] || 'default';

  return (
    <div className="bg-white p-3 rounded-lg shadow-sm w-full">
      <div className="flex flex-row items-center justify-between">
        <div className="flex items-center space-x-2">
          <Badge variant={badgeVariant}>
            {responder.position || '대원'}
          </Badge>
          <span className="font-medium">{responder.name}</span>
        </div>
        <Badge variant="warning">진행중</Badge>
      </div>
    </div>
  );
};

export default ResponderInfo;