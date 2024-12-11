const express = require('express');
const bcrypt = require('bcrypt');
const nodemailer = require('nodemailer');
const router = express.Router();
const dotenv = require('dotenv');
dotenv.config();
const { User, Announcement, Suggestion, Query, Place, Crop, Price, Counter, Weather, Sell, Buy, Image } = require('./models');

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

// Fetch the names of users meeting the conditions
router.get('/admin-presidents', async (req, res) => {
    try {
        const users = await User.aggregate([
            {
                $match: {
                    user_type: 'admin',
                    job_title: 'President',
                },
            },
            {
                $lookup: {
                    from: 'places', // The name of the collection for places
                    localField: 'address', // The field from the User schema to match
                    foreignField: 'place_name', // The field in the Place schema to match
                    as: 'matchedPlace', // The array to store matching place records
                },
            },
            {
                $unwind: '$matchedPlace', // Flatten the matched place array
            },
            {
                $project: {
                    name: 1, // Include the user's name in the result,
                    photoID: 1,
                    place_name: '$matchedPlace.place_name', // Include the place name from the matchedPlace
                },
            },
        ]);

        // Return the list of objects with both user names and their corresponding place names
        res.json(users);
    } catch (err) {
        console.error('Error fetching users:', err);
        res.status(500).json({ message: 'An error occurred while fetching users.' });
    }
});

// Count the number of users 
router.get('/count-users/:place_name', async (req, res) => {
    try {
        const { place_name } = req.params;

        // Count the number of users with `user_type = 'user'` in the corresponding place
        const count = await User.aggregate([
            {
                $match: {
                    user_type: 'user',
                },
            },
            {
                $lookup: {
                    from: 'places', // Join with the places collection
                    localField: 'address', // Match user address with place_name
                    foreignField: 'place_name',
                    as: 'matchedPlace',
                },
            },
            {
                $unwind: '$matchedPlace',
            },
            {
                $match: {
                    'matchedPlace.place_name': place_name, // Filter by the place_name passed in the URL
                },
            },
            {
                $count: 'userCount', // Count the users
            },
        ]);

        if (count.length === 0) {
            return res.status(404).json({ message: `No users found in place: ${place_name}` });
        }

        res.json({ place_name, userCount: count[0].userCount });
    } catch (err) {
        console.error('Error counting users:', err);
        res.status(500).json({ message: 'An error occurred while counting users.' });
    }
});

// Get all admin users for a given place
router.get('/all-admins/:place_name', async (req, res) => {
    try {
        const { place_name } = req.params;

        const admins = await User.aggregate([
            {
                $match: {
                    user_type: 'admin',
                },
            },
            {
                $lookup: {
                    from: 'places', // Join with the places collection
                    localField: 'address', // Match user address with place_name
                    foreignField: 'place_name',
                    as: 'matchedPlace',
                },
            },
            {
                $unwind: '$matchedPlace',
            },
            {
                $match: {
                    'matchedPlace.place_name': place_name, // Filter by the place_name passed in the URL
                },
            },
            {
                $project: {
                    name: 1, // Include name field
                    phone: 1, // Include phone number
                    email: 1, // Include email
                    job_title: 1, // Include job title
                    photoID: 1,
                },
            },
        ]);

        if (admins.length === 0) {
            return res.status(404).json({ message: `No admin users found in place: ${place_name}` });
        }

        res.json(admins);
    } catch (err) {
        console.error('Error fetching admin users:', err);
        res.status(500).json({ message: 'An error occurred while fetching admin users.' });
    }
});

//Add village to place collection
router.post('/add-place', async (req, res) => {
    try {
        const { place_name } = req.body;

        // Check if place_name is provided
        if (!place_name) {
            return res.status(400).send('Place name is required.');
        }

        // Check if the place_name already exists in the collection
        const existingPlace = await Place.findOne({ place_name: place_name });
        if (existingPlace) {
            return res.status(400).send('Place with this name already exists.');
        }

        const placeId = await getNextSequenceValue('places');  
        const newPlace = new Place({
            id: placeId,
            place_name: place_name,
        });
        await newPlace.save();
        res.status(200).send('Village added successfully.');
    } catch (err) {
        res.status(500).send('Error adding village: ' + err.message);
    }
});

// Add admin user
router.post('/add-admin-user', async (req, res) => {
    try {
        const { name, password, phone, email, address, raID } = req.body;

        // Check if all required fields are provided
        if (!name || !password || !phone || !email || !address || !raID) {
            return res.status(400).send('All fields (name, password, phone, email, address, raID) are required.');
        }

        const userId = await getNextSequenceValue('users');  
        let username = name.toLowerCase().replace(/\s+/g, '');
        let existingUser = await User.findOne({ username });

        // If username exists, append the user ID to ensure it's unique
        if (existingUser) {
            username = username.substring(0, 4) + userId;
            existingUser = await User.findOne({ username });
            // In case the new username is still taken (highly unlikely but possible)
            if (existingUser) {
                return res.status(400).send('Generated username already exists. Please choose a different name.');
            }
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Create new admin user
        const newUser = new User({
            id: userId,
            username,
            name,
            phone,
            address,
            job_title: 'President',
            email,
            password: hashedPassword,
            activation: 1,
            user_type: 'admin',
            raID,
            photoID: 2  // Default photo ID
        });

        // Save the new user
        await newUser.save();
        res.status(200).send({ message: 'Admin user added successfully.', username: username });
        
    } catch (err) {
        console.error(err);  // Log the error for debugging
        res.status(500).send('Error adding admin user: ' + err.message);
    }
});


// Send welcome email to new panchayath
router.post('/send-email', async (req, res) => {
    try {
        const { name, email, place, username, password } = req.body;
        if (!name || !email || !place || !username || !password) {
            return res.status(400).send('All fields are required: name, email, place, username, and password.');
        }

        // Create transporter for sending the email
        const transporter = nodemailer.createTransport({
            service: 'Gmail',
            auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS,
            }
        });

        // Define the email options with dynamic values
        const mailOptions = {
            from: process.env.EMAIL_USER,
            to: email,
            subject: 'Welcome to Gramsathi',
            text: `Hi ${name},

Panchayath ${place} has been added to the Gramsathi application. 
Welcome onboard as the President.

Login Credentials:
Username: ${username}
Password: ${password}

Do not share your credentials. Change the password using the forgot password option.

With warm regards,
Gramsathi Administrator`
        };

        // Send the email
        const info = await transporter.sendMail(mailOptions);

        // Check if the email was successfully sent
        if (info.accepted.length > 0) {
            res.status(200).send('Email sent successfully.');
        } else {
            res.status(500).send('Error sending email: Email was not accepted.');
        }
    } catch (err) {
        // Catch and respond with any error that occurs during the email sending process
        res.status(500).send('Error sending email: ' + err.message);
    }
});

module.exports = router;
