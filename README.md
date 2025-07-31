# Pwnage

An aggregator of Teh Pwnage posts.

## How to run

Create a file named `.env` with the following credentials:

```
NODE_ENV=DEVELOPMENT

GOOGLE_APPLICATION_CREDENTIALS=
GCP_PROJECT_ID=
```

Build the docker image by running:

`docker compose -f docker-compose.dev.yml -f docker-compose.dev.yml build`

Run the image in a docker container by running:

`docker compose -f docker-compose.dev.yml -f docker-compose.dev.yml up`

## How to deploy

From the `server/` directory, run `gcloud builds submit`
