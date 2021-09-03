# AWS AppSync GraphQL Workshop

This project contains slides and terraform script for an AWS AppSync GraphQL workshop.

## Starting the presentation

Switch to `presentation` and install reveal-md:

    npm i

Start presentation:

    npx reveal-md slides.md

## Applying terraform script

Switch to `terraform` and apply terraform script:

    terraform init
    terraform apply

This will create a sample AppSync stack with 3 DynamoDB tables and the necessary data sources,
schema and resolvers.
