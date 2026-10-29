package main

import (
	"context"
	"fmt"
	"log"
	"os/exec"
	"strings"
	"sync"
	"unicode"

	"go.mau.fi/whatsmeow"
	"go.mau.fi/whatsmeow/types"
	"go.mau.fi/whatsmeow/types/events"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/reflect/protoreflect"
)

type delivery struct{ name, subject, handle string }

var teamupBin = envOr("TEAMUP_BIN", "teamup")

type daemon struct {
	client    *whatsmeow.Client
	log       *messageLog
	delivery  delivery
	names     []string
	groupsMu  sync.RWMutex
	groupName map[types.JID]string
}

func run(ctx context.Context, target delivery, names []string) error {
	client, err := openClient(ctx)
	if err != nil {
		return err
	}
	if client.Store.ID == nil {
		return fmt.Errorf("not linked yet; run: teamup-wa-watch link")
	}
	messages, err := openMessageLog(statePath("messages.jsonl"))
	if err != nil {
		return err
	}
	session := &daemon{client: client, log: messages, delivery: target, names: names}
	client.AddEventHandler(session.handleEvent(ctx))
	if err := client.Connect(); err != nil {
		return err
	}
	defer client.Disconnect()
	<-ctx.Done()
	return nil
}

func (session *daemon) handleEvent(ctx context.Context) func(any) {
	return func(event any) {
		switch event := event.(type) {
		case *events.Connected:
			go session.resolveGroups(ctx)
		case *events.LoggedOut:
			log.Println("logged out by WhatsApp; link again")
		case *events.Message:
			session.record(event, false)
		case *events.HistorySync:
			session.recordHistory(ctx, event)
		}
	}
}

func (session *daemon) resolveGroups(ctx context.Context) {
	joined, err := session.client.GetJoinedGroups(ctx)
	if err != nil {
		log.Println("list groups:", err)
		return
	}
	found := map[types.JID]string{}
	for _, group := range joined {
		if session.isWatched(group.Name) {
			found[group.JID] = group.Name
		}
	}
	session.groupsMu.Lock()
	session.groupName = found
	session.groupsMu.Unlock()
	log.Printf("watching %d of %d named groups: %v", len(found), len(session.names), found)
}

func (session *daemon) isWatched(name string) bool {
	for _, wanted := range session.names {
		if normalizedName(name) == normalizedName(wanted) {
			return true
		}
	}
	return false
}

func normalizedName(name string) string {
	return strings.ToLower(strings.Join(strings.Fields(name), " "))
}

func (session *daemon) watchedGroup(chat types.JID) (string, bool) {
	session.groupsMu.RLock()
	defer session.groupsMu.RUnlock()
	name, ok := session.groupName[chat]
	return name, ok
}

func (session *daemon) hasResolvedGroups() bool {
	session.groupsMu.RLock()
	defer session.groupsMu.RUnlock()
	return session.groupName != nil
}

func (session *daemon) recordHistory(ctx context.Context, sync *events.HistorySync) {
	if !session.hasResolvedGroups() {
		session.resolveGroups(ctx)
	}
	for _, conversation := range sync.Data.GetConversations() {
		chat, err := types.ParseJID(conversation.GetID())
		if err != nil {
			continue
		}
		if _, ok := session.watchedGroup(chat); !ok {
			continue
		}
		for _, past := range conversation.GetMessages() {
			if message, err := session.client.ParseWebMessage(chat, past.GetMessage()); err == nil {
				session.record(message, true)
			}
		}
	}
}

func (session *daemon) record(message *events.Message, fromHistory bool) {
	group, ok := session.watchedGroup(message.Info.Chat)
	text := describeMessage(message)
	if !ok || text == "" || !hasContent(message.Message.ProtoReflect()) {
		return
	}
	if message.Info.MediaType != "" && strings.TrimSpace(captionOf(text)) == "" {
		log.Printf("media without caption %s: %.20000s", message.Info.ID, protojson.Format(message.Message))
	}
	logged := entry{ID: message.Info.ID, Time: message.Info.Timestamp, Group: group, Sender: message.Info.Sender.User,
		Name: message.Info.PushName, ByMe: message.Info.IsFromMe, Text: text, History: fromHistory}
	isNew, err := session.log.record(logged)
	if err != nil {
		log.Println("record message:", err)
	}
	if isNew && !fromHistory && !logged.ByMe && hasWords(captionOf(logged.Text)) {
		session.deliver(logged)
	}
}

func (session *daemon) deliver(logged entry) {
	target := session.delivery
	body := fmt.Sprintf("@%s new in %s: %s: %s", target.handle, logged.Group, firstNonEmpty(logged.Name, logged.Sender), logged.Text)
	var err error
	for attempt := 0; attempt < deliveryAttempts; attempt++ {
		exec.Command(teamupBin, "recv", target.subject, "--as", target.name).Run()
		if err = exec.Command(teamupBin, "say", target.subject, "--as", target.name, "--", body).Run(); err == nil {
			return
		}
	}
	log.Println("deliver:", err)
}

const deliveryAttempts = 5

func captionOf(text string) string {
	if strings.HasPrefix(text, "[") {
		if end := strings.Index(text, "]"); end > 0 {
			return text[end+1:]
		}
	}
	return text
}

func hasWords(text string) bool {
	return strings.IndexFunc(text, func(char rune) bool { return unicode.IsLetter(char) || unicode.IsDigit(char) }) >= 0
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func describeMessage(message *events.Message) string {
	text := firstTextField(message.Message.ProtoReflect())
	if message.Info.MediaType == "" || message.Info.MediaType == "url" {
		return text
	}
	return strings.TrimSpace("[" + message.Info.MediaType + "] " + text)
}

var keyExchangeFieldNames = map[protoreflect.Name]bool{"senderKeyDistributionMessage": true, "messageContextInfo": true}

func hasContent(message protoreflect.Message) bool {
	found := false
	message.Range(func(field protoreflect.FieldDescriptor, _ protoreflect.Value) bool {
		found = !keyExchangeFieldNames[field.Name()]
		return !found
	})
	return found
}

var textFieldNames = map[protoreflect.Name]bool{"conversation": true, "text": true, "caption": true}

func firstTextField(message protoreflect.Message) string {
	found := ""
	message.Range(func(field protoreflect.FieldDescriptor, value protoreflect.Value) bool {
		switch {
		case field.Kind() == protoreflect.StringKind && !field.IsList() && textFieldNames[field.Name()]:
			found = value.String()
		case field.Kind() == protoreflect.MessageKind && !field.IsList() && !field.IsMap():
			found = firstTextField(value.Message())
		}
		return found == ""
	})
	return found
}
