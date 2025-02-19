const customerState = require('@log-collector-sdk/core/lib/CustomerState');

exports.check = (req, res) => {
  // You could iterate through customers and check the status of each collector.
  res.status(200).json({ status: 'ok', customers: Array.from(customerState.customers.keys()) });
};
