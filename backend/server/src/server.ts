import express from "express";
import logger from "./log.js";
import { router } from "./router.js";
import cors from "cors";
import * as gcp from "gcp-metadata";
import { Database } from "./database.js";

async function init() {
  let projectId = process.env.GCP_PROJECT_ID;
  if (!projectId) {
    const isAvailable = await gcp.isAvailable();
    if (isAvailable) {
      projectId = await gcp.project("project-id");
    }
    if (!projectId) {
      throw "Missing Project ID";
    }
  }

  const database = new Database();

  const expressApp = express();
  expressApp.use(cors());
  expressApp.use(express.json());

  expressApp.use((req, res, next) => {
    logger.info(
      `Request ${req.method} ${req.originalUrl} BODY: ${JSON.stringify(
        req.body
      )}`
    );
    next();
  });
  expressApp.use("/v1", router(database));

  const port = process.env.PORT || 8080;
  expressApp.listen(port, () => {
    logger.info(`Web server started on port ${port}`);
  });
}

init();
