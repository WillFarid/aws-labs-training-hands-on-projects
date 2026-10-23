import json
import os
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import ClientError

from src import handler


@pytest.fixture(autouse=True)
def table():
    with patch.dict(os.environ, {"USERS_TABLE_NAME": "test-users"}):
        with patch.object(handler, "dynamodb") as mock_db:
            mock_table = MagicMock()
            mock_db.Table.return_value = mock_table
            yield mock_table


def call(event=None):
    return handler.lambda_handler({"httpMethod": "GET", **(event or {})}, None)


def test_successful_request_returns_users(table):
    table.scan.return_value = {
        "Items": [{"userId": "example-1", "name": "Example User"}]
    }
    result = call()
    body = json.loads(result["body"])
    assert result["statusCode"] == 200
    assert body["count"] == 1
    assert body["hasMore"] is False
    assert "nextToken" not in body
    table.scan.assert_called_once_with(Limit=25)


def test_decimal_values_are_serialised(table):
    table.scan.return_value = {
        "Items": [{"userId": "a", "age": Decimal("30"), "score": Decimal("4.5")}]
    }
    user = json.loads(call()["body"])["users"][0]
    assert user["age"] == 30 and user["score"] == 4.5


@pytest.mark.parametrize("limit", ["0", "101", "500", "abc", "2.5", ""])
def test_invalid_limit_returns_400(table, limit):
    result = call({"queryStringParameters": {"limit": limit}})
    assert result["statusCode"] == 400
    table.scan.assert_not_called()


def test_custom_limit_is_passed_to_dynamodb(table):
    table.scan.return_value = {"Items": []}
    call({"queryStringParameters": {"limit": "10"}})
    table.scan.assert_called_once_with(Limit=10)


def test_pagination_round_trip(table):
    table.scan.return_value = {
        "Items": [{"userId": "a"}],
        "LastEvaluatedKey": {"userId": "a"},
    }
    body = json.loads(call()["body"])
    assert body["hasMore"] is True

    table.scan.reset_mock()
    table.scan.return_value = {"Items": [{"userId": "b"}]}
    call({"queryStringParameters": {"nextToken": body["nextToken"]}})
    table.scan.assert_called_once_with(
        Limit=25, ExclusiveStartKey={"userId": "a"}
    )


@pytest.mark.parametrize("token", ["not-base64!!", "e30=", "W10="])
def test_malformed_token_returns_400(table, token):
    result = call({"queryStringParameters": {"nextToken": token}})
    assert result["statusCode"] == 400
    table.scan.assert_not_called()


def test_dynamodb_validation_error_returns_400(table):
    table.scan.side_effect = ClientError(
        {"Error": {"Code": "ValidationException", "Message": "bad key"}}, "Scan"
    )
    token = handler.encode_token({"wrong": "key"})
    result = call({"queryStringParameters": {"nextToken": token}})
    assert result["statusCode"] == 400


def test_dynamodb_failure_returns_generic_500(table):
    table.scan.side_effect = ClientError(
        {"Error": {"Code": "InternalServerError", "Message": "secret detail"}},
        "Scan",
    )
    result = call()
    assert result["statusCode"] == 500
    assert "secret detail" not in result["body"]


@pytest.mark.parametrize("method", ["POST", "PUT", "DELETE"])
def test_wrong_method_returns_405(method):
    result = handler.lambda_handler({"httpMethod": method}, None)
    assert result["statusCode"] == 405


def test_http_api_v2_event_format(table):
    table.scan.return_value = {"Items": []}
    event = {"requestContext": {"http": {"method": "GET"}}}
    assert handler.lambda_handler(event, None)["statusCode"] == 200


def test_missing_configuration_returns_500(table):
    with patch.dict(os.environ, {}, clear=True):
        result = call()
    assert result["statusCode"] == 500
    table.scan.assert_not_called()
