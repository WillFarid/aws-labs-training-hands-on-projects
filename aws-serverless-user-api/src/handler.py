"""Read user records from DynamoDB through an API Gateway Lambda proxy."""

import base64
import binascii
import json
import logging
import os
from decimal import Decimal
from typing import Any

import boto3
from botocore.exceptions import BotoCoreError, ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DEFAULT_LIMIT = 25
MAX_LIMIT = 100

# Reuse the DynamoDB resource across warm Lambda invocations.
dynamodb = boto3.resource("dynamodb")


def json_default(value: Any) -> Any:
    """Convert DynamoDB Decimal values into valid JSON numbers."""
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    raise TypeError(f"Unsupported JSON type: {type(value).__name__}")


def response(status_code: int, body: dict[str, Any]) -> dict[str, Any]:
    """Format responses for API Gateway Lambda proxy integration."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Cache-Control": "no-store",
        },
        "body": json.dumps(body, default=json_default),
    }


def encode_token(key: dict[str, Any]) -> str:
    """Encode a DynamoDB LastEvaluatedKey as an opaque URL-safe token."""
    raw = json.dumps(key, default=json_default).encode("utf-8")
    return base64.urlsafe_b64encode(raw).decode("ascii")


def decode_token(token: str) -> dict[str, Any]:
    """Decode a pagination token. Raises ValueError if it is malformed."""
    try:
        raw = base64.urlsafe_b64decode(token.encode("ascii"))
        key = json.loads(raw, parse_float=Decimal)
    except (binascii.Error, UnicodeError, ValueError) as exc:
        raise ValueError("Malformed pagination token") from exc
    if not isinstance(key, dict) or not key:
        raise ValueError("Malformed pagination token")
    return key


def get_method(event: dict[str, Any]) -> str | None:
    """Support both REST API (v1) and HTTP API (v2) event formats."""
    method = event.get("httpMethod")
    if method is None:
        method = event.get("requestContext", {}).get("http", {}).get("method")
    return method


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    """Handle a request to retrieve a page of user records."""
    table_name = os.environ.get("USERS_TABLE_NAME")

    if not table_name:
        logger.error("USERS_TABLE_NAME is not configured")
        return response(500, {"message": "Server configuration error"})

    method = get_method(event)
    if method and method != "GET":
        return response(405, {"message": "Method not allowed"})

    query = event.get("queryStringParameters") or {}

    try:
        limit = int(query.get("limit", DEFAULT_LIMIT))
        if not 1 <= limit <= MAX_LIMIT:
            raise ValueError("Limit outside allowed range")
    except (TypeError, ValueError):
        return response(
            400, {"message": f"limit must be an integer from 1 to {MAX_LIMIT}"}
        )

    scan_kwargs: dict[str, Any] = {"Limit": limit}
    token = query.get("nextToken")
    if token:
        try:
            scan_kwargs["ExclusiveStartKey"] = decode_token(token)
        except ValueError:
            return response(400, {"message": "nextToken is invalid"})

    try:
        # A Scan keeps this example generic. For large tables, prefer a Query
        # built around your real partition-key / index design.
        table = dynamodb.Table(table_name)
        result = table.scan(**scan_kwargs)

        items = result.get("Items", [])
        body: dict[str, Any] = {
            "users": items,
            "count": len(items),
            "hasMore": "LastEvaluatedKey" in result,
        }
        if "LastEvaluatedKey" in result:
            body["nextToken"] = encode_token(result["LastEvaluatedKey"])

        return response(200, body)

    except ClientError as exc:
        # A tampered token that decodes but doesn't match the key schema.
        if exc.response.get("Error", {}).get("Code") == "ValidationException":
            logger.warning("Rejected pagination token: %s", exc)
            return response(400, {"message": "nextToken is invalid"})
        logger.exception("DynamoDB read failed")
        return response(500, {"message": "Unable to retrieve users"})
    except BotoCoreError:
        # Keep internal AWS errors out of the public HTTP response.
        logger.exception("DynamoDB read failed")
        return response(500, {"message": "Unable to retrieve users"})
