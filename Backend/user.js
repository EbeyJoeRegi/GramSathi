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
    try {
      const announcements = await Announcement.find().sort({ created_at: -1 });
      res.status(200).json(announcements);
    } catch (err) {
      console.error('Error:', err);
      res.status(500).json({ error: 'Internal server error' });
    }
  });

module.exports = router;