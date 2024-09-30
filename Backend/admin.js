const express = require('express');
const router = express.Router();
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
router.post('/activate-user', async (req, res) => {
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

module.exports = router;

