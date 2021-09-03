resource "aws_appsync_graphql_api" "api" {
  name                = "ProductsApi"
  authentication_type = "API_KEY"

  schema = file("${path.module}/schema.graphql")
}

resource "aws_appsync_api_key" "api_key" {
  api_id = aws_appsync_graphql_api.api.id
}

resource "aws_appsync_datasource" "companies_datasource" {
  api_id           = aws_appsync_graphql_api.api.id
  name             = "Companies"
  service_role_arn = aws_iam_role.role.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.companies_table.name
  }
}

resource "aws_appsync_datasource" "brands_datasource" {
  api_id           = aws_appsync_graphql_api.api.id
  name             = "Brands"
  service_role_arn = aws_iam_role.role.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.brands_table.name
  }
}

resource "aws_appsync_datasource" "products_datasource" {
  api_id           = aws_appsync_graphql_api.api.id
  name             = "Products"
  service_role_arn = aws_iam_role.role.arn
  type             = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = aws_dynamodb_table.products_table.name
  }
}

resource "aws_appsync_resolver" "create_company_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "createCompany"
  type        = "Mutation"
  data_source = aws_appsync_datasource.companies_datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "PutItem",
    "key" : {
        "id": $util.dynamodb.toDynamoDBJson($util.autoId())
    },
    "attributeValues" : $util.dynamodb.toMapValuesJson($ctx.args)
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

resource "aws_appsync_resolver" "get_company_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "getCompany"
  type        = "Query"
  data_source = aws_appsync_datasource.companies_datasource.name

  request_template = <<EOF
{
    "version": "2017-02-28",
    "operation": "GetItem",
    "key": {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
    }
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

resource "aws_appsync_resolver" "create_brand_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "createBrand"
  type        = "Mutation"
  data_source = aws_appsync_datasource.brands_datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "PutItem",
    "key" : {
        "id": $util.dynamodb.toDynamoDBJson($util.autoId())
    },
    "attributeValues" : $util.dynamodb.toMapValuesJson($ctx.args)
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

resource "aws_appsync_resolver" "get_brand_field_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "brand"
  type        = "Product"
  data_source = aws_appsync_datasource.brands_datasource.name

  request_template = <<EOF
{
    "version": "2017-02-28",
    "operation": "GetItem",
    "key": {
        "id": $util.dynamodb.toDynamoDBJson($ctx.source.brandId)
    }
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

resource "aws_appsync_resolver" "get_products_by_brand_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "getProductsByBrand"
  type        = "Query"
  data_source = aws_appsync_datasource.products_datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "Scan",

    "filter" : $util.transform.toDynamoDBFilterExpression({
      "brandId": {
        "contains": $ctx.args.brandId
      }
    })
}
EOF

  response_template = "$util.toJson($ctx.result.items)"
}

resource "aws_appsync_resolver" "create_product_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "createProduct"
  type        = "Mutation"
  data_source = aws_appsync_datasource.products_datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "PutItem",
    "key" : {
        "id": $util.dynamodb.toDynamoDBJson($util.autoId())
    },
    "attributeValues" : $util.dynamodb.toMapValuesJson($ctx.args)
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

resource "aws_appsync_resolver" "update_product_availability_resolver" {
  api_id      = aws_appsync_graphql_api.api.id
  field       = "updateProductAvailability"
  type        = "Mutation"
  data_source = aws_appsync_datasource.products_datasource.name

  request_template = <<EOF
{
    "version" : "2017-02-28",
    "operation" : "UpdateItem",
    "key" : {
        "id": $util.dynamodb.toDynamoDBJson($ctx.args.id)
    },
    "update": {
        "expression" : "SET availability = :availability",
        "expressionValues" : {
            ":availability" : $util.dynamodb.toDynamoDBJson($ctx.args.availability)
        }
    }
}
EOF

  response_template = "$util.toJson($ctx.result)"
}

output "api_url" {
  value = aws_appsync_graphql_api.api.uris["GRAPHQL"]
}

output "api_key" {
  value     = aws_appsync_api_key.api_key.key
  sensitive = true
}
