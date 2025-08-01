import { Request, Response, NextFunction } from "express";
import { OAuth2Client } from "google-auth-library";

export class GCPAuthMiddleware {
  private client = new OAuth2Client();
  private expectedEmail: string;
  private audience: string;

  constructor(projectId: string, region: string, expectedEmail: string) {
    this.expectedEmail = expectedEmail;
    this.audience = `https://${region}-${projectId}.a.run.app`;
  }

  middleware = async (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith("Bearer ")) {
      return res.status(401).send("Missing or invalid auth header");
    }

    const token = authHeader.split(" ")[1];
    try {
      const ticket = await this.client.verifyIdToken({
        idToken: token,
        audience: this.audience,
      });

      const payload = ticket.getPayload();
      if (payload?.email !== this.expectedEmail) {
        return res.status(403).send("Unauthorized caller");
      }

      next();
    } catch {
      return res.status(401).send("Token verification failed");
    }
  };
}
