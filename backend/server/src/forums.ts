import axios from "axios";
import xml2js from "xml2js";
import { ForumThread } from "./database.js";

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

export class Forums {
  private atomBaseUrl: string;

  constructor(atomBaseUrl: string) {
    this.atomBaseUrl = atomBaseUrl;
  }

  async getRecentThreads(limit = 5): Promise<ForumThread[]> {
    let response;
    try {
      response = await axios.get(`${this.atomBaseUrl}&limit=${limit}`, {
        responseType: "text",
      });
    } catch (error) {
      throw new Error("Error fetching the forum feed");
    }

    const parser = new xml2js.Parser({
      explicitArray: false,
      explicitCharkey: false,
      mergeAttrs: true,
      trim: true,
      normalizeTags: true,
    });

    let result;
    try {
      result = await parser.parseStringPromise(response.data);
    } catch (e) {
      throw new Error("Error parsing XML");
    }

    let entries = result.feed.entry;
    if (!entries) return [];
    if (!Array.isArray(entries)) {
      entries = [entries];
    }

    const threads: ForumThread[] = [];

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

      threads.push({
        id: threadId,
        type: "forumThread",
        title: entry.title._,
        url: entry.link?.href,
        publishedAt: entry.published,
        updatedAt: entry.updated,
        uid: authorUid,
        author: authorName,
        avatarUrl: `https://forum.8bitwars.com/uploads/avatars/avatar_${authorUid}.png`,
        content: entry.content?._,
      });
    }

    return threads;
  }
}
