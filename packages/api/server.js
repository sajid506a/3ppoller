const express = require('express');
const customerState = require('@log-collector-sdk/core/lib/CustomerState');
const registrationController = require('./controllers/registration');
const healthController = require('./controllers/health');

const app = express();
app.use(express.json());

app.post('/register', registrationController.register);
app.delete('/unregister', registrationController.unregister);
app.get('/health', healthController.check);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`API running on port ${PORT}`));
