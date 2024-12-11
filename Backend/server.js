const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const cors = require('cors');
const twilio = require('twilio');
const nodemailer = require('nodemailer');
const dotenv = require('dotenv');

dotenv.config();
const app = express();
const port = 3000;
const {  User, Announcement,Suggestion, Query, Place, Crop, Price, Counter} = require('./models');
const saltRounds = 10;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// MongoDB connection
mongoose.connect('mongodb://localhost:27017/village_app')
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('Database connection error:', err));

// Import routes
const userRoutes = require('./user');
const adminRoutes = require('./admin');
const imageRoutes = require('./image');
const administratorRoutes = require('./administrator');

// Use routes
app.use('/', userRoutes);
app.use('/', adminRoutes);
app.use('/', imageRoutes);
app.use('/', administratorRoutes);

const getNextSequenceValue = async (sequenceName) => {
    const sequenceDocument = await Counter.findById(sequenceName);

    if (!sequenceDocument) {
        throw new Error('Sequence document not found or created');
    }

    const result = await Counter.findByIdAndUpdate(
        sequenceName,
        { $inc: { sequence_value: 1 } },
        { new: true }
    );

    if (result) {
        return result.sequence_value;
    } else {
        throw new Error('Failed to increment sequence value');
    }
};

// Function to generate a random 6-digit OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP
};
const otpStore = {};

const twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

// Send OTP endpoint
app.post('/send-otp', async (req, res) => {
  let { phoneNumber } = req.body;

  // Check if the phone number starts with the country code +91
  if (!phoneNumber.startsWith('+91')) { 
      phoneNumber = `+91${phoneNumber}`;
  }

  const otp = generateOTP();
  otpStore[phoneNumber] = otp;

  // Log the OTP for testing purposes
  console.log(`Generated OTP for phone ${phoneNumber}: ${otp}`);

  try {
      // Send OTP via SMS
      await twilioClient.messages.create({
          body: `Your OTP is: ${otp}`,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: phoneNumber,
      });

      res.status(200).json({ message: 'OTP sent successfully.' });
  } catch (error) {
      console.error('Error sending OTP:', error);

      // Check if the error is due to an unverified number
      if (error.code === 21608) {
          console.error(`Failed to send OTP to unverified number ${phoneNumber}. OTP: ${otp}`);
          // Return a success message instead of an error
          return res.status(200).json({ message: 'OTP generation successful, but number is unverified.' });
      }

      // Handle other types of errors
      res.status(500).json({ error: 'Failed to send OTP.' });
  }
});

// Verify OTP endpoint
app.post('/verify-otp', (req, res) => {
  let { phoneNumber, otp } = req.body;

  // Ensure the phone number is in the correct format
  if (!phoneNumber.startsWith('+91')) {
      phoneNumber = `+91${phoneNumber}`;
  }

  // Check if the OTP is valid
  if (otpStore[phoneNumber] === otp) {
      // OTP is valid, clear the stored OTP
      delete otpStore[phoneNumber];
      return res.status(200).json({ message: 'OTP verified successfully.' });
  } else {
      return res.status(400).json({ error: 'Invalid OTP.' });
  }
});


// Send Email OTP
app.post('/send-email-otp', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ message: 'Email is required.' });
  }

  const otp = generateOTP();
  otpStore[email] = otp; // Store the OTP for this email

  // Log the OTP for testing purposes
  console.log(`Generated OTP for email ${email}: ${otp}`);
  
  // Create a transporter object using SMTP
  const transporter = nodemailer.createTransport({
    service: 'gmail', // Use your email service provider
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  // Send OTP email
  try {
    await transporter.sendMail({
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'Your OTP Code',
      text: `Your OTP code is ${otp}. It is valid for 10 minutes.`,
    });

    return res.status(200).json({ message: 'OTP sent successfully.' });
  } catch (error) {
    console.error('Error sending email:', error);
    return res.status(500).json({ message: 'Failed to send OTP. Please try again.' });
  }
});

// Verify Email OTP
app.post('/verify-email-otp', (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({ message: 'Email and OTP are required.' });
  }

  const storedOtp = otpStore[email];

  if (!storedOtp) {
    return res.status(400).json({ message: 'No OTP sent to this email.' });
  }

  if (storedOtp !== otp) {
    return res.status(400).json({ message: 'Invalid OTP.' });
  }

  // Optionally, remove the OTP from the store after verification
  delete otpStore[email];

  return res.status(200).json({ message: 'OTP verified successfully.' });
});

