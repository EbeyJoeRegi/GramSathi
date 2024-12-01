const express = require('express');
const moment = require('moment');
const axios = require('axios');
const router = express.Router();
const { User, Announcement, Suggestion, Query, Place, Crop, Price, Counter, Weather, Sell, Buy } = require('./models');

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

const API_KEY = process.env.WEATHER_KEY;

// Fetch Weather
router.get('/weather', async (req, res) => {
  const { username, lat, lon } = req.query;

  // Ensure username, latitude, and longitude are provided
  if (!username || !lat || !lon) {
    return res.status(400).send('Username, latitude, and longitude are required.');
  }

  try {
    // Check if weather data exists for the given username
    let weather = await Weather.findOne({ username });

    // If no weather data exists for the username
    if (!weather) {
      // Calculate the next sequence value for the weather data
      const newWeatherId = await getNextSequenceValue('weather');

      // Fetch the weather data for the given latitude and longitude
      const weatherResponse = await axios.get(
        `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&appid=${API_KEY}`
      );

      if (weatherResponse.status === 200) {
        const temp = weatherResponse.data.main.temp;
        const weatherCondition = weatherResponse.data.weather[0].main;
        const cityName = weatherResponse.data.name; // Extract the city name

        // Create new weather data with fetched temperature and city
        weather = new Weather({
          id: newWeatherId,
          username,
          temperature: `${temp.toFixed(1)}°C`,
          weatherCondition: `${weatherCondition}`,
          city: `${cityName}`, // Store the city name
          lastUpdated: new Date(), // Ensure updatedAt is set correctly
        });

        // Save the new weather data to the database
        await weather.save();

        return res.json(weather); // Send the new weather data to the frontend
      } else {
        return res.status(500).send('Failed to fetch weather data from API');
      }
    }

    // If the user already exists, check the time gap between last update and now
    const lastUpdated = moment(weather.lastUpdated);
    const now = moment();
    const diffMinutes = now.diff(lastUpdated, 'minutes');

    if (diffMinutes < 30) {
      // If data is recent (less than 30 minutes), send the existing weather data
      return res.json(weather);
    }

    // If data is older than 30 minutes, fetch new weather data
    const weatherResponse = await axios.get(
      `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&appid=${API_KEY}`
    );

    if (weatherResponse.status === 200) {
      const temp = weatherResponse.data.main.temp;
      const weatherCondition = weatherResponse.data.weather[0].main;
      const cityName = weatherResponse.data.name;

      // Update the weather data with new temperature and city
      weather.temperature = `${temp.toFixed(1)}°C`;
      weather.weatherCondition = `${weatherCondition}`;
      weather.city = `${cityName}`; // Update the city name
      weather.lastUpdated = new Date(); // Make sure to update updatedAt

      // Save the updated weather data
      await weather.save();

      return res.json(weather); // Send the updated weather data to the frontend
    } else {
      return res.status(500).send('Failed to fetch weather data from API');
    }
  } catch (error) {
    console.error('Error occurred:', error);
    res.status(500).send('An error occurred while fetching weather data.');
  }
});

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

//Crop sell
router.post('/sell', async (req, res) => {
  try {
    const { sellername, cropname, quantity, price } = req.body; // Use req.body for JSON payload

    // Get the next sequence ID using the getNextSequenceValue function
    const sellId = await getNextSequenceValue('Sell'); // 'sell_sequence' is the name of the sequence

    // Create a new Sell entry, including the sequence ID
    const newSell = new Sell({
      id: sellId,  // Using the sequence ID as the document's _id
      sellername,
      cropname,
      quantity,
      price,
    });

    // Save the new sell entry to the database
    await newSell.save();

    res.status(200).json({ message: 'Crop listed for sale successfully', sell: newSell });
  } catch (err) {
    res.status(500).json({ error: 'Error creating sell entry', details: err.message });
  }
});

