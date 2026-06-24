type MailPayload = {
  from: string;
  to: string;
  subject: string;
  text: string;
  html: string;
};

type TransportOptions = {
  host: string;
  port: number;
  secure: boolean;
  auth?: {
    user?: string;
    pass?: string;
  };
};

type MailTransporter = {
  sendMail(payload: MailPayload): Promise<unknown>;
  verify?: () => Promise<unknown>;
};

type NodemailerModule = {
  createTransport(options: TransportOptions): MailTransporter;
};

export type VerificationMailInput = {
  to: string;
  username: string;
  verificationToken: string;
};

export type PasswordResetMailInput = {
  to: string;
  username: string;
  resetCode: string;
  expiresAt: string;
};

let transporter: MailTransporter | null = null;

function isNodemailerModule(value: unknown): value is NodemailerModule {
  if (typeof value !== "object" || value === null) {
    return false;
  }

  const candidate = value as Record<string, unknown>;
  return typeof candidate.createTransport === "function";
}

async function getTransporter(): Promise<MailTransporter> {
  const { env } = await import("../config/env");

  if (!transporter) {
    const nodemailerModuleUnknown: unknown = await import("nodemailer");

    if (!isNodemailerModule(nodemailerModuleUnknown)) {
      throw new Error("Nodemailer module is not available");
    }

    const nodemailerModule = nodemailerModuleUnknown;
    const secure = Boolean(env.MAIL_SECURE) || env.MAIL_PORT === 465;

    const transportOptions: TransportOptions = {
      host: env.MAIL_HOST,
      port: env.MAIL_PORT,
      secure,
      auth:
        env.MAIL_USER || env.MAIL_PASSWORD
          ? {
              user: env.MAIL_USER,
              pass: env.MAIL_PASSWORD,
            }
          : undefined,
    };

    transporter = nodemailerModule.createTransport(transportOptions);
    transporter.verify?.().catch((err) => {
      console.error("[MAIL] Transporter verification failed:", err);
    });
  }

  return transporter;
}

function formatMailFrom(env: {
  MAIL_FROM: string;
  MAIL_FROM_NAME?: string;
  MAIL_FROM_EMAIL?: string;
}): string {
  let mailFrom = env.MAIL_FROM;

  if (env.MAIL_FROM_EMAIL) {
    if (env.MAIL_FROM_NAME) {
      mailFrom = `${env.MAIL_FROM_NAME} <${env.MAIL_FROM_EMAIL}>`;
    } else {
      mailFrom = env.MAIL_FROM_EMAIL;
    }
  }

  return mailFrom;
}

export async function sendVerificationEmail({
  to,
  username,
  verificationToken,
}: VerificationMailInput): Promise<void> {
  const { env } = await import("../config/env");

  const verificationUrl = new URL(
    "/api/v1/auth/verifica-email",
    env.APP_PUBLIC_URL,
  );
  verificationUrl.searchParams.set("token", verificationToken);
  verificationUrl.searchParams.set("email", to);

  try {
    await (
      await getTransporter()
    ).sendMail({
      from: formatMailFrom(env),
      to,
      subject: "Verifica la tua email - CoinCasa",
      text: [
        `Ciao ${username},`,
        "",
        "grazie per esserti registrato su CoinCasa.",
        `Per verificare la tua email clicca su questo link: ${verificationUrl.toString()}`,
        "",
        "Se non hai richiesto questa registrazione puoi ignorare questa email.",
      ].join("\n"),
      html: `
        <p>Ciao <strong>${username}</strong>,</p>
        <p>Grazie per esserti registrato su CoinCasa.</p>
        <p>
          Per verificare la tua email clicca qui:
          <a href="${verificationUrl.toString()}">Verifica email</a>
        </p>
        <p>Se non hai richiesto questa registrazione puoi ignorare questa email.</p>
      `,
    });
  } catch (err) {
    console.error("Failed to send verification email:", err);
    throw err;
  }
}

export async function sendPasswordResetEmail({
  to,
  username,
  resetCode,
  expiresAt,
}: PasswordResetMailInput): Promise<void> {
  const { env } = await import("../config/env");

  const expiresAtDate = new Date(expiresAt);
  const formattedExpiry = Number.isNaN(expiresAtDate.getTime())
    ? expiresAt
    : expiresAtDate.toLocaleString("it-IT", {
        dateStyle: "short",
        timeStyle: "short",
      });

  try {
    await (
      await getTransporter()
    ).sendMail({
      from: formatMailFrom(env),
      to,
      subject: "Codice di recupero password - CoinCasa",
      text: [
        `Ciao ${username},`,
        "",
        "hai richiesto il recupero della password su CoinCasa.",
        `Il tuo codice di recupero è: ${resetCode}`,
        `Scade il: ${formattedExpiry}`,
        "",
        "Se non hai richiesto tu questa email puoi ignorarla.",
      ].join("\n"),
      html: `
        <p>Ciao <strong>${username}</strong>,</p>
        <p>Hai richiesto il recupero della password su CoinCasa.</p>
        <p style="font-size: 1.2rem; font-weight: 700; letter-spacing: 0.15em;">
          ${resetCode}
        </p>
        <p>Il codice scade il <strong>${formattedExpiry}</strong>.</p>
        <p>Se non hai richiesto tu questa email puoi ignorarla.</p>
      `,
    });
  } catch (err) {
    console.error("Failed to send password reset email:", err);
    throw err;
  }
}
