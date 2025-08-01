import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, Firestore } from "firebase-admin/firestore";
import z from "zod";

export class Database {
  private firestore: Firestore;

  constructor() {
    initFirebaseAdmin();
    this.firestore = getFirestore();
  }

  async putPosts(posts: Post[]) {
    const batch = this.firestore.batch();
    for (const post of posts) {
      batch.set(this.firestore.collection("posts").doc(post.id), post, {
        merge: true,
      });
    }
    await batch.commit();
  }

  async getPostsBefore(publishedAt: string, limit: number): Promise<Post[]> {
    const snapshot = await this.firestore
      .collection("posts")
      .where("publishedAt", "<", publishedAt)
      .orderBy("publishedAt", "desc")
      .limit(limit)
      .get();

    const posts: Post[] = [];
    for (const doc of snapshot.docs) {
      const data = doc.data();
      try {
        posts.push(postSchema.parse(data));
      } catch (e) {
        console.warn(`Invalid Post data for document ${doc.id}`);
      }
    }

    return posts;
  }
}

function initFirebaseAdmin() {
  initializeApp({
    credential: applicationDefault(),
  });
}

const youtubeVideoSchema = z.object({
  id: z.string(),
  type: z.literal("youtubeVideo"),
  title: z.string(),
  url: z.string(),
  publishedAt: z.string(),
  updatedAt: z.string(),
  thumbnailUrl: z.string(),
  description: z.string(),
  likes: z.int(),
  views: z.int(),
});

export type YoutubeVideo = z.infer<typeof youtubeVideoSchema>;

const forumThreadSchema = z.object({
  id: z.string(),
  type: z.literal("forumThread"),
  title: z.string(),
  url: z.string(),
  publishedAt: z.string(),
  updatedAt: z.string().nullable().optional(),
  uid: z.string(),
  author: z.string(),
  avatarUrl: z.string(),
  content: z.string(),
});

export type ForumThread = z.infer<typeof forumThreadSchema>;

export const patreonPostSchema = z.object({
  id: z.string(),
  type: z.literal("patreonPost"),
  url: z.string(),
  publishedAt: z.string(),
  title: z.string(),
  teaserText: z.string().nullable().optional(),
  imageUrl: z.string().nullable().optional(),
});

export type PatreonPost = z.infer<typeof patreonPostSchema>;

const postSchema = z.object({
  id: z.string(),
  publishedAt: z.string(),
  updatedAt: z.string(),
  url: z.string(),
  data: z.discriminatedUnion("type", [
    youtubeVideoSchema,
    forumThreadSchema,
    patreonPostSchema,
  ]),
});

export type Post = z.infer<typeof postSchema>;
