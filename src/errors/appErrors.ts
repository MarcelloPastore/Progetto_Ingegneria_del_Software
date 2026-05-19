export class DuplicateUserError extends Error {
  constructor() {
    super("L'utente esiste già");
    this.name = "DuplicateUserError";
  }
}

export class InvalidCredentialsError extends Error {
  constructor() {
    super("Credenziali errate");
    this.name = "InvalidCredentialsError";
  }
}

export class MissingAuthTokenError extends Error {
  constructor() {
    super("Token mancante");
    this.name = "MissingAuthTokenError";
  }
}

export class MalformedAuthorizationHeaderError extends Error {
  constructor() {
    super("Intestazione Authorization malformata");
    this.name = "MalformedAuthorizationHeaderError";
  }
}

export class InvalidTokenPayloadError extends Error {
  constructor() {
    super("Payload token non valido");
    this.name = "InvalidTokenPayloadError";
  }
}
