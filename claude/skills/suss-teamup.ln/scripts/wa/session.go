package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/skip2/go-qrcode"
	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/store"
	"go.mau.fi/whatsmeow/store/sqlstore"
	waLog "go.mau.fi/whatsmeow/util/log"
	_ "modernc.org/sqlite"
)

const linkedDeviceName = "digest agent"

var stateDir = envOr("TEAMUP_WA_STATE", filepath.Join(os.Getenv("HOME"), ".local/state/suss-teamup/wa"))

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func statePath(name string) string { return filepath.Join(stateDir, name) }

func openClient(ctx context.Context) (*whatsmeow.Client, error) {
	if err := os.MkdirAll(stateDir, 0o700); err != nil {
		return nil, err
	}
	sessionDB := statePath("session.db")
	container, err := sqlstore.New(ctx, "sqlite", "file:"+sessionDB+"?_pragma=foreign_keys(1)&_pragma=busy_timeout(5000)", nil)
	if err != nil {
		return nil, err
	}
	if err := os.Chmod(sessionDB, 0o600); err != nil {
		return nil, err
	}
	device, err := container.GetFirstDevice(ctx)
	if err != nil {
		return nil, err
	}
	store.SetOSInfo(linkedDeviceName, [3]uint32{1, 0, 0})
	return whatsmeow.NewClient(device, waLog.Stdout("whatsapp", "WARN", false)), nil
}

func link(ctx context.Context) error {
	client, err := openClient(ctx)
	if err != nil {
		return err
	}
	if client.Store.ID != nil {
		return fmt.Errorf("already linked as %s; delete %s to link again", client.Store.ID, statePath("session.db"))
	}
	qrCodes, err := client.GetQRChannel(ctx)
	if err != nil {
		return err
	}
	if err := client.Connect(); err != nil {
		return err
	}
	defer client.Disconnect()
	return showQRCodes(qrCodes)
}

func showQRCodes(qrCodes <-chan whatsmeow.QRChannelItem) error {
	page := statePath("link.html")
	opened := false
	for item := range qrCodes {
		switch item.Event {
		case whatsmeow.QRChannelEventCode:
			if err := writeQRPage(page, item.Code, item.Timeout); err != nil {
				return err
			}
			if !opened {
				opened = exec.Command("open", page).Run() == nil
			}
			fmt.Printf("QR code refreshed (valid %s); scan it from %s\n", item.Timeout, page)
		case "success":
			fmt.Println("linked")
			return os.WriteFile(page, []byte(linkedPage), 0o600)
		default:
			return fmt.Errorf("linking ended: %s %v", item.Event, item.Error)
		}
	}
	return fmt.Errorf("linking ended without a scan")
}

func writeQRPage(page, code string, valid time.Duration) error {
	if err := qrcode.WriteFile(code, qrcode.Medium, 512, statePath("link.png")); err != nil {
		return err
	}
	html := fmt.Sprintf(qrPage, time.Now().Unix(), valid.Round(time.Second))
	return os.WriteFile(page, []byte(html), 0o600)
}

const qrPage = `<!doctype html><meta charset="utf-8"><meta http-equiv="refresh" content="2">
<title>Link digest agent</title><body style="font-family:sans-serif;text-align:center;background:#fff">
<h2>WhatsApp → Linked devices → Link a device</h2><img src="link.png?%d" width="512"><p>Refreshes by itself; this code is valid %s.</p>`

const linkedPage = `<!doctype html><meta charset="utf-8"><title>Linked</title><body style="font-family:sans-serif;text-align:center"><h2>Linked. You can close this tab.</h2>`
