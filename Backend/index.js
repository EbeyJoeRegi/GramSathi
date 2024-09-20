const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const bcrypt = require('bcrypt');

const app = express();
const port = 3000;
const saltRounds = 10;

// MongoDB connection
mongoose.connect('mongodb://localhost:27017/village_app')
  .then(() => {
    console.log('Connected to MongoDB');
  })
  .catch(err => {
    console.error('Database connection error:', err);
  });

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Define schemas and models
const userSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  username: { type: String, unique: true, required: true },
  name: String,
  phone: String,
  address: String,
  job_title: String,
  email: String,
  password: String,
  activation: { type: Number, default: 0 },
  user_type: { type: String, default: 'user' }
});

const announcementSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  title: String,
  content: String,
  created_at: { type: Date, default: Date.now }
});

const suggestionSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  title: String,
  content: String,
  username: String,
  created_at: { type: Date, default: Date.now },
  response: String
});

const querySchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  username: String,
  matter: String,
  time: { type: Date, default: Date.now },
  admin_response: String
});

const placeSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  place_name: String
});

const cropSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  crop_name: { type: String, required: true },
  avg_price: { type: mongoose.Schema.Types.Mixed, required: true },
});

const priceSchema = new mongoose.Schema({
  id: { type: Number, unique: true },
  place_id: { type: Number, ref: 'Place', required: true },
  crop_id: { type: Number, ref: 'Crop', required: true },
  price: mongoose.Schema.Types.Mixed,
  month_year: String
});

const counterSchema = new mongoose.Schema({
  _id: String,
  sequence_value: Number
});

const User = mongoose.model('User', userSchema);
const Announcement = mongoose.model('Announcement', announcementSchema);
const Suggestion = mongoose.model('Suggestion', suggestionSchema);
const Query = mongoose.model('Query', querySchema);
const Place = mongoose.model('Place', placeSchema);
const Crop = mongoose.model('Crop', cropSchema);
const Price = mongoose.model('Price', priceSchema);
const Counter = mongoose.model('Counter', counterSchema);

