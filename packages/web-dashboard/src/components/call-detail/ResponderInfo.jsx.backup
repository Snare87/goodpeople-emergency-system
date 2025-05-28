import React from 'react';

const ResponderInfo = ({ responder }) => {
  if (!responder) return null;

  return (
    <div className="mt-4 p-3 bg-yellow-50 rounded-lg">
      <h4 className="font-medium mb-2">응답자 정보</h4>
      <p>이름: {responder.name}</p>
      {responder.position && (
        <p>직책: {responder.position}</p>
      )}
    </div>
  );
};

export default ResponderInfo;
