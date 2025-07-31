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
}

function initFirebaseAdmin() {
  initializeApp({
    credential: applicationDefault(),
  });
}

const youtubeVideoSchema = z.object({
  id: z.string(),
  title: z.string(),
  url: z.url(),
  publishedAt: z.string(),
  updatedAt: z.string(),
  thumbnailUrl: z.url(),
  description: z.string(),
  likes: z.int(),
  views: z.int(),
});

export type YoutubeVideo = z.infer<typeof youtubeVideoSchema>;

const forumThreadSchema = z.object({
  id: z.string(),
  title: z.string(),
  url: z.url(),
  publishedAt: z.string(),
  updatedAt: z.string(),
  uid: z.string(),
  author: z.string(),
  avatarUrl: z.string(),
  content: z.string(),
});

export type ForumThread = z.infer<typeof forumThreadSchema>;

const postSchema = z.object({
  type: z.union([z.literal("youtube_video"), z.literal("forum_thread")]),
  id: z.string(),
  publishedAt: z.string(),
  data: z.union([youtubeVideoSchema, forumThreadSchema]),
});

export type Post = z.infer<typeof postSchema>;
