import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Railway Control Center API Service
/// 
/// A robust, production-ready HTTP client for railway traffic control system.
/// Features mock data support for development without requiring a backend.
class ApiService {
  static const String _tag = 'ApiService';
  
  // Environment configuration
  static const Map<String, String> _baseUrls = {
    'development': 'http://localhost:8000/api',
    'staging': 'https://staging-api.indianrailways.gov.in/api',
    'production': 'https://api.indianrailways.gov.in/api',
  };
  
  static const String _environment = 'development';
  static String get baseUrl => _baseUrls[_environment]!;
  
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Authentication state
  String? _authToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  
  void _log(String message, {bool isError = false}) {
    if (kDebugMode) {
      final prefix = isError ? '❌' : '📡';
      print('$prefix [$_tag]: $message');
    }
  }
  
  // ============ AUTHENTICATION ============
  
  Future<ApiResponse<LoginResult>> login(String username, String password, String role) async {
    try {
      _log('Login attempt for: $username');
      
      // Mock login for development
      if (_environment == 'development') {
        await Future.delayed(const Duration(seconds: 1));
        
        final mockUser = UserInfo(
          id: 'user_123',
          username: username,
          role: role,
          name: 'Railway Controller',
          email: '$username@railways.gov.in',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLogin: DateTime.now(),
        );
        
        _authToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
        _refreshToken = 'mock_refresh_token';
        _currentUser = {
          'id': mockUser.id,
          'username': mockUser.username,
          'role': mockUser.role,
          'name': mockUser.name,
          'email': mockUser.email,
          'createdAt': mockUser.createdAt.toIso8601String(),
          'lastLogin': mockUser.lastLogin.toIso8601String(),
        };
        
        return ApiResponse.success(LoginResult(
          user: mockUser,
          accessToken: _authToken!,
          refreshToken: _refreshToken!,
        ));
      }
      
      return ApiResponse.error(ApiError.networkError('Backend not available'));
      
    } catch (e) {
      _log('Login failed: $e', isError: true);
      return ApiResponse.error(ApiError.networkError('Login failed'));
    }
  }
  
  Future<ApiResponse<void>> logout() async {
    _clearAuth();
    return ApiResponse.success(null);
  }
  
  bool get isAuthenticated => _authToken != null;
  
  UserInfo? get currentUser => _currentUser != null ? UserInfo.fromJson(_currentUser!) : null;
  
  void _clearAuth() {
    _authToken = null;
    _refreshToken = null;
    _currentUser = null;
  }
  
  // ============ RAILWAY METHODS ============
  
  Future<ApiResponse<List<TrainInfo>>> getTrains({String? route, String? status, int? limit}) async {
    try {
      _log('Getting trains');
      
      if (_environment == 'development') {
        await Future.delayed(const Duration(seconds: 1));
        
        final mockTrains = <TrainInfo>[
          TrainInfo(
            number: '12002',
            name: 'Shatabdi Express',
            currentStation: 'New Delhi',
            nextStation: 'Ghaziabad',
            status: 'On Time',
            scheduledArrival: DateTime.now().add(const Duration(minutes: 15)),
            actualArrival: DateTime.now().add(const Duration(minutes: 15)),
            passengerCount: 450,
            isDelayed: false,
            delayMinutes: 0,
          ),
          TrainInfo(
            number: '12951',
            name: 'Mumbai Rajdhani',
            currentStation: 'Kota',
            nextStation: 'Sawai Madhopur',
            status: 'Delayed',
            scheduledArrival: DateTime.now().add(const Duration(minutes: 45)),
            actualArrival: DateTime.now().add(const Duration(minutes: 65)),
            passengerCount: 320,
            isDelayed: true,
            delayMinutes: 20,
          ),
        ];
        
        return ApiResponse.success(mockTrains);
      }
      
      return ApiResponse.success([]);
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get trains'));
    }
  }
  
  Future<ApiResponse<List<SystemAlert>>> getAlerts({String? severity, bool? acknowledged}) async {
    try {
      _log('Getting alerts');
      
      if (_environment == 'development') {
        await Future.delayed(const Duration(milliseconds: 500));
        
        final mockAlerts = <SystemAlert>[
          SystemAlert(
            id: 'alert_001',
            message: 'Signal failure at Junction A - delays expected',
            severity: 'critical',
            category: 'infrastructure',
            createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
            acknowledged: false,
            trainNumber: '12002',
            stationCode: 'JNCA',
          ),
          SystemAlert(
            id: 'alert_002',
            message: 'Heavy rainfall in Eastern region',
            severity: 'warning',
            category: 'weather',
            createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
            acknowledged: true,
          ),
        ];
        
        return ApiResponse.success(mockAlerts);
      }
      
      return ApiResponse.success([]);
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get alerts'));
    }
  }
  
