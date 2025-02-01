#!/bin/bash

# Set project name and directory
PROJECT_NAME="shop_management_system"
BACKEND_DIR="$PROJECT_NAME/backend"
FRONTEND_DIR="$PROJECT_NAME/frontend"

# Create project directories
echo "Creating project directories..."
mkdir -p $BACKEND_DIR $FRONTEND_DIR

# Initialize Node.js backend
echo "Initializing Node.js backend..."
cd $BACKEND_DIR
npm init -y

# Install necessary backend packages
echo "Installing backend dependencies..."
npm install express mongoose cors dotenv multer google-cloud-storage

# Create basic server file
cat <<EOT >> server.js
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

// Basic route
app.get('/', (req, res) => {
    res.send('Welcome to the Shop Management System API!');
});

// Start server
app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});
EOT

# Create .env file for environment variables
echo "Creating .env file..."
cat <<EOT >> .env
MONGO_URI=your_mongodb_connection_string
GOOGLE_APPLICATION_CREDENTIALS=path_to_your_service_account_json
EOT

# Navigate to frontend directory
cd ../$FRONTEND_DIR

# Initialize React Native app
echo "Creating React Native app..."
npx react-native init ShopManagementSystem

# Navigate to the Google Cloud Storage setup
cd $FRONTEND_DIR/ShopManagementSystem
echo "Setting up Google Cloud Storage..."

# Create a bucket in Google Cloud Storage
BUCKET_NAME=${PROJECT_NAME}-bucket
echo "Creating Google Cloud Storage bucket: $BUCKET_NAME"
gsutil mb gs://$BUCKET_NAME

# Now install Firebase for the frontend (if authentication and storage are needed)
echo "Installing Firebase for the frontend..."
npm install @react-native-firebase/app @react-native-firebase/storage

# Create a dummy file in frontend for initializing storage (optional)
cat <<EOT >> ./index.js
import 'react-native-gesture-handler';
import { AppRegistry } from 'react-native';
import App from './App';
import { name as appName } from './app.json';

AppRegistry.registerComponent(appName, () => App);
EOT

# Output completion message
echo "Project setup completed!"
echo "Backend located in: $BACKEND_DIR"
echo "Frontend located in: $FRONTEND_DIR"
echo "Google Cloud Storage bucket created: gs://$BUCKET_NAME"