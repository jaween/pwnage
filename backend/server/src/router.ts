import { Request, Response, Router } from "express";
import { Database, Post } from "./database.js";
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

  router.post("/internal/poll", async (req: Request, res: Response) => {
    let youtubePosts: Post[] = [];
    try {
      const videos = await youtube.getRecentVideos();
      youtubePosts = videos.map((video) => ({
        id: generateShortId(`youtube_video_${video.id}`),
        type: "youtube_video",
        publishedAt: video.publishedAt,
        updatedAt: video.updatedAt,
        data: video,
      }));
    } catch (e) {
      console.error("Failed to fetch YouTube videos");
    }

    let forumPosts: Post[] = [];
    try {
      const threads = await forum.getRecentThreads();
      forumPosts = threads.map((thread) => ({
        id: generateShortId(`forum_thread_${thread.id}`),
        type: "forum_thread",
        publishedAt: thread.publishedAt,
        updatedAt: thread.updatedAt,
        data: thread,
      }));
    } catch (e) {
      console.error("Failed to fetch Patreon threads");
    }

    let patreonPosts: Post[] = [];
    try {
      const posts = await patreon.getRecentPosts();
      patreonPosts = posts.map((post) => ({
        id: generateShortId(`patreon_post_${post.id}`),
        type: "patreon_post",
        publishedAt: post.publishedAt,
        updatedAt: post.publishedAt,
        data: post,
      }));
    } catch (e) {
      console.error("Failed to fetch Patreon posts");
    }

    try {
      await database.putPosts([
        ...youtubePosts,
        ...forumPosts,
        ...patreonPosts,
      ]);
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Error saving posts" });
    }

    return res.sendStatus(200);
  });

  return router;
}
