import { createHash } from "crypto";

const BASE58 = "123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ";

function toBase58(buffer: Buffer): string {
  let num = BigInt("0x" + buffer.toString("hex"));
  let result = "";

  while (num > 0) {
    const rem = Number(num % 58n);
    result = BASE58[rem] + result;
    num = num / 58n;
  }

  return result || "1";
}

// Generates a deterministic ID that's unique enough
export function generateShortId(input: string): string {
  const hash = createHash("sha256").update(input).digest();
  const first12Bytes = hash.subarray(0, 12);
  return toBase58(first12Bytes);
}
