package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

const usage = `usage: teamup-wa link | run <name> <subject> <handle> <group>...

  link  link this Mac as a WhatsApp device; shows a QR code to scan with the phone
  run   stay connected: log every message of the named groups, deliver live ones to a teamup channel`

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := dispatch(ctx, os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "teamup-wa:", err)
		os.Exit(1)
	}
}

func dispatch(ctx context.Context, args []string) error {
	switch {
	case len(args) == 1 && args[0] == "link":
		return link(ctx)
	case len(args) >= 5 && args[0] == "run":
		return run(ctx, delivery{name: args[1], subject: args[2], handle: args[3]}, args[4:])
	}
	return fmt.Errorf("%s", usage)
}
