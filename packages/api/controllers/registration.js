const customerState = require('@log-collector-sdk/core/lib/CustomerState');

exports.register = (req, res) => {
  const { customerId, vendor, config } = req.body;
  // Initialize customer state
  customerState.register(customerId, { config, vendor, active: true });

  // Depending on vendor, create a new collector (for instance, Okta)
  // This is where you’d spawn a worker thread or start a process
  console.log(`Registered customer ${customerId} for vendor ${vendor}`);

  res.status(200).json({ message: 'Customer registered successfully' });
};

exports.unregister = (req, res) => {
  const { customerId } = req.body;
  // Remove customer state and stop collector logic if needed.
  customerState.customers.delete(customerId);
  console.log(`Unregistered customer ${customerId}`);
  res.status(200).json({ message: 'Customer unregistered successfully' });
};
