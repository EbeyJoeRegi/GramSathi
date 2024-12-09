const express = require('express');
const router = express.Router();
const multer = require('multer');
const fs = require('fs');
const { Counter, Image, CloudImage } = require('./models');

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

// Multer Configuration
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'uploads/');
    },
    filename: (req, file, cb) => {
        const uniqueName = Date.now() + '-' + file.originalname;
        cb(null, uniqueName);
    }
});

const upload = multer({ storage: storage });

// API Endpoint to Accept and Store Image
router.post('/upload', upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No file uploaded" });
        }

        const { filename, mimetype, path } = req.file;

        // Get Next Sequence Value
        const imageId = await getNextSequenceValue('image');

        // Save to MongoDB
        const img = new Image({
            id: imageId,
            name: filename,
            img: {
                data: fs.readFileSync(path), // Read the file
                contentType: mimetype
            }
        });

        await img.save();

        // Delete file from local storage after saving to MongoDB
        fs.unlinkSync(path);

        res.status(200).json({
            message: "Image uploaded and stored in MongoDB",
            imageId: img.id
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to upload image" });
    }
});

// Retrieve an Image
router.get('/image/:id', async (req, res) => {
    try {
        // Validate the provided ID
        const image = await Image.findOne({ id: req.params.id }); // Use custom id instead of MongoDB's ObjectId
        if (!image) return res.status(404).json({ error: "Image not found" });

        // Send the image with the correct Content-Type
        res.set('Content-Type', image.img.contentType);
        res.send(image.img.data);
    } catch (err) {
        console.error("Error retrieving image:", err.message);
        res.status(500).json({ error: "Failed to retrieve image" });
    }
});

//Cloudinary

const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');

// Configure Cloudinary
cloudinary.config({
    cloud_name: process.env.CLOUD_NAME,
    api_key: process.env.CLOUD_API_KEY,
    api_secret:process.env.CLOUD_SECRET,
});

// Configure Cloudinary Storage
const cloud_storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'uploads', // Specify the folder in Cloudinary
        allowed_formats: ['jpg', 'jpeg', 'png'] // Allow specific file types
    }
});

const CLoud_upload = multer({ storage: cloud_storage });

router.post('/cloud_upload', CLoud_upload.single('image'), async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No file uploaded" });
        }

        const { path: cloudinaryUrl, filename } = req.file;

        // Get Next Sequence Value
        const imageId = await getNextSequenceValue('image');

        // Save Cloudinary URL to MongoDB
        const img = new CloudImage({
            id: imageId,
            name: filename,
            img: {
                data: cloudinaryUrl, // Save Cloudinary URL instead of raw data
                contentType: req.file.mimetype
            }
        });

        await img.save();

        res.status(200).json({
            message: "Image uploaded and stored in MongoDB via Cloudinary",
            imageId: img.id,
            cloudinaryUrl: cloudinaryUrl
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to upload image" });
    }
});

//retrive from cloud
router.get('/cloud_image/:id', async (req, res) => {
    try {
        const imageId = req.params.id;

        // Find image by ID
        const image = await CloudImage.findOne({ id: imageId });

        if (!image) {
            return res.status(404).json({ error: "Image not found" });
        }

        res.status(200).json({
            id: image.id,
            name: image.name,
            url: image.img.data, // Cloudinary URL
            contentType: image.img.contentType
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to retrieve image" });
    }
});

module.exports = router;