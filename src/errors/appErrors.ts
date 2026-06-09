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

export class AuthenticatedUserNotFoundError extends Error {
  constructor() {
    super("Utente autenticato non trovato");
    this.name = "AuthenticatedUserNotFoundError";
  }
}

export class UserNotFoundError extends Error {
  constructor() {
    super("Utente non trovato");
    this.name = "UserNotFoundError";
  }
}

export class InvalidOrExpiredResetCodeError extends Error {
  constructor() {
    super("Codice di recupero non valido o scaduto");
    this.name = "InvalidOrExpiredResetCodeError";
  }
}

export class EmailDeliveryError extends Error {
  constructor() {
    super("Impossibile inviare l'email di verifica");
    this.name = "EmailDeliveryError";
  }
}

export class PasswordResetEmailDeliveryError extends Error {
  constructor() {
    super("Impossibile inviare l'email di recupero password");
    this.name = "PasswordResetEmailDeliveryError";
  }
}

export class InvalidEmailVerificationTokenError extends Error {
  constructor() {
    super("Token di verifica email non valido o scaduto");
    this.name = "InvalidEmailVerificationTokenError";
  }
}
