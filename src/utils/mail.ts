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
};

type NodemailerModule = {
  createTransport(options: TransportOptions): MailTransporter;
};

export type VerificationMailInput = {
  to: string;
  username: string;
  verificationToken: string;
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
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (transporter as any).verify();
      // eslint-disable-next-line no-console
      console.log("Mail transporter verified: able to connect to SMTP host");
    } catch (err) {
      console.error("Mail transporter verification failed:", err);
      throw err;
    }
  }

  return transporter;
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

  let mailFrom = env.MAIL_FROM;

  if (env.MAIL_FROM_EMAIL) {
    if (env.MAIL_FROM_NAME) {
      mailFrom = `${env.MAIL_FROM_NAME} <${env.MAIL_FROM_EMAIL}>`;
    } else {
      mailFrom = env.MAIL_FROM_EMAIL;
    }
  }

  await (
    await getTransporter()
  ).sendMail({
    from: mailFrom,
    to,
    subject: "Verifica la tua email - CoinCasa",
    text: [
      `Ciao ${username},`,
      "",
      "grazie per esserti registrato su CoinCasa.",
      `Per verificare la tua email apri questo link: ${verificationUrl.toString()}`,
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
}
