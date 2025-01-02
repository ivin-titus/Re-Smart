import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'dart:convert';
import 'dart:async';
import './weather_widget.dart';
import './config/env.dart';

class MiniWeatherWidget extends StatefulWidget {
  const MiniWeatherWidget({Key? key}) : super(key: key);

  @override
  _MiniWeatherWidgetState createState() => _MiniWeatherWidgetState();
}

class _MiniWeatherWidgetState extends State<MiniWeatherWidget> {
  Map<String, dynamic>? _weatherData;
  String? _error;
  bool _loading = false;
  bool _isExpanded = false;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() => _loading = true);

    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) throw Exception('Location disabled');
      }

      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission != PermissionStatus.granted) {
          throw Exception('Permission denied');
        }
      }

      final locationData = await _location.getLocation();
      await _fetchWeather(
        lat: locationData.latitude,
        lon: locationData.longitude,
      );
    } catch (e) {
      setState(() {
        _error = 'Location error';
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeather({double? lat, double? lon}) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=${Environment.weatherApiKey}&units=metric'
        ),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _weatherData = json.decode(response.body);
          _loading = false;
        });
      } else {
        throw Exception('API Error');
      }
    } catch (e) {
      setState(() {
        _error = 'Weather update failed';
        _loading = false;
      });
    }
  }

IconData _getDetailedWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear sky': return Icons.wb_sunny_rounded;
      case 'few clouds': return Icons.cloud_outlined;
      case 'scattered clouds': return Icons.cloud_rounded;
      case 'broken clouds': return Icons.cloud;
      case 'shower rain': return Icons.grain_rounded;
      case 'rain': return Icons.water_drop_rounded;
      case 'thunderstorm': return Icons.flash_on_rounded;
      case 'snow': return Icons.ac_unit_rounded;
      case 'mist': return Icons.cloud_rounded;
      case 'smoke': return Icons.cloud;
      case 'haze': return Icons.cloud;
      case 'dust': return Icons.blur_on;
      case 'fog': return Icons.cloud_rounded;
      case 'sand': return Icons.grain;
      case 'ash': return Icons.blur_circular;
      case 'squall': return Icons.air;
      case 'tornado': return Icons.air;
      default: return Icons.wb_sunny_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isExpanded) {
      return Column(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up),
            onPressed: () => setState(() => _isExpanded = false),
          ),
          const WeatherWidget(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxWidth * 0.15;
        final tempSize = constraints.maxWidth * 0.12;

        return Container(
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_loading)
                  const CircularProgressIndicator(color: Colors.white)
                else if (_error != null)
                  Icon(Icons.error_outline, 
                    color: Colors.redAccent,
                    size: iconSize.clamp(24.0, 32.0),
                  )
                else if (_weatherData != null)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _getDetailedWeatherIcon(_weatherData!['weather'][0]['description']),
                          color: Colors.white,
                          size: iconSize.clamp(24.0, 32.0),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_weatherData!['main']['temp'].round()}°C',
                          style: TextStyle(
                            fontSize: tempSize.clamp(20.0, 28.0),
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white70,
                  ),
                  onPressed: () => setState(() => _isExpanded = true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}