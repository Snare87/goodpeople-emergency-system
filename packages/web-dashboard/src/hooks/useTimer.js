// src/hooks/useTimer.js
import { useState, useEffect } from 'react';

export const useTimer = (interval = 3000) => {
  const [currentTime, setCurrentTime] = useState(Date.now());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now());
    }, interval);

    return () => clearInterval(timer);
  }, [interval]);

  return currentTime;
};