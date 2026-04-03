import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { AgentChat } from "@/components/agent-chat"
import { AppIcon } from "@/components/app-icon"
import {
  Timer,
  Terminal,
  Eye,
  GithubLogo,
  Desktop,
  HardDrive,
  Gear,
  NotePencil,
  Images,
} from "@phosphor-icons/react/dist/ssr"

function TerminalBlock({
  children,
  title,
}: {
  children: React.ReactNode
  title?: string
}) {
  return (
    <div className="overflow-hidden rounded-lg border border-border/50 bg-zinc-950">
      {title && (
        <div className="border-b border-border/30 px-4 py-2 text-[11px] text-muted-foreground">
          {title}
        </div>
      )}
      <pre
        className="scrollbar-none overflow-x-auto p-4 text-[13px] leading-relaxed text-zinc-300"
        style={{ scrollbarWidth: "none" }}
      >
        <code>{children}</code>
      </pre>
    </div>
  )
}

function Step({
  number,
  title,
  children,
}: {
  number: number
  title: string
  children: React.ReactNode
}) {
  return (
    <div className="flex gap-4">
      <div className="flex size-8 shrink-0 items-center justify-center rounded-full border border-border/50 bg-card text-xs font-medium text-primary">
        {number}
      </div>
      <div>
        <h3 className="mb-1 text-sm font-medium">{title}</h3>
        <p className="text-sm leading-relaxed text-muted-foreground">
          {children}
        </p>
      </div>
    </div>
  )
}

function FeatureCard({
  icon,
  title,
  description,
}: {
  icon: React.ReactNode
  title: string
  description: string
}) {
  return (
    <Card className="border-border/50 bg-card/50">
      <CardContent className="flex flex-col gap-2 p-5">
        <div className="text-primary">{icon}</div>
        <h3 className="text-sm font-medium">{title}</h3>
        <p className="text-xs leading-relaxed text-muted-foreground">
          {description}
        </p>
      </CardContent>
    </Card>
  )
}

