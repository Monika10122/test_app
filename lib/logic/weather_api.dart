import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

@HiveType(typeId: 1)
class WeatherDetails {
  @HiveField(0)
  final String dayOfWeek;

  @HiveField(1)
  String temperature;

  @HiveField(2)
  String windSpeed;

  @HiveField(3)
  String precipitation;

  @HiveField(4)
  String notes;

  WeatherDetails({
    required this.dayOfWeek,
    required this.temperature,
    required this.windSpeed,
    required this.precipitation,
    required this.notes,
  });
}

class WeatherForecastContainer extends StatefulWidget {
  final String location;
  final String temperature;
  final String weatherCondition;
  final List<Map<String, String>> weatherForecasts;

  const WeatherForecastContainer({
    Key? key,
    required this.location,
    required this.temperature,
    required this.weatherCondition,
    required this.weatherForecasts,
  }) : super(key: key);

  @override
  _WeatherForecastContainerState createState() =>
      _WeatherForecastContainerState();
}

class _WeatherForecastContainerState extends State<WeatherForecastContainer> {
  List<String> daysOfWeek = [
    'Понеділок',
    'Вівторок',
    'Середа',
    'Четверг',
    'П\'ятниця',
    'Субота',
    'Неділя'
  ];
  List<WeatherDetails> savedCities = [];
  List<TextEditingController> additionalNotesControllers = [];

  @override
  void dispose() {
    for (var controller in additionalNotesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Hive.initFlutter();
    _openBoxAndLoadCities();
  }

  Future<void> _openBoxAndLoadCities() async {
    await Hive.openBox<WeatherDetails>('weather_details');
    _loadSavedCities();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFFBCEAD5).withOpacity(0.5),
              ),
              padding: const EdgeInsets.all(10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Погода на наступні 5 днів',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 400,
                      child: ListView.builder(
                        itemCount: widget.weatherForecasts.length,
                        itemBuilder: (context, index) {
                          String forecastDayOfWeek =
                              daysOfWeek[(DateTime.now().weekday + index)];

                          String forecastTemperature = '';
                          String forecastWindSpeed = '';
                          String forecastPrecipitation = '';
                          if (widget.weatherForecasts.isNotEmpty) {
                            forecastTemperature = widget.weatherForecasts[index]
                                    ['temperature'] ??
                                '';
                            forecastWindSpeed = widget.weatherForecasts[index]
                                    ['windSpeed'] ??
                                '';
                            forecastPrecipitation = widget
                                    .weatherForecasts[index]['precipitation'] ??
                                '';
                          }
                          WeatherDetails savedCity = savedCities.firstWhere(
                            (city) => city.dayOfWeek == forecastDayOfWeek,
                            orElse: () => WeatherDetails(
                              dayOfWeek: forecastDayOfWeek,
                              temperature: '',
                              windSpeed: '',
                              precipitation: '',
                              notes: '',
                            ),
                          );

                          return InkWell(
                            onTap: () {
                              _showWeatherDetails(
                                context,
                                savedCity,
                              );
                            },
                            child: SingleChildScrollView(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                padding: const EdgeInsets.all(5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color:
                                      const Color.fromARGB(255, 121, 187, 241),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            forecastDayOfWeek,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Температура: $forecastTemperature°C',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Вітер: $forecastWindSpeed км/год',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            'Вологість: $forecastPrecipitation%',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          // Додаємо виведення нотаток
                                          Text(
                                            'Нотатки: ${savedCity.notes}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeatherDetails(
    BuildContext context,
    WeatherDetails savedCity,
  ) {
    additionalNotesControllers = savedCity.notes
        .split('\n')
        .map((note) => TextEditingController(text: note))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Редагувати інформацію'),
              content: Column(
                children: [
                  for (var i = 0; i < additionalNotesControllers.length; i++)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: additionalNotesControllers[i],
                            decoration:
                                const InputDecoration(labelText: 'Нотатки'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              additionalNotesControllers.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        additionalNotesControllers.add(TextEditingController());
                      });
                    },
                    child: const Text('Додати нотатку'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Скасувати'),
                ),
                TextButton(
                  onPressed: () async {
                    await Hive.openBox<WeatherDetails>('weather_details');
                    var hiveBox = Hive.box<WeatherDetails>('weather_details');
                    await hiveBox.put(
                      savedCity.dayOfWeek,
                      WeatherDetails(
                        dayOfWeek: savedCity.dayOfWeek,
                        temperature: savedCity.temperature,
                        windSpeed: savedCity.windSpeed,
                        precipitation: savedCity.precipitation,
                        notes: additionalNotesControllers
                            .map((controller) => controller.text)
                            .join('\n'),
                      ),
                    );
                    setState(() {
                      _loadSavedCities();
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Зберегти'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _loadSavedCities() async {
    try {
      var hiveBox = Hive.box<WeatherDetails>('weather_details');
      setState(() {
        savedCities = hiveBox.values.toList();
      });
    } catch (error) {
      print('Error loading saved cities: $error');
    }
  }
}
