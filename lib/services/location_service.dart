import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  Map<String, dynamic> _locationsData = {};
  bool _isLoaded = false;

  factory LocationService() {
    return _instance;
  }

  LocationService._internal();

  Future<void> loadLocations() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString('assets/philippines_complete.json');
      _locationsData = jsonDecode(jsonString);
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ Error loading locations: $e');
    }
  }

  /// Get all regions
  List<String> getRegions() {
    if (!_isLoaded) return [];
    List<String> regions = [];
    _locationsData.forEach((key, value) {
      if (value is Map && value.containsKey('region_name')) {
        regions.add(value['region_name']);
      }
    });
    regions.sort();
    return regions;
  }

  /// Get provinces for a given region
  List<String> getProvinces(String regionName) {
    if (!_isLoaded) return [];
    List<String> provinces = [];
    
    _locationsData.forEach((regionCode, regionData) {
      if (regionData is Map && regionData['region_name'] == regionName) {
        if (regionData.containsKey('province_list')) {
          final provinceList = regionData['province_list'] as Map;
          provinces.addAll(provinceList.keys.cast<String>());
        }
      }
    });
    
    provinces.sort();
    return provinces;
  }

  /// Get municipalities for a given region and province
  List<String> getMunicipalities(String regionName, String provinceName) {
    if (!_isLoaded) return [];
    List<String> municipalities = [];
    
    _locationsData.forEach((regionCode, regionData) {
      if (regionData is Map && regionData['region_name'] == regionName) {
        if (regionData.containsKey('province_list')) {
          final provinceList = regionData['province_list'] as Map;
          final province = provinceList[provinceName];
          if (province is Map && province.containsKey('municipality_list')) {
            municipalities.addAll((province['municipality_list'] as Map).keys.cast<String>());
          }
        }
      }
    });
    
    municipalities.sort();
    return municipalities;
  }

  /// Get barangays for a given region, province, and municipality
  List<String> getBarangays(String regionName, String provinceName, String municipalityName) {
    if (!_isLoaded) return [];
    List<String> barangays = [];
    
    _locationsData.forEach((regionCode, regionData) {
      if (regionData is Map && regionData['region_name'] == regionName) {
        if (regionData.containsKey('province_list')) {
          final provinceList = regionData['province_list'] as Map;
          final province = provinceList[provinceName];
          if (province is Map && province.containsKey('municipality_list')) {
            final municipality = (province['municipality_list'] as Map)[municipalityName];
            if (municipality is Map && municipality.containsKey('barangay_list')) {
              barangays.addAll(List<String>.from(municipality['barangay_list'] ?? []));
            }
          }
        }
      }
    });
    
    barangays.sort();
    return barangays;
  }
}
