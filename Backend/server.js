const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const bcrypt = require('bcrypt');
const cors = require('cors');
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

// Use routes
app.use('/', userRoutes);
app.use('/', adminRoutes);

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

// Login endpoint
app.post('/login', async (req, res) => {
    const { username, password } = req.body;
    console.log(username);
    console.log(password);
  
    try {
      const user = await User.findOne({ username });
  
      if (user) {
        const match = await bcrypt.compare(password, user.password);
        if (match) {
          if (user.activation === 0) {
            return res.status(200).json({ success: false, message: 'Account not activated' });
          }
          res.status(200).json({ success: true, userType: user.user_type });
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

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
