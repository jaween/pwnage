import express from "express";
import logger from "./log.js";
import { router } from "./router.js";
import cors from "cors";
import * as gcp from "gcp-metadata";
import { Database } from "./database.js";
import { Patreon } from "./patreon.js";
import { Youtube } from "./youtube.js";
import { Forums } from "./forums.js";
import { GCPAuthMiddleware } from "./auth.js";
import { AtomFeedService } from "./atom.js";

async function init() {
  let projectId = process.env.GCP_PROJECT_ID;
  let serviceAccountEmail = process.env.SERVICE_ACCOUNT ?? "none";
  if (!projectId) {
    const isAvailable = await gcp.isAvailable();
    if (isAvailable) {
      projectId = await gcp.project("project-id");
    }
    if (!projectId) {
      throw "Missing Project ID";
    }
  }

  let youtubeChannelId = process.env.YOUTUBE_CHANNEL_ID;
  if (!youtubeChannelId) {
    throw "Missing YouTube Channel ID";
  }

  let forumsAtomUrl = process.env.FORUMS_ATOM_URL;
  if (!forumsAtomUrl) {
    throw "Missing Forums Atom URL";
  }

  let patreonCampaignId = process.env.PATREON_CAMPAIGN_ID;
  if (!patreonCampaignId) {
    throw "Missing Patreon Campaign ID";
  }

  const database = new Database();
  const gcpAuthMiddleware = new GCPAuthMiddleware(
    projectId,
    serviceAccountEmail
  );
  const atomFeedService = new AtomFeedService();
  const youtube = new Youtube(youtubeChannelId);
  const forum = new Forums(forumsAtomUrl);
  const patreon = new Patreon(patreonCampaignId);

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
  expressApp.use(
    "/v1",
    router(
      database,
      gcpAuthMiddleware,
      atomFeedService,
      youtube,
      forum,
      patreon
    )
  );

  const port = process.env.PORT || 8080;
  expressApp.listen(port, () => {
    logger.info(`Web server started on port ${port}`);
  });
}

init();
