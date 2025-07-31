import { Request, Response, Router } from "express";
import {
  Database,
  ForumThread,
  PatreonPost,
  Post,
  YoutubeVideo as YoutubeVideo,
} from "./database.js";
import axios from "axios";
import xml2js from "xml2js";
import { generateShortId } from "./util.js";
import { Patreon } from "./patreon.js";

export function router(database: Database, patreon: Patreon): Router {
  const router = Router();

  router.post("/youtube", async (req: Request, res: Response) => {
    const channelUrl =
      "https://www.youtube.com/feeds/videos.xml?channel_id=UCKkt1XBxvF6EKalH8G2vP2A";

    let response: any;
    try {
      response = await axios.get(channelUrl, { responseType: "text" });
    } catch (error) {
      return res.status(500).json({ error: "Error fetching the YouTube feed" });
    }

    const parser = new xml2js.Parser();
    let result: any;
    try {
      result = await parser.parseStringPromise(response.data);
    } catch (e) {
      return res.status(500).json({ error: "Error parsing XML" });
    }

    const entries = result.feed.entry;
    const videos: YoutubeVideo[] = [];
    for (const entry of entries) {
      videos.push({
        id: entry["yt:videoId"][0],
        title: entry.title[0],
        url: entry.link[0].$.href,
        publishedAt: entry.published[0],
        updatedAt: entry.updated[0],
        thumbnailUrl: entry["media:group"][0]["media:thumbnail"][0].$.url,
        description: entry["media:group"][0]["media:description"][0],
        likes:
          entry["media:group"][0]["media:community"][0]["media:starRating"][0].$
            .count,
        views:
          entry["media:group"][0]["media:community"][0]["media:statistics"][0].$
            .views,
      });
    }

    const posts: Post[] = videos.map((video) => {
      return {
        id: generateShortId(`youtube_video_${video.id}`),
        type: "youtube_video",
        publishedAt: video.publishedAt,
        updatedAt: video.updatedAt,
        data: video,
      };
    });

    try {
      await database.putPosts(posts);
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Error saving posts" });
    }

    return res.status(200);
  });

  router.post("/forum", async (req: Request, res: Response) => {
    const feedUrl =
      "https://forum.8bitwars.com/syndication.php?type=atom1.0&limit=10";

    let response: any;
    try {
      response = await axios.get(feedUrl, { responseType: "text" });
    } catch (error) {
      return res.status(500).json({ error: "Error fetching the forum feed" });
    }

    const parser = new xml2js.Parser({
      explicitArray: false,
      explicitCharkey: false,
      mergeAttrs: true,
      trim: true,
      normalizeTags: true,
    });

    let result: any;
    try {
      result = await parser.parseStringPromise(response.data);
    } catch (e) {
      return res.status(500).json({ error: "Error parsing XML" });
    }

    let entries = result.feed.entry;
    if (!Array.isArray(entries)) {
      entries = [entries];
    }

    const posts: Post[] = [];

    for (const entry of entries) {
      let authorAnchorTag = entry.author.name._;
      const { href: authorProfileUrl, text: authorName } = parseAnchorTag(
        authorAnchorTag
      ) || { href: "", text: "" };
      if (!authorProfileUrl || !authorName) {
        continue;
      }

      const authorUid = getQueryParamFromUrl(authorProfileUrl, "uid");
      if (!authorUid) {
        continue;
      }

      const threadId = getQueryParamFromUrl(entry.id, "tid");
      if (!threadId) {
        continue;
      }

      const thread: ForumThread = {
        id: threadId,
        title: entry.title._,
        url: entry.link?.href,
        publishedAt: entry.published,
        updatedAt: entry.updated,
        uid: authorUid,
        author: authorName,
        avatarUrl: `https://forum.8bitwars.com/uploads/avatars/avatar_${authorUid}.png`,
        content: entry.content?._,
      };

      posts.push({
        id: generateShortId(`forum_thread_${thread.id}`),
        type: "forum_thread",
        publishedAt: thread.publishedAt,
        updatedAt: thread.updatedAt,
        data: thread,
      });
    }

    try {
      await database.putPosts(posts);
    } catch (e) {
      console.error(e);
      return res.status(500).json({ error: "Error saving posts" });
    }

    return res.status(200);
  });

  router.post("/patreon", async (req: Request, res: Response) => {
    let patreonPosts: PatreonPost[];
    try {
      patreonPosts = await patreon.getRecentPosts();
    } catch (e) {
      return res.status(500).json({ error: "Error fetching Patreon posts" });
    }

    const posts: Post[] = patreonPosts.map((post): Post => {
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

    return res.status(200);
  });

  return router;
}

function parseAnchorTag(anchor: string): { href: string; text: string } | null {
  const match = anchor.match(/<a\s+href="([^"]+)">([^<]+)<\/a>/);
  if (!match) return null;
  return {
    href: match[1],
    text: match[2],
  };
}

function getQueryParamFromUrl(url: string, queryParam: string): string | null {
  try {
    const parsedUrl = new URL(url);
    return parsedUrl.searchParams.get(queryParam);
  } catch {
    return null;
  }
}
