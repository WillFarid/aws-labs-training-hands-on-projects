# Security

## What's in place

- **Least-privilege IAM:** the Lambda role only gets `DynamoDBReadPolicy` on the single users table (`dynamodb:GetItem`, `Scan`, `Query`, ...). It cannot write or delete.
- **API key + throttling:** API Gateway requires `x-api-key` and enforces 10 req/s (burst 20).
- **Encryption:** DynamoDB encryption at rest is enabled; all API traffic is HTTPS.
- **No secret leakage:** AWS error details are logged to CloudWatch only; clients get generic messages.
- **Input validation:** `limit` is bounded to 1-100, `nextToken` is validated, and tampered tokens return `400`.
- **No secrets in the repo:** configuration comes from environment variables; `.env` files are git-ignored.
- **Data protection:** the table has `DeletionPolicy: Retain` and point-in-time recovery enabled.

## Known limitations

- **API keys are not user authentication.** They identify a client, not a person. For real user data, put a Cognito authorizer or Lambda authorizer in front of the API.
- **Returns whole records.** Every attribute stored on a user is returned. Add a projection or an allow-list of fields before storing sensitive data (emails, phone numbers, etc.).
- **No CORS configuration.** Browser clients on another origin will be blocked until you add it deliberately.
- **No WAF.** Consider AWS WAF for public production use.

## Reporting a vulnerability

Please open a private security advisory on the GitHub repository rather than a public issue.
