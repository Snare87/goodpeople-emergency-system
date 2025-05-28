// lib/utils/data_compression.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class DataCompression {
  // JSON 데이터 압축
  static Uint8List compressJson(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    final bytes = utf8.encode(jsonString);
    final compressed = gzip.encode(bytes);
    return Uint8List.fromList(compressed);
  }

  // 압축된 데이터 해제
  static Map<String, dynamic> decompressJson(Uint8List compressedData) {
    final decompressed = gzip.decode(compressedData);
    final jsonString = utf8.decode(decompressed);
    return json.decode(jsonString) as Map<String, dynamic>;
  }

  // 데이터 크기 최적화
  static Map<String, dynamic> optimizeCallData(Map<String, dynamic> data) {
    // 불필요한 필드 제거
    final optimized = Map<String, dynamic>.from(data);
    
    // timestamp를 더 작은 형식으로 변환
    if (optimized['startAt'] != null) {
      optimized['s'] = optimized['startAt'];
      optimized.remove('startAt');
    }
    
    // 긴 필드명을 짧게 변경
    final fieldMapping = {
      'eventType': 'et',
      'address': 'addr',
      'status': 'st',
      'responder': 'resp',
      'acceptedAt': 'accAt',
      'completedAt': 'compAt',
    };
    
    fieldMapping.forEach((longName, shortName) {
      if (optimized.containsKey(longName)) {
        optimized[shortName] = optimized[longName];
        optimized.remove(longName);
      }
    });
    
    return optimized;
  }
}
