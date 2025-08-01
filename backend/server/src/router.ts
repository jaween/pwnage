import { Request, Response, Router } from "express";
import {
  Database,
  ForumThread,
  PatreonPost,
  Post,
  YoutubeVideo as YoutubeVideo,
} from "./database.js";
import { generateShortId } from "./util.js";
import { Patreon } from "./patreon.js";
import { Youtube } from "./youtube.js";
import { Forums } from "./forums.js";

export function router(
  database: Database,
  youtube: Youtube,
  forum: Forums,
  patreon: Patreon
): Router {
  const router = Router();

  router.post("/youtube", async (req, res) => {
    let videos: YoutubeVideo[] = [];
    try {
      videos = await youtube.getRecentVideos();
    } catch (e) {
      return res.status(500).json({ error: "Error fetching YouTube videos" });
    }

    const posts: Post[] = videos.map((video) => ({
      id: generateShortId(`youtube_video_${video.id}`),
      type: "youtube_video",
      publishedAt: video.publishedAt,
      updatedAt: video.updatedAt,
      data: video,
    }));

    try {
      await database.putPosts(posts);
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Failed" });
    }

    return res.sendStatus(200);
  });

  router.post("/forum", async (req, res) => {
    let threads: ForumThread[] = [];
    try {
      threads = await forum.getRecentThreads();
    } catch (e) {
      return res.status(500).json({ error: "Error fetching forum threads" });
    }

    const posts: Post[] = threads.map((thread) => ({
      id: generateShortId(`forum_thread_${thread.id}`),
      type: "forum_thread",
      publishedAt: thread.publishedAt,
      updatedAt: thread.updatedAt,
      data: thread,
    }));

    try {
      await database.putPosts(posts);
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Error saving posts" });
    }

    return res.sendStatus(200);
  });

  router.post("/patreon", async (req: Request, res: Response) => {
    let patreonPosts: PatreonPost[];
    try {
      patreonPosts = await patreon.getRecentPosts();
    } catch (e) {
      return res.status(500).json({ error: "Error fetching Patreon posts" });
    }

    const posts: Post[] = patreonPosts.map((post) => {
      return {
        id: generateShortId(`patreon_post_${post.id}`),
        type: "patreon_post",
        publishedAt: post.publishedAt,
        updatedAt: post.publishedAt,
        data: post,
      };
    });

    try {
      await database.putPosts(posts);
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Error saving posts" });
    }

    return res.sendStatus(200);
  });

  return router;
}
