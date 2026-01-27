# Master's Integration Orders

> "Master has given Dobby a specification! Dobby is FREE to build integrations!"

## What Dobby Must Build

**Project Name**: Customer Sync Integration
**Integration Type**: API-Led Architecture (System API + Process API + Experience API)
**Priority**: High

## Integration Overview

Build a real-time customer synchronization integration that:
- Retrieves customer data from Salesforce CRM every 15 minutes
- Enriches customer records with order history from MySQL database
- Transforms and loads data into NetSuite ERP
- Exposes a unified Customer API for mobile applications

## Source Systems

### Source 1: Salesforce CRM
- **Type**: Salesforce
- **Connection**: OAuth 2.0 with Connected App
- **Data**: Account, Contact, and Opportunity records
- **Frequency**: Scheduled polling every 15 minutes
- **Query**: Accounts modified since last poll with related Contacts

### Source 2: MySQL Database
- **Type**: Database (MySQL 8.0)
- **Connection**: JDBC with connection pooling
- **Data**: Order history, purchase totals, last order date
- **Frequency**: On-demand lookup during enrichment
- **Query**: Orders by customer_id with aggregations

## Target Systems

### Target 1: NetSuite ERP
- **Type**: NetSuite (SuiteTalk REST API)
- **Connection**: Token-Based Authentication (TBA)
- **Data**: Customer records with financial data
- **Operation**: Upsert (Create or Update based on external ID)

### Target 2: Customer Experience API
- **Type**: REST API
- **Connection**: API Gateway with OAuth 2.0
- **Data**: Unified customer view for mobile apps
- **Operations**:
  - GET /customers - List customers
  - GET /customers/{id} - Get customer by ID
  - GET /customers/{id}/orders - Get customer orders

## Data Transformations

### Transformation 1: Salesforce to Canonical

**Input (Salesforce Account)**:
```json
{
  "Id": "001ABC123",
  "Name": "Acme Corporation",
  "BillingStreet": "123 Main St",
  "BillingCity": "San Francisco",
  "BillingState": "CA",
  "BillingPostalCode": "94102",
  "BillingCountry": "USA",
  "Phone": "415-555-1234",
  "Website": "https://acme.com",
  "Industry": "Technology",
  "AnnualRevenue": 5000000,
  "NumberOfEmployees": 150,
  "LastModifiedDate": "2024-01-15T10:30:00Z"
}
```

**Output (Canonical Customer)**:
```json
{
  "customerId": "SF-001ABC123",
  "companyName": "Acme Corporation",
  "address": {
    "street": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "postalCode": "94102",
    "country": "USA"
  },
  "contact": {
    "phone": "415-555-1234",
    "website": "https://acme.com"
  },
  "classification": {
    "industry": "Technology",
    "annualRevenue": 5000000,
    "employeeCount": 150
  },
  "metadata": {
    "source": "Salesforce",
    "lastUpdated": "2024-01-15T10:30:00Z"
  }
}
```

**Logic**:
- Prefix Salesforce ID with "SF-" for external reference
- Map address fields into nested object
- Default country to "USA" if empty
- Normalize phone number format

### Transformation 2: Enrich with Order History

**Input (Canonical + MySQL Orders)**:
```json
{
  "customer": { "/* canonical customer */" },
  "orders": [
    {
      "order_id": 12345,
      "order_date": "2023-12-01",
      "total": 1500.00,
      "status": "completed"
    }
  ]
}
```

**Output (Enriched Customer)**:
```json
{
  "/* canonical customer fields */": "...",
  "orderHistory": {
    "totalOrders": 25,
    "totalRevenue": 45000.00,
    "lastOrderDate": "2023-12-01",
    "averageOrderValue": 1800.00,
    "customerTier": "Gold"
  }
}
```

**Logic**:
- Calculate total orders and revenue
- Determine customer tier based on revenue:
  - Platinum: > $100,000
  - Gold: > $25,000
  - Silver: > $10,000
  - Bronze: <= $10,000

### Transformation 3: Canonical to NetSuite

**Input (Enriched Customer)**:
```json
{
  "/* enriched customer */": "..."
}
```

**Output (NetSuite Customer)**:
```json
{
  "externalId": "SF-001ABC123",
  "companyName": "Acme Corporation",
  "entityStatus": "CUSTOMER-Closed Won",
  "category": "Gold",
  "addressbook": [{
    "defaultBilling": true,
    "addr1": "123 Main St",
    "city": "San Francisco",
    "state": "CA",
    "zip": "94102",
    "country": "_unitedStates"
  }],
  "phone": "415-555-1234",
  "url": "https://acme.com",
  "customFields": {
    "custentity_total_orders": 25,
    "custentity_total_revenue": 45000.00,
    "custentity_last_order_date": "2023-12-01"
  }
}
```