// forgetpassword endpoint
app.post('/forgetpw', async (req, res) => {
  const { username } = req.body;
  let phoneNumber; // Declare phoneNumber outside of the try block

  try {
    // Check if user exists
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // If user is found, generate OTP and send it to phone number
    phoneNumber = user.phone; // Assign value to phoneNumber
    if (!phoneNumber) {
      return res.status(400).json({ success: false, message: 'Phone number is not available for this user.' });
    }

    if (!phoneNumber.startsWith('+91')) { 
      phoneNumber = `+91${phoneNumber}`;
    }
    const otp = generateOTP();
    otpStore[phoneNumber] = otp; // Store OTP temporarily

    // Log the OTP for testing purposes
    console.log(`Generated OTP for phone ${phoneNumber}: ${otp}`);

    // Send OTP via Twilio
    const twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
    await twilioClient.messages.create({
      body: `Your OTP is: ${otp}`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: phoneNumber,
    });

    // Respond with a success message
    return res.status(200).json({ success: true, message: 'OTP sent successfully.' });
    
  } catch (error) {
    console.error('Error sending OTP:', error);

    // Check if the error is due to an unverified number
    if (error.code === 21608) {
      // Log the attempted OTP send
      console.log(`Attempted to send OTP to unverified number ${phoneNumber}.`);
      // Respond with a success message for testing
      return res.status(200).json({ success: true, message: 'OTP generation successful, but number is unverified.',phoneNumber });
    }

    // Handle other types of errors
    res.status(500).json({ success: false, error: 'Failed to send OTP.' });
  }
});

// Endpoint to reset password
app.post('/reset-password', async (req, res) => {
  const { username, new_password, confirm_password } = req.body;

  // Check if both passwords match
  if (new_password !== confirm_password) {
    return res.status(400).json({ success: false, message: 'Passwords do not match!' });
  }

  // Validate password format (minimum 8 characters, letters, numbers, special characters)
  const passwordPattern = /^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;
  if (!passwordPattern.test(new_password)) {
    return res.status(400).json({
      success: false,
      message: 'Password must be at least 8 characters long, contain letters, numbers, and special characters.',
    });
  }

  try {
    // Fetch user by username
    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(new_password, 10);

    // Update the user's password in the database
    user.password = hashedPassword;
    await user.save();

    return res.status(200).json({ success: true, message: 'Password reset successfully!' });
  } catch (error) {
    console.error('Error resetting password:', error);
    return res.status(500).json({ success: false, message: 'An error occurred. Please try again.' });
  }
});

// Login endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    try {
      const user = await User.findOne({ username });
  
      if (user) {
        const match = await bcrypt.compare(password, user.password);
        if (match) {
          if (user.activation === 0) {
            return res.status(200).json({ success: false, message: 'Account not activated' });
          }
          res.status(200).json({ success: true, userType: user.user_type, name: user.name});
        } else {
          res.status(401).json({ success: false, message: 'Invalid credentials' });
        }
      } else {
        res.status(401).json({ success: false, message: 'Invalid credentials' });
      }
    } catch (err) {
      console.error('Error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
  
  // Signup endpoint
  app.post('/signup', async (req, res) => {
    const { name, phone, address, jobTitle, email, password, raID } = req.body; // Include RaID
    let username = name.toLowerCase().replace(/\s+/g, ''); // Generate username
    const userType = 'user'; // Default user type
    const imageID = 1;
  
    try {
      const existingUser = await User.findOne({ raID }); // Check for existing RaID
      if (existingUser) {
        return res.status(400).json({ error: 'Ration Card Number already exists.' });
      }
      
      const nextId = await getNextSequenceValue('users');  
      let usernameExists = await User.findOne({ username });
      while (usernameExists) {
          username = `${username}${nextId}`; // Append number to username if it exists
          usernameExists = await User.findOne({ username });
      }
  
      const hashedPassword = await bcrypt.hash(password, saltRounds);
        
      const newUser = new User({
        id: nextId,
        username,
        name,
        phone,
        address,
        job_title: jobTitle,
        email,
        password: hashedPassword,
        user_type: userType,
        raID,
        photoID:imageID,
      });
  
      await newUser.save();
      res.status(200).json({ message: 'User registered successfully. Awaiting activation.' });
    } catch (err) {
      console.error('Error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
});


// Fetch locations endpoint
app.get('/locations', async (req, res) => {
    try {
      // Fetch all documents from the 'places' collection
      const locations = await Place.find({}, 'id place_name'); // The second argument specifies the fields to return
  
      if (locations.length === 0) {
        return res.status(404).json({ message: 'No locations found' });
      }
  
      res.status(200).json(locations);
    } catch (err) {
      console.error('Database query error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // API to get user details by username
  app.get('/user/:username', async (req, res) => {
    try {
      const username = req.params.username;
  
      // Find the user by username
      const user = await User.findOne({ username: username });
  
      if (!user) {
        return res.status(404).json({ message: 'User not found' });
      }
  
      // Find the place associated with the user's address
      const place = await Place.findOne({ place_name: user.address });
  
      if (place) {
        // Include place_id in the response
        const { password, ...userDetails } = user.toObject();
        userDetails.place_id = place.id; // Add place_id to the response
        return res.status(200).json(userDetails);
      } else {
        // If no place is found with the given address
        const { password, ...userDetails } = user.toObject();
        return res.status(200).json(userDetails);
      }
    } catch (error) {
      res.status(500).json({ message: 'An error occurred', error: error.message });
    }
  });

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
