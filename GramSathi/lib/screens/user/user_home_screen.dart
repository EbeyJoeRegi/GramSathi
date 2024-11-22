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

  UserHomeScreen({required this.username, required this.name});

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
          _weatherCondition = weatherData['weather'][0]['description'];

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
    Color bgColor = Colors.blueAccent.withOpacity(0.7);

    switch (_weatherCondition) {
      case 'clear sky':
        weatherIcon = WeatherIcons.day_sunny;
        bgColor = Colors.yellow.withOpacity(0.7);
        break;
      case 'few clouds':
      case 'scattered clouds':
      case 'broken clouds':
        weatherIcon = WeatherIcons.cloud;
        bgColor = Colors.grey.withOpacity(0.7);
        break;
      case 'shower rain':
      case 'rain':
        weatherIcon = WeatherIcons.rain;
        bgColor = Colors.blueGrey.withOpacity(0.7);
        break;
      case 'thunderstorm':
        weatherIcon = WeatherIcons.thunderstorm;
        bgColor = Colors.deepPurple.withOpacity(0.7);
        break;
      case 'snow':
        weatherIcon = WeatherIcons.snow;
        bgColor = Colors.lightBlue.withOpacity(0.7);
        break;
      case 'mist':
        weatherIcon = WeatherIcons.fog;
        bgColor = Colors.lightGreen.withOpacity(0.7);
        break;
      default:
        weatherIcon = WeatherIcons.cloud_refresh;
        bgColor = Colors.teal.withOpacity(0.7);
    }

    return AnimatedContainer(
      duration: Duration(seconds: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(35.0),
      ),
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
              SizedBox(height: 4.0),
              Text(
                _weatherCondition.isNotEmpty
                    ? _weatherCondition.toUpperCase()
                    : 'Fetching...',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
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
            color: Colors.black,
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
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildWeatherWidget(),
          ),
          SizedBox(height: 16.0),
          _buildAnnouncementsSection(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsSection() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    } else if (_announcements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'No announcements in the last 2 days!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          final announcementDate =
              convertUtcToIst(DateTime.parse(announcement['created_at']));
          final formattedDate =
              DateFormat('yyyy-MM-dd HH:mm').format(announcementDate);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            elevation: 4.0,
            child: ListTile(
              title: Text(
                announcement['title'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement['content'],
                    style: TextStyle(fontSize: 14.0),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Date: $formattedDate',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