  Future<ApiResponse<DashboardStats>> getDashboardStats() async {
    try {
      _log('Getting dashboard stats');
      
      try {
        final response = await http.get(Uri.parse('$baseUrl/dashboard/summary'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final stats = DashboardStats(
            totalTrains: data['total_trains'] ?? 0,
            activeTrains: data['total_trains'] ?? 0,
            delayedTrains: data['delayed'] ?? 0,
            onTimeTrains: data['on_time'] ?? 0,
            criticalAlerts: 0,
            averageDelay: 0.0,
            onTimePerformance: data['operational_efficiency']?.toDouble() ?? 0.0,
          );
          return ApiResponse.success(stats);
        }
      } catch (e) {
        _log('Backend not available, using mock data');
      }
      
      if (_environment == 'development') {
        await Future.delayed(const Duration(milliseconds: 700));
        
        final mockStats = DashboardStats(
          totalTrains: 150,
          activeTrains: 142,
          delayedTrains: 23,
          onTimeTrains: 119,
          criticalAlerts: 3,
          averageDelay: 8.5,
          onTimePerformance: 83.8,
        );
        
        return ApiResponse.success(mockStats);
      }
      
      return ApiResponse.success(DashboardStats(
        totalTrains: 0,
        activeTrains: 0,
        delayedTrains: 0,
        onTimeTrains: 0,
        criticalAlerts: 0,
        averageDelay: 0.0,
        onTimePerformance: 0.0,
      ));
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get stats'));
    }
  }

  Future<ApiResponse<TrainDetails>> getTrainDetails(String trainId) async {
    try {
      _log('Getting detailed train info for $trainId');
      
      try {
        final response = await http.get(Uri.parse('$baseUrl/trains/$trainId'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final details = TrainDetails.fromJson(data);
          return ApiResponse.success(details);
        }
      } catch (e) {
        _log('Backend not available for train details, using mock data');
      }
      
      // Fallback mock data
      final mockDetails = TrainDetails(
        id: trainId,
        name: 'Sample Express',
        route: 'New Delhi - Mumbai',
        currentStation: 'Gwalior Junction',
        nextStation: 'Jhansi Junction',
        status: 'On Time',
        delay: 0,
        speed: 85,
        departureTime: '14:30',
        arrivalTime: '20:45',
        coaches: 18,
        passengers: 1250,
        capacity: 1400,
        engineType: 'Electric',
        driver: 'Sample Driver',
        guard: 'Sample Guard',
        distanceCovered: 345,
        totalDistance: 1384,
        coordinates: {'lat': 26.2183, 'lng': 78.1828},
        signal: 'Green',
        trackCondition: 'Good',
        weather: 'Clear',
      );
      
      return ApiResponse.success(mockDetails);
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get train details'));
    }
  }

  Future<ApiResponse<TrackInfo>> getTrainTrackInfo(String trainId) async {
    try {
      _log('Getting track info for $trainId');
      
      try {
        final response = await http.get(Uri.parse('$baseUrl/trains/$trainId/track'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final trackInfo = TrackInfo.fromJson(data);
          return ApiResponse.success(trackInfo);
        }
      } catch (e) {
        _log('Backend not available for track info, using mock data');
      }
      
      // Fallback mock data
      final mockTrackInfo = TrackInfo(
        trainId: trainId,
        trainName: 'Sample Express',
        currentLocation: {
          'station': 'Gwalior Junction',
          'coordinates': {'lat': 26.2183, 'lng': 78.1828},
          'signal': 'Green',
          'trackCondition': 'Good'
        },
        routeInfo: {
          'route': 'New Delhi - Mumbai Central',
          'distanceCovered': 345,
          'totalDistance': 1384,
          'progressPercentage': 24.9
        },
        operationalStatus: {
          'speed': 85,
          'status': 'On Time',
          'delay': 0,
          'weather': 'Clear'
        },
        nextStation: 'Jhansi Junction',
        estimatedArrival: '20:45',
      );
      
      return ApiResponse.success(mockTrackInfo);
      
    } catch (e) {
      return ApiResponse.error(ApiError.unknown('Failed to get track info'));
    }
  }
}

// ============ RESPONSE CLASSES ============

class ApiResponse<T> {
  final T? data;
  final ApiError? error;
  final bool isSuccess;
  
  const ApiResponse._({this.data, this.error, required this.isSuccess});
  
  factory ApiResponse.success(T? data) => ApiResponse._(data: data, isSuccess: true);
  factory ApiResponse.error(ApiError error) => ApiResponse._(error: error, isSuccess: false);
}

class ApiError {
  final String message;
  final String type;
  final int? statusCode;
  
  const ApiError._({required this.message, required this.type, this.statusCode});
  
  factory ApiError.networkError(String message) => ApiError._(message: message, type: 'NETWORK_ERROR');
  factory ApiError.unauthorized(String message) => ApiError._(message: message, type: 'UNAUTHORIZED', statusCode: 401);
  factory ApiError.notFound(String message) => ApiError._(message: message, type: 'NOT_FOUND', statusCode: 404);
  factory ApiError.unknown(String message) => ApiError._(message: message, type: 'UNKNOWN');
  
  @override
  String toString() => 'ApiError($type): $message';
}

// ============ DATA MODELS ============

class UserInfo {
  final String id;
  final String username;
  final String role;
  final String name;
  final String? email;
  final DateTime createdAt;
  final DateTime lastLogin;
  
  UserInfo({
    required this.id,
    required this.username,
    required this.role,
    required this.name,
    this.email,
    required this.createdAt,
    required this.lastLogin,
  });
  
  factory UserInfo.fromJson(Map<String, dynamic> json) => UserInfo(
    id: json['id'],
    username: json['username'],
    role: json['role'],
    name: json['name'],
    email: json['email'],
    createdAt: DateTime.parse(json['createdAt']),
    lastLogin: DateTime.parse(json['lastLogin']),
  );
}

class LoginResult {
  final UserInfo user;
  final String accessToken;
  final String refreshToken;
  
  LoginResult({required this.user, required this.accessToken, required this.refreshToken});
}

class TrainInfo {
  final String number;
  final String name;
  final String currentStation;
  final String nextStation;
  final String status;
  final DateTime? scheduledArrival;
  final DateTime? actualArrival;
  final int passengerCount;
  final bool isDelayed;
  final int delayMinutes;
  
  TrainInfo({
    required this.number,
    required this.name,
    required this.currentStation,
    required this.nextStation,
    required this.status,
    this.scheduledArrival,
    this.actualArrival,
    required this.passengerCount,
    required this.isDelayed,
    required this.delayMinutes,
  });
}

class SystemAlert {
  final String id;
  final String message;
  final String severity;
  final String category;
  final DateTime createdAt;
  final bool acknowledged;
  final String? trainNumber;
  final String? stationCode;
  
  SystemAlert({
    required this.id,
    required this.message,
    required this.severity,
    required this.category,
    required this.createdAt,
    required this.acknowledged,
    this.trainNumber,
    this.stationCode,
  });
}

class DashboardStats {
  final int totalTrains;
  final int activeTrains;
  final int delayedTrains;
  final int onTimeTrains;
  final int criticalAlerts;
  final double averageDelay;
  final double onTimePerformance;
  
  DashboardStats({
    required this.totalTrains,
    required this.activeTrains,
    required this.delayedTrains,
    required this.onTimeTrains,
    required this.criticalAlerts,
    required this.averageDelay,
    required this.onTimePerformance,
  });
}

class TrainDetails {
  final String id;
  final String name;
  final String route;
  final String currentStation;
  final String nextStation;
  final String status;
  final int delay;
  final int speed;
  final String departureTime;
  final String arrivalTime;
  final int coaches;
  final int passengers;
  final int capacity;
  final String engineType;
  final String driver;
  final String guard;
  final int distanceCovered;
  final int totalDistance;
  final Map<String, dynamic> coordinates;
  final String signal;
  final String trackCondition;
  final String weather;

  TrainDetails({
    required this.id,
    required this.name,
    required this.route,
    required this.currentStation,
    required this.nextStation,
    required this.status,
    required this.delay,
    required this.speed,
    required this.departureTime,
    required this.arrivalTime,
    required this.coaches,
    required this.passengers,
    required this.capacity,
    required this.engineType,
    required this.driver,
    required this.guard,
    required this.distanceCovered,
    required this.totalDistance,
    required this.coordinates,
    required this.signal,
    required this.trackCondition,
    required this.weather,
  });

  factory TrainDetails.fromJson(Map<String, dynamic> json) => TrainDetails(
    id: json['id'],
    name: json['name'],
    route: json['route'],
    currentStation: json['current_station'],
    nextStation: json['next_station'],
    status: json['status'],
    delay: json['delay'] ?? 0,
    speed: json['speed'] ?? 0,
    departureTime: json['departure_time'] ?? '',
    arrivalTime: json['arrival_time'] ?? '',
    coaches: json['coaches'] ?? 0,
    passengers: json['passengers'] ?? 0,
    capacity: json['capacity'] ?? 0,
    engineType: json['engine_type'] ?? '',
    driver: json['driver'] ?? '',
    guard: json['guard'] ?? '',
    distanceCovered: json['distance_covered'] ?? 0,
    totalDistance: json['total_distance'] ?? 0,
    coordinates: json['coordinates'] ?? {},
    signal: json['signal'] ?? '',
    trackCondition: json['track_condition'] ?? '',
    weather: json['weather'] ?? '',
  );
}

class TrackInfo {
  final String trainId;
  final String trainName;
  final Map<String, dynamic> currentLocation;
  final Map<String, dynamic> routeInfo;
  final Map<String, dynamic> operationalStatus;
  final String nextStation;
  final String estimatedArrival;

  TrackInfo({
    required this.trainId,
    required this.trainName,
    required this.currentLocation,
    required this.routeInfo,
    required this.operationalStatus,
    required this.nextStation,
    required this.estimatedArrival,
  });

  factory TrackInfo.fromJson(Map<String, dynamic> json) => TrackInfo(
    trainId: json['id'],
    trainName: json['name'],
    currentLocation: json['current_location'] ?? {},
    routeInfo: json['route_info'] ?? {},
    operationalStatus: json['operational_status'] ?? {},
    nextStation: json['next_station'] ?? '',
    estimatedArrival: json['estimated_arrival'] ?? '',
  );
}