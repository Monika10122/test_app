import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../logic/config.dart';
import '../logic/hive.dart';
import '../logic/weather_api.dart';
import '../logic/api.dart' as weatherApi;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String location = '';
  String temperature = '';
  String weatherCondition = '';
  List<Map<String, String>> weatherForecasts = [];
  Set<String> savedCities = {};

  weatherApi.WeatherApi api = weatherApi.WeatherApi();

  Future<void> fetchData(String city) async {
    final currentWeather = await api.fetchDataFromAPI(city);
    final forecasts = await api.fetchWeatherForecastsFromAPI(city);

    setState(() {
      location = currentWeather['location']!;
      temperature = currentWeather['temperature']!;
      weatherCondition = currentWeather['weatherCondition']!;
      weatherForecasts = forecasts;
    });
  }

  Future<void> _loadSavedCities() async {
    try {
      setState(() {
        savedCities = Set.from(HiveBoxes.savedCities.values);
      });
    } catch (error) {
      print('Error loading saved cities: $error');
    }
  }

  Future<void> _saveCity(String city) async {
    try {
      savedCities.add(city);
      await HiveBoxes.savedCities.add(city);
    } catch (error) {
      print('Error saving city: $error');
    }
  }

  Future<void> _removeCity(String city) async {
    try {
      savedCities.remove(city);
      await HiveBoxes.savedCities.delete(city);
    } catch (error) {
      print('Error removing city: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
    fetchData('Kyiv');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Погода - $location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch<String>(
                context: context,
                delegate: _WeatherSearchDelegate(),
              );
              if (result != null && result.isNotEmpty) {
                fetchData(result);
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 177, 213, 243),
              ),
              child: Text(
                'Збережені міста',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            for (String city in savedCities)
              ListTile(
                title: Text(city),
                onTap: () {
                  fetchData(city);
                  Navigator.pop(context); 
                },
                onLongPress: () {
                  _removeCity(city);
                  _loadSavedCities();
                  Navigator.pop(context); 
                },
              ),
          ],
        ),
      ),
      backgroundColor: const Color(0xFFDEF5E5),
      body: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          children: [
            const SizedBox(height: 10.0),
            if (weatherForecasts.isNotEmpty)
              WeatherForecastContainer(
                location: location,
                temperature: temperature,
                weatherCondition: weatherCondition,
                weatherForecasts: weatherForecasts,
              ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              _saveCity(location);
              _loadSavedCities();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Місто збережено: $location'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Icon(Icons.save),
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            onPressed: () {
              fetchData(location);
            },
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _WeatherSearchDelegate extends SearchDelegate<String> {
  final weatherApi.WeatherApi api = weatherApi.WeatherApi();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(query);
  }

  Widget _buildSearchResults(String query) {
    return FutureBuilder<List<String>>(
      future: _getData(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(14.0),
            child: Text('Яке місто шукаєте?',
            style: TextStyle(fontSize: 18),),
          );
        } else {
          return ListView(
            children: snapshot.data!.map((place) {
              return ListTile(
                title: Text(place),
                onTap: () {
                  close(context, place);
                },
              );
            }).toList(),
          );
        }
      },
    );
  }

  Future<List<String>> _getData(String query) async {
    const apiKey = Config.apiKey2;
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$apiKey&types=place';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'];
      final List<String> places = [];
      for (var feature in features) {
        final placeName = feature['place_name'];
        places.add(placeName);
        if (places.length >= 3) {
          break;
        }
      }
      return places;
    } else {
      throw Exception('Failed to fetch search results');
    }
  }
}
