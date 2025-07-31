import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getFirestore, Firestore } from "firebase-admin/firestore";

export class Database {
  private firestore: Firestore;

  constructor() {
    initFirebaseAdmin();
    this.firestore = getFirestore();
  }
}

function initFirebaseAdmin() {
  initializeApp({
    credential: applicationDefault(),
  });
}
