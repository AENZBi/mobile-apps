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
            Alert.alert('Product Added', `Product ${response.data.name} has been added.`);
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
