import axios from "axios";
import { YoutubeVideo } from "./database.js";

export class Youtube {
  private apiKey: string;
  private channelId: string;

  constructor(channelId: string, apiKey: string) {
    this.channelId = channelId;
    this.apiKey = apiKey;
  }

  async getRecentVideos(limit = 5): Promise<YoutubeVideo[]> {
    const searchResponse = await axios.get(
      "https://www.googleapis.com/youtube/v3/search",
      {
        params: {
          part: "snippet",
          channelId: this.channelId,
          maxResults: limit,
          order: "date",
          type: "video",
          key: this.apiKey,
        },
      }
    );

    const videoIds = searchResponse.data.items
      .map((item: any) => item.id.videoId)
      .join(",");

    const videoDetailsResponse = await axios.get(
      "https://www.googleapis.com/youtube/v3/videos",
      {
        params: {
          part: "snippet,liveStreamingDetails",
          id: videoIds,
          key: this.apiKey,
        },
      }
    );

    const videos: YoutubeVideo[] = videoDetailsResponse.data.items.map(
      (item: any) => ({
        id: item.id,
        type: "youtubeVideo",
        url: `https://www.youtube.com/watch?v=${item.id}`,
        publishedAt: new Date(item.snippet.publishedAt).toISOString(),
        updatedAt: new Date(item.snippet.publishedAt).toISOString(),
        channel: {
          name: item.snippet.channelTitle,
          imageUrl:
            "https://yt3.googleusercontent.com/S9JpZaNNSU3Mnpf1hcThTX9_idWkP80hGWJQq_phybGW_QsPkPkZ_PsVQohBSQkun8iSf_GDFg",
        },
        title: item.snippet.title,
        description: item.snippet.description,
        thumbnailUrl:
          item.snippet.thumbnails?.maxres?.url ??
          item.snippet.thumbnails?.high?.url ??
          item.snippet.thumbnails?.default?.url,
      })
    );

    return videos;
  }
}
