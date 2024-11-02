import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart';
import 'market_updates_screen.dart';
import 'feedback_hub.dart';
import 'important_contacts_screen.dart';
import 'suggestions_screen.dart';
import 'user_profile.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class UserHomeScreen extends StatefulWidget {
  final String username;
  final String name;
  final String place;

  UserHomeScreen(
      {required this.username, required this.name, required this.place});

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _temperature = '';
  String _city = '';
  String _weatherCondition = '';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements(widget.place);
    _fetchLocationAndWeather();
  }

  Future<void> _fetchAnnouncements(String place) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/announcements?place=$place'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> announcementsJson = json.decode(response.body);
        final twoDaysAgo = DateTime.now().subtract(Duration(days: 2));
        final recentAnnouncements = announcementsJson
            .map((announcement) => Map<String, dynamic>.from(announcement))
            .where((announcement) =>
                DateTime.parse(announcement['created_at']).isAfter(twoDaysAgo))
            .toList();

        setState(() {
          _announcements = recentAnnouncements;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load announcements';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLocationAndWeather() async {
    try {
      final locationResponse =
          await http.get(Uri.parse('https://ipapi.co/json/'));
      if (locationResponse.statusCode == 200) {
        final locationData = json.decode(locationResponse.body);
        _city = locationData['city'];
        final lat = locationData['latitude'];
        final lon = locationData['longitude'];

        final weatherResponse = await http.get(
          Uri.parse(
            'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=e8544d130b60b1a8ee3cf6b86ae6b593',
          ),
        );

        if (weatherResponse.statusCode == 200) {
          final weatherData = json.decode(weatherResponse.body);
          final temp = weatherData['main']['temp'];
          _weatherCondition = weatherData['weather'][0]['main'];

          // Add a print statement to debug weather condition
          print('Weather Condition: $_weatherCondition');

          setState(() {
            _temperature =
                '${temp.toStringAsFixed(1)}°C'; // Corrected degree symbol
          });
        }
      }
    } catch (e) {
      setState(() {
        _temperature = 'Error fetching weather';
      });
    }
  }

  DateTime convertUtcToIst(DateTime utcDateTime) {
    return utcDateTime.add(Duration(hours: 5, minutes: 30));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  Widget _buildWeatherWidget() {
    IconData weatherIcon;

    // Map more weather conditions to corresponding icons
    switch (_weatherCondition) {
      case 'Clear':
        weatherIcon = WeatherIcons.day_sunny;
        break;
      case 'Clouds':
        weatherIcon = WeatherIcons.cloud;
        break;
      case 'Rain':
        weatherIcon = WeatherIcons.rain;
        break;
      case 'Thunderstorm':
        weatherIcon = WeatherIcons.thunderstorm;
        break;
      case 'Drizzle':
        weatherIcon = WeatherIcons.showers;
        break;
      case 'Snow':
        weatherIcon = WeatherIcons.snow;
        break;
      case 'Mist':
      case 'Fog':
      case 'Haze':
        weatherIcon = WeatherIcons.fog;
        break;
      case 'Smoke':
      case 'Dust':
      case 'Sand':
      case 'Ash':
      case 'Squall':
      case 'Tornado':
        weatherIcon = WeatherIcons.dust;
        break;
      default:
        weatherIcon = WeatherIcons.cloud_refresh; // Fallback icon
    }

    // Add temperature-based logic for icon changes
    if (_temperature.isNotEmpty) {
      final tempValue = double.tryParse(_temperature.split('°')[0]);
      if (tempValue != null) {
        if (tempValue < 10) {
          weatherIcon =
              WeatherIcons.snowflake_cold; // Cold icon for low temperatures
        } else if (tempValue > 30) {
          weatherIcon = WeatherIcons.hot; // Hot icon for high temperatures
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _city.isNotEmpty ? _city : 'Loading...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                _temperature.isNotEmpty ? _temperature : 'Loading...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Icon(
            weatherIcon,
            color: Colors.white,
            size: 50,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: <Widget>[
          _buildHomePage(),
          MarketUpdatesScreen(),
          FeedbackHub(username: widget.username),
          SuggestionsScreen(username: widget.username),
          ImportantContactsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback), // Feedback Hub icon
            label: 'Feedback Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz), // Exchange Zone icon
            label: 'Exchange Zone',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: 'Emergency',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Image.asset(
                'assets/images/icon.png',
                height: 55.0,
                width: 54.0,
              ),
            ),
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Hi, ${widget.name}',
                  textStyle: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Set to black
                  ),
                  speed: Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ],
        ),
        backgroundColor: Colors.white, // Set AppBar color to white
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserProfilePage(username: widget.username),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white, // Set the entire background to white
        child: Column(
          children: [
            SizedBox(height: 15.0), // Gap between AppBar and container
            Center(
              child: Container(
                width: 390,
                height: 150, // Set the desired width here
                decoration: BoxDecoration(
                  color: Colors.teal
                      .withOpacity(0.7), // Teal background with opacity
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(35.0),
                    bottom: Radius.circular(35.0),
                  ), // Rounded borders
                ),
                padding: const EdgeInsets.all(16.0),
                child: _buildWeatherWidget(),
              ),
            ),
            SizedBox(height: 28.0), // Space before the heading
            Padding(
              padding: const EdgeInsets.only(right: 180),
              child: Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 5), // Space before announcements list
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(child: Text(_errorMessage))
                      : ListView.builder(
                          padding: EdgeInsets.all(16.0),
                          itemCount: _announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = _announcements[index];
                            final dateTimeUtc =
                                DateTime.parse(announcement['created_at']);
                            final dateTimeIst = convertUtcToIst(dateTimeUtc);
                            final formattedDate =
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(dateTimeIst);

                            // Safely access announcement fields
                            final title = announcement['title'] ?? 'No Title';
                            final description =
                                announcement['content'] ?? 'No Description';
                            final admin = announcement['admin'] ?? 'UnKnown';

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      description,
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Posted by: $admin',
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Posted on: $formattedDate',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
