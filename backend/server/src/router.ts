import { Request, Response, Router } from "express";
import { Database, Post, YoutubeVideo as YoutubeVideo } from "./database.js";
import axios from "axios";
import xml2js from "xml2js";

export function router(database: Database): Router {
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

    const entries = result.feed.entry || [];
    const videos: YoutubeVideo[] = entries.map((entry: any): YoutubeVideo => {
      return {
        videoId: entry["yt:videoId"][0],
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
      };
    });

    const posts: Post[] = videos.map((video) => {
      return {
        type: "youtube_video",
        id: `youtube_${video.videoId}`,
        publishedAt: video.publishedAt,
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

  return router;
}
