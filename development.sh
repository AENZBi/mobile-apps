#!/bin/bash

# Variables
PROJECT_NAME="shop_management_system"
BACKEND_DIR="$PROJECT_NAME/backend"
FRONTEND_DIR="$PROJECT_NAME/frontend"
PRODUCT_MODEL_PATH="$BACKEND_DIR/models/Product.js"
PRODUCT_ROUTES_PATH="$BACKEND_DIR/routes/products.js"
PRODUCT_FORM_PATH="$FRONTEND_DIR/ShopManagementSystem/ProductForm.js"
SERVER_PATH="$BACKEND_DIR/server.js"

# Create project directories
echo "Creating project directories..."
mkdir -p $BACKEND_DIR $FRONTEND_DIR/ShopManagementSystem

# Initialize Node.js backend
echo "Initializing Node.js backend..."
cd $BACKEND_DIR
npm init -y

# Install necessary backend packages
echo "Installing backend dependencies..."
npm install express mongoose cors dotenv

# Create product model
cat <<EOT > $PRODUCT_MODEL_PATH
const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
    name: { type: String, required: true },
    price: { type: Number, required: true },
    quantity: { type: Number, required: true },
    description: { type: String },
    category: { type: String },
});

const Product = mongoose.model('Product', productSchema);

module.exports = Product;
EOT

# Create product routes
cat <<EOT > $PRODUCT_ROUTES_PATH
const express = require('express');
const Product = require('../models/Product');

const router = express.Router();

// Get all products
router.get('/', async (req, res) => {
    try {
        const products = await Product.find();
        res.json(products);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
});

// Create new product
router.post('/', async (req, res) => {
    const product = new Product(req.body);
    try {
        const newProduct = await product.save();
        res.status(201).json(newProduct);
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
});

// Export the router
module.exports = router;
EOT

# Create the server file
cat <<EOT > $SERVER_PATH
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.error(err));

// Define routes
const productsRouter = require('./routes/products');
app.use('/api/products', productsRouter);

// Basic route
app.get('/', (req, res) => {
    res.send('Welcome to the Shop Management System API!');
});

// Start server
app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});
EOT

# Navigate to frontend directory
cd ../$FRONTEND_DIR

# Initialize React Native app
echo "Creating React Native app..."
npx react-native init ShopManagementSystem

# Navigate to the Google Cloud Storage setup
cd ShopManagementSystem

# Install axios for HTTP requests
echo "Installing Axios for front-end HTTP requests..."
npm install axios

# Create ProductForm.js for handling product form submission
cat <<EOT > ProductForm.js
import React, { useState } from 'react';
import { View, TextInput, Button, Alert } from 'react-native';
import axios from 'axios';

const ProductForm = () => {
    const [name, setName] = useState('');
    const [price, setPrice] = useState('');
    const [quantity, setQuantity] = useState('');
    const [description, setDescription] = useState('');
    const [category, setCategory] = useState('');

    const addProduct = async () => {
        try {
            const response = await axios.post('http://<YOUR_BACKEND_SERVER_URL>/api/products', {
                name,
                price,
                quantity,
                description,
                category,
            });
            Alert.alert('Product Added', \`Product \${response.data.name} has been added.\`);
        } catch (error) {
            Alert.alert('Error', 'Failed to add product.');
        }
    };

    return (
        <View>
            <TextInput placeholder="Product Name" onChangeText={setName} />
            <TextInput placeholder="Price" keyboardType="numeric" onChangeText={setPrice} />
            <TextInput placeholder="Quantity" keyboardType="numeric" onChangeText={setQuantity} />
            <TextInput placeholder="Description" onChangeText={setDescription} />
            <TextInput placeholder="Category" onChangeText={setCategory} />
            <Button title="Add Product" onPress={addProduct} />
        </View>
    );
};

export default ProductForm;
EOT

# Integrate ProductForm with App.js
cat <<EOT > App.js
import React from 'react';
import { SafeAreaView } from 'react-native';
import ProductForm from './ProductForm';

const App = () => {
    return (
        <SafeAreaView>
            <ProductForm />
        </SafeAreaView>
    );
};

export default App;
EOT

# Output completion message
echo "Project setup completed!"
echo "Backend located in: $BACKEND_DIR"
echo "Frontend located in: $FRONTEND_DIR/ShopManagementSystem"
echo "Next steps:"
echo "1. Update the MONGO_URI in your backend .env file."
echo "2. Start the backend server: cd $BACKEND_DIR && node server.js"
echo "3. Run your React Native app: cd $FRONTEND_DIR/ShopManagementSystem && npx react-native run-android (or run-ios)"
