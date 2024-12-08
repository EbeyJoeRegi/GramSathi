const mongoose = require('mongoose');

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
    user_type: { type: String, default: 'user' },
    raID: { type: String, unique: true, required: true }
});

const imageSchema = new mongoose.Schema({
    id: { type: Number, unique: true },
    name: String,
    img: {
        data: Buffer,
        contentType: String
    }
});

const announcementSchema = new mongoose.Schema({
    id: { type: Number, unique: true },    
    admin: String,
    title: String,
    content: String,
    created_at: { type: Date, default: Date.now }
});

const suggestionSchema = new mongoose.Schema({
    id: { type: Number, unique: true },
    title: String, 
    admin: String,
    content: String,
    username: String,
    created_at: { type: Date, default: Date.now },
    response: String
});

const querySchema = new mongoose.Schema({
    id: { type: Number, unique: true },
    username: String, 
    admin: String,
    type:Number,
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

const weatherSchema = new mongoose.Schema({
    id: {type: Number,required: true,unique: true,},
    username: {type: String,required: true,unique: true,},
    temperature: {type: String,required: true,},
    weatherCondition: {type: String,required: true,},
    city: {type: String,required: true,},
    lastUpdated: {type: Date,default: Date.now,},
});

const sellSchema = new mongoose.Schema({
    id: {type: Number,unique: true,},
    sellername: {type: String,required: true,},
    cropname: {type: String,required: true,},
    quantity: {type: Number, required: true,},
    price: {type: Number, required: true,},
    date_updated: {type: Date,default: Date.now,},
    sold: {type: Boolean,default: false,},
  });

  const buySchema = new mongoose.Schema({
    id: {type: Number,unique: true,},
    buyername: {type: String, required: true,},
    sell_id: {type: Number,required: true,},
    sellername: {type: String,required: true,},
    date: {type: Date,default: Date.now,},
    buy: {type: Boolean,default: false,},
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
const Weather = mongoose.model('Weather', weatherSchema);
const Sell = mongoose.model('Sell', sellSchema);
const Buy = mongoose.model('Buy', buySchema);
const Image = mongoose.model('Image', imageSchema);

module.exports = {
    User,
    Announcement,
    Suggestion,
    Query,
    Place,
    Crop,
    Price,
    Counter,
    Sell,
    Buy,
    Weather,
    Image,
};
