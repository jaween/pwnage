import { Request, Response, Router } from "express";
import { Database } from "./database.js";

export function router(database: Database): Router {
  const router = Router();

  router.get("/pwnage", async (req: Request, res: Response) => {
    return res.json({ test: 1234 });
  });

  return router;
}
