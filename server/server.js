const express = require('express');
const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware for parsing JSON
app.use(express.json());

// Client for look up public keys at Apple
const client = jwksClient({
    jwksUri: 'https://appleid.apple.com/auth/keys'
});

// Function for getting public key
function getAppleKey(header, callback) {
    client.getSigningKey(header.kid, function (err, key) {
        if (err) {
            callback(err);
        } else {
            const signingKey = key.getPublicKey();
            callback(null, signingKey);
        }
    });
}

// Route for authenticate
app.post('/auth/apple', (req, res) => {
    const { identityToken } = req.body;

    if (!identityToken) {
        return res.status(400).json({ error: 'identityToken missing' });
    }

    jwt.verify(identityToken, getAppleKey, {
        algorithms: ['RS256']
    }, (err, decoded) => {
        if (err) {
            console.error('Error verifying token:', err);
            return res.status(401).json({ error: 'Invalid token' });
        }

        // decoded contains user data
        console.log('Token verified:', decoded);

        res.json({
            success: true,
            user: {
                id: decoded.sub,
                email: decoded.email,
                email_verified: decoded.email_verified
            }
        });
    });
});

app.listen(PORT, () => {
    console.log(`Server listening on port ${PORT}`);
});