//auto incement
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
  const { username, name, phone, address, jobTitle, email, password } = req.body;
  const userType = 'user'; // Default user type

  try {
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ error: 'Try using different username' });
    }

    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Get the next ID value
    const nextId = await getNextSequenceValue('users');

    const newUser = new User({
      id: nextId,
      username,
      name,
      phone,
      address,
      job_title: jobTitle,
      email,
      password: hashedPassword,
      user_type: userType
    });

    await newUser.save();
    res.status(200).json({ message: 'User registered successfully. Awaiting activation.' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


//admin create announcements
app.post('/createAnnouncement', async (req, res) => {
  const { title, content } = req.body;

  try {
    // Log incoming request
    console.log('Incoming request:', req.body);

    // Get the next ID value
    const announcementId = await getNextSequenceValue('announcements');
    console.log('Generated Announcement ID:', announcementId);

    // Create and save the new announcement
    const newAnnouncement = new Announcement({
      id: announcementId, // Use the auto-incremented ID
      title,
      content
    });
    
    console.log('New Announcement:', newAnnouncement);

    await newAnnouncement.save();
    res.status(200).json({ message: 'Announcement created successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Retrieve announcements endpoint
app.get('/announcements', async (req, res) => {
  try {
    const announcements = await Announcement.find().sort({ created_at: -1 });
    res.status(200).json(announcements);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete announcement endpoint
app.delete('/deleteAnnouncement/:id', async (req, res) => {
  const { id } = req.params;

  try {
    // Find by 'id' field instead of '_id'
    const result = await Announcement.findOneAndDelete({ id: Number(id) });

    if (result) {
      res.status(200).json({ message: 'Announcement deleted successfully' });
    } else {
      res.status(404).json({ message: 'Announcement not found' });
    }
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update announcement endpoint
app.put('/updateAnnouncement/:id', async (req, res) => {
  const { id } = req.params;
  const { title, content } = req.body;

  try {
    // Convert the id to a number if it's not already
    const announcementId = Number(id);

    // Update the announcement by the 'id' field
    const result = await Announcement.findOneAndUpdate(
      { id: announcementId }, // Use 'id' field for query
      { title, content },
      { new: true } // Option to return the updated document
    );

    if (result) {
      res.status(200).json({ message: 'Announcement updated successfully', data: result });
    } else {
      res.status(404).json({ message: 'Announcement not found' });
    }
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Activate user endpoint
app.post('/activate-user', async (req, res) => {
  const { user_id } = req.body;

  try {
    const result = await User.updateOne({ id: user_id }, { activation: 1 }); // Use the custom 'id' field
    if (result.nModified === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json({ message: 'User activated successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Deactivate user endpoint
app.post('/deactivate-user', async (req, res) => {
  const { user_id } = req.body;

  try {
    await User.deleteOne({ id: user_id }); // Use the custom 'id' field
    res.status(200).json({ message: 'User deactivated successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Endpoint to get pending users
app.get('/pending-users', async (req, res) => {
  try {
    const users = await User.find({ activation: 0 });

    if (users.length === 0) {
      return res.status(404).json({ message: 'No pending users found' });
    }

    res.status(200).json(users);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/* wait here */

// Respond to suggestion endpoint
app.post('/respondSuggestion', async (req, res) => {
  const { id, response } = req.body;

  try {
    // Update the suggestion with the specified id
    const result = await Suggestion.updateOne({ id: id }, { response: response });
    // Successfully updated
      res.status(200).json({ message: 'Suggestion responded successfully' });
    
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all queries
app.get('/admin/queries', async (req, res) => {
  try {
    const queries = await Query.find().sort({ time: -1 });
    res.status(200).json(queries);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create a new query
app.post('/createQuery', async (req, res) => {
  const { username, matter, time } = req.body;

  try {
    const queryId = await getNextSequenceValue('queries'); // Get the next sequence value for the query ID
    const newQuery = new Query({
      id: queryId,
      username,
      matter,
      time
    });

    await newQuery.save(); // Save the new query to the database
    res.sendStatus(200);
  } catch (err) {
    console.error(err);
    res.status(500).send('Failed to create query');
  }
});

// Respond to a query
app.put('/admin/respondQuery/:id', async (req, res) => {
  const { id } = req.params;
  const { response } = req.body;

  try {
    // Use findOneAndUpdate to update by custom id field
    const result = await Query.findOneAndUpdate(
      { id: parseInt(id, 10) }, // Assuming id is a number
      { admin_response: response },
      { new: true } // Return the updated document
    );

    if (!result) {
      return res.status(404).json({ error: 'Query not found' });
    }

    res.status(200).json({ message: 'Query responded successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Get all admin users
app.get('/admin/users', async (req, res) => {
  try {
    const excludedId = 19; // Use a number if your custom `id` field is a number

    const admins = await User.find({ 
      user_type: 'admin',
      id: { $ne: excludedId } // Exclude the user with id 19
    });

    res.status(200).json(admins);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Remove an admin user
app.post('/remove-admin', async (req, res) => {
  const { user_id } = req.body;

  try {
    // Delete the user with the specified id and user_type 'admin'
    const result = await User.deleteOne({ id: user_id, user_type: 'admin' });

    if (result.deletedCount === 0) {
      // No document was deleted
      res.status(404).json({ message: 'Admin not found or not an admin' });
    } else {
      // Successfully deleted
      res.status(200).json({ message: 'Admin removed successfully' });
    }
  } catch (err) {
    console.error('Database query error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});


// Add an admin user
app.post('/add-admin', async (req, res) => {
  const { username, password, name, phone, address, job_title, email } = req.body;
  const activation = 1; // Activation status for new admins
  const userType = 'admin'; // User type for new admins

  try {
    // Check if the username already exists
    const existingUser = await User.findOne({ username });
    if (existingUser) {
      return res.status(400).json({ error: 'Username already exists' });
    }

    // Get the next sequence number for the ID
    const usersId = await getNextSequenceValue('users');

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, saltRounds);

    // Create a new user
    const newUser = new User({
      id: usersId,
      username,
      password: hashedPassword,
      name,
      phone,
      address,
      job_title,
      email,
      activation,
      user_type: userType
    });

    // Save the new user to the database
    await newUser.save();

    res.status(200).json({ message: 'Admin added successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all users
app.get('/users', async (req, res) => {
  try {
    const users = await User.find({
      user_type: 'user',
      activation: true
    }).select('id username name phone address job_title email');

    res.status(200).json(users);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Remove an user
app.post('/remove-user', async (req, res) => {
  const { user_id } = req.body;

  try {
    const result = await User.deleteOne({ id: user_id, user_type: 'user' });

    if (result.deletedCount > 0) {
      res.status(200).json({ message: 'User removed successfully' });
    } else {
      res.status(404).json({ message: 'User not found or not a user' });
    }
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// Add crop endpoint
app.post('/addCrop', async (req, res) => {
  const { crop_name, avg_price } = req.body;

  try {
    const newCrop = new Crop({ crop_name, avg_price });
    await newCrop.save();
    res.status(200).json({ message: 'Crop added successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update crop price endpoint
app.put('/updatePrice/:cropId', async (req, res) => {
  const { cropId } = req.params;
  const { price } = req.body;

  try {
    await Crop.findByIdAndUpdate(cropId, { avg_price: price });
    res.status(200).json({ message: 'Crop price updated successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update crop endpoint
app.put('/updateCrop/:id', async (req, res) => {
  const { id } = req.params;
  const { crop_name, avg_price } = req.body;

  try {
    await Crop.findByIdAndUpdate(id, { crop_name, avg_price });
    res.status(200).json({ message: 'Crop updated successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/* started from here */

// User profile endpoint
app.get('/user/profile', async (req, res) => {
  const { username } = req.query;

  try {
    const user = await User.findOne({ username });
    res.status(200).json(user);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update user profile endpoint
app.put('/user/profile/update', async (req, res) => {
  const { username, name, phone, address, jobTitle, email } = req.body;

  try {
    await User.findOneAndUpdate({ username }, { name, phone, address, job_title: jobTitle, email });
    res.status(200).json({ message: 'Profile updated successfully' });
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

// Get all queries for a user
app.get('/queries', async (req, res) => {
  const { username } = req.query;

  if (!username) {
    return res.status(400).json({ error: 'Username query parameter is required' });
  }

  try {
    const results = await Query.find({ username })
      .sort({ time: -1 }) // Sort by time in descending order
      .exec();

    res.json(results);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch queries' });
  }
});

// Retrieve all suggestions endpoint
app.get('/suggestions', async (req, res) => {
  try {
    // Fetch all suggestions, sorted by created_at in descending order
    const results = await Suggestion.find({})
      .sort({ created_at: -1 }) // Sort by created_at descending
      .exec();

    res.status(200).json(results);
  } catch (err) {
    console.error('Database query error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create suggestion endpoint
app.post('/createSuggestion', async (req, res) => {
  const { title, content, username } = req.body;

  try {
    // Get the next sequence value for the id
    const suggestionsId = await getNextSequenceValue('suggestions');

    // Create a new suggestion document
    const newSuggestion = new Suggestion({
      id: suggestionsId,
      title,
      content,
      username,
      created_at: new Date() // Optionally set created_at manually
    });

    // Save the document to the database
    await newSuggestion.save();

    res.status(200).json({ message: 'Suggestion submitted successfully' });
  } catch (err) {
    console.error('Database query error:', err);
    res.status(500).json({ error: 'Database error' });
  }
});


/* ----  */

// Get all places
app.get('/places', async (req, res) => {
  try {
    const places = await Place.find();
    res.status(200).json(places);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get crops by place
app.get('/crops/:placeId', async (req, res) => {
  const placeId = parseInt(req.params.placeId, 10);

  if (isNaN(placeId)) {
    return res.status(400).json({ error: 'Invalid placeId format. Ensure it is an integer.' });
  }

  try {
    const results = await Price.aggregate([
      {
        $match: { place_id: placeId }
      },
      {
        $lookup: {
          from: 'crops',
          localField: 'crop_id',
          foreignField: 'id',
          as: 'cropDetails'
        }
      },
      {
        $unwind: {
          path: '$cropDetails',
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $project: {
          _id: 0,
          crop_name: { $ifNull: ['$cropDetails.crop_name', 'Unknown'] },
          price: 1,
          month_year: 1,
          id: 1,
          avg_price: { $ifNull: ['$cropDetails.avg_price', 0] }
        }
      }
    ]);

    if (results.length === 0) {
      return res.status(200).json([]); // Return an empty array with a 200 status
    }

    res.json(results);
  } catch (err) {
    console.error('Error fetching crops:', err);
    res.status(500).json({ error: 'Failed to fetch crops' });
  }
});

// Fetch all crops with their average prices
app.get('/all-crops', async (req, res) => {
  try {
    const crops = await Crop.find({}); // Find all crops
    res.status(200).json(crops);
  } catch (err) {
    console.error('Database query error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update crop price
app.post('/update-price', async (req, res) => {
  const { id, price, month_year } = req.body;
  try {
    // Check if the document exists
    const existingPrice = await Price.findOne({ id: id });
    if (!existingPrice) {
      console.log('Document with id', id, 'not found.');
      return res.status(404).json({ error: 'Price not found' });
    }

    // Perform the update
    const result = await Price.updateOne(
      { id: id },
      { $set: { price: price, month_year: month_year } }
    );

    if (result.modifiedCount === 0) {
      console.log('No documents were modified.');
      return res.status(404).json({ error: 'Price not modified' });
    }
    res.json({ message: 'Price updated successfully' });
  } 
  catch (err) {
    console.error('Error updating price:', err);
    res.status(500).json({ error: 'Failed to update crop price' });
  }
});

// Add new price
app.post('/add-price', async (req, res) => {
  const { place_id, crop_id, price, month_year } = req.body;

  try {
    // Check if the combination of crop_id and place_id exists in the database
    const existingPrice = await Price.findOne({ place_id, crop_id });
    if (existingPrice) {
      return res.status(400).json({ error: 'Crop is already available in the location' });
    }

    // Get the next sequence value for the 'price' sequence
    const priceId = await getNextSequenceValue('price');

    // Create and save the new price document with the sequence value
    const newPrice = new Price({ id: priceId, place_id, crop_id, price, month_year });
    await newPrice.save();

    res.json({ message: 'Price added successfully' });
  } catch (err) {
    console.error('Error adding price:', err);
    res.status(500).json({ error: 'Failed to add new price' });
  }
});

// Update crop average price
app.post('/update-average-price', async (req, res) => {
  const { crop_id, average_price } = req.body;

  try {
    // Find and update the crop's average price by the crop_id
    const result = await Crop.updateOne(
      { id: crop_id },
      { $set: { avg_price: average_price } }
    );

    if (result.modifiedCount === 0) {
      return res.status(404).json({ error: 'Crop not found or no changes made' });
    }

    res.json({ message: 'Average price updated successfully' });
  } catch (err) {
    console.error('Error updating average price:', err);
    res.status(500).json({ error: 'Failed to update average price' });
  }
});

// Add new crop
app.post('/add-crop', async (req, res) => {
  const { crop_name, avg_price } = req.body;

  try {
    // Check if crop_name already exists
    const existingCrop = await Crop.findOne({ crop_name });
    if (existingCrop) {
      return res.status(400).json({ error: 'Crop already exists' });
    }

    // Get the next sequence value for the id
    const cropId = await getNextSequenceValue('crop');

    // Create a new crop entry
    const newCrop = new Crop({
      id: cropId,
      crop_name,
      avg_price
    });

    // Save the new crop to the database
    await newCrop.save();

    res.json({ message: 'Crop added successfully', crop: newCrop });
  } catch (err) {
    console.error('Error adding crop:', err); // Log error details
    res.status(500).json({ error: 'Failed to add new crop', details: err.message });
  }
});

// Fetch all admins
app.get('/admins', async (req, res) => {
    try {
      // Assuming there is a 'users' collection with a 'user_type' field for admins
      const admins = await User.find({ user_type: 'admin' }).select('name phone job_title');
      res.json(admins);
    } catch (err) {
      console.error('Error fetching admin contacts:', err);
      res.status(500).send('Server error');
    }
  });
  
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
