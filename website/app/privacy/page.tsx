export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-2xl px-6 py-20">
      <h1 className="mb-8 text-3xl font-medium">Privacy Policy</h1>
      <p className="mb-2 text-xs text-muted-foreground">
        Last updated: April 3, 2026
      </p>

      <div className="flex flex-col gap-6 text-sm leading-relaxed text-muted-foreground">
        <section>
          <h2 className="mb-2 text-base font-medium text-foreground">
            No data collection
          </h2>
          <p>
            Oneshot does not collect, store, transmit, or share any personal
            data. No analytics, no tracking, no telemetry.
          </p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-medium text-foreground">
            Screenshots
          </h2>
          <p>
            Screenshots you capture are held in memory only on your Mac. They
            are never written to disk and are never sent to any server. They are
            served exclusively on localhost and are only accessible from your own
            machine. Screenshots are automatically deleted after they are read or
            after a configurable expiry period.
          </p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-medium text-foreground">
            Network
          </h2>
          <p>
            Oneshot runs a local HTTP server on localhost. No network requests
            are made to any external server. The app does not communicate with
            the internet in any way.
          </p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-medium text-foreground">
            Screen Recording permission
          </h2>
          <p>
            Oneshot requires macOS Screen Recording permission to capture
            screenshots using ScreenCaptureKit. This permission is used solely
            for the screenshot capture functionality. No screen data is recorded,
            stored persistently, or transmitted.
          </p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-medium text-foreground">
            Third parties
          </h2>
          <p>
            Oneshot does not include any third-party analytics, advertising, or
            tracking frameworks.
          </p>
        </section>

        <section>
          <h2 className="mb-2 text-base font-medium text-foreground">
            Contact
          </h2>
          <p>
            If you have questions about this privacy policy, open an issue on{" "}
            <a
              href="https://github.com/Kalypsokichu-code/shots-for-agents"
              className="text-foreground underline underline-offset-4"
            >
              GitHub
            </a>
            .
          </p>
        </section>
      </div>
    </div>
  )
}
