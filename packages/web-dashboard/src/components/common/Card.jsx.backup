// src/components/common/Card.jsx
import React from 'react';

const Card = ({ title, children, className = '', headerAction }) => {
  return (
    <div className={`bg-white rounded-lg shadow ${className}`}>
      {title && (
        <div className="flex items-center justify-between p-4 border-b">
          <h3 className="text-lg font-semibold">{title}</h3>
          {headerAction}
        </div>
      )}
      <div className="p-4">
        {children}
      </div>
    </div>
  );
};

export default Card;