//Fetch Crops for Buying
router.get('/sell', async (req, res) => {
  try {
    // Extract query parameters
    const { sellername, sold } = req.query;

    // Build the query object based on parameters
    let query = { sellername };

    // If 'sold' parameter is provided, filter by its value
    if (sold !== undefined) {
      query.sold = sold === 'true';  // Convert 'true'/'false' to Boolean
    }

    // Fetch the data from the database
    const sellRecords = await Sell.find(query);

    // Return the results
    if (sellRecords.length > 0) {
      res.json(sellRecords);
    } else {
      res.status(404).json({ message: 'No records found' });
    }
  } catch (error) {
    console.error('Error fetching data:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

//filter for sell - buy screen
router.get('/sell/filter', async (req, res) => {
  try {
    const { filter, username } = req.query;
    const users = username;

    // Ensure the filter is valid
    if (!filter || !['my-village', 'all-village'].includes(filter)) {
      return res.status(400).json({ error: 'Invalid filter value' });
    }

    // If the filter is 'my-village', username is required
    if (filter === 'my-village' && !username) {
      return res.status(400).json({ error: 'Username is required for my-village filter' });
    }

    let query = { sold: false }; // Default to only unsold items

    // If the filter is 'my-village', apply location-based filtering
    if (filter === 'my-village') {
      // Fetch the user's details based on the provided username
      const user = await User.findOne({ username });
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      // Fetch all usernames associated with the same address (same village)
      const sameLocationUsers = await User.find({ address: user.address }).select('username');
      const usernamess = sameLocationUsers.map((u) => u.username);
      const usernames = usernamess.filter(username => username !== users);

      // Update query to filter by the seller's usernames in the same village
      query.sellername = { $in: usernames };
    }

    // Fetch the sell items based on the query
    const sellItems = await Sell.find(query).lean(); // Use lean() to get plain JS objects
    const filteredSellItems = sellItems.filter(item => item.sellername !== users);
    // Fetch user details for each sell item
    const sellerDetails = await User.find({
      username: { $in: filteredSellItems.map(item => item.sellername) }
    }).select('username name phone address');

    // Map user details to the sell items
    const sellItemsWithDetails = filteredSellItems.map(item => {
      const seller = sellerDetails.find(user => user.username === item.sellername);
      return {
        ...item,
        sellerDetails: seller || {} // Add user details or default to empty object
      };
    });

    return res.json(sellItemsWithDetails);

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'An error occurred while fetching sell items' });
  }
});

//Mark a Crop as Sold
router.put('/sell/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const updatedSell = await Sell.findOneAndUpdate(
      { id: id },
      { sold: true },
      { new: true }  // Return the updated document
    );

    if (!updatedSell) {
      return res.status(404).json({ error: 'Crop not found' });
    }

    res.status(200).json({ message: 'Crop marked as sold', sell: updatedSell });
  } catch (err) {
    res.status(500).json({ error: 'Error updating sell entry', details: err });
  }
});

//Fetch Purchase History
router.get('/buy', async (req, res) => {
  try {
    const { buyername } = req.query;

    // Find purchases where buyername matches and buy is true
    const purchases = await Buy.find({ buyername, buy: true });

    // Manually populate the `sell_id` field using the custom `id` field in Sell
    const populatedPurchases = await Promise.all(
      purchases.map(async (purchase) => {
        // Find the corresponding Sell document based on the custom `id` field
        const sell = await Sell.findOne({ id: purchase.sell_id });

        if (sell) {
          // Create a plain object copy of the purchase to avoid issues with Mongoose immutability
          const purchaseObj = purchase.toObject();

          // Look up the seller's information from the User table using sellername
          const user = await User.findOne({ username: sell.sellername });

          if (user) {
            // Add seller's address to the sell_info field
            purchaseObj.sell_info = {
              cropname: sell.cropname,
              price: sell.price,
              quantity: sell.quantity,
              address: user.address,  // Add the seller's address
            };
          } else {
            purchaseObj.sell_info = {
              cropname: sell.cropname,
              price: sell.price,
              quantity: sell.quantity,
              address: null,  // Optional: handle case where no matching user is found
            };
          }

          return purchaseObj;
        } else {
          // Optional: handle case where no matching sell is found
          purchase.sell_info = null;
          return purchase;  // Use the original purchase if no matching sell
        }
      })
    );

    // Return the populated purchases along with cropname, price, quantity, and seller's address
    res.status(200).json(populatedPurchases);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching purchases', details: err });
  }
});