export default function Page() {
  return (
    <div className="min-h-svh">
      {/* Hero */}
      <section className="mx-auto max-w-5xl px-6 pt-24 pb-20">
        <div className="flex flex-col gap-6">
          <AppIcon className="size-16" />

          <h1 className="max-w-2xl text-3xl font-medium tracking-tight sm:text-4xl lg:text-5xl">
            One-time screenshots for AI agents.
          </h1>

          <div className="flex flex-wrap gap-3">
            {/* TODO: Uncomment when App Store listing is live
            <a href="#" className="inline-flex">
              <Button size="lg" className="gap-2">
                <Desktop size={16} />
                Download for Mac
              </Button>
            </a>
            */}
            <a
              href="https://github.com/Kalypsokichu-code/shots-for-agents"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex"
            >
              <Button size="lg" className="gap-2">
                <GithubLogo size={16} />
                GitHub
              </Button>
            </a>
          </div>
        </div>

        {/* Full-width animated chat */}
        <div className="mt-12">
          <AgentChat />
        </div>
      </section>

      {/* How It Works */}
      <section className="border-t border-border/30 px-6 py-20">
        <div className="mx-auto grid max-w-5xl gap-12 lg:grid-cols-[1fr_1.2fr]">
          <div>
            <h2 className="mb-2 text-2xl font-medium">How it works</h2>
            <p className="mb-8 text-sm text-muted-foreground">
              Three steps. No config required.
            </p>

            <div className="flex flex-col gap-6">
              <Step number={1} title="Capture">
                <kbd className="rounded border border-border/50 bg-muted px-1.5 py-0.5 text-xs">
                  Ctrl+Shift+S
                </kbd>{" "}
                → select a region, add a note for context. Take as many as you
                need.
              </Step>

              <Step number={2} title="Paste">
                Clipboard gets curl commands. Paste into your agent.
              </Step>

              <Step number={3} title="Gone">
                Agent reads them, screenshots expire.{" "}
                <code className="text-xs text-red-400">410 Gone</code>.
              </Step>
            </div>
          </div>

          <TerminalBlock title="Terminal — agent fetches 3 screenshots">
            <span className="text-zinc-500">$</span>{" "}
            <span className="text-emerald-400">curl</span> -s -o
            /tmp/shot-A1B2C3D4.png http://localhost:9853/s/A1B2C3D4.png{"\n"}
            <span className="text-zinc-500">$</span>{" "}
            <span className="text-emerald-400">curl</span> -s -o
            /tmp/shot-E5F6G7H8.png http://localhost:9853/s/E5F6G7H8.png{"\n"}
            <span className="text-zinc-500">$</span>{" "}
            <span className="text-emerald-400">curl</span> -s -o
            /tmp/shot-I9J0K1L2.png http://localhost:9853/s/I9J0K1L2.png{"\n"}
            <span className="text-zinc-500">
              $ # Agent reads all 3 screenshots
            </span>
            {"\n\n"}
            <span className="text-zinc-500">$</span>{" "}
            <span className="text-emerald-400">curl</span> -s
            http://localhost:9853/s/A1B2C3D4.png{"\n"}
            <span className="text-red-400">Gone</span>{" "}
            <span className="text-zinc-500">(HTTP 410)</span>
            {"\n"}
            <span className="text-zinc-500">$</span>{" "}
            <span className="text-emerald-400">curl</span> -s
            http://localhost:9853/s/E5F6G7H8.png{"\n"}
            <span className="text-red-400">Gone</span>{" "}
            <span className="text-zinc-500">(HTTP 410)</span>
            {"\n"}
            <span className="text-zinc-500">$</span>{" "}
            <span className="text-emerald-400">curl</span> -s
            http://localhost:9853/s/I9J0K1L2.png{"\n"}
            <span className="text-red-400">Gone</span>{" "}
            <span className="text-zinc-500">(HTTP 410)</span>
          </TerminalBlock>
        </div>
      </section>

      {/* Batch Capture */}
      <section className="border-t border-border/30 px-6 py-20">
        <div className="mx-auto max-w-5xl">
          <div className="mb-8 max-w-lg">
            <Badge variant="secondary" className="mb-3">
              Batch Capture
            </Badge>
            <h2 className="mb-2 text-2xl font-medium">
              Multiple screenshots, one paste
            </h2>
            <p className="text-sm leading-relaxed text-muted-foreground">
              Snap multiple regions. One paste, all screenshots.
            </p>
          </div>

          <TerminalBlock title="Clipboard contents">
            {"| Screenshot | Fetch |\n"}
            {"|------------|-------|\n"}
            {
              "| shot-1     | `curl -s -o /tmp/shot-A1B2C3D4.png http://localhost:9853/s/...` |\n"
            }
            {
              "| shot-2     | `curl -s -o /tmp/shot-E5F6G7H8.png http://localhost:9853/s/...` |\n"
            }
            {
              "| shot-3     | `curl -s -o /tmp/shot-I9J0K1L2.png http://localhost:9853/s/...` |"
            }
          </TerminalBlock>
        </div>
      </section>

      {/* Features Grid */}
      <section className="border-t border-border/30 px-6 py-20">
        <div className="mx-auto max-w-5xl">
          <h2 className="mb-8 text-2xl font-medium">
            Built for the AI workflow
          </h2>

          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            <FeatureCard
              icon={<Eye size={20} />}
              title="Menu bar only"
              description="Lives in your menu bar with thumbnail previews of recent captures. Edit annotations or remove shots before pasting."
            />
            <FeatureCard
              icon={<HardDrive size={20} />}
              title="Nothing on disk"
              description="Screenshots live in memory only. When the app quits, everything is gone."
            />
            <FeatureCard
              icon={<Timer size={20} />}
              title="Configurable expiry"
              description="Unread screenshots expire after 10 minutes. Read screenshots stay for 60 seconds after first fetch. Both configurable."
            />
            <FeatureCard
              icon={<Terminal size={20} />}
              title="Curl, not URLs"
              description="Clipboard gets a curl command, not a URL. AI agents can't fetch localhost, but they can run shell commands."
            />
            <FeatureCard
              icon={<Gear size={20} />}
              title="Configurable"
              description="Change the port, expiry times, capture shortcut, and launch-at-login from the settings window."
            />
            <FeatureCard
              icon={<NotePencil size={20} />}
              title="Annotations"
              description="Add a note after each capture to tell the AI what to look at. Edit or remove annotations anytime before pasting."
            />
            <FeatureCard
              icon={<Images size={20} />}
              title="Capture management"
              description="Preview, edit, and remove individual captures from the menu bar. Captures auto-clear once the AI reads them."
            />
            <FeatureCard
              icon={<GithubLogo size={20} />}
              title="Open source"
              description="MIT licensed. Read the code, fork it, contribute. Built with Swift, ScreenCaptureKit, and FlyingFox."
            />
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border/30 px-6 py-10">
        <div className="mx-auto flex max-w-5xl flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm text-muted-foreground">
            Built for people who talk to AI all day.
          </p>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
            <a
              href="https://github.com/Kalypsokichu-code/shots-for-agents"
              target="_blank"
              rel="noopener noreferrer"
              className="transition-colors hover:text-foreground"
            >
              GitHub
            </a>
            <span className="text-border">·</span>
            <a href="/privacy" className="transition-colors hover:text-foreground">
              Privacy
            </a>
            <span className="text-border">·</span>
            <span>MIT License</span>
            <span className="text-border">·</span>
            <a
              href="https://www.instagram.com/kalypsodesigns"
              target="_blank"
              rel="noopener noreferrer"
              className="transition-colors hover:text-foreground"
            >
              Made by Kalypso
            </a>
          </div>
        </div>
      </footer>
    </div>
  )
}