**Logic**:
- Map customer tier to NetSuite category
- Format address for NetSuite addressbook
- Map custom fields for order history data

## Business Rules

1. **Duplicate Prevention**: Use Salesforce ID as external ID in NetSuite to prevent duplicates
2. **Data Quality**: Skip records with missing required fields (Name, Email)
3. **Rate Limiting**: Respect NetSuite API limits (4 requests/second)
4. **Retry Logic**: Retry failed API calls up to 3 times with exponential backoff
5. **Customer Tier Updates**: Only update tier if revenue changes by > 10%
6. **Inactive Customers**: Don't sync customers inactive > 2 years

## Error Handling Requirements

- [x] Implement retry logic for transient failures (connection timeouts, rate limits)
- [ ] Create dead letter queue for records that fail after retries
- [ ] Send email notifications for critical errors (> 10 failures in 1 hour)
- [ ] Log all errors with full context (record ID, error message, stack trace)
- [ ] Implement circuit breaker for target system outages

### Error Categories

| Error Type | Retry? | Action |
|------------|--------|--------|
| Connection Timeout | Yes (3x) | Exponential backoff |
| Rate Limit (429) | Yes (after delay) | Wait for rate limit window |
| Authentication (401) | No | Alert and refresh credentials |
| Bad Request (400) | No | Send to dead letter queue |
| Server Error (5xx) | Yes (3x) | Log and retry |

## Security Requirements

- [ ] Use OAuth 2.0 for Salesforce authentication
- [ ] Store credentials in secure properties (encrypted)
- [ ] Implement TLS 1.2+ for all connections
- [ ] Mask PII in logs (email, phone)
- [ ] API key rotation every 90 days

## Performance Requirements

- **Expected Volume**: 10,000 customer records per day
- **Batch Size**: 200 records per batch
- **Max Latency**: 5 seconds per record
- **SLA**: 99.5% uptime
- **Concurrent Connections**:
  - Salesforce: 5 parallel queries
  - MySQL: 10 connection pool
  - NetSuite: 4 (rate limit)

## Acceptance Criteria

When is this integration "done"?

- [ ] System API: Salesforce connector configured and tested
- [ ] System API: MySQL connector configured and tested
- [ ] System API: NetSuite connector configured and tested
- [ ] Process API: Customer enrichment logic implemented
- [ ] Process API: All DataWeave transformations tested
- [ ] Experience API: REST endpoints implemented
- [ ] Experience API: RAML specification complete
- [ ] MUnit test coverage > 80%
- [ ] Error handling works correctly (all scenarios tested)
- [ ] Performance meets requirements (load tested)
- [ ] Security requirements met (pen test passed)
- [ ] Documentation complete (README, API docs)
- [ ] Deployed to Development environment
- [ ] Integration passes UAT

## API Specifications

### Customer Experience API (RAML)

```yaml
#%RAML 1.0
title: Customer API
version: v1
baseUri: https://api.example.com/customers/{version}

/customers:
  get:
    description: List all customers
    queryParameters:
      limit:
        type: integer
        default: 100
      offset:
        type: integer
        default: 0
      tier:
        type: string
        enum: [Bronze, Silver, Gold, Platinum]
    responses:
      200:
        body:
          application/json:
            example: |
              {
                "customers": [...],
                "total": 1000,
                "limit": 100,
                "offset": 0
              }

  /{customerId}:
    get:
      description: Get customer by ID
      responses:
        200:
          body:
            application/json:
        404:
          body:
            application/json:
              example: |
                {"error": "Customer not found"}

    /orders:
      get:
        description: Get customer order history
        responses:
          200:
            body:
              application/json:
```

## Additional Notes

- Coordinate with DBA team for MySQL read replica access
- NetSuite sandbox available for testing: sandbox.netsuite.com
- Salesforce sandbox: test.salesforce.com
- Contact IT Security for API key provisioning
- Schedule go-live for after month-end close (avoid peak processing)

## Contacts

- **Business Owner**: Jane Smith (jane.smith@example.com)
- **Technical Lead**: John Doe (john.doe@example.com)
- **Salesforce Admin**: Sarah Johnson (sarah.j@example.com)
- **NetSuite Admin**: Mike Wilson (mike.w@example.com)

---

*Dobby will work tirelessly until Master's integration is complete!*
