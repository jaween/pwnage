import axios from "axios";
import xml2js from "xml2js";
import { YoutubeVideo } from "./database.js";

export class Youtube {
  private feedUrl: string;

  constructor(channelId: string) {
    this.feedUrl = `https://www.youtube.com/feeds/videos.xml?channel_id=${channelId}`;
  }

  async getRecentVideos(): Promise<YoutubeVideo[]> {
    let response;
    try {
      response = await axios.get(this.feedUrl, { responseType: "text" });
    } catch (error) {
      throw new Error("Error fetching the YouTube feed");
    }

    const parser = new xml2js.Parser();
    let result;
    try {
      result = await parser.parseStringPromise(response.data);
    } catch (e) {
      throw new Error("Error parsing XML");
    }

    const entries = result.feed.entry;
    if (!entries || !Array.isArray(entries)) {
      return [];
    }

    const videos: YoutubeVideo[] = [];
    for (const entry of entries) {
      let thumbnailUrl = entry["media:group"][0][
        "media:thumbnail"
      ][0].$.url.replace("hqdefault", "maxresdefault");
      videos.push({
        id: entry["yt:videoId"][0],
        type: "youtubeVideo",
        url: entry.link[0].$.href,
        publishedAt: entry.published[0],
        updatedAt: entry.updated[0],
        channel: {
          name: entry.author[0].name[0],
          // TODO: Get image from query
          imageUrl:
            "https://yt3.googleusercontent.com/S9JpZaNNSU3Mnpf1hcThTX9_idWkP80hGWJQq_phybGW_QsPkPkZ_PsVQohBSQkun8iSf_GDFg",
        },
        title: entry.title[0],
        description: entry["media:group"][0]["media:description"][0],
        thumbnailUrl: thumbnailUrl,
      });
    }

    return videos;
  }
}
