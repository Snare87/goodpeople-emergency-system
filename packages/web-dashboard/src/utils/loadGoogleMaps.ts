// src/utils/loadGoogleMaps.ts

export function loadGoogleMaps(): Promise<void> {
  return new Promise((resolve, reject) => {
    // 이미 로드되었거나 로딩 중이면 스킵
    if (window.google?.maps) {
      resolve();
      return;
    }
    
    // 이미 스크립트가 로딩 중인지 확인
    const existingScript = document.querySelector('script[src*="maps.googleapis.com"]');
    if (existingScript) {
      // 로딩이 완료될 때까지 대기
      window.addEventListener('googleMapsLoaded', () => resolve(), { once: true });
      return;
    }

    const script = document.createElement('script');
    const apiKey = process.env.REACT_APP_GOOGLE_MAPS_API_KEY;
    
    if (!apiKey) {
      reject(new Error('Google Maps API key is not configured'));
      return;
    }
    
    console.log('[GoogleMaps] Loading with API key:', apiKey.substring(0, 10) + '...');
    
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}&callback=initMap&language=ko`;
    script.async = true;
    script.defer = true;
    
    // 전역 콜백 함수 정의
    window.initMap = () => {
      window.googleMapsLoaded = true;
      window.dispatchEvent(new Event('googleMapsLoaded'));
      resolve();
    };
    
    script.onerror = () => {
      reject(new Error('Failed to load Google Maps'));
    };
    
    document.head.appendChild(script);
  });
}
