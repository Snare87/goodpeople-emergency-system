// src/components/dashboard/SituationInfo.jsx
import React from 'react';

const SituationInfo = ({ info }) => {
  return (
    <div className="bg-white border border-gray-200 rounded-lg p-6 h-full">
      <h3 className="text-lg font-semibold mb-3 text-gray-900">상황 정보</h3>
      {info ? (
        <div className="text-gray-700 leading-relaxed">
          <p className="whitespace-pre-wrap">{info}</p>
        </div>
      ) : (
        <div className="flex items-center justify-center h-[calc(100%-2rem)] text-gray-400">
          <p>추가 상황 정보가 없습니다</p>
        </div>
      )}
    </div>
  );
};

export default SituationInfo;