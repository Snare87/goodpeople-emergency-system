// src/pages/DashboardPage.jsx - 응답자 탭 제거
import React, { useState } from 'react';
import Header from '../components/Header';
import CallsList from '../components/CallsList';
import KakaoMap from '../components/KakaoMap';
import useCallsData from '../hooks/useCallsData';
import { dispatchCall, acceptCall, completeCall, reactivateCall, cancelCall } from '../services/callService';

export default function DashboardPage() {
  // 커스텀 훅을 사용하여 데이터 관리
  const { activeCalls, completedCalls, selectedCall, selectedCallId, selectCall } = useCallsData();
  // activeTab 상태 제거 (불필요)
  const [listTab, setListTab] = useState('active');

  // 지도 중심 좌표
  const center = selectedCall
    ? [selectedCall.lat, selectedCall.lng]
    : [37.5665, 126.9780];

  // 커스텀 지령서 레이아웃 - 3개 영역으로 분할
const renderCustomCallDetail = () => {
  if (!selectedCall) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="text-center p-8 bg-gray-50 rounded-lg shadow-sm border border-gray-200 max-w-md">
          <p className="text-gray-600 text-xl font-medium mb-2">재난 목록을 선택하세요</p>
          <p className="text-gray-500 text-sm">좌측의 재난 목록에서 항목을 선택하면 상세 정보가 표시됩니다.</p>
        </div>
      </div>
    );
  }

    // 현재 시간을 사용하여 경과 시간 계산
    const currentTime = Date.now();

    // 경과 시간 계산 함수
    const getElapsedTime = (timestamp) => {
      if (!timestamp) return '';
      
      const diff = Math.max(0, Math.floor((currentTime - timestamp) / 1000));
      
      if (diff < 60) return `${diff}초 전`;
      if (diff < 3600) return `${Math.floor(diff / 60)}분 전`;
      if (diff < 86400) return `${Math.floor(diff / 3600)}시간 ${Math.floor((diff % 3600) / 60)}분 전`;
      
      const date = new Date(timestamp);
      return date.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' });
    };

    // 대원 종류에 따른 스타일을 결정하는 함수
    const getResponderTypeBadgeStyle = (position) => {
      if (!position) return 'bg-gray-100 text-gray-800';
      
      // 종류에 따른 색상 설정
      if (position.includes('구조')) {
        return 'bg-blue-100 text-blue-800'; // 구조대원: 파란색
      } else if (position.includes('구급')) {
        return 'bg-emerald-100 text-emerald-800'; // 구급대원: 에메랄드색
      } else if (position.includes('화재') || position.includes('진압')) {
        return 'bg-red-100 text-red-800'; // 화재진압: 빨간색
      }
      
      // 기본값
      return 'bg-gray-100 text-gray-800';
    };

    return (
      <div className="grid grid-cols-12 gap-4 h-full">
        {/* 좌측: 기본 지령서 정보 (1/4) */}
        <div className="col-span-3 flex flex-col">
          <h3 className="text-lg font-semibold mb-2">
            {selectedCall.eventType} 상황
          </h3>                 
          {/* 발생 정보 */}
          <div className="mb-4 p-3 bg-gray-50 rounded-lg">
            <h4 className="font-medium mb-2">발생 정보</h4>
            <p>주소: {selectedCall.address}</p>
            <p>날짜: {new Date(selectedCall.startAt).toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
            <p>시간: {new Date(selectedCall.startAt).toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit', hour12: false })}</p>
            <p className="text-xs text-gray-500 mt-1">
              {getElapsedTime(selectedCall.startAt)}
            </p>
          </div>
          
          {/* 상태에 따른 버튼 */}
          <div className="mt-auto flex justify-center gap-2">
            {selectedCall.status === 'completed' ? (
              <button 
                className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
                onClick={() => reactivateCall(selectedCall.id)}
              >
                재호출하기
              </button>
            ) : (
              <>
                {selectedCall.status === 'idle' && (
                  <button 
                    className="px-4 py-2 bg-primary text-white rounded hover:bg-blue-600"
                    onClick={() => dispatchCall(selectedCall.id)}
                  >
                    호출하기
                  </button>
                )}
                
                {selectedCall.status === 'dispatched' && !selectedCall.responder && (
                  <button 
                    className="px-4 py-2 bg-yellow-500 text-white rounded"
                    disabled={true}
                  >
                    찾는중
                  </button>
                )}
                
                {selectedCall.responder && (
                  <button 
                    className="px-4 py-2 bg-green-500 text-white rounded"
                    disabled={true}
                  >
                    매칭완료
                  </button>
                )}
                
                <button 
                  className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
                  onClick={() => completeCall(selectedCall.id)}
                >
                  재난종료
                </button>

                {/* 찾는중 상태일 때만 호출취소 버튼 표시 */}
                  {selectedCall.status === 'dispatched' && !selectedCall.responder && (
                    <button 
                      className="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600"
                      onClick={() => cancelCall(selectedCall.id)}
                    >
                      호출취소
                    </button>
                  )}

              </>
            )}
          </div>
        </div>
        
        {/* 중앙: 응답자 정보 (1/4) - 이 부분은 유지하고 응답자 정보를 표시 */}
        <div className="col-span-3 bg-gray-100 rounded-lg p-4 flex flex-col">
          <h3 className="text-lg font-semibold mb-3">응답자</h3>
          
          {/* 응답자 정보 컨테이너 */}
          <div className="flex-1 flex items-center justify-center">
            {selectedCall.responder ? (
              <div className="bg-white p-3 rounded-lg shadow-sm w-full">
                {/* 응답자 정보 가로 배치 */}
                <div className="flex flex-row items-center justify-between">
                  <div className="flex items-center space-x-2">
                    {/* 대원 종류에 따른 스타일 적용 */}
                    <span className={`px-2 py-1 rounded-md text-sm ${getResponderTypeBadgeStyle(selectedCall.responder.position)}`}>
                      {selectedCall.responder.position || '대원'}
                    </span>
                    <span className="font-medium">
                      {selectedCall.responder.name}
                    </span>
                  </div>
                  <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-md text-sm">
                    진행중
                  </span>
                </div>
              </div>
            ) : (
              <div className="bg-white p-3 rounded-lg shadow-sm w-full flex items-center justify-center h-16">
                <p className="text-gray-500">매칭된 응답자가 없습니다</p>
              </div>
            )}
          </div>
        </div>
        
        {/* 우측: 내용 영역 (2/4 = 1/2) */}
        <div className="col-span-6 bg-gray-200 rounded-lg flex items-center justify-center p-4">
          <div className="text-center">
            <h3 className="text-lg font-semibold mb-2 text-gray-800">상황 정보</h3>
            <p className="text-gray-600 font-medium">
              {selectedCall.info || '상세 정보가 없습니다'}
            </p>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <Header title="대시보드" />

      <main className="p-6 space-y-6">
        {/* 그리드 레이아웃 */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* 왼쪽: 재난 목록 */}
          <aside className="md:col-span-1 bg-white rounded-lg shadow flex flex-col">
            {/* 목록 탭 */}
            <div className="flex border-b">
              <button
                onClick={() => setListTab('active')}
                className={`flex-1 py-3 text-center font-medium ${
                  listTab === 'active'
                    ? 'border-b-2 border-primary text-primary'
                    : 'text-gray-600'
                }`}
              >
                재난 목록
              </button>
              <button
                onClick={() => setListTab('completed')}
                className={`flex-1 py-3 text-center font-medium ${
                  listTab === 'completed'
                    ? 'border-b-2 border-primary text-primary'
                    : 'text-gray-600'
                }`}
              >
                완료 목록
              </button>
            </div>
            
            {/* 목록 내용 - 스크롤 개선 */}
            <div className="p-4 overflow-y-auto h-[calc(100vh-200px)]" style={{ minHeight: "200px" }}>
              {listTab === 'active' ? (
                // 활성 재난 목록
                 <CallsList
                  calls={activeCalls}
                  onSelect={selectCall}
                  selectedId={selectedCallId}
                  onDispatch={dispatchCall}
                  onCancel={cancelCall}
                />
              ) : (
                // 완료된 재난 목록
                <CallsList
                  calls={completedCalls}
                  onSelect={selectCall}
                  selectedId={selectedCallId}
                  showCompletedInfo={true}
                  onReactivate={reactivateCall}
                />
              )}
            </div>
          </aside>

          {/* 오른쪽: 탭 패널과 지도 */}
          <div className="md:col-span-2 grid grid-rows-2 gap-6" style={{ height: 'calc(100vh - 150px)' }}>
            {/* 지령서 패널 - 응답자 탭 제거 */}
            <section className="bg-white rounded-lg shadow flex flex-col">           
              {/* 콘텐츠 부분 - 항상 renderCustomCallDetail 표시 */}
              <div className="p-4 flex-1 overflow-auto">
                {renderCustomCallDetail()}
              </div>
            </section>

            {/* 지도 */}
            <section className="bg-white rounded-lg shadow overflow-hidden flex flex-col">
              <div className="p-2 border-b">
                <h2 className="text-lg font-semibold">지도</h2>
              </div>
              <div className="flex-1">
                <KakaoMap calls={activeCalls} center={center} />
              </div>
            </section>
          </div>
        </div>
      </main>
    </div>
  );
}