// 기본 타입 정의
export interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'responder' | 'viewer';
}

export interface Emergency {
  id: string;
  type: 'fire' | 'medical' | 'accident' | 'other';
  location: {
    lat: number;
    lng: number;
    address: string;
  };
  status: 'pending' | 'responding' | 'resolved';
  createdAt: Date;
  description: string;
  reporterId?: string;
  responders?: string[];
}

export interface Responder {
  id: string;
  name: string;
  status: 'available' | 'busy' | 'offline';
  location?: {
    lat: number;
    lng: number;
  };
  specialization: string[];
  assignedEmergencies?: string[];
}

export interface Location {
  lat: number;
  lng: number;
  address?: string;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}
