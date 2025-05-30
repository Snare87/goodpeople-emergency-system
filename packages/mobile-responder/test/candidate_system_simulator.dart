// test/candidate_system_simulator.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'mock_data_generator.dart';

class CandidateSystemSimulator extends StatefulWidget {
  @override
  _CandidateSystemSimulatorState createState() => _CandidateSystemSimulatorState();
}

class _CandidateSystemSimulatorState extends State<CandidateSystemSimulator> {
  // 시뮬레이션 상태
  TestScenario? currentScenario;
  Map<String, DateTime?> acceptTimes = {};
  String? selectedResponderId;
  bool useNewSystem = true;
  
  // 통계
  int totalSimulations = 0;
  int newSystemWins = 0;
  double avgTimeSavedSeconds = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('후보자 시스템 시뮬레이터'),
        actions: [
          Switch(
            value: useNewSystem,
            onChanged: (value) => setState(() => useNewSystem = value),
          ),
          Text(useNewSystem ? '새 시스템' : '기존 시스템'),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 시나리오 선택
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () => runScenario('optimal_far'),
                  child: Text('최적≠최단거리'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => runScenario('multiple_accept'),
                  child: Text('다중 수락'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => runScenario('random'),
                  child: Text('랜덤'),
                ),
              ],
            ),
          ),
          
          // 현재 시나리오 정보
          if (currentScenario != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('시나리오: ${currentScenario!.description}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('재난: ${currentScenario!.incident['type']} - ${currentScenario!.incident['address']}'),
                ],
              ),
            ),
            
            // 대원 목록
            Expanded(
              child: ListView.builder(
                itemCount: currentScenario!.responders.length,
                itemBuilder: (context, index) {
                  final responder = currentScenario!.responders[index];
                  final acceptTime = acceptTimes[responder.id];
                  final isSelected = selectedResponderId == responder.id;
                  
                  return Card(
                    color: isSelected ? Colors.green[100] : null,
                    margin: EdgeInsets.all(8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(responder.name[0]),
                        backgroundColor: acceptTime != null ? Colors.blue : Colors.grey,
                      ),
                      title: Text('${responder.name} (${responder.rank})'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('직선: ${responder.straightDistance}m / 도로: ${responder.actualDistanceText}'),
                          Text('예상 도착: ${responder.etaText}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            )),
                          if (acceptTime != null)
                            Text('수락 시각: ${acceptTime.second}초'),
                        ],
                      ),
                      trailing: isSelected 
                        ? Icon(Icons.check_circle, color: Colors.green, size: 32)
                        : null,
                      onTap: () => simulateAccept(responder),
                    ),
                  );
                },
              ),
            ),
          ],
          
          // 통계
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Text('시뮬레이션 통계', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('총 실행'),
                        Text('$totalSimulations회'),
                      ],
                    ),
                    Column(
                      children: [
                        Text('새 시스템 우위'),
                        Text('$newSystemWins회 (${totalSimulations > 0 ? (newSystemWins / totalSimulations * 100).toStringAsFixed(1) : 0}%)'),
                      ],
                    ),
                    Column(
                      children: [
                        Text('평균 시간 단축'),
                        Text('${avgTimeSavedSeconds.toStringAsFixed(1)}초'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void runScenario(String type) {
    setState(() {
      currentScenario = MockDataGenerator.generateScenario(type);
      acceptTimes.clear();
      selectedResponderId = null;
    });
    
    // 자동 시뮬레이션 시작
    if (type == 'multiple_accept') {
      autoSimulateMultipleAccepts();
    }
  }
  
  void simulateAccept(MockResponder responder) {
    if (acceptTimes.containsKey(responder.id)) return;
    
    setState(() {
      acceptTimes[responder.id] = DateTime.now();
      
      if (useNewSystem) {
        // 새 시스템: 2분 후 최적 선택
        Future.delayed(Duration(seconds: 2), () {
          selectOptimalResponder();
        });
      } else {
        // 기존 시스템: 첫 수락자 즉시 선택
        if (selectedResponderId == null) {
          selectedResponderId = responder.id;
          calculateStats();
        }
      }
    });
  }
  
  void autoSimulateMultipleAccepts() async {
    for (final responder in currentScenario!.responders) {
      await Future.delayed(Duration(seconds: responder.acceptDelay));
      simulateAccept(responder);
    }
  }
  
  void selectOptimalResponder() {
    if (currentScenario == null) return;
    
    // 수락한 대원 중 ETA 최소
    MockResponder? optimal;
    int minEta = 999999;
    
    for (final responder in currentScenario!.responders) {
      if (acceptTimes.containsKey(responder.id) && responder.etaSec < minEta) {
        minEta = responder.etaSec;
        optimal = responder;
      }
    }
    
    if (optimal != null) {
      setState(() {
        selectedResponderId = optimal!.id;
      });
      calculateStats();
    }
  }
  
  void calculateStats() {
    // 통계 계산 로직
    totalSimulations++;
    
    // 첫 수락자와 최적 대원의 ETA 차이 계산
    final firstAcceptor = currentScenario!.responders
      .where((r) => acceptTimes.containsKey(r.id))
      .first;
    
    final selectedResponder = currentScenario!.responders
      .firstWhere((r) => r.id == selectedResponderId);
    
    if (selectedResponder.etaSec < firstAcceptor.etaSec) {
      newSystemWins++;
      avgTimeSavedSeconds = ((avgTimeSavedSeconds * (totalSimulations - 1)) + 
        (firstAcceptor.etaSec - selectedResponder.etaSec)) / totalSimulations;
    }
  }
}
