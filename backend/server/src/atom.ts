import { ForumThread, PatreonPost, Post, YoutubeVideo } from "./database";

export class AtomFeedService {
  private escapeXml(s: string): string {
    if (!s) {
      return "";
    }
    return s
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&apos;");
  }

  buildXml(posts: Post[], updatedDate: Date): string {
    const entries: string[] = [];

    for (const post of posts) {
      const id = this.escapeXml(post.id);
      const updated = this.escapeXml(post.updatedAt);
      const published = this.escapeXml(post.publishedAt);

      let title = "";
      let link = "";
      let summary = "";

      switch (post.data.type) {
        case "youtubeVideo": {
          const data = post.data as YoutubeVideo;
          title = this.escapeXml(data.title);
          link = this.escapeXml(data.url);
          summary = this.escapeXml(data.description);
          break;
        }
        case "forumThread": {
          const data = post.data as ForumThread;
          title = this.escapeXml(data.title);
          link = this.escapeXml(data.url);
          summary = this.escapeXml(data.content.slice(0, 500));
          break;
        }
        case "patreonPost": {
          const data = post.data as PatreonPost;
          title = this.escapeXml(data.title);
          link = this.escapeXml(data.url);
          summary = this.escapeXml(data.teaserText ?? "");
          break;
        }
      }

      entries.push(`<entry>
  <id>${id}</id>
  <title>${title}</title>
  <link href="${link}" />
  <updated>${updated}</updated>
  <published>${published}</published>
  <summary type="html"><![CDATA[${summary}]]></summary>
</entry>`);
    }

    const entriesXml = entries.join("\n");
    const feedUpdated = updatedDate.toISOString();
    return `<?xml version="1.0" encoding="utf-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Posts Feed</title>
  <updated>${feedUpdated}</updated>
  <id>https://tehpwnage.com/posts/atom</id>
  ${entriesXml}
</feed>`;
  }
}
