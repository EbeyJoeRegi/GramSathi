import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '/config.dart';
import 'market_updates_screen.dart';
import 'feedback_hub.dart';
import 'important_contacts_screen.dart';
import 'exchange_zone.dart';
import 'user_profile.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class UserHomeScreen extends StatefulWidget {
  final String username;
  final String name;

  UserHomeScreen({required this.username, required this.name});

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final Uri chatbotUrl = Uri.parse(
      'https://cdn.botpress.cloud/webchat/v2.2/shareable.html?configUrl=https://files.bpcontent.cloud/2024/10/17/14/20241017142921-2XCQF05J.json');
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _temperature = '';
  String _city = '';
  String _lastUpdated = '';
  String formattedDate = '';
  String _weatherCondition = '';
  String place = '';

  @override
  void initState() {
    super.initState();
    fetchUserName(widget.username);
  }

  Future<void> fetchUserName(String username) async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/user/$username'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          place = data['address'];
        });
        _fetchAnnouncements(place);
        _fetchLocationAndWeather();
      } else if (response.statusCode == 404) {
        print('User not found');
      } else {
        print('Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching user details: $error');
    }
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

  void _openChatbot() async {
    if (await canLaunchUrl(chatbotUrl)) {
      await launchUrl(chatbotUrl);
    } else {
      throw 'Could not launch $chatbotUrl';
    }
  }

  Future<void> _fetchLocationAndWeather() async {
    try {
      // Use Geolocator to get the current location
      Position position = await _getCurrentLocation();

      // Get the latitude and longitude from the position
      final lat = position.latitude;
      final lon = position.longitude;

      final username = widget.username;
      final weatherResponse = await http.get(
        Uri.parse(
          '${AppConfig.baseUrl}/weather?username=$username&lat=$lat&lon=$lon',
        ),
      );

      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final temp = weatherData['temperature'];
        _weatherCondition = weatherData['weatherCondition'];
        _city = weatherData['city'];
        _lastUpdated = weatherData['lastUpdated'];
        DateTime lastUpdated = DateTime.parse(_lastUpdated);
        formattedDate = DateFormat('dd-MM-yyyy hh:mm:ss').format(lastUpdated);

        setState(() {
          _temperature = temp;
        });
      } else {
        setState(() {
          _temperature = 'Error fetching weather from backend';
        });
        print('Weather API error: ${weatherResponse.statusCode}');
      }
    } catch (e) {
      setState(() {
        _temperature = 'Error fetching weather';
      });
      print('Exception: $e');
    }
  }

  // Function to get current location using Geolocator
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle case when location services are disabled
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error('Location permissions are denied');
      }
    }

    // Set location settings for better accuracy and power management
    LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best, // Using best accuracy
      distanceFilter: 0, // No distance filter, will receive updates immediately
      timeLimit:
          Duration(seconds: 10), // Set a timeout for getting the location
    );

    // Get the current location using the new settings
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings, // Pass location settings here
      );
    } catch (e) {
      return Future.error('Failed to get location: $e');
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
      padding: const EdgeInsets.all(5.0),
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
                  fontSize: _temperature.contains('Error')
                      ? 17
                      : 18, // Reduced font size for errors
                  color: _temperature.contains('Error')
                      ? Colors.white
                      : Colors.white, // Red for errors
                ),
              ),
              SizedBox(height: 5),
              Text(
                _lastUpdated.isNotEmpty
                    ? "last updated at $formattedDate"
                    : 'Loading...',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontStyle: FontStyle.italic, // Makes the text italic
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
          MarketUpdatesScreen(username: widget.username),
          FeedbackHub(username: widget.username),
          ExchangeZone(username: widget.username),
          ImportantContactsScreen(username: widget.username),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFF5B4C2E),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(50.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8.0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
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
              icon: Icon(Icons.feedback),
              label: 'Feedback Hub',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Exchange Zone',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts),
              label: 'Emergency',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color(0xff005F3D),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 7.0),
              child: Image.asset(
                'assets/images/icon.png',
                height: 54.0,
                width: 53.0,
              ),
            ),
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'Hi, ${widget.name}',
                  textStyle: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  speed: Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 1,
            ),
          ],
        ),
        backgroundColor: Colors.white,
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
      body: Stack(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(height: 18.0),
                Center(
                  child: Container(
                    width: 385,
                    height: 145,
                    decoration: BoxDecoration(
                      color: Color(0xff015F3E).withOpacity(0.8),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25.0),
                        bottom: Radius.circular(25.0),
                      ),
                    ),
                    padding: const EdgeInsets.all(17.0),
                    child: _buildWeatherWidget(),
                  ),
                ),
                SizedBox(height: 26.0),
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
                SizedBox(height: 5),
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
                                final dateTimeIst =
                                    convertUtcToIst(dateTimeUtc);
                                final formattedDate =
                                    DateFormat('dd MMM yyyy, hh:mm a')
                                        .format(dateTimeIst);
                                final title =
                                    announcement['title'] ?? 'No Title';
                                final description =
                                    announcement['content'] ?? 'No Description';
                                final admin =
                                    announcement['admin'] ?? 'UnKnown';

                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  color: Color(0xFFE6F4E3),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xff015F3E)),
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
                                            fontSize: 14,
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
                )
              ],
            ),
          ),
          Positioned(
            bottom: 20.0,
            right: 20.0,
            child: IconButton(
              onPressed: _openChatbot,
              icon: Icon(Icons.support_agent_sharp, color: Color(0xff005F3D)),
              splashRadius: 24.0, // Adjust splash radius if needed
              iconSize: 40.0,
            ),
          )
        ],
      ),
    );
  }
}
