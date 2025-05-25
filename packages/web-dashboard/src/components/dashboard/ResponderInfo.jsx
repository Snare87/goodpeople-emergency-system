// src/components/dashboard/ResponderInfo.jsx
import React, { useState, useEffect } from 'react';
import Badge from '../common/Badge';
import { POSITION_BADGE_VARIANTS } from '../../constants/badgeVariants';
import { ref, get } from 'firebase/database';
import { db } from '../../firebase';

const ResponderInfo = ({ responder }) => {
  const [certifications, setCertifications] = useState([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (responder?.id) {
      loadCertifications();
    }
  }, [responder?.id]);

  const loadCertifications = async () => {
    try {
      setLoading(true);
      // responder.id는 "resp_userId_timestamp" 형식이므로 userId 추출
      const userId = responder.id.split('_')[1];
      
      const userSnapshot = await get(ref(db, `users/${userId}`));
      if (userSnapshot.exists()) {
        const userData = userSnapshot.val();
        setCertifications(userData.certifications || []);
      }
    } catch (error) {
      console.error('자격증 정보 로드 실패:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!responder) {
    return (
      <div className="bg-white p-6 rounded-lg shadow-sm w-full flex flex-col items-center justify-center h-full">
        <p className="text-base text-gray-500">매칭된 응답자가 없습니다</p>
      </div>
    );
  }

  const badgeVariant = POSITION_BADGE_VARIANTS[responder.position] || 'default';

  return (
    <div className="bg-white p-6 rounded-lg shadow-sm w-full h-full flex flex-col">
      {/* 상단: 대원 정보 (확대) */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-3">
          <Badge variant={badgeVariant} size="md">
            {responder.position || '대원'}
          </Badge>
          <span className="text-lg font-medium">
            {responder.rank || '소방사'}
          </span>
          <span className="text-lg font-medium">
            {responder.name}
          </span>
        </div>
        <Badge variant="warning" size="md">진행중</Badge>
      </div>
      
      {/* 자격증 정보 (확대 및 세로 배치) */}
      <div className="flex-1">
        <h4 className="text-sm font-semibold text-gray-700 mb-3">보유 자격증</h4>
        {loading ? (
          <div className="text-sm text-gray-400">로딩중...</div>
        ) : certifications.length > 0 ? (
          <div className="space-y-2">
            {certifications.map((cert, index) => (
              <div 
                key={index} 
                className="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg text-sm font-medium"
              >
                {cert}
              </div>
            ))}
          </div>
        ) : (
          <div className="text-sm text-gray-400">자격증 정보 없음</div>
        )}
      </div>
    </div>
  );
};

export default ResponderInfo;