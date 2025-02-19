class CustomerState {
  constructor() {
    this.customers = new Map();
  }

  register(customerId, state) {
    this.customers.set(customerId, state);
  }

  update(customerId, newState) {
    this.customers.set(customerId, { ...this.customers.get(customerId), ...newState });
  }

  get(customerId) {
    return this.customers.get(customerId);
  }
}

module.exports = new CustomerState();
