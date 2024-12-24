const express = require('express');
const router = express.Router();
const nodemailer = require('nodemailer');
const dotenv = require('dotenv');
const { User, Announcement, Suggestion, Query, Place, Crop, Price, Counter } = require('./models');

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
//retrival from /user/announcements

//admin create announcements
router.post('/createAnnouncement', async (req, res) => {
  const { admin, title, content } = req.body;

  try {
    // Log incoming request
    console.log('Incoming request:', req.body);

    // Get the next ID value
    const announcementId = await getNextSequenceValue('announcements');
    console.log('Generated Announcement ID:', announcementId);

    // Create and save the new announcement
    const newAnnouncement = new Announcement({
      id: announcementId, // Use the auto-incremented ID
      admin,
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


// Delete announcement endpoint
router.delete('/deleteAnnouncement/:id', async (req, res) => {
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
router.put('/updateAnnouncement/:id', async (req, res) => {
  const { id } = req.params;
  const { admin, title, content } = req.body;

  try {
    // Convert the id to a number if it's not already
    const announcementId = Number(id);

    // Update the announcement by the 'id' field
    const result = await Announcement.findOneAndUpdate(
      { id: announcementId }, // Use 'id' field for query
      { admin, title, content },
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
router.post('/activate-user', async (req, res) => {
  const { user_id, admin } = req.body; // Admin is assumed to be the admin's username

  try {
    // Retrieve details of the activated user
    const user = await User.findOne({ id: user_id });
    if (!user) {
      return res.status(404).json({ error: 'User details not found' });
    }

    // Retrieve details of the admin user
    const adminDetails = await User.findOne({ username: admin });
    if (!adminDetails) {
      return res.status(404).json({ error: 'Admin not found' });
    }

    // Email data
    const emailSubject = 'Your Account Has Been Activated';
    const emailText = `
      Hi ${user.name},

      Your account has been activated for the village ${user.address}. 
      You can now log in using the credentials you provided during signup.

      Username: ${user.username}

      Welcome to GramSathi!

      With warm regards,
      ${adminDetails.name} 
      ${user.address}
    `;

    // Create a transporter using your SMTP server credentials (you may want to use environment variables for this)
    const transporter = nodemailer.createTransport({
      service: 'gmail', // You can use any SMTP service here (Gmail, SendGrid, etc.)
      auth: {
        user: process.env.EMAIL_USER, // Set your email ID (should be in .env)
        pass: process.env.EMAIL_PASS, // Set your email password (should be in .env)
      },
    });

    // Define email options
    const mailOptions = {
      from: process.env.EMAIL_ID, // The email ID you want to send from
      to: user.email, // The recipient's email address
      subject: emailSubject,
      text: emailText, // The plain text content of the email
    };

    // Send the email
    await transporter.sendMail(mailOptions);
    
    // Update the user activation status
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
router.post('/deactivate-user', async (req, res) => {
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
router.get('/pending-users', async (req, res) => {
  try {
    const { username } = req.query; // Get username from query parameters

    if (!username) {
      return res.status(400).json({ message: 'Username is required' });
    }

    // Find the user with the given username
    const user = await User.findOne({ username });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userAddress = user.address; // Get the address of the user

    // Find pending users from the same address
    const users = await User.find({ activation: 0, address: userAddress });

    if (users.length === 0) {
      return res.status(404).json({ message: 'No pending users found from this address' });
    }

    res.status(200).json(users);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all queries
router.get('/admin/queries', async (req, res) => {
  try {
    const { username, type } = req.query; // Get username from request query

    if (!username) {
      return res.status(400).json({ error: 'Username is required' });
    }

    // Step 1: Get the address of the user with the given username
    const adminUser = await User.findOne({ username });

    if (!adminUser || !adminUser.address) {
      return res.status(404).json({ error: 'Admin user or address not found' });
    }

    const location = adminUser.address;

    // Step 2: Get all users with the same address and user_type='user'
    const usersInLocation = await User.find({
      address: location,
      user_type: 'user'
    }).select('username');

    const userUsernames = usersInLocation.map(user => user.username);

    if (userUsernames.length === 0) {
      return res.status(404).json({ error: 'No users found in this location' });
    }

    // Step 3: Get all queries of type=1 for the retrieved usernames
    const queries = await Query.find({
      username: { $in: userUsernames },
      type: type
    }).sort({ time: -1 });

    res.status(200).json(queries);
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Respond to a query
router.put('/admin/respondQuery/:id', async (req, res) => {
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

//Retrieve Suggestions from /users/suggestion

// Respond to suggestion endpoint
router.post('/respondSuggestion', async (req, res) => {
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

// Location retrival from server/location
// Crops retrival from user/crops/:placeId

// Fetch all crops with their average prices
router.get('/all-crops', async (req, res) => {
  try {
    const crops = await Crop.find({}); // Find all crops
    res.status(200).json(crops);
  } catch (err) {
    console.error('Database query error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Update crop price
router.post('/update-price/:id', async (req, res) => {
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
router.post('/add-price', async (req, res) => {
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
router.post('/update-average-price', async (req, res) => {
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
router.post('/add-crop', async (req, res) => {
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

// Get all admin users
router.get('/admin/users', async (req, res) => {
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
router.post('/remove-admin', async (req, res) => {
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
router.post('/add-admin', async (req, res) => {
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
router.get('/users', async (req, res) => {
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
router.post('/remove-user', async (req, res) => {
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

// Get all announcements posted by administrators
router.get('/announcement-administrator', async (req, res) => {
  try {
    // Find all users with user_type 'administrator'
    const admins = await User.find({ user_type: 'administrator' });

    // If no administrators found, return an empty list
    if (!admins || admins.length === 0) {
      return res.status(404).json({ message: 'No administrators found' });
    }

    // Extract the admin usernames (you can use '_id' or 'username' to filter by)
    const adminUsernames = admins.map(admin => admin.name);

    // Find all announcements posted by these administrators
    const announcements = await Announcement.find({ admin: { $in: adminUsernames } });

    // If no announcements found, return an empty list
    if (announcements.length === 0) {
      return res.status(404).json({ message: 'No announcements found for administrators' });
    }

    // Return the found announcements
    return res.status(200).json(announcements);
  } catch (error) {
    console.error(error);
    return res.status(500).json({ message: 'Server error', error: error.message });
  }
});

module.exports = router;

