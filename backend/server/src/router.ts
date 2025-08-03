import { Request, Response, Router } from "express";
import { Database, Post } from "./database.js";
import { generateShortId } from "./util.js";
import { Patreon } from "./patreon.js";
import { Youtube } from "./youtube.js";
import { Forums } from "./forums.js";
import { GCPAuthMiddleware } from "./auth.js";
import { AtomFeedService } from "./atom.js";
import z from "zod";

export function router(
  database: Database,
  gcpAuthMiddleware: GCPAuthMiddleware,
  atomFeedService: AtomFeedService,
  youtube: Youtube,
  forum: Forums,
  patreon: Patreon
): Router {
  const router = Router();

  router.get("/posts", async (req, res) => {
    const fromQuery = req.query.from;
    const limitQuery = req.query.limit;
    const filterQuery = req.query.filter as string | undefined;

    const from =
      typeof fromQuery === "string" ? fromQuery : new Date().toISOString();
    const limit = Number(limitQuery) > 0 ? Number(limitQuery) : 10;
    const filter = parseFilterParam(filterQuery);

    let posts: Post[];
    try {
      posts = await database.getPostsBefore(from, limit, filter);
    } catch (e) {
      console.error("Failed to fetch Posts");
      return res.sendStatus(500);
    }

    const accept = req.headers.accept || "";
    if (accept.includes("application/atom+xml")) {
      const feedXml = atomFeedService.buildXml(posts, new Date());
      res.type("application/atom+xml").send(feedXml);
    } else {
      res.json({ posts: posts });
    }
  });

  router.post(
    "/internal/poll",
    gcpAuthMiddleware.middleware,
    async (req: Request, res: Response) => {
      let youtubePosts: Post[] = [];
      try {
        const videos = await youtube.getRecentVideos();
        youtubePosts = videos.map((video) => ({
          id: generateShortId(`youtubeVideo_${video.id}`),
          publishedAt: video.publishedAt,
          updatedAt: video.updatedAt,
          url: video.url,
          author: {
            name: video.channel.name,
            avatarUrl: video.channel.imageUrl,
          },
          data: video,
        }));
      } catch (e) {
        console.error("Failed to fetch YouTube videos");
      }

      let forumPosts: Post[] = [];
      try {
        const threads = await forum.getRecentThreads(50);
        forumPosts = threads.map((thread) => ({
          id: generateShortId(`forumThread_${thread.id}`),
          publishedAt: thread.publishedAt,
          updatedAt: thread.updatedAt ?? thread.publishedAt,
          url: thread.url,
          author: {
            name: thread.author.name,
            avatarUrl: thread.author.avatarUrl,
          },
          data: thread,
        }));
      } catch (e) {
        console.error("Failed to fetch Forum threads");
      }

      let patreonPosts: Post[] = [];
      try {
        const posts = await patreon.getRecentPosts(50);
        patreonPosts = posts.map((post) => ({
          id: generateShortId(`patreonPost_${post.id}`),
          publishedAt: post.publishedAt,
          updatedAt: post.publishedAt,
          url: post.url,
          author: { name: post.author.name, avatarUrl: post.author.avatarUrl },
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
    }
  );

  return router;
}

const filterMap = {
  youtube: "youtubeVideo",
  patreon: "patreonPost",
  forum: "forumThread",
} as const;

const filterParamSchema = z
  .string()
  .transform((str) => str.split(","))
  .pipe(z.array(z.enum(["youtube", "patreon", "forum"])));

type FilterType = (typeof filterMap)[keyof typeof filterMap];

export function parseFilterParam(param: string | undefined): FilterType[] {
  if (!param) return [];

  const parsed = filterParamSchema.safeParse(param);
  if (!parsed.success) return [];

  return parsed.data.map((key) => filterMap[key]);
}
