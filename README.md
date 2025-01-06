# GramSathi Application

GramSathi is a community-focused mobile application designed to bridge the gap between villagers and administrative officials. It offers features to manage announcements, market prices, suggestions, queries, and emergency contacts. Additionally, it facilitates buying and selling products among users from different villages.

## Roles
- **Administrator:** Can post announcements, view villages, and add or edit villages and their admins.
- **Village Admin:** Manages village-specific users, announcements, and market updates.
- **User:** Can view announcements, post suggestions, complaints, and queries, and participate in buying and selling.

## Chatbot Support
GramSathi includes a chatbot feature to assist users with common queries, information about available insurance, subsidies, and provides quick access to important crop information.

## Features
- **User Authentication:** Admin-approved registration for users.
- **Announcements:** View important village updates.
- **Market Prices:** Monitor crop prices by place and crop.
- **Queries and Suggestions:** Post and track responses from admins.
- **Emergency Contacts:** Access contact details for emergencies.
- **Multi-village Support:** Admin can manage multiple villages with separate admins and users.
- **Buying and Selling Platform:** Trade products between users across different villages.

---

## Technologies Used
- **Frontend:** Flutter (Version 3.24.3)
- **Backend:** Node.js with Express.js
- **Database:** MongoDB

---

## Prerequisites
1. **Node.js** - Download and install [Node.js](https://nodejs.org/).
2. **Flutter SDK** - Install Flutter by following the [official guide](https://flutter.dev/docs/get-started/install).
3. **MongoDB** - Set up a MongoDB database locally or using [MongoDB Atlas](https://www.mongodb.com/).
4. **Android Studio** - Install Android Studio emulator (Pixel 7 with API level 29).

---

## Installation Guide

### 1. Fork the Repository

Fork this repository by clicking on the "Fork" button at the top right of this page.

### 2. Clone the Repository

```bash
git clone https://github.com/EbeyJoeRegi/Rural-Nexus
```

### 3. Navigate to the Project Directory

```bash
cd GramSathi
```

---

## Backend Setup

1. Navigate to the backend directory:
```bash
cd GramSathi/Backend
```
2. Install dependencies:
```bash
npm install
```
3. Create a `.env` file and configure environment variables based on details in the backend folder.

4. Start the server:
```bash
node server.js
```

---

## Frontend Setup

1. Navigate to the frontend directory:
```bash
cd GramSathi/Application
```
2. Install dependencies:
```bash
flutter pub get
```
3. Configure the API URL in the `../lib/config/app_config.dart` file:

Provide the IP address & port details:
```dart
class AppConfig {
  static const String baseUrl = 'http://localhost:3000';
}
```
4. Run the application:
```bash
flutter run
```

---

## Database Setup (JSON Files)

1. Navigate to the Database directory:
```bash
cd GramSathi/DB
```

2. The `DB` folder contains JSON files required to initialize the database.

3. Import these JSON files into MongoDB using the following steps:
   - Open MongoDB Compass.
   - Connect to your database instance.
   - Create a database named `gramsathi`.
   - Click on "Import Data" and select the JSON files from the `DB` folder.
   - Ensure collections are created successfully.

4. Verify that the data is imported correctly by viewing the collections.

---

## Screenshots
Screenshots of the project are provided in the `Images` folder.

---

## Contributors

- **[Aju Thomas](https://github.com/Aju34807)** 
- **[Anjalita Joyline Fernandes](https://github.com/Anjalita)** 
- **[Chinmayee N](https://github.com/Chinmayee1103)**
- **[Ebey Joe Regi](https://github.com/EbeyJoeRegi)** 

---

## License
This project is licensed under the [MIT License](LICENSE).

---

## Contact
For any issues or queries, please contact:
- **Name:** Ebey Joe Regi
- **Email:** ebeyjoeregi13@gmail.com

---

![Home Page](Images/Login%20Screen.png)