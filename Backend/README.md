# Backend - GramSathi Application

This folder contains the backend code for the GramSathi Application, developed using Node.js with Express.js and MongoDB.

## Features
- RESTful APIs for handling user data, announcements, suggestions, queries, and market price information.
- Integration with Twilio for SMS notifications.
- Email notifications .
- Weather API integration for fetching weather data.
- Cloudinary support for storing and managing images.

---

## Prerequisites
1. **Node.js** - Download and install [Node.js](https://nodejs.org/).
2. **MongoDB** - Install MongoDB locally or create an account with [MongoDB Atlas](https://www.mongodb.com/).

---
### 4. Environment Variables Configuration

Create a `.env` file in the `Backend` folder with the following keys:

```plaintext
# Twilio Account
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=

# Mail
EMAIL_USER=
EMAIL_PASS=

# Weather
WEATHER_KEY=

# Cloudinary
CLOUD_NAME=
CLOUD_API_KEY=
CLOUD_SECRET=

# MongoDB Connection
MONGODB_CONNECT_URI=
```
Replace the placeholders with your credentials.

### 5. Start the Server
```bash
node server.js
```

The server should start on `http://localhost:3000` (or as configured).

---
