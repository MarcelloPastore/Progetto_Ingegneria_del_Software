export interface JwtLike {
  sign(payload: unknown, options?: { expiresIn?: string }): string;
  verify(token: string): unknown;
}

export function getJwt(server: { jwt?: JwtLike }): JwtLike {
  if (!server.jwt) {
    throw new Error("JWT plugin non registrato");
  }

  return server.jwt;
}
