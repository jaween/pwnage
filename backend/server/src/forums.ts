import axios from "axios";
import xml2js from "xml2js";
import { ForumThread } from "./database.js";

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

    // Saves refetching the same avatar URL for repeat users
    const avatarUrls: { [uid: string]: string } = {};
    for (const entry of entries) {
      let authorAnchorTag = entry.author.name._;
      const authorUid = getQueryParamFromUrl(
        parseAnchorTag(authorAnchorTag)?.href ?? "",
        "uid"
      );
      if (!authorUid) {
        continue;
      }
      avatarUrls[authorUid] = "";
    }
    for (const uid of Object.keys(avatarUrls)) {
      avatarUrls[uid] = await queryAvatarUrl(uid);
    }

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
        publishedAt: new Date(entry.published).toISOString(),
        updatedAt: new Date(entry.updated).toISOString(),
        author: {
          uid: authorUid,
          name: authorName,
          avatarUrl: avatarUrls[authorUid],
        },
        content: entry.content?._,
      });
    }

    return threads;
  }
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

async function queryAvatarUrl(authorUid: string): Promise<string> {
  const baseUrl = "https://forum.8bitwars.com/uploads/avatars";
  const defaultAvatar = "https://forum.8bitwars.com/images/default_avatar.png";

  const tryUrl = async (url: string): Promise<boolean> => {
    try {
      const response = await axios.head(url);
      return response.status === 200;
    } catch {
      return false;
    }
  };

  const jpgUrl = `${baseUrl}/avatar_${authorUid}.jpg`;
  if (await tryUrl(jpgUrl)) {
    return jpgUrl;
  }

  const pngUrl = `${baseUrl}/avatar_${authorUid}.png`;
  if (await tryUrl(pngUrl)) {
    return pngUrl;
  }

  return defaultAvatar;
}
