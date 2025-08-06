import { Request, Response, Router } from "express";
import {
  Database,
  ForumThread,
  PatreonPost,
  Post,
  YoutubeVideo,
} from "./database.js";
import { generateShortId } from "./util.js";
import { Patreon } from "./patreon.js";
import { Youtube } from "./youtube.js";
import { Forums } from "./forums.js";
import { GCPAuthMiddleware } from "./auth.js";
import { AtomFeedService } from "./atom.js";
import z from "zod";
import { Readable } from "stream";

export function router(
  database: Database,
  gcpAuthMiddleware: GCPAuthMiddleware,
  atomFeedService: AtomFeedService,
  youtube: Youtube,
  forum: Forums,
  patreon: Patreon,
  serverBaseUrl: string
): Router {
  const router = Router();

  router.get("/posts", async (req, res) => {
    const beforeQuery = req.query.before;
    const limitQuery = req.query.limit;
    const filterQuery = req.query.filter as string | undefined;
    const appPlatform = req.headers["x-app-platform"] as string | undefined;

    const before =
      typeof beforeQuery === "string"
        ? new Date(beforeQuery).toISOString()
        : new Date().toISOString();
    let limit = Number(limitQuery);
    limit = limit > 0 && limit < 30 ? Number(limitQuery) : 10;
    const filter = parseFilterParam(filterQuery);

    let unproxiedPosts: Post[];
    try {
      unproxiedPosts = await database.getPostsBefore(before, limit, filter);
    } catch (e) {
      console.error("Failed to fetch Posts");
      return res.sendStatus(500);
    }

    const shouldProxy = appPlatform === "web";
    const proxiedPosts: Post[] = shouldProxy ? [] : unproxiedPosts;
    if (shouldProxy) {
      for (const post of unproxiedPosts) {
        proxiedPosts.push({
          ...post,
          author: {
            ...post.author,
            avatarUrl: proxifyImage(post.author.avatarUrl, serverBaseUrl)!,
          },
          data: ((): YoutubeVideo | PatreonPost | ForumThread => {
            switch (post.data.type) {
              case "youtubeVideo":
                return {
                  ...post.data,
                  channel: {
                    ...post.data.channel,
                    imageUrl: proxifyImage(
                      post.data.channel.imageUrl,
                      serverBaseUrl
                    )!,
                  },
                  thumbnailUrl: proxifyImage(
                    post.data.thumbnailUrl,
                    serverBaseUrl
                  )!,
                };
              case "forumThread":
                return {
                  ...post.data,
                  author: {
                    ...post.data.author,
                    avatarUrl: proxifyImage(
                      post.data.author.avatarUrl,
                      serverBaseUrl
                    )!,
                  },
                };
              case "patreonPost":
                return {
                  ...post.data,
                  author: {
                    ...post.data.author,
                    avatarUrl: proxifyImage(
                      post.data.author.avatarUrl,
                      serverBaseUrl
                    )!,
                  },
                  imageUrl: proxifyImage(
                    post.data.imageUrl ?? undefined,
                    serverBaseUrl
                  ),
                };
              default:
                return post.data;
            }
          })(),
        });
      }
    }

    const accept = req.headers.accept || "";
    if (accept.includes("application/json")) {
      res.json({ posts: proxiedPosts, hasMore: proxiedPosts.length >= limit });
    } else {
      const feedXml = atomFeedService.buildXml(proxiedPosts, new Date());
      res.type("application/atom+xml").send(feedXml);
    }
  });

  // Since we just link to external images, this avoids CORS issues when deployed on the web
  router.get("/image_proxy", async (req, res) => {
    const targetUrl = req.query.url as string;
    if (!targetUrl) {
      return res.status(400).send("Missing url parameter");
    }

    try {
      const response = await fetch(targetUrl);
      if (!response.ok) {
        return res.status(response.status).send("Failed to fetch image");
      }

      res.setHeader(
        "Content-Type",
        response.headers.get("content-type") || "application/octet-stream"
      );
      res.setHeader("Access-Control-Allow-Origin", "*");

      const nodeStream = Readable.fromWeb(response.body as any);
      nodeStream.pipe(res);
    } catch (err) {
      console.error("Error proxying image:", err);
      res.status(500).send("Error fetching image");
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
        const threads = await forum.getRecentThreads();
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
        const posts = await patreon.getRecentPosts();
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

function proxifyImage(
  url: string | null | undefined,
  serverBaseUrl: string
): string | null | undefined {
  if (!url) {
    return url;
  }
  return `${serverBaseUrl}/v1/image_proxy?url=${encodeURIComponent(url)}`;
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
  if (!param) {
    return Object.values(filterMap);
  }

  const parsed = filterParamSchema.safeParse(param);
  if (!parsed.success) {
    return Object.values(filterMap);
  }

  return parsed.data.map((key) => filterMap[key]);
}
