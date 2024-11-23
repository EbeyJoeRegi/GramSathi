const express = require('express');
const router = express.Router();
const { User, Announcement,Suggestion, Query, Place, Crop, Price, Counter } = require('./models');

// Auto increment helper function
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

// Retrieve announcements endpoint
router.get('/announcements', async (req, res) => {
  const location = req.query.place; // Assuming location is passed as a query parameter

  if (!location) {
      return res.status(400).json({ error: 'Location is required' });
  }

  try {
      // Step 1: Find all users from the specified location
      const users = await User.find({ address: location }).select('name');
      // Check if users were found
      if (!users.length) {
          return res.status(404).json({ message: 'No users found in the specified location.' });
      }

      // Extract usernames from the found users
      const name = users.map(user => user.name);

      // Step 2: Find announcements posted by these users
      const announcements = await Announcement.find({ admin: { $in: name } }).sort({ created_at: -1 });

      res.status(200).json(announcements);
  } catch (err) {
      console.error('Error:', err);
      res.status(500).json({ error: 'Internal server error' });
  }
});


// Fetch locations endpoint
router.get('/locations', async (req, res) => {
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

// Get crops by place
router.get('/crops/:placeId', async (req, res) => {
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

// Retrieve all suggestions endpoint
router.get('/suggestions', async (req, res) => {
  try {
    // Extract the username from the query parameters
    const { username } = req.query;

    // Step 1: Find the user by username to get their address
    const user = await User.findOne({ username: username });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Step 2: Get all users with the same address as the current user
    const usersInSameAddress = await User.find({ address: user.address });

    // Step 3: Extract the usernames of users in the same address
    const usernamesInSameAddress = usersInSameAddress.map(user => user.username);

    // Step 4: Fetch all suggestions for users in the same address
    const suggestions = await Suggestion.find({
      username: { $in: usernamesInSameAddress }, // Match suggestions for users in the same address
    })
      .sort({ created_at: -1 }) // Sort by created_at in descending order
      .exec();

    // Step 5: Return the suggestions
    res.status(200).json(suggestions);
  } catch (err) {
    console.error('Database query error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Create suggestion endpoint
router.post('/createSuggestion', async (req, res) => {
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

// Create a new query
router.post('/createQuery', async (req, res) => {
  const { username, matter, time, type } = req.body;

  // Validate input
  if (!username || !matter || !time || type === undefined) {
    return res.status(400).json({ error: 'All fields (username, matter, time, type) are required' });
  }

  try {
    // Ensure type is a valid number
    const typeNumber = parseInt(type, 10);
    if (isNaN(typeNumber)) {
      return res.status(400).json({ error: 'Type must be a valid number' });
    }

    // Generate a new query ID
    const queryId = await getNextSequenceValue('queries');

    // Create the new query document
    const newQuery = new Query({
      id: queryId,
      username,
      matter,
      time,
      type: typeNumber
    });

    // Save the new query to the database
    await newQuery.save();
    res.sendStatus(200);
  } catch (err) {
    console.error(err);
    res.status(500).send('Failed to create query');
  }
});

// Get all queries for a user
router.get('/queries', async (req, res) => {
  const { username, type } = req.query;

  // Validate required query parameters
  if (!username) {
    return res.status(400).json({ error: 'Username query parameter is required' });
  }

  if (!type) {
    return res.status(400).json({ error: 'Type query parameter is required' });
  }

  try {
    // Convert type to a number
    const typeNumber = parseInt(type, 10);
    if (isNaN(typeNumber)) {
      return res.status(400).json({ error: 'Type query parameter must be a valid number' });
    }

    // Query the database with filters
    const results = await Query.find({ username, type: typeNumber })
      .sort({ time: -1 }) // Sort by time in descending order
      .exec();

    res.json(results);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch queries' });
  }
});


// Fetch all admins
router.get('/admins', async (req, res) => {
  try {
    // Assuming there is a 'users' collection with a 'user_type' field for admins
    const admins = await User.find({ user_type: 'admin' }).select('name phone job_title');
    res.json(admins);
  } catch (err) {
    console.error('Error fetching admin contacts:', err);
    res.status(500).send('Server error');
  }
});

// User profile endpoint
router.get('/user/profile', async (req, res) => {
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
router.put('/user/profile/update', async (req, res) => {
  const { username, name, phone, address, jobTitle, email } = req.body;

  try {
    await User.findOneAndUpdate({ username }, { name, phone, address, job_title: jobTitle, email });
    res.status(200).json({ message: 'Profile updated successfully' });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});



module.exports = router;