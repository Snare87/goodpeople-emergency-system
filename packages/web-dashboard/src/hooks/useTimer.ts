// src/hooks/useTimer.ts
import { useState, useEffect } from 'react';

export const useTimer = (interval: number = 3000): number => {
  const [currentTime, setCurrentTime] = useState<number>(Date.now());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(Date.now());
    }, interval);

    return () => clearInterval(timer);
  }, [interval]);

  return currentTime;
};