//Notification to seller
router.get('/notify', async (req, res) => {
  const { username } = req.query; // Get the username from query parameters
  try {
    // Step 1: Fetch notifications where the seller is the current user and buy is false
    const notifications = await Buy.find({
      sellername: username,
      buy: false, // Only fetch notifications where buy is false
    });

    // Step 2: For each notification, fetch the buyer's phone number and the crop name
    const updatedNotifications = await Promise.all(notifications.map(async (notification) => {
      // Fetch the buyer's phone number from the User schema
      const buyer = await User.findOne({ username: notification.buyername });

      // Fetch the crop name from the Sell schema based on sell_id
      const sell = await Sell.findOne({ id: notification.sell_id });

      // Add phone number and crop name to the notification
      return {
        ...notification.toObject(),
        buyerphone: buyer ? buyer.phone : null, // Add buyer's phone or null if not found
        cropname: sell ? sell.cropname : null, // Add crop name or null if not found
      };
    }));

    // Step 3: Return the updated notifications
    res.status(200).json(updatedNotifications);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

//Notify Seller About Buyer's Interest
router.post('/notify', async (req, res) => {
  try {
    const { buyername, sellername, sell_id } = req.body;

    // Convert sell_id to a number
    const numericSellId = Number(sell_id);

    // Check if the sell entry exists
    const sellEntry = await Sell.findOne({ id: numericSellId });
    if (!sellEntry) {
      return res.status(404).json({ error: 'Sell entry not found' });
    }

    // Check if a notification with the same buyer, seller, and sell_id already exists
    const existingNotification = await Buy.findOne({
      buyername,
      sellername,
      sell_id: numericSellId,
    });

    if (existingNotification) {
      return res.status(400).json({
        error: 'Notification already exists for this buyer, seller, and sell_id combination.',
      });
    }

    // Generate buyId using sequence function
    const buyId = await getNextSequenceValue('Buy');

    // Create a new notification for the Buy collection
    const newNotification = new Buy({
      id: buyId, // Use custom id
      sellername,
      buyername,
      sell_id: numericSellId, // Ensure sell_id is stored as a number
      buy: false, // Default value
    });

    await newNotification.save();

    res.status(201).json({
      message: 'Notification sent to the seller and saved successfully',
      notification: newNotification,
    });
  } catch (err) {
    console.error('Error:', err);
    res.status(500).json({ error: 'Error creating notification', details: err });
  }
});

// Mark notification as bought
router.put('/notify/:id', async (req, res) => {
  const { id } = req.params;  // id is a number, as per your schema
  try {
    // Find the document by id first
    const notification = await Buy.findOne({ id: parseInt(id) });

    if (!notification) {
      return res.status(404).send('Notification not found');
    }

    // Ensure that 'buy' is false before updating it to true
    if (notification.buy === true) {
      return res.status(400).send('Buy status is already true');
    }

    // Proceed with the update if 'buy' is false
    notification.buy = true;
    await notification.save();  // Save the updated notification

    res.json(notification);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

// Delete notification
router.delete('/notify/:id', async (req, res) => {
  const { id } = req.params;  // id is a number, as per your schema
  try {
    // Find the document first
    const notification = await Buy.findOne({ id: parseInt(id) });

    if (!notification) {
      return res.status(404).send('Notification not found');
    }

    // Check if the 'buy' field is false before deleting
    if (notification.buy === true) {
      return res.status(400).send('Cannot delete: Buy status is true');
    }

    // Proceed with the deletion if 'buy' is false
    await Buy.findOneAndDelete({ id: parseInt(id) });

    res.send('Notification deleted');
  } catch (err) {
    console.error(err);
    res.status(500).send('Server Error');
  }
});

module.exports = router;