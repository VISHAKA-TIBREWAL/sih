from flask import Flask, jsonify, request
from flask_cors import CORS
import json
from datetime import datetime, timedelta
import random

app = Flask(__name__)
CORS(app)

# Dummy train data
TRAINS_DATA = [
    {
        "id": "12345",
        "name": "Rajdhani Express",
        "route": "New Delhi - Mumbai Central",
        "current_station": "Gwalior Junction",
        "next_station": "Jhansi Junction",
        "status": "On Time",
        "delay": 0,
        "speed": 85,
        "departure_time": "14:30",
        "arrival_time": "20:45",
        "coaches": 18,
        "passengers": 1250,
        "capacity": 1400,
        "engine_type": "Electric",
        "driver": "Rajesh Kumar",
        "guard": "Amit Sharma",
        "distance_covered": 345,
        "total_distance": 1384,
        "coordinates": {"lat": 26.2183, "lng": 78.1828},
        "signal": "Green",
        "track_condition": "Good",
        "weather": "Clear"
    },
    {
        "id": "12904",
        "name": "Goldn Temple Mail",
        "route": "Mumbai Central - Amritsar",
        "current_station": "Vadodara Junction",
        "next_station": "Anand Junction",
        "status": "Delayed",
        "delay": 15,
        "speed": 0,
        "departure_time": "21:40",
        "arrival_time": "12:30+1",
        "coaches": 20,
        "passengers": 1680,
        "capacity": 1800,
        "engine_type": "Electric",
        "driver": "Suresh Patel",
        "guard": "Mohan Singh",
        "distance_covered": 98,
        "total_distance": 1928,
        "coordinates": {"lat": 22.3072, "lng": 73.1812},
        "signal": "Red",
        "track_condition": "Under Maintenance",
        "weather": "Light Rain"
    },
    {
        "id": "12002",
        "name": "Shatabdi Express",
        "route": "New Delhi - Bhopal",
        "current_station": "Agra Cantt",
        "next_station": "Gwalior Junction",
        "status": "On Time",
        "delay": 0,
        "speed": 110,
        "departure_time": "06:00",
        "arrival_time": "14:15",
        "coaches": 12,
        "passengers": 850,
        "capacity": 1000,
        "engine_type": "Electric",
        "driver": "Pradeep Joshi",
        "guard": "Ramesh Verma",
        "distance_covered": 232,
        "total_distance": 707,
        "coordinates": {"lat": 27.1767, "lng": 78.0081},
        "signal": "Green",
        "track_condition": "Excellent",
        "weather": "Clear"
    },
    {
        "id": "12626",
        "name": "Kerala Express",
        "route": "New Delhi - Trivandrum",
        "current_station": "Nagpur Junction",
        "next_station": "Ballarshah Junction",
        "status": "Running Late",
        "delay": 45,
        "speed": 95,
        "departure_time": "11:55",
        "arrival_time": "11:40+2",
        "coaches": 22,
        "passengers": 1950,
        "capacity": 2200,
        "engine_type": "Electric",
        "driver": "Anand Kumar",
        "guard": "Vijay Nair",
        "distance_covered": 1056,
        "total_distance": 2647,
        "coordinates": {"lat": 21.1458, "lng": 79.0882},
        "signal": "Yellow",
        "track_condition": "Good",
        "weather": "Cloudy"
    }
]

STATIONS_DATA = [
    {
        "id": "NDLS",
        "name": "New Delhi",
        "code": "NDLS",
        "platforms": 16,
        "tracks": 8,
        "status": "Operational",
        "trains_present": 12,
        "passenger_count": 25000
    },
    {
        "id": "CSTM",
        "name": "Mumbai Central",
        "code": "CSTM", 
        "platforms": 18,
        "tracks": 10,
        "status": "Operational",
        "trains_present": 15,
        "passenger_count": 32000
    }
]

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()})

@app.route('/api/trains', methods=['GET'])
def get_all_trains():
    """Get all trains with basic info"""
    simplified_trains = []
    for train in TRAINS_DATA:
        simplified_trains.append({
            "id": train["id"],
            "name": train["name"],
            "route": train["route"],
            "current_station": train["current_station"],
            "status": train["status"],
            "delay": train["delay"],
            "speed": train["speed"]
        })
    return jsonify(simplified_trains)

@app.route('/api/trains/<train_id>', methods=['GET'])
def get_train_details(train_id):
    """Get detailed information for a specific train"""
    train = next((t for t in TRAINS_DATA if t["id"] == train_id), None)
    if not train:
        return jsonify({"error": "Train not found"}), 404
    
    return jsonify(train)

@app.route('/api/trains/<train_id>/track', methods=['GET'])
def get_train_track_info(train_id):
    """Get track and location information for a specific train"""
    train = next((t for t in TRAINS_DATA if t["id"] == train_id), None)
    if not train:
        return jsonify({"error": "Train not found"}), 404
    
    track_info = {
        "id": train["id"],
        "name": train["name"],
        "current_location": {
            "station": train["current_station"],
            "coordinates": train["coordinates"],
            "signal": train["signal"],
            "track_condition": train["track_condition"]
        },
        "route_info": {
            "route": train["route"],
            "distance_covered": train["distance_covered"],
            "total_distance": train["total_distance"],
            "progress_percentage": round((train["distance_covered"] / train["total_distance"]) * 100, 1)
        },
        "operational_status": {
            "speed": train["speed"],
            "status": train["status"],
            "delay": train["delay"],
            "weather": train["weather"]
        },
        "next_station": train["next_station"],
        "estimated_arrival": train["arrival_time"]
    }
    
    return jsonify(track_info)

@app.route('/api/stations', methods=['GET'])
def get_all_stations():
    """Get all stations"""
    return jsonify(STATIONS_DATA)

@app.route('/api/stations/<station_id>', methods=['GET'])
def get_station_details(station_id):
    """Get detailed information for a specific station"""
    station = next((s for s in STATIONS_DATA if s["id"] == station_id), None)
    if not station:
        return jsonify({"error": "Station not found"}), 404
    
    return jsonify(station)

@app.route('/api/dashboard/summary', methods=['GET'])
def get_dashboard_summary():
    """Get summary data for dashboard"""
    total_trains = len(TRAINS_DATA)
    on_time = len([t for t in TRAINS_DATA if t["status"] == "On Time"])
    delayed = len([t for t in TRAINS_DATA if "Delayed" in t["status"] or "Late" in t["status"]])
    
    return jsonify({
        "total_trains": total_trains,
        "on_time": on_time,
        "delayed": delayed,
        "operational_efficiency": round((on_time / total_trains) * 100, 1),
        "average_speed": round(sum([t["speed"] for t in TRAINS_DATA]) / total_trains, 1),
        "total_passengers": sum([t["passengers"] for t in TRAINS_DATA]),
        "last_updated": datetime.now().isoformat()
    })

if __name__ == '__main__':
    print("🚂 Railway Management Backend API Server Starting...")
    print("📡 Server will run on http://0.0.0.0:8000")
    print("🌐 CORS enabled for frontend integration")
    app.run(host='0.0.0.0', port=8000, debug=True)