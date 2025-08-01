import axios from "axios";
import { PatreonPost, patreonPostSchema } from "./database.js";

export class Patreon {
  private campaignId: string;
  private baseUrl = "https://www.patreon.com/api/posts";

  constructor(campaignId: string) {
    this.campaignId = campaignId;
  }

  async getRecentPosts(limit = 5): Promise<PatreonPost[]> {
    const response = await axios.get(`${this.baseUrl}`, {
      params: {
        "filter[campaign_id]": this.campaignId,
        "filter[is_draft]": false,
        "page[size]": limit,
        "fields[post]":
          "id,url,title,teaser_text,content,image,thumbnail_url,published_at",
        include: "images",
      },
    });

    const data = response.data;

    const imagesById: Record<string, any> = {};
    if (Array.isArray(data.included)) {
      for (const included of data.included) {
        if (included.type === "media" && included.id) {
          imagesById[included.id] = included;
        }
      }
    }

    let posts: PatreonPost[] = [];
    for (const entry of data.data) {
      try {
        posts.push(
          patreonPostSchema.parse({
            id: entry.id,
            type: "patreonPost",
            url: entry.attributes.url,
            publishedAt: entry.attributes.published_at,
            title: entry.attributes.title,
            teaserText: entry.attributes.teaser_text ?? null,
            imageUrl: entry.attributes.image?.thumb_url ?? null,
          })
        );
      } catch (e) {
        console.error(e);
        continue;
      }
    }

    return posts;
  }
